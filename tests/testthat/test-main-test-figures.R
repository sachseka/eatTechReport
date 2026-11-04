test_that("mathematics figures separate the base from the two focus-domain groups", {
  input <- example_report("v3_ma_mg_mm", scope = "haupttest_struktur")
  main_test <- summarise_report_input(input)$main_test
  plan <- main_test_figure_plan(input$config, main_test)
  expect_length(plan$selection, 0L)
  expect_length(plan$modules, 3L)
  expect_identical(lapply(plan$modules, `[[`, "module_ids"),
                   list("MA_BM", c("MG_EM", "MG_EM_B"), c("MM_EM", "MM_EM_B")))
  expect_identical(unname(plan$modules[[1L]]$legend_labels), "MO-BM")
  expect_identical(unname(plan$modules[[2L]]$legend_labels), c("MG-EM-A", "MG-EM-B"))
  expect_identical(unname(plan$modules[[3L]]$legend_labels), c("MM-EM-A", "MM-EM-B"))
  expect_match(plan$modules[[1L]]$caption, "VERA-3-Basismoduls 2027")
  expect_match(plan$modules[[2L]]$caption, "Gr\u00f6\u00dfen und Messen")
  expect_match(plan$modules[[3L]]$caption, "Muster und Strukturen")
  expect_match(plan$modules[[2L]]$note, "MG-EM-A = Gr\u00f6\u00dfen und Messen")
  expect_identical(item_module_short_labels(main_test$modules, input$config),
                   unlist(lapply(plan$modules, `[[`, "legend_labels")))
})

test_that("German report figures compare all modules of each scale without extra selection plots", {
  input <- example_report(scope = "haupttest_struktur")
  main_test <- summarise_report_input(input)$main_test
  plan <- main_test_figure_plan(input$config, main_test)
  expect_length(plan$selection, 0L)
  expect_length(plan$modules, 2L)
  expect_identical(lapply(plan$modules, `[[`, "module_ids"),
                   list(c("DL_BM", "DL_EM", "DL_EM_B"), c("DH_BM", "DH_EM", "DH_EM_B")))
  expect_identical(unname(plan$modules[[1L]]$legend_labels), c("DL-BM", "DL-EM-A", "DL-EM-B"))
  expect_identical(unname(plan$modules[[2L]]$legend_labels), c("DH-BM", "DH-EM-A", "DH-EM-B"))
  expect_match(plan$modules[[1L]]$caption, "Verteilung der Items in den Testmodulen")
  expect_match(plan$modules[[2L]]$note, "DH-BM = Zuh\u00f6ren Basismodul")
})

test_that("free module IDs cannot become paths and report groups never paginate", {
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
  expect_length(plan$selection, 0L)
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
  expect_length(plan$selection, 0L)
  expect_length(plan$modules, 1L)
  expect_identical(plan$modules[[1L]]$scale_id, "DL")
})
