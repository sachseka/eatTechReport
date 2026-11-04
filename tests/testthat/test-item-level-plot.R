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
  expect_true(all(built$data[[1L]]$xmax - built$data[[1L]]$xmin <= 0.35 + 1e-8))
  expect_match(plot$labels$caption, "Synthetisches Beispiel")
  expect_match(plot$labels$caption, "illustrative Stufenzuordnungen")
  expect_true(all(built$layout$panel_params[[1L]]$y$breaks ==
                    floor(built$layout$panel_params[[1L]]$y$breaks)))
})

test_that("module plots compare reused items in one panel and retain a shared scale", {
  input <- example_report("v3_ma_mg_mm", scope = "haupttest_struktur")
  plot <- plot_item_levels(input, "MO", by = "module")
  counts <- attr(plot, "item_level_counts")
  modules <- summarise_report_input(input)$main_test$modules
  expect_identical(unique(counts$module_id), modules$module_id)
  expect_equal(as.numeric(tapply(counts$n_items, counts$module_id, sum)[modules$module_id]), modules$n_items)
  expect_gt(sum(counts$n_items), nrow(input$data$main_test$items))
  expect_no_warning(all_built <- ggplot2::ggplot_build(plot))
  expect_length(all_built$layout$panel_params, 1L)
  limits <- all_built$layout$panel_params[[1L]]$y.range
  bars <- all_built$data[[1L]]
  labels <- all_built$data[[2L]]
  expect_equal(as.numeric(bars$x), as.numeric(labels$x))
  expect_equal(bars$y, labels$label)
  expect_true(all(bars$xmax - bars$xmin <= 0.35 + 1e-8))
  expect_equal(length(unique(bars$fill)), nrow(modules))
  expect_equal(as.numeric(table(round(as.numeric(bars$x)))), rep(nrow(modules), 5))
  expect_identical(as.character(all_built$plot$scales$get_scales("fill")$get_breaks()),
                   modules$module_id)

  selected <- rev(modules$module_id[-1L])
  page <- plot_item_levels(input, "MO", by = "module", module_ids = selected)
  expect_identical(unique(attr(page, "item_level_counts")$module_id), modules$module_id[-1L])
  page_built <- ggplot2::ggplot_build(page)
  expect_identical(page_built$layout$panel_params[[1L]]$y.range, limits)
  expect_identical(page_built$plot$scales$get_scales("fill")$map(selected),
                   all_built$plot$scales$get_scales("fill")$map(selected))
  expect_equal(attr(page, "suggested_height_cm"), 9.4)
  expect_equal(attr(plot, "suggested_height_cm"), 9.4)
})

test_that("legend labels wrap without shortening names and add sufficient height", {
  input <- example_report("v3_ma_mg_mm", scope = "haupttest_struktur")
  input$data$main_test$modules$label[1L] <-
    "Mathematik Basismodul mit einer bewusst langen vollstaendigen Modulbezeichnung"
  plot <- plot_item_levels(input, "MO", by = "module")
  labels <- plot$scales$get_scales("fill")$labels
  expect_match(labels[[1L]], "\n", fixed = TRUE)
  expect_identical(gsub("\n", " ", labels[[1L]], fixed = TRUE),
                   input$data$main_test$modules$label[1L])
  expect_gt(attr(plot, "suggested_height_cm"), 9.4)
})

test_that("larger module sets remain together and keep distinguishable series", {
  input <- example_report("v3_ma_mg_mm", scope = "haupttest_struktur")
  main_test <- input$data$main_test
  source_module <- main_test$modules[2L, ]
  source_links <- main_test$module_items[
    main_test$module_items$module_id == source_module$module_id, ]
  for (i in seq_len(5L)) {
    added <- source_module
    added$module_id <- paste0("extra_", i)
    added$label <- paste("Weiteres Erg\u00e4nzungsmodul", i)
    added$position <- nrow(main_test$modules) + 1L
    main_test$modules <- rbind(main_test$modules, added)
    links <- source_links
    links$module_id <- added$module_id
    main_test$module_items <- rbind(main_test$module_items, links)
  }
  input$data$main_test <- main_test
  plot <- plot_item_levels(input, "MO", by = "module")
  expect_no_warning(built <- ggplot2::ggplot_build(plot))
  expect_length(built$layout$panel_params, 1L)
  expect_equal(length(unique(built$data[[1L]]$fill)), nrow(main_test$modules))
  expect_equal(nrow(attr(plot, "item_level_counts")), 5L * nrow(main_test$modules))
  expect_gt(attr(plot, "suggested_height_cm"), 9.4)
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
