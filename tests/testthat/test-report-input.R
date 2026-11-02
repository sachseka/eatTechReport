test_that("pilot-study examples retain the established PV calculations", {
  for (profile in c("v3_de_lesen_zuhoeren", "v3_ma_mg_mm")) {
    input <- example_report(profile, n_persons = 2L, n_pv = 1L)
    legacy <- example_leistung_input(profile, n_persons = 2L, n_pv = 1L)
    expect_true(validate_report_input(input))
    expect_identical(performance_component(input), legacy)
    expect_identical(summarise_leistung_input(input), summarise_leistung_input(legacy))
    summary <- summarise_report_input(input)
    expect_identical(summary$descriptives$n_persons, rep(2L, length(input$config$scales)))
    expect_equal(summary$sample$totals$n_analysis_persons, 2)
    expect_equal(summary$sample$totals$n_participants, 4)
    expect_equal(summary$design$totals$n_items, nrow(input$data$design$items))
  }
})

test_that("old performance-only inputs remain valid report inputs", {
  input <- example_report(scope = "pilotierung_leistung")
  expect_identical(input, example_leistung_input())
  expect_true(validate_report_input(input))
  expect_identical(summarise_report_input(input), summarise_leistung_input(input))
})

test_that("full input validation checks both modules before output is attempted", {
  input <- example_report()
  input$data$sample$response_counts$n_valid[1L] <- 10000
  expect_error(validate_report_input(input), "Nvalid")
  expect_error(render_report(input$config, input$data,
                             corporate_template = tempfile(fileext = ".dotx"),
                             output_dir = tempfile()), "Nvalid")
  # Performance-only operations deliberately validate their own component.
  expect_true(validate_leistung_input(input))

  input <- example_report()
  input$data$design$block_items$item_id[1L] <- "missing_item"
  expect_error(summarise_report_input(input), "unbekannte IDs")
  input <- example_report()
  input$data$extra <- TRUE
  expect_error(validate_report_input(input), "data erwartet genau")
  input <- example_report()
  input$config$schema_version <- "future"
  expect_error(validate_report_input(input), "schema_version")
  input <- example_report()
  input$unexpected <- TRUE
  expect_error(validate_report_input(input), "input erwartet genau")
})

test_that("performance-only edited text directories need no new study blocks", {
  destination <- tempfile("old-scope-texts-")
  files <- edit_report_texts(destination, scope = "pilotierung_leistung")
  expect_length(files, 3L)
  expect_setequal(normalizePath(report_text_files(destination, "pilotierung_leistung"),
                                winslash = "/"), files)
  expect_error(report_text_files(destination, "pilotierung"), "pilotierung_design_pool")
})
