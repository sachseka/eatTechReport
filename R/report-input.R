# Extract the established performance contract without changing its meaning.
# Full reports validate their design and sample through validate_report_input().
performance_component <- function(input) {
  if (is.list(input) && is.list(input$config) &&
      identical(input$config$scope, "pilotierung")) {
    if (!identical(input$config$schema_version, "0.3.0-draft")) {
      stop("scope = 'pilotierung' erwartet schema_version = '0.3.0-draft'.", call. = FALSE)
    }
    fields <- c("population", "pvs", "design", "sample")
    if (!is.list(input$data) || is.data.frame(input$data) ||
        is.null(names(input$data)) || anyDuplicated(names(input$data)) ||
        !setequal(names(input$data), fields)) {
      stop("data erwartet genau: population, pvs, design, sample.", call. = FALSE)
    }
    input$config$scope <- "pilotierung_leistung"
    input$config$schema_version <- "0.2.0-draft"
    input$data <- input$data[c("population", "pvs")]
  }
  input
}

#' Validate inputs for the implemented technical-report sections
#'
#' Validate the performance component and, for the pilot-study scope, the item
#' inventory, booklet design, participation, sample characteristics and counts
#' of valid item responses. No cases are excluded or imputed by the report.
#'
#' @param input A list with `config` and `data`, as returned by [example_report()].
#' @return Invisibly `TRUE`, or an error identifying invalid input.
#' @details Scope `pilotierung` uses schema `0.3.0-draft` and requires
#'   `data$population`, `data$pvs`, `data$design` and `data$sample`. The earlier
#'   performance-only scope `pilotierung_leistung` remains supported unchanged.
#'   Sample composition describes the distinct persons in `data$population`;
#'   participation and class returns are reported separately. Missing categorical
#'   values form a separate category and remain in percentage denominators.
#'   Counts of valid responses use the analysis population of the corresponding
#'   scale; their upstream scoring and missing-value rules must be described in
#'   `data$sample$response_definition`.
#' @seealso [summarise_report_input()], [render_report()]
#' @examples
#' validate_report_input(example_report())
#' @export
validate_report_input <- function(input) {
  validate_leistung_input(input)
  if (identical(input$config$scope, "pilotierung")) {
    validate_design_data(input$data$design, input$config)
    validate_sample_data(input$data$sample, input)
  }
  invisible(TRUE)
}

#' Summarise the implemented technical-report sections
#'
#' Build the common numerical source for editable text, tables and graphics.
#' Totals count distinct persons, items and tasks rather than adding overlapping
#' groups. Values remain unrounded until they are displayed in the report.
#'
#' @inheritParams validate_report_input
#' @return The performance components `descriptives`, `percentages`, `per_pv`,
#'   plus `design` and `sample` for scope `pilotierung`. Design includes item
#'   pool counts, blocks, booklets and their slots. Sample includes overall and
#'   state-level participation, characteristics and valid-response summaries
#'   separated by pilot and anchor roles. Uncollected characteristics are NULL;
#'   percentages for empty populations and undefined sample SDs are NA.
#' @seealso [example_report()], [validate_report_input()]
#' @examples
#' results <- summarise_report_input(example_report())
#' results$design$pool
#' results$sample$characteristics$gender
#' @export
summarise_report_input <- function(input) {
  validate_report_input(input)
  result <- summarise_leistung_input(input)
  if (identical(input$config$scope, "pilotierung")) {
    result$design <- summarise_design_data(input$data$design, input$config)
    result$sample <- summarise_sample_data(input$data$sample, input)
  }
  result
}
