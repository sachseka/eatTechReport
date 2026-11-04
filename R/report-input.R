# Extract the established performance contract without changing its meaning.
# Full reports validate their design and sample through validate_report_input().
performance_component <- function(input) {
  if (is.list(input) && is.list(input$config) &&
      isTRUE(input$config$scope %in% c("pilotierung", "haupttest_struktur", "bericht"))) {
    has_main_test <- input$config$scope %in% c("haupttest_struktur", "bericht")
    is_complete <- identical(input$config$scope, "bericht")
    schema <- if (is_complete) "0.5.0-draft" else if (has_main_test) "0.4.0-draft" else "0.3.0-draft"
    if (!identical(input$config$schema_version, schema)) {
      stop("scope = '", input$config$scope, "' erwartet schema_version = '",
           schema, "'.", call. = FALSE)
    }
    fields <- c("population", "pvs", "design", "sample")
    if (has_main_test) fields <- c(fields, "main_test")
    if (is_complete) fields <- c(fields, "main_test_results")
    if (!is.list(input$data) || is.data.frame(input$data) ||
        is.null(names(input$data)) || anyDuplicated(names(input$data)) ||
        !setequal(names(input$data), fields)) {
      stop("data erwartet genau: ", paste(fields, collapse = ", "), ".", call. = FALSE)
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
#'   Lists and tables must contain the fields of the selected schema; arbitrary
#'   additional fields are rejected. Design blocks may additionally contain
#'   logical `is_norming` values without missing entries. This explicit flag
#'   controls norming-block shading; anchor items alone do not imply it.
#'   All scopes optionally accept `config$conventions`, created with
#'   [report_conventions()]. These thresholds populate report text; they do not
#'   select items or change supplied results. Older inputs without this block
#'   remain valid.
#'   Scope `haupttest_struktur` uses schema `0.4.0-draft` and additionally requires
#'   `data$main_test`: selected items, modules, ordered item membership and
#'   documented pilot-wave membership. It extends the draft with main-test
#'   selection and structure, not item-quality profiles or transformations.
#'   Each selected item's `task_label` and `domain_id` must agree within its
#'   `task_id`. Labels are supplied in `data$main_test$items` and used in the
#'   report's task matrix. This inventory is independent of the current pilot
#'   inventory; selected items may originate in earlier pilot waves.
#'   Optional `data$main_test$item_levels` supplies exactly one `level_label`
#'   per selected `item_id`, using the labels of its configured scale. These
#'   upstream assignments enable item-level figures; no assignment is inferred
#'   from person PVs or numerical cut values.
#'   Scope `bericht` uses schema `0.5.0-draft` and additionally requires
#'   `data$main_test_results`: complete item statistics, explicitly supplied
#'   affine transformations for persons and items, and their definitions. It
#'   includes the final report chapters through interpretation and references.
#'   Item statistics contain finite `logit` values and `p_correct` values
#'   between zero and one for every selected item. Each scale used by selected
#'   items requires one `person` and one `item` transformation, with finite
#'   `intercept`, positive finite `slope` and a nonempty `source_label`.
#'   The formula is `report_score = intercept + slope * logit`.
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
  if (input$config$scope %in% c("pilotierung", "haupttest_struktur", "bericht")) {
    validate_design_data(input$data$design, input$config)
    validate_sample_data(input$data$sample, input)
  }
  if (input$config$scope %in% c("haupttest_struktur", "bericht")) {
    validate_main_test_data(input$data$main_test, input$config)
  }
  if (identical(input$config$scope, "bericht")) {
    validate_main_test_results(input$data$main_test_results, input$config, input$data$main_test)
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
#'   plus `design` and `sample` for scopes `pilotierung`, `haupttest_struktur`
#'   and `bericht`. Design includes item
#'   pool counts, blocks, booklets and their slots. Sample includes overall and
#'   state-level participation, characteristics and valid-response summaries
#'   separated by pilot and anchor roles. Uncollected characteristics are NULL;
#'   percentages for empty populations and undefined sample SDs are NA.
#'   Scope `haupttest_struktur` additionally returns `main_test` with distinct
#'   overall/domain counts, module counts, ordered tasks and pilot-wave counts.
#'   Wave counts can overlap; module durations are not added to a test duration.
#'   When supplied, `main_test$item_levels` contains complete competence-level
#'   item counts for `selection` and `modules`, including zero-count levels.
#'   Scope `bericht` also returns `main_test_results` with `item_statistics`,
#'   `module_statistics`, `transformations` and `definitions`. Module summaries
#'   contain unweighted item means of `p_correct` and `logit`, and minimum and
#'   maximum item report scores calculated using the supplied item
#'   transformations. Person PV values are never transformed again.
#' @seealso [example_report()], [validate_report_input()]
#' @examples
#' results <- summarise_report_input(example_report())
#' results$design$pool
#' results$sample$characteristics$gender
#' @export
summarise_report_input <- function(input) {
  validate_report_input(input)
  result <- summarise_leistung_input(input)
  if (input$config$scope %in% c("pilotierung", "haupttest_struktur", "bericht")) {
    result$design <- summarise_design_data(input$data$design, input$config)
    result$sample <- summarise_sample_data(input$data$sample, input)
  }
  if (input$config$scope %in% c("haupttest_struktur", "bericht")) {
    result$main_test <- summarise_main_test_data(input$data$main_test, input$config)
  }
  if (identical(input$config$scope, "bericht")) {
    result$main_test_results <- summarise_main_test_results(
      input$data$main_test_results, input$config, input$data$main_test)
  }
  result
}
