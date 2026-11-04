#' Technical reports for educational assessments
#'
#' Tools for VERA-3 test designs, sample descriptions, competence distributions,
#' main-test selections, item statistics and supplied scale transformations.
#' Performance inputs contain complete, unweighted plausible values on the
#' reporting scale (`bista_500`). Design, participation, sample characteristics and
#' main-test results are supplied as separate R tables. The package includes
#' the corporate Word template and editable Quarto text blocks. Scope
#' `bericht` renders the report through the reference list; study-specific
#' text review remains necessary. Quarto is required for rendering. Automatic
#' field and table-of-contents updates additionally require Microsoft Word on
#' Windows. Synthetic examples are available for every implemented scope.
#'
#' @seealso [example_report()], [validate_report_input()],
#'   [summarise_report_input()], [render_report()], [edit_report_texts()]
#'
#'   [Package website](https://sachseka.github.io/eatTechReport/),
#'   [source repository](https://github.com/sachseka/eatTechReport),
#'   [issue tracker](https://github.com/sachseka/eatTechReport/issues).
#'
#' @importFrom knitr kable
#' @importFrom rmarkdown render
#' @keywords internal
"_PACKAGE"
