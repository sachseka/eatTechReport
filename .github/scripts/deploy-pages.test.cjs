'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const deploy = require('./deploy-pages.cjs');

function mock(options = {}) {
  const calls = [];
  const outputs = {};
  const messages = [];
  let time = 0;
  let statusIndex = 0;
  const statuses = options.statuses || ['queued', 'succeed'];
  const input = {
    artifactId: '12345',
    context: {
      ref: 'refs/heads/main', eventName: 'push', sha: 'test-sha',
      repo: { owner: 'sachseka', repo: 'eatTechReport' },
    },
    timeoutMs: 20,
    pollIntervalMs: 5,
    now: () => time,
    sleep: async ms => { time += ms; },
    core: {
      getIDToken: async () => options.token === undefined ? 'private-oidc' : options.token,
      setOutput: (key, value) => { outputs[key] = value; },
      info: value => messages.push(value),
      warning: value => messages.push(value),
    },
    github: {
      request: async (route, params) => {
        calls.push({ route, params });
        if (route.endsWith('/cancel')) {
          if (options.cancelError) throw options.cancelError;
          return { data: {} };
        }
        if (route.startsWith('POST')) {
          if (options.createError) throw options.createError;
          return { data: options.deployment || {
            id: 'deploy-1', page_url: 'https://sachseka.github.io/eatTechReport/',
          } };
        }
        if (options.statusError) throw options.statusError;
        const status = statuses[Math.min(statusIndex++, statuses.length - 1)];
        return { data: { status } };
      },
    },
  };
  return { input, calls, outputs, messages };
}

test('deploys the exact build artifact with OIDC and waits for success', async () => {
  const m = mock();
  const url = await deploy(m.input);
  assert.equal(url, 'https://sachseka.github.io/eatTechReport/');
  assert.equal(m.outputs.page_url, url);
  assert.equal(m.calls[0].params.artifact_id, 12345);
  assert.equal(m.calls[0].params.pages_build_version, 'test-sha');
  assert.equal(m.calls[0].params.oidc_token, 'private-oidc');
  assert.equal(m.calls[1].params.pages_deployment_id, 'deploy-1');
  assert.equal(m.calls.length, 3);
  assert.ok(m.messages.every(message => !message.includes('private-oidc')));
});

test('refuses pull requests and non-main branches before contacting GitHub', async () => {
  for (const change of [{ eventName: 'pull_request' }, { ref: 'refs/heads/feature' }]) {
    const m = mock();
    Object.assign(m.input.context, change);
    await assert.rejects(deploy(m.input), /only be deployed from main/);
    assert.equal(m.calls.length, 0);
  }
});

test('rejects missing, malformed and unsafe artifact IDs', async () => {
  for (const id of [undefined, '', 'abc', '1x', '0', '-1', '1.2', '9007199254740992']) {
    const m = mock();
    m.input.artifactId = id;
    await assert.rejects(deploy(m.input), /valid artifact ID/);
    assert.equal(m.calls.length, 0);
  }
});

test('requires a positive timeout and polling interval', async () => {
  for (const change of [{ timeoutMs: 0 }, { pollIntervalMs: 0 }, { timeoutMs: NaN }]) {
    const m = mock();
    Object.assign(m.input, change);
    await assert.rejects(deploy(m.input), /must be positive/);
    assert.equal(m.calls.length, 0);
  }
});

test('requires an OIDC token', async () => {
  const m = mock({ token: '' });
  await assert.rejects(deploy(m.input), /OIDC token/);
  assert.equal(m.calls.length, 0);
});

test('requires a returned deployment ID', async () => {
  const m = mock({ deployment: {} });
  await assert.rejects(deploy(m.input), /deployment ID/);
  assert.equal(m.calls.length, 1);
});

test('requires a returned URL and cancels the incomplete deployment', async () => {
  const m = mock({ deployment: { id: 'deploy-1' } });
  await assert.rejects(deploy(m.input), /Pages URL/);
  assert.ok(m.calls.at(-1).route.endsWith('/cancel'));
});

test('recognises all terminal deployment errors without publishing a URL', async () => {
  for (const status of ['deployment_failed', 'deployment_content_failed',
    'deployment_cancelled', 'deployment_lost']) {
    const m = mock({ statuses: [status] });
    await assert.rejects(deploy(m.input), new RegExp(status));
    assert.deepEqual(m.outputs, {});
    assert.equal(m.calls.length, 2);
  }
});

test('cancels a timed-out deployment', async () => {
  const m = mock({ statuses: ['deployment_in_progress'] });
  await assert.rejects(deploy(m.input), /Timed out/);
  assert.ok(m.calls.at(-1).route.endsWith('/cancel'));
  assert.equal(m.calls.at(-1).params.pages_deployment_id, 'deploy-1');
  assert.deepEqual(m.outputs, {});
});

test('rejects malformed status responses and cancels', async () => {
  const m = mock({ statuses: [undefined] });
  await assert.rejects(deploy(m.input), /no Pages deployment status/);
  assert.ok(m.calls.at(-1).route.endsWith('/cancel'));
});

test('API errors never expose the OIDC request or raw error text', async () => {
  const secretError = Object.assign(new Error('private-oidc'), { status: 403 });
  const m = mock({ createError: secretError });
  await assert.rejects(deploy(m.input), error => {
    assert.match(error.message, /HTTP 403/);
    assert.doesNotMatch(error.message, /private-oidc/);
    return true;
  });
  assert.equal(m.calls.length, 1);
});

test('status API failure cancels; cancellation failure preserves the original error', async () => {
  const m = mock({
    statusError: Object.assign(new Error('private-oidc'), { status: 503 }),
    cancelError: Object.assign(new Error('private-oidc'), { status: 500 }),
  });
  await assert.rejects(deploy(m.input), /HTTP 503/);
  assert.ok(m.calls.at(-1).route.endsWith('/cancel'));
  assert.ok(m.messages.some(message => message.includes('HTTP 500')));
  assert.ok(m.messages.every(message => !message.includes('private-oidc')));
});
