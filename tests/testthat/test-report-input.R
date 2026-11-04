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

test_that("main-test structure extends reports without changing pilot results", {
  for (profile in c("v3_de_lesen_zuhoeren", "v3_ma_mg_mm")) {
    pilot <- example_report(profile, n_persons = 2L, n_pv = 1L)
    input <- example_report(profile, n_persons = 2L, n_pv = 1L,
                              scope = "haupttest_struktur")
    expect_true(validate_report_input(input))
    expect_identical(performance_component(input), performance_component(pilot))
    results <- summarise_report_input(input)
    expect_identical(results[names(results) != "main_test"], summarise_report_input(pilot))
    expect_equal(results$main_test$totals$n_items, nrow(input$data$main_test$items))
    input$data$main_test$module_items$item_id[1L] <- "unknown"
    expect_error(render_report(input$config, input$data, output_dir = tempfile()), "unbekannt")
    input$data$main_test <- NULL
    expect_error(validate_report_input(input), "data erwartet genau")
  }
})

test_that("main-test text editing requires both new blocks only for its scope", {
  destination <- tempfile("main-test-texts-")
  files <- edit_report_texts(destination, scope = "haupttest_struktur")
  expect_length(files, 10L)
  expect_true(all(c("haupttest_auswahl.qmd", "haupttest_module.qmd") %in% basename(files)))
  expect_length(report_text_files(destination, "pilotierung"), 8L)
  unlink(file.path(destination, "haupttest_module.qmd"))
  expect_error(report_text_files(destination, "haupttest_struktur"), "haupttest_module")
})

test_that("complete report inputs extend the draft through final results", {
  for (profile in c("v3_de_lesen_zuhoeren", "v3_ma_mg_mm")) {
    input <- example_report(profile, scope = "bericht", n_persons = 2, n_pv = 1)
    previous <- example_report(profile, scope = "haupttest_struktur", n_persons = 2, n_pv = 1)
    expect_true(validate_report_input(input))
    expect_identical(input$config$schema_version, "0.5.0-draft")
    expect_identical(performance_component(input), performance_component(previous))
    result <- summarise_report_input(input)
    expect_identical(result[names(result) != "main_test_results"], summarise_report_input(previous))
    expect_equal(nrow(result$main_test_results$item_statistics), nrow(input$data$main_test$items))
    input$data$main_test_results$item_statistics$p_correct[1L] <- 2
    expect_error(render_report(input$config, input$data, output_dir = tempfile()), "p_correct")
    input$data$main_test_results <- NULL
    expect_error(validate_report_input(input), "main_test_results")
  }
  destination <- tempfile("complete-texts-")
  expect_length(edit_report_texts(destination, scope = "bericht"), 15L)
  expect_true(all(report_completion_text_names() %in% basename(report_text_files(destination, "bericht"))))
  expect_length(report_text_files(destination, "haupttest_struktur"), 10L)
})
