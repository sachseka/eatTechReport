# Run the package's performance tests from the repository, without installation.
# Rscript --vanilla examples/check_leistung_input.R
file_arg <- grep('^--file=', commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(file_arg) != 1L) stop('Bitte dieses Pruefskript mit Rscript ausfuehren.')
script_dir <- dirname(normalizePath(sub('^--file=', '', file_arg), mustWork = TRUE))
source(file.path(script_dir, 'leistung_input.R'), encoding = 'UTF-8')
if (!requireNamespace('testthat', quietly = TRUE)) {
  stop('Fuer die Paketpruefungen wird testthat benoetigt.')
}
testthat::test_dir(file.path(dirname(script_dir), 'tests', 'testthat'),
                   filter = '^(performance|plot)$', reporter = 'summary',
                   stop_on_failure = TRUE)
