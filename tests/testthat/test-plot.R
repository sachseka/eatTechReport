test_that("plots preserve the exact empirical percentages and summaries", {
  demo <- example_report()
  plot <- plot_performance(demo, "DL")
  result <- summarise_leistung_input(demo)
  expected_shares <- result$percentages[result$percentages$scale_id == "DL", ]
  expected_summary <- result$descriptives[result$descriptives$scale_id == "DL", ]
  rownames(expected_shares) <- rownames(expected_summary) <- NULL
  expect_s3_class(plot, "ggplot")
  expect_equal(attr(plot, "population_percentages"), expected_shares)
  expect_equal(attr(plot, "descriptives"), expected_summary)
  expect_no_warning(built <- ggplot2::ggplot_build(plot))
  expect_true(all(demo$config$scales$DL$cuts %in% built$layout$panel_params[[1L]]$x$breaks))
  expect_true(any(grepl(",", built$layout$panel_params[[1L]]$y$get_labels(), fixed = TRUE)))
  expect_match(plot$labels$caption, "Synthetisches Beispiel")
})

test_that("bandwidth changes the curve but cannot change level shares", {
  demo <- example_report("v3_ma_mg_mm")
  narrow <- plot_performance(demo, "MO", bandwidth = 10)
  wide <- plot_performance(demo, "MO", bandwidth = 80)
  expect_equal(attr(narrow, "population_percentages"), attr(wide, "population_percentages"))
  expect_false(identical(attr(narrow, "density_data"), attr(wide, "density_data")))
  expect_equal(attr(wide, "density_bandwidth"), 80)
  expect_error(plot_performance(demo, "MG"), "scale_id")
  for (bandwidth in list(0, -1, NA_real_, Inf, c(10, 20), "nrd0")) {
    expect_error(plot_performance(demo, "MO", bandwidth = bandwidth), "bandwidth")
  }
})

test_that("duplicating PV sets does not alter the automatic smoothing or curve", {
  demo <- example_report("v3_ma_mg_mm", n_pv = 2L)
  original <- plot_performance(demo, "MO")
  doubled <- demo
  copies <- demo$data$pvs
  copies$pv_id <- ifelse(copies$pv_id == "pv01", "pv03", "pv04")
  doubled$data$pvs <- rbind(demo$data$pvs, copies)
  doubled$config$scales$MO$pv_ids <- sprintf("pv%02d", 1:4)
  repeated <- plot_performance(doubled, "MO")
  expect_equal(attr(repeated, "density_bandwidth"), attr(original, "density_bandwidth"))
  expect_equal(attr(repeated, "density_data"), attr(original, "density_data"))
  expect_equal(attr(repeated, "population_percentages"), attr(original, "population_percentages"))
})

test_that("constant PVs and empty outer intervals remain visible and labelled", {
  demo <- example_report("v3_ma_mg_mm", n_persons = 2L, n_pv = 1L)
  demo$data$pvs$value <- c(500, 500)
  plot <- plot_performance(demo, "MO")
  density <- attr(plot, "density_data")
  expect_true(all(is.finite(density$density)))
  expect_lt(min(density$value), min(demo$config$scales$MO$cuts))
  expect_gt(max(density$value), max(demo$config$scales$MO$cuts))
  built <- ggplot2::ggplot_build(plot)
  labels <- built$data[[5L]]$label
  expect_length(labels, 5L)
  expect_identical(labels, c("Ia", "Ib", "II", "III", "IV"))
  percent_labels <- built$data[[6L]]$label
  expect_match(percent_labels[1L], 'plain("0,0")', fixed = TRUE)
  expect_match(percent_labels[5L], 'plain("0,0")', fixed = TRUE)
  expect_equal(attr(plot, "population_percentages")$percent, c(0, 0, 100, 0, 0))
})
