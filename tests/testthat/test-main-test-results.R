main_results_fixture <- function(profile = "v3_de_lesen_zuhoeren") {
  config <- example_leistung_input(profile)$config
  main_test <- example_main_test_data(config)
  list(config = config, main_test = main_test,
       data = example_main_test_results(config, main_test))
}

test_that("final item summaries use supplied affine item transformations", {
  for (profile in c("v3_de_lesen_zuhoeren", "v3_ma_mg_mm")) {
    fixture <- main_results_fixture(profile)
    expect_true(validate_main_test_results(fixture$data, fixture$config, fixture$main_test))
    result <- summarise_main_test_results(fixture$data, fixture$config, fixture$main_test)
    expect_equal(stats::plogis((result$item_statistics$report_score - 500) / 100 -
                                result$item_statistics$logit),
                 rep(0.625, nrow(result$item_statistics)))
    expect_equal(nrow(result$item_statistics), nrow(fixture$main_test$items))
    expect_gt(sum(result$module_statistics$n_items), nrow(result$item_statistics))
    expect_identical(result$transformations$target,
                     rep(c("person", "item"), length(unique(result$item_statistics$scale_id))))
    expect_true(all(result$item_statistics$p_correct >= 0 & result$item_statistics$p_correct <= 1))
    if (profile == "v3_ma_mg_mm") expect_identical(unique(result$module_statistics$scale_id), "MO")
  }
})

test_that("module statistics distinguish reused items and mixed scale modules", {
  fixture <- main_results_fixture()
  fixture$data$item_statistics$p_correct <- seq_len(nrow(fixture$data$item_statistics)) / 10
  fixture$data$item_statistics$logit <- seq_len(nrow(fixture$data$item_statistics))
  extra <- fixture$main_test$module_items[fixture$main_test$module_items$module_id == "DH_BM", ]
  extra$module_id <- "DL_BM"
  extra$task_position <- extra$task_position + 10
  fixture$main_test$module_items <- rbind(fixture$main_test$module_items, extra)
  result <- summarise_main_test_results(fixture$data, fixture$config, fixture$main_test)
  for (i in seq_len(nrow(result$module_statistics))) {
    row <- result$module_statistics[i, ]
    ids <- fixture$main_test$module_items$item_id[fixture$main_test$module_items$module_id == row$module_id]
    selected <- subset(result$item_statistics, item_id %in% ids & scale_id == row$scale_id)
    expect_equal(row$n_items, nrow(selected))
    expect_equal(row$mean_p_correct, mean(selected$p_correct))
    expect_equal(row$mean_logit, mean(selected$logit))
    expect_equal(c(row$min_report_score, row$max_report_score), range(selected$report_score))
  }
  expect_identical(result$module_statistics$scale_id[result$module_statistics$module_id == "DL_BM"],
                     c("DL", "DH"))
})

test_that("summaries are stable under row and column reordering", {
  fixture <- main_results_fixture()
  expected <- summarise_main_test_results(fixture$data, fixture$config, fixture$main_test)
  reorder <- function(x) x[rev(seq_len(nrow(x))), rev(names(x)), drop = FALSE]
  fixture$main_test <- lapply(fixture$main_test, reorder)
  fixture$data$item_statistics <- reorder(fixture$data$item_statistics)
  fixture$data$transformations <- reorder(fixture$data$transformations)
  fixture$data$definitions <- rev(fixture$data$definitions)
  expect_identical(summarise_main_test_results(fixture$data, fixture$config, fixture$main_test), expected)
  expect_identical(example_main_test_results(fixture$config, fixture$main_test),
                   example_main_test_results(fixture$config, lapply(fixture$main_test, reorder)))
})

test_that("transformations require exactly both purposes for the used scales", {
  fixture <- main_results_fixture()
  valid <- fixture$data
  check <- function(data) validate_main_test_results(data, fixture$config, fixture$main_test)
  data <- valid
  data$transformations <- data$transformations[-1L, ]
  expect_error(check(data), "person und item fuer jede")
  data <- valid
  data$transformations <- rbind(data$transformations, data$transformations[1L, ])
  expect_error(check(data), "doppelte Skala-Ziel")
  data <- valid
  data$transformations$target[1L] <- "threshold"
  expect_error(check(data), "nur person und item")
  data <- valid
  data$transformations$scale_id[1L] <- "unknown"
  expect_error(check(data), "unbekannte oder ungenutzte")
  fixture$config$domains <- rbind(fixture$config$domains,
    data.frame(domain_id = "DO", label = "Orthografie", scale_id = "DO"))
  expect_true(check(valid))
  data <- valid
  unused <- data$transformations[1:2, ]
  unused$scale_id <- "DO"
  data$transformations <- rbind(data$transformations, unused)
  expect_error(check(data), "unbekannte oder ungenutzte")
})

