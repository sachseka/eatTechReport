conventions_fixture <- function() {
  report_conventions(0.30, 0.15, 1.15, 1.30, 0.40, 0.60)
}

test_that("report inputs accept conventions without altering numerical results", {
  for (scope in c("pilotierung_leistung", "pilotierung", "haupttest_struktur", "bericht")) {
    input <- example_report(scope = scope, n_persons = 2, n_pv = 1)
    before <- summarise_report_input(input)
    input$config$conventions <- conventions_fixture()
    expect_true(validate_report_input(input))
    expect_identical(summarise_report_input(input), before)
    input$config$conventions$item_selection$infit_max <- "1.15"
    expect_error(validate_report_input(input), "endliche Zahl")
  }
})

test_that("conventions preserve explicit thresholds without requiring linking", {
  result <- conventions_fixture()
  expect_identical(result$item_selection,
    list(discrimination_target = 0.30, discrimination_min = 0.15,
         infit_max = 1.15, infit_exception_max = 1.30))
  expect_identical(result$linking,
    list(residual_correlation_abs = 0.40, dependent_item_weight = 0.60))
  expect_true(validate_report_conventions(result))
  expect_true(validate_report_conventions(NULL))
  without_linking <- report_conventions(0.30, 0.15, 1.15, 1.30)
  expect_identical(names(without_linking), "item_selection")
  without_linking["linking"] <- list(NULL)
  expect_true(validate_report_conventions(without_linking))
  expect_error(report_conventions(0.30, 0.15, 1.15, 1.30, 0.40), "gemeinsam")
  expect_error(report_conventions(0.30, 0.15, 1.15, 1.30,
                                 dependent_item_weight = 0.60), "gemeinsam")
})

test_that("conventions reject malformed blocks and ambiguous field names", {
  valid <- conventions_fixture()
  invalid <- list(TRUE, list(), unname(valid), as.data.frame(valid$item_selection))
  for (value in invalid) expect_error(validate_report_conventions(value), "config\\$conventions")
  bad <- valid
  bad$extra <- 1
  expect_error(validate_report_conventions(bad), "Konventionen")
  bad <- valid
  bad$item_selection <- bad$item_selection[-1L]
  expect_error(validate_report_conventions(bad), "item_selection")
  bad <- valid
  names(bad$item_selection)[2L] <- names(bad$item_selection)[1L]
  expect_error(validate_report_conventions(bad), "item_selection")
  bad <- valid
  bad$linking$unused <- 0.60
  expect_error(validate_report_conventions(bad), "linking")
})

test_that("threshold types, ranges and relationships are enforced", {
  valid <- conventions_fixture()
  for (group in names(valid)) {
    for (name in names(valid[[group]])) {
      for (value in list(NA_real_, NaN, Inf, -Inf, "0.30", TRUE, numeric(),
                        c(0.30, 0.40), 0.30 + 0i, list(0.30))) {
        bad <- valid
        bad[[group]][[name]] <- value
        expect_error(validate_report_conventions(bad), "endliche Zahl")
      }
    }
  }
  expect_error(report_conventions(1.01, 0.15, 1.15, 1.30), "Wertebereich")
  expect_error(report_conventions(0.30, -1.01, 1.15, 1.30), "Wertebereich")
  expect_error(report_conventions(0.30, 0.31, 1.15, 1.30), "uebersteigen")
  expect_error(report_conventions(0.30, 0.15, 0, 1.30), "Wertebereich")
  expect_error(report_conventions(0.30, 0.15, 1.15, 1.14), "kleiner")
  expect_error(report_conventions(0.30, 0.15, 1.15, 1.30, -0.01, 0.60), "Wertebereich")
  expect_error(report_conventions(0.30, 0.15, 1.15, 1.30, 1.01, 0.60), "Wertebereich")
  expect_error(report_conventions(0.30, 0.15, 1.15, 1.30, 0.40, 0), "Wertebereich")
  expect_error(report_conventions(0.30, 0.15, 1.15, 1.30, 0.40, 1.01), "Wertebereich")
  expect_true(validate_report_conventions(report_conventions(1, -1, 1, 1, 0, 1)))
})

test_that("convention text distinguishes supplied values from missing placeholders", {
  config <- list(report = list(data_origin = "synthetic"), conventions = conventions_fixture())
  before <- config
  synthetic <- report_convention_value(config, "item_selection", "discrimination_target", "Zielschwelle")
  expect_identical(synthetic, '[0,30]{custom-style="EatSimulatedValue"}')
  expect_identical(config, before)
  config$report$data_origin <- "observed"
  expect_identical(report_convention_value(config, "item_selection", "infit_max", "Zielschwelle"),
                   "1,15")
  expect_identical(report_convention_value(config, "linking", "dependent_item_weight", "Gewicht", digits = 1L),
                   "0,6")
  config$conventions <- NULL
  config$report$data_origin <- "synthetic"
  expect_identical(report_convention_value(config, "item_selection", "infit_max", "Zielschwelle"),
                   "\\[Zielschwelle\\]")
  config$conventions <- report_conventions(0.30, 0.15, 1.15, 1.30)
  expect_identical(report_convention_value(config, "linking", "dependent_item_weight", "Gewicht [offen]"),
                   "\\[Gewicht \\[offen\\]\\]")
  expect_error(report_convention_value(config, "other", "infit_max", "Ziel"), "Unbekannte")
  expect_error(report_convention_value(config, "item_selection", "typo", "Ziel"), "Unbekannte")
  expect_error(report_convention_value(config, "linking", "infit_max", "Ziel"), "Unbekannte")
  expect_error(report_convention_value(config, "item_selection", "infit_max", ""), "placeholder")
  expect_error(report_convention_value(config, "item_selection", "infit_max", "Ziel", 1.5), "digits")
  config$conventions$item_selection$infit_max <- NA_real_
  expect_error(report_convention_value(config, "item_selection", "infit_max", "Ziel"), "endliche Zahl")
})
