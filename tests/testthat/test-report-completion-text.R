completion_text_fixture <- function(profile = "v3_de_lesen_zuhoeren") {
  config <- example_leistung_input(profile)$config
  main_test <- example_main_test_data(config)
  list(config = config, main_test_results = summarise_main_test_results(
    example_main_test_results(config, main_test), config, main_test))
}

test_that("module statistics retain supplied values and display precision", {
  fixture <- completion_text_fixture()
  rows <- fixture$main_test_results
  rows$module_statistics$mean_p_correct[1] <- 0.12349
  rows$module_statistics$mean_logit[1] <- -0.1251
  before <- rows
  table <- report_completion_module_table(rows)
  expect_identical(rows, before)
  expect_identical(table[["M L\u00f6sung (%)"]][1], "12,3")
  expect_identical(table[["M Logit"]][1], "-0,13")
  expect_identical(table[["Items (N)"]], rows$module_statistics$n_items)
  markdown <- study_table_markdown(table)
  expect_match(markdown, "*M* Logit", fixed = TRUE)
  expect_match(markdown, "Items \\(*N*\\)", fixed = TRUE)
})

test_that("formulas use independent person and item coefficients and escape labels", {
  fixture <- completion_text_fixture()
  rows <- fixture$main_test_results
  rows$transformations$intercept[1:2] <- c(-5.125, 600)
  rows$transformations$slope[1:2] <- c(0.00000123, 42.5)
  rows$transformations$source_label[1] <- "Quelle *ungeprueft* | [Entwurf]"
  fixture$config$scales$DL$label <- "Lesen *Beispiel*"
  markdown <- report_transformation_markdown(rows, fixture$config)
  expect_match(markdown, "-5{,}125 + 0{,}00000123 \\cdot \\theta", fixed = TRUE)
  expect_match(markdown, "600 + 42{,}5 \\cdot \\beta", fixed = TRUE)
  expect_match(markdown, "Lesen \\*Beispiel\\*", fixed = TRUE)
  expect_match(markdown, "Quelle \\*ungeprueft\\*", fixed = TRUE)
  expect_match(markdown, "\\[Entwurf\\]", fixed = TRUE)
  expect_error(report_transformation_number("500 + \\input{secret}"), "endliche Zahlen")
  expect_error(report_transformation_number(c(1, 2)), "endliche Zahlen")
  expect_error(report_transformation_number(Inf), "endliche Zahlen")
  expect_error(report_transformation_number(1 + 1i), "endliche Zahlen")
})

test_that("bibliographies cover configured background sources without foreign domains", {
  fixture <- completion_text_fixture()
  basic <- report_completion_bibliography(fixture$config)
  expect_length(basic, 1L)
  expect_match(basic, "KMK (2012)", fixed = TRUE)
  german <- paste(report_completion_bibliography(fixture$config, TRUE), collapse = "\n")
  expect_match(german, "Cohen, J. (1960)", fixed = TRUE)
  expect_match(german, "IQB (2013a)", fixed = TRUE)
  expect_match(german, "IQB (2013b)", fixed = TRUE)
  expect_false(grepl("Reiss", german, fixed = TRUE))
  fixture$config$domains <- subset(fixture$config$domains, domain_id == "DL")
  expect_false(any(grepl("2013b", report_completion_bibliography(fixture$config, TRUE), fixed = TRUE)))
  math <- paste(report_completion_bibliography(completion_text_fixture("v3_ma_mg_mm")$config,
                                               TRUE), collapse = "\n")
  expect_match(math, "Reiss, K. & Winkelmann, H. (2008)", fixed = TRUE)
  expect_match(math, "Yen, W. M. (1984)", fixed = TRUE)
  expect_match(math, "Yen, W. M. (1993)", fixed = TRUE)
  expect_false(grepl("IQB (2013a)", math, fixed = TRUE))
})

test_that("all final chapter blocks knit for German and global mathematics", {
  text_dir <- system.file("quarto", "texts", package = "eatTechReport")
  previous_options <- options(device = function(...) grDevices::pdf(file = NULL, ...))
  on.exit(options(previous_options), add = TRUE)
  for (profile in c("v3_de_lesen_zuhoeren", "v3_ma_mg_mm")) {
    fixture <- completion_text_fixture(profile)
    env <- new.env(parent = globalenv())
    env$config <- fixture$config
    env$results <- list(main_test_results = fixture$main_test_results)
    sources <- file.path(text_dir, report_completion_text_names())
    source <- unlist(lapply(sources, readLines, encoding = "UTF-8"), use.names = FALSE)
    source <- gsub("(label: |\\{asis, )", paste0("\\1", profile, "_"), source)
    markdown <- paste(knitr::knit_child(text = source, envir = env,
      options = list(echo = FALSE), quiet = TRUE), collapse = "\n")
    expect_match(markdown, "{#haupttest_itemprofil}", fixed = TRUE)
    expect_match(markdown, "{#literatur}", fixed = TRUE)
    expect_match(markdown, "Synthetisches Beispiel", fixed = TRUE)
    expect_match(markdown, "y_{\\mathrm{Person}} = 500 + 100 \\cdot \\theta", fixed = TRUE)
    expect_match(markdown, "y_{\\mathrm{Item}} = 550 + 100 \\cdot \\beta", fixed = TRUE)
    expect_false(grepl("@haupttest_transformation", markdown, fixed = TRUE))
    if (fixture$config$report$subject == "ma") {
      expect_match(markdown, "globalen Skala MO", fixed = TRUE)
      expect_false(grepl("Deutsch-Gesamtwert", markdown, fixed = TRUE))
    } else {
      expect_match(markdown, "Deutsch-Gesamtwert", fixed = TRUE)
      expect_false(grepl("globalen Skala MO", markdown, fixed = TRUE))
    }
  }
})
