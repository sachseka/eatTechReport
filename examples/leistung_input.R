# Compatibility entry point for the former standalone prototype.
# The implementation now lives in the R package; no code is duplicated here.
# This source-only route supports in-memory examples and summaries. Rendering
# and copying packaged text blocks require an installed eatTechReport package.
(function(target) {
  sources <- lapply(sys.frames(), function(frame) frame$ofile)
  sources <- Filter(function(path) is.character(path) && length(path) == 1L, sources)
  if (!length(sources)) stop('Bitte diese Datei mit source() laden.')
  this_file <- normalizePath(tail(sources, 1L)[[1L]], mustWork = TRUE)
  root <- dirname(dirname(this_file))
  # Performance functions also use the shared report validators and synthetic
  # design/sample generators. Load the complete function set to keep those
  # dependencies in sync with the package, without maintaining a second list.
  for (path in list.files(file.path(root, 'R'), pattern = '\\.R$', full.names = TRUE)) {
    source(path, local = target, encoding = 'UTF-8')
  }
})(environment())
