test_that("selection graphics preserve upstream assignments and show empty stages", {
  input <- example_report(scope = "haupttest_struktur")
  input$data$main_test$item_levels$level_label <- "II"
  plot <- plot_item_levels(input, "DL")
  expected <- summarise_report_input(input)$main_test$item_levels$selection
  expected <- expected[expected$scale_id == "DL", , drop = FALSE]
  rownames(expected) <- NULL
  expect_s3_class(plot, "ggplot")
  expect_identical(attr(plot, "item_level_counts"), expected)
  expect_identical(attr(plot, "scale_id"), "DL")
  expect_identical(attr(plot, "by"), "selection")
  expect_no_warning(built <- ggplot2::ggplot_build(plot))
  expect_identical(as.character(plot$data$level_label), c("Ia", "Ib", "II", "III", "IV"))
  expect_equal(built$data[[2L]]$label, c(0, 0, 4, 0, 0))
  expect_equal(sum(built$data[[1L]]$y), 4)
  expect_match(plot$labels$caption, "Synthetisches Beispiel")
  expect_match(plot$labels$caption, "illustrative Stufenzuordnungen")
  expect_true(all(built$layout$panel_params[[1L]]$y$breaks ==
                    floor(built$layout$panel_params[[1L]]$y$breaks)))
})

test_that("module plots count reused items per module and retain a shared scale", {
  input <- example_report("v3_ma_mg_mm", scope = "haupttest_struktur")
  plot <- plot_item_levels(input, "MO", by = "module")
  counts <- attr(plot, "item_level_counts")
  modules <- summarise_report_input(input)$main_test$modules
  expect_identical(unique(counts$module_id), modules$module_id)
  expect_equal(as.numeric(tapply(counts$n_items, counts$module_id, sum)[modules$module_id]), modules$n_items)
  expect_gt(sum(counts$n_items), nrow(input$data$main_test$items))
  expect_no_warning(all_built <- ggplot2::ggplot_build(plot))
  expect_length(all_built$layout$panel_params, nrow(modules))
  limits <- lapply(all_built$layout$panel_params, function(panel) panel$y.range)
  expect_true(all(vapply(limits, identical, logical(1), limits[[1L]])))

  selected <- rev(modules$module_id[-1L])
  page <- plot_item_levels(input, "MO", by = "module", module_ids = selected)
  expect_identical(unique(attr(page, "item_level_counts")$module_id), modules$module_id[-1L])
  page_built <- ggplot2::ggplot_build(page)
  expect_identical(page_built$layout$panel_params[[1L]]$y.range, limits[[1L]])
  expect_equal(attr(page, "suggested_height_cm"), 12.2)
  expect_equal(attr(plot, "suggested_height_cm"), 16.2)
})

test_that("module plots isolate scales even when a module contains several domains", {
  input <- example_report(scope = "haupttest_struktur")
  links <- input$data$main_test$module_items
  extra <- links[links$module_id == "DH_BM", , drop = FALSE]
  extra$module_id <- "DL_BM"
  extra$task_position <- extra$task_position + 10L
  input$data$main_test$module_items <- rbind(links, extra)
  plot <- plot_item_levels(input, "DL", by = "module", module_ids = "DL_BM")
  expect_equal(sum(attr(plot, "item_level_counts")$n_items), 3)
  expect_identical(unique(attr(plot, "item_level_counts")$scale_id), "DL")
  expect_error(plot_item_levels(input, "DL", by = "module", module_ids = "DH_EM"), "module_ids")
})

test_that("item graphics reject missing assignments and invalid selectors", {
  input <- example_report(scope = "haupttest_struktur")
  for (font in list("", NA_character_, c("sans", "serif"), 11)) {
    expect_error(plot_item_levels(input, "DL", font_family = font), "font_family")
  }
  for (scale in list("MG", NA_character_, c("DL", "DH"), 11)) {
    expect_error(plot_item_levels(input, scale), "scale_id")
  }
  expect_error(plot_item_levels(input, "DL", module_ids = "DL_BM"), "by = 'module'")
  for (ids in list(character(), c("DL_BM", "DL_BM"), NA_character_, 1, "unknown")) {
    expect_error(plot_item_levels(input, "DL", by = "module", module_ids = ids), "module_ids")
  }
  input$data$main_test$item_levels <- NULL
  expect_error(plot_item_levels(input, "DL"), "item_levels")
  expect_error(plot_item_levels(example_report(), "DL"), "item_levels")
})

test_that("counts do not depend on persons, cuts or PV values", {
  input <- example_report(scope = "haupttest_struktur")
  before <- plot_item_levels(input, "DL")
  input$data$pvs$value <- input$data$pvs$value + 100
  input$config$scales$DL$cuts <- input$config$scales$DL$cuts + 70
  after <- plot_item_levels(input, "DL")
  expect_identical(attr(before, "item_level_counts"), attr(after, "item_level_counts"))
})

test_that("the default plot font saves portably and small counts stay integer", {
  input <- example_report(scope = "haupttest_struktur")
  plot <- plot_item_levels(input, "DL", by = "module")
  built <- ggplot2::ggplot_build(plot)
  expect_true(all(built$layout$panel_params[[1L]]$y$breaks %in% c(0, 1)))
  path <- tempfile(fileext = ".pdf")
  expect_no_warning(ggplot2::ggsave(path, plot, width = 15.5,
                                    height = attr(plot, "suggested_height_cm"), units = "cm"))
  expect_gt(file.info(path)$size, 0)
})
