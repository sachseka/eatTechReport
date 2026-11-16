# A presentation copy keeps the canonical order of the five mathematical
# domains independent of row order in the caller's configuration. Inputs are
# archived unchanged; booklet and module sequences keep their explicit order.
report_presentation_config <- function(config) {
  if (identical(config$report$subject, "ma")) {
    order <- match(c("MZ", "MG", "MS", "MM", "MR", "MD"), config$domains$domain_id)
    config$domains <- config$domains[order[!is.na(order)], , drop = FALSE]
    rownames(config$domains) <- NULL
  }
  config
}
