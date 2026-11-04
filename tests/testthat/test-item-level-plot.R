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
  expect_equal(built$data[[1L]]$y, c(0, 0, 4, 0, 0))
  expect_length(built$data, 1L)
  expect_equal(sum(built$data[[1L]]$y), 4)
  expect_true(all(built$data[[1L]]$xmax - built$data[[1L]]$xmin <= 0.35 + 1e-8))
  expect_null(plot$labels$title)
  expect_null(plot$labels$subtitle)
  expect_null(plot$labels$caption)
  expect_identical(attr(plot, "data_origin"), "synthetic")
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
  expect_length(all_built$data, 1L)
  expect_true(all(bars$xmax - bars$xmin <= 0.35 + 1e-8))
  expect_equal(length(unique(bars$fill)), 2L)
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
  expect_equal(attr(page, "suggested_height_cm"), 8.4)
  expect_equal(attr(plot, "suggested_height_cm"), 8.4)
  expect_identical(plot$theme$legend.position, "right")
  expect_identical(plot$labels$y, "Anzahl Items")
})

test_that("legends use stable short display labels independently of free module names", {
  input <- example_report("v3_ma_mg_mm", scope = "haupttest_struktur")
  input$data$main_test$modules$label[1L] <-
    "Mathematik Basismodul mit einer bewusst langen vollstaendigen Modulbezeichnung"
  plot <- plot_item_levels(input, "MO", by = "module")
  labels <- plot$scales$get_scales("fill")$labels
  expect_identical(unname(labels), c("MO-BM", "MG-EM-A", "MG-EM-B", "MM-EM-A", "MM-EM-B"))
  expect_equal(attr(plot, "suggested_height_cm"), 8.4)
})

test_that("larger module sets retain all counts and stay within the corporate palette", {
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
  ids <- c(source_module$module_id, "MG_EM_B", paste0("extra_", seq_len(5L)))
  plot <- plot_item_levels(input, "MO", by = "module", module_ids = ids)
  expect_no_warning(built <- ggplot2::ggplot_build(plot))
  expect_length(built$layout$panel_params, 1L)
  expect_setequal(unique(built$data[[1L]]$fill),
                  c("#B40036", "#00818D", "#EFA7C0", "#CAC5CD", "#534856", "#271A2B"))
  expect_equal(nrow(attr(plot, "item_level_counts")), 5L * length(ids))
  expect_gt(attr(plot, "suggested_height_cm"), 8.4)
})

test_that("German scales reuse corporate colours and single-series plots omit legends", {
  input <- example_report(scope = "haupttest_struktur")
  dl <- plot_item_levels(input, "DL", by = "module")
  dh <- plot_item_levels(input, "DH", by = "module")
  colours <- function(plot) {
    built <- ggplot2::ggplot_build(plot)
    unique(built$data[[1L]]$fill)
  }
  expect_identical(colours(dl), c("#B40036", "#00818D", "#EFA7C0"))
  expect_identical(colours(dl), colours(dh))
  expect_identical(dl$theme$legend.position, "right")
  expect_identical(dl$labels$x, "Kompetenzstufen Lesen")
  expect_null(dl$labels$y)
  single <- plot_item_levels(input, "DL", by = "module", module_ids = "DL_BM")
  expect_identical(single$theme$legend.position, "none")
  expect_equal(sum(attr(single, "item_level_counts")$n_items), 3L)
})

test_that("math base and supplement figures restart the same palette", {
  input <- example_report("v3_ma_mg_mm", scope = "haupttest_struktur")
  base <- plot_item_levels(input, "MO", by = "module", module_ids = "MA_BM")
  mg <- plot_item_levels(input, "MO", by = "module", module_ids = c("MG_EM", "MG_EM_B"))
  mm <- plot_item_levels(input, "MO", by = "module", module_ids = c("MM_EM", "MM_EM_B"))
  colours <- function(plot) unique(ggplot2::ggplot_build(plot)$data[[1L]]$fill)
  expect_identical(colours(base), "#B40036")
  expect_identical(colours(mg), c("#B40036", "#00818D"))
  expect_identical(colours(mg), colours(mm))
  expect_identical(base$theme$legend.position, "right")
  limits <- function(plot) ggplot2::ggplot_build(plot)$layout$panel_params[[1L]]$y.range
  expect_equal(limits(base), limits(mg))
  expect_equal(limits(mg), limits(mm))
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
  expect_true(all(built$layout$panel_params[[1L]]$y$breaks %in% c(0, 1, 2)))
  path <- tempfile(fileext = ".pdf")
  expect_no_warning(ggplot2::ggsave(path, plot, width = 15.5,
                                    height = attr(plot, "suggested_height_cm"), units = "cm"))
  expect_gt(file.info(path)$size, 0)
})