test_that("invalid item statistics fail before summarising", {
  fixture <- main_results_fixture()
  valid <- fixture$data
  check <- function(data) validate_main_test_results(data, fixture$config, fixture$main_test)
  data <- valid
  data$item_statistics <- data$item_statistics[-1L, ]
  expect_error(check(data), "jedes ausgewaehlte Item")
  data <- valid
  data$item_statistics$item_id[1L] <- "unknown"
  expect_error(check(data), "unbekannte IDs")
  data <- valid
  data$item_statistics$item_id[1L] <- data$item_statistics$item_id[2L]
  expect_error(check(data), "Duplikate")
  for (value in list(-0.1, 1.1, Inf, NA_real_, "0.5", 1 + 1i)) {
    data <- valid
    data$item_statistics$p_correct[1L] <- value
    expect_error(check(data), "p_correct")
  }
  data <- valid
  data$item_statistics$p_correct[c(1, 2)] <- c(0, 1)
  expect_true(check(data))
  for (value in list(NA_real_, NaN, Inf, "0", 1 + 1i)) {
    data <- valid
    data$item_statistics$logit[1L] <- value
    expect_error(check(data), "logit")
  }
})

test_that("affine coefficients and explanatory metadata are explicit and finite", {
  fixture <- main_results_fixture()
  valid <- fixture$data
  check <- function(data) validate_main_test_results(data, fixture$config, fixture$main_test)
  for (value in list(0, -1, Inf, NA_real_, "100", 1 + 1i)) {
    data <- valid
    data$transformations$slope[1L] <- value
    expect_error(check(data), "slope")
  }
  for (value in list(NA_real_, Inf, "500", 1 + 1i)) {
    data <- valid
    data$transformations$intercept[1L] <- value
    expect_error(check(data), "intercept")
  }
  data <- valid
  data$item_statistics$logit[] <- 1e308
  expect_error(check(data), "nichtendliche Berichtswerte")
  for (value in list("", NA_character_, "text\ntext")) {
    data <- valid
    data$transformations$source_label[1L] <- value
    expect_error(check(data), "source_label")
  }
  data <- valid
  data$definitions$population <- NULL
  expect_error(check(data), "definitions erwartet genau")
  data <- valid
  data$definitions$p_correct <- c("one", "two")
  expect_error(check(data), "genau einen Beschreibungstext")
  data <- valid
  data$definitions$logit <- ""
  expect_error(check(data), "definitions.*Zeichenketten")
})

test_that("input structure is strict and transformation purposes stay distinct", {
  fixture <- main_results_fixture()
  valid <- fixture$data
  check <- function(data) validate_main_test_results(data, fixture$config, fixture$main_test)
  expect_error(check(valid[-1L]), "main_test_results erwartet genau")
  data <- valid
  data$unknown <- TRUE
  expect_error(check(data), "main_test_results erwartet genau")
  data <- valid
  data$item_statistics$extra <- 1
  expect_error(check(data), "item_statistics muss.*genau")
  data <- valid
  data$item_statistics <- data$item_statistics[FALSE, ]
  expect_error(check(data), "nichtleere Tabelle")
  data <- valid
  data$item_statistics$logit <- as.list(data$item_statistics$logit)
  expect_error(check(data), "eindimensionale Spalten")
  before <- summarise_main_test_results(valid, fixture$config, fixture$main_test)
  data <- valid
  data$transformations$intercept[data$transformations$target == "person"] <- 1200
  fixture$config$scales$DL$cuts <- fixture$config$scales$DL$cuts + 100
  after <- summarise_main_test_results(data, fixture$config, fixture$main_test)
  expect_identical(after$item_statistics, before$item_statistics)
  expect_identical(after$module_statistics, before$module_statistics)
})
