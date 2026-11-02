# Compatibility entry point for the former standalone prototype.
# The implementation now lives in the R package; no code is duplicated here.
(function(target) {
  sources <- lapply(sys.frames(), function(frame) frame$ofile)
  sources <- Filter(function(path) is.character(path) && length(path) == 1L, sources)
  if (!length(sources)) stop('Bitte diese Datei mit source() laden.')
  this_file <- normalizePath(tail(sources, 1L)[[1L]], mustWork = TRUE)
  root <- dirname(dirname(this_file))
  source(file.path(root, 'R', 'performance.R'), local = target, encoding = 'UTF-8')
  source(file.path(root, 'R', 'plot.R'), local = target, encoding = 'UTF-8')
})(environment())
