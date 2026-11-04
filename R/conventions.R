#' Specify item-quality and linking conventions for report text
#'
#' Construct a validated, optional `config$conventions` block. These values
#' document upstream decisions; they do not select items, fit models or change
#' supplied results. There are no default thresholds for a real study.
#'
#' @param discrimination_target Desired point-biserial item discrimination:
#'   the reported convention is strictly greater than this value.
#' @param discrimination_min Inclusive lower bound for item discrimination.
#' @param infit_max Inclusive regular upper bound for Infit/MNSQ.
#' @param infit_exception_max Inclusive upper bound accepted after justified
#'   substantive consideration. Must be at least `infit_max`.
#' @param residual_correlation_abs Optional absolute residual-correlation
#'   threshold for dependent linking items. The threshold is inclusive.
#' @param dependent_item_weight Optional multiplicative linking weight in
#'   `(0, 1]`. Supply both linking arguments together, or neither.
#' @return A list containing `item_selection` and, when supplied, `linking`.
#'   Assign the result to `input$config$conventions`.
#' @details Discrimination values must be finite numbers in `[-1, 1]`, with
#'   `discrimination_min <= discrimination_target`. Infit limits must be
#'   positive finite numbers. No lower Infit bound is defined by this interface.
#'   The absolute residual-correlation threshold must lie in `[0, 1]`.
#'
#'   The optional linking convention describes the weighted-linking procedure
#'   in the Sprachgebrauch (`DS`) text. Its presence does not apply the procedure
#'   to another domain, alter any item weight or claim that linking was performed.
#'   Actual application and its empirical results remain upstream inputs.
#'
#'   Report text displays supplied values as numbers, for example `0,30`.
#'   With synthetic data the number is highlighted in yellow. Missing optional
#'   conventions retain editorial placeholders in square brackets.
#'   Existing inputs without `config$conventions` remain valid.
#' @seealso [example_report()], [validate_report_input()], [render_report()]
#' @examples
#' # Illustrative conventions, not approved thresholds for a study.
#' conventions <- report_conventions(
#'   discrimination_target = 0.30, discrimination_min = 0.15,
#'   infit_max = 1.15, infit_exception_max = 1.30
#' )
#' conventions$item_selection
#' @export
report_conventions <- function(discrimination_target, discrimination_min,
                               infit_max, infit_exception_max,
                               residual_correlation_abs = NULL,
                               dependent_item_weight = NULL) {
  if (xor(is.null(residual_correlation_abs), is.null(dependent_item_weight))) {
    stop("Beide Linkingkonventionen gemeinsam angeben oder beide weglassen.",
         call. = FALSE)
  }
  conventions <- list(item_selection = list(
    discrimination_target = discrimination_target,
    discrimination_min = discrimination_min,
    infit_max = infit_max,
    infit_exception_max = infit_exception_max
  ))
  if (!is.null(residual_correlation_abs)) {
    conventions$linking <- list(
      residual_correlation_abs = residual_correlation_abs,
      dependent_item_weight = dependent_item_weight
    )
  }
  validate_report_conventions(conventions)
  conventions
}

report_convention_fields <- function() {
  list(item_selection = c("discrimination_target", "discrimination_min",
                          "infit_max", "infit_exception_max"),
       linking = c("residual_correlation_abs", "dependent_item_weight"))
}

validate_report_conventions <- function(conventions) {
  if (is.null(conventions)) return(invisible(TRUE))
  fail <- function(message) stop("config$conventions: ", message, call. = FALSE)
  exact_list <- function(value, fields, label) {
    if (!is.list(value) || is.data.frame(value) || is.null(names(value)) ||
        anyNA(names(value)) || anyDuplicated(names(value)) ||
        !setequal(names(value), fields)) {
      fail(paste0(label, " erwartet genau die Felder: ", paste(fields, collapse = ", "), "."))
    }
  }
  fields <- report_convention_fields()
  optional <- if (is.list(conventions)) intersect("linking", names(conventions)) else character()
  exact_list(conventions, c("item_selection", optional), "Konventionen")
  exact_list(conventions$item_selection, fields$item_selection, "item_selection")
  number <- function(value, label, lower, upper, open_lower = FALSE) {
    if (!is.numeric(value) || is.complex(value) || length(value) != 1L ||
        is.na(value) || !is.finite(value)) {
      fail(paste0(label, " muss genau eine endliche Zahl sein."))
    }
    if (value < lower || value > upper || (open_lower && value == lower)) {
      fail(paste0(label, " liegt ausserhalb des zulaessigen Wertebereichs."))
    }
  }
  selection <- conventions$item_selection
  for (name in c("discrimination_target", "discrimination_min")) {
    number(selection[[name]], paste0("item_selection$", name), -1, 1)
  }
  for (name in c("infit_max", "infit_exception_max")) {
    number(selection[[name]], paste0("item_selection$", name), 0, Inf, TRUE)
  }
  if (selection$discrimination_min > selection$discrimination_target) {
    fail("discrimination_min darf discrimination_target nicht uebersteigen.")
  }
  if (selection$infit_exception_max < selection$infit_max) {
    fail("infit_exception_max darf nicht kleiner als infit_max sein.")
  }
  if (!is.null(conventions$linking)) {
    exact_list(conventions$linking, fields$linking, "linking")
    number(conventions$linking$residual_correlation_abs,
           "linking$residual_correlation_abs", 0, 1)
    number(conventions$linking$dependent_item_weight,
           "linking$dependent_item_weight", 0, 1, TRUE)
  }
  invisible(TRUE)
}

# Explicit field lookup catches misspelled paths before they silently turn into
# unfilled placeholders. Missing optional conventions remain editable text.
report_convention_value <- function(config, group, name, placeholder, digits = 2L) {
  fields <- report_convention_fields()
  scalar_text <- function(x) is.character(x) && length(x) == 1L &&
    !is.na(x) && nzchar(trimws(x))
  if (!scalar_text(group) || !group %in% names(fields) ||
      !scalar_text(name) || !name %in% fields[[group]]) {
    stop("Unbekannte Konvention: group und name pruefen.", call. = FALSE)
  }
  if (!scalar_text(placeholder)) {
    stop("placeholder muss genau einen nichtleeren Text enthalten.", call. = FALSE)
  }
  if (!is.numeric(digits) || is.complex(digits) || length(digits) != 1L ||
      is.na(digits) || !is.finite(digits) || digits != floor(digits) ||
      digits < 0 || digits > 8) {
    stop("digits muss eine ganze Zahl zwischen 0 und 8 sein.", call. = FALSE)
  }
  validate_report_conventions(config$conventions)
  value <- config$conventions[[group]][[name]]
  if (is.null(value)) return(report_markdown_text(paste0("[", placeholder, "]")))
  report_text_value(study_number(value, digits), config)
}
