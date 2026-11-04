test_that("a single figure retains every module with safe unique filenames", {
  input <- example_report("v3_ma_mg_mm", scope = "haupttest_struktur")
  main_test <- summarise_report_input(input)$main_test
  original <- main_test$modules
  counts <- main_test$item_levels$modules
  # Arbitrary module IDs must never become filesystem paths.
  ids <- paste0("../module ", seq_len(7L))
  main_test$modules <- original[rep(1L, 7L), ]
  main_test$modules$module_id <- ids
  main_test$item_levels$modules <- do.call(rbind, lapply(ids, function(id) {
    rows <- counts[counts$module_id == original$module_id[1L], ]
    rows$module_id <- id
    rows
  }))
  plan <- main_test_figure_plan(input$config, main_test)
  expect_length(plan$selection, 1L)
  expect_length(plan$modules, 1L)
  expect_identical(unlist(lapply(plan$modules, `[[`, "module_ids"), use.names = FALSE), ids)
  expect_equal(vapply(plan$modules, function(x) length(x$module_ids), integer(1)), 7L)
  filenames <- vapply(c(plan$selection, plan$modules), `[[`, character(1), "file")
  expect_identical(filenames, basename(filenames))
  expect_false(anyDuplicated(filenames) > 0L)
  expect_true(all(vapply(plan$modules, `[[`, numeric(1), "height") <= 16.2))
})

test_that("legacy inputs need no figures and unused configured scales are omitted", {
  input <- example_report(scope = "haupttest_struktur")
  main_test <- summarise_report_input(input)$main_test
  empty <- list(selection = list(), modules = list())
  expect_identical(main_test_figure_plan(input$config, NULL), empty)
  expect_identical(main_test_figure_plan(input$config, list()), empty)
  main_test$item_levels$selection <- subset(main_test$item_levels$selection, scale_id == "DL")
  main_test$item_levels$modules <- subset(main_test$item_levels$modules, scale_id == "DL")
  plan <- main_test_figure_plan(input$config, main_test)
  expect_length(plan$selection, 1L)
  expect_identical(plan$selection[[1L]]$scale_id, "DL")
})
