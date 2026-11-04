'use strict';

// Documented API: https://docs.github.com/en/rest/pages/pages
// Keep deployment inside the existing Actions allowlist and use the job's OIDC
// identity. No repository write token or additional deployment secret is needed.
module.exports = async function deployPages({
  github,
  context,
  core,
  artifactId,
  timeoutMs = 600_000,
  pollIntervalMs = 5_000,
  now = Date.now,
  sleep = ms => new Promise(resolve => setTimeout(resolve, ms)),
}) {
  if (context.ref !== 'refs/heads/main' || context.eventName === 'pull_request') {
    throw new Error('GitHub Pages may only be deployed from main.');
  }
  if (!/^\d+$/.test(String(artifactId)) ||
      !Number.isSafeInteger(Number(artifactId)) || Number(artifactId) <= 0) {
    throw new Error('The website build did not provide a valid artifact ID.');
  }
  if (!Number.isFinite(timeoutMs) || timeoutMs <= 0 ||
      !Number.isFinite(pollIntervalMs) || pollIntervalMs <= 0) {
    throw new Error('Deployment timeout and polling interval must be positive.');
  }

  // Do not include request objects in errors: the creation request contains an
  // OIDC token. GitHub API status codes are sufficient for actionable failures.
  async function request(route, parameters) {
    try {
      return await github.request(route, {
        ...context.repo,
        ...parameters,
        request: { timeout: 30_000 },
      });
    } catch (error) {
      const status = Number.isInteger(error.status) ? ` (HTTP ${error.status})` : '';
      throw new Error(`GitHub Pages API request failed${status}: ${route}.`);
    }
  }

  const oidcToken = await core.getIDToken();
  if (typeof oidcToken !== 'string' || !oidcToken) {
    throw new Error('GitHub did not provide a deployment OIDC token.');
  }
  const { data: deployment } = await request(
    'POST /repos/{owner}/{repo}/pages/deployments',
    {
      artifact_id: Number(artifactId),
      pages_build_version: context.sha,
      oidc_token: oidcToken,
    },
  );
  if (!deployment || !deployment.id) {
    throw new Error('GitHub did not return a Pages deployment ID.');
  }
  const deploymentId = deployment.id;
  const deadline = now() + timeoutMs;
  const terminalErrors = new Set([
    'deployment_failed', 'deployment_content_failed',
    'deployment_cancelled', 'deployment_lost',
  ]);
  let finished = false;

  try {
    if (typeof deployment.page_url !== 'string' || !deployment.page_url) {
      throw new Error('GitHub did not return a Pages URL.');
    }
    core.info(`Checking Pages deployment ${deploymentId}.`);
    while (now() < deadline) {
      const { data } = await request(
        'GET /repos/{owner}/{repo}/pages/deployments/{pages_deployment_id}',
        { pages_deployment_id: deploymentId },
      );
      if (!data || typeof data.status !== 'string' || !data.status) {
        throw new Error('GitHub returned no Pages deployment status.');
      }
      if (data.status === 'succeed') {
        finished = true;
        core.setOutput('page_url', deployment.page_url);
        core.info(`Published ${deployment.page_url}`);
        return deployment.page_url;
      }
      if (terminalErrors.has(data.status)) {
        finished = true;
        throw new Error(`Pages deployment ended with ${data.status}.`);
      }
      core.info(`Pages deployment status: ${data.status}.`);
      await sleep(Math.min(pollIntervalMs, Math.max(0, deadline - now())));
    }
    throw new Error('Timed out waiting for the Pages deployment.');
  } finally {
    // Avoid leaving an unfinished deployment active after a timeout/API error.
    if (!finished) {
      try {
        await request(
          'POST /repos/{owner}/{repo}/pages/deployments/{pages_deployment_id}/cancel',
          { pages_deployment_id: deploymentId },
        );
      } catch (error) {
        core.warning(error.message);
      }
    }
  }
};
