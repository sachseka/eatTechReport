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
  expect_match(math, "KMK (2022)", fixed = TRUE)
  expect_false(grepl("Reiss", math, fixed = TRUE))
  expect_match(math, "Yen, W. M. (1984)", fixed = TRUE)
  expect_match(math, "Yen, W. M. (1993)", fixed = TRUE)
  expect_false(grepl("IQB (2013a)", math, fixed = TRUE))
})

test_that("software citations use declared study metadata consistently", {
  config <- completion_text_fixture()$config
  config$report$data_origin <- "observed"
  config$editorial <- list(testcenter_year = 2026L, testcenter_version = "19.1.0",
    kodierbox_year = 2026L, kodierbox_version = "1.17.4",
    eatpreptba_year = 2026L, eatpreptba_version = "0.9.8.9049",
    tam_year = 2025L, tam_version = "4.3-25")
  before <- config
  expect_identical(report_software_citation(config, "testcenter"), "IQB, 2026b")
  expect_identical(report_software_citation(config, "kodierbox"), "IQB, 2026a")
  expect_identical(report_software_citation(config, "eatpreptba"), "Franikowski et al., 2026")
  expect_identical(report_software_citation(config, "tam"), "Robitzsch et al., 2025")
  references <- report_software_bibliography(config)
  expect_match(references[1], "(2026b)", fixed = TRUE)
  expect_match(references[2], "(2026a)", fixed = TRUE)
  expect_match(references[3], "Schumann, K.", fixed = TRUE)
  expect_match(references[4], "4\\.3\\-25", fixed = TRUE)
  expect_match(references[4], "10.32614/CRAN.package.TAM", fixed = TRUE)
  expect_identical(config, before)
  config$editorial$testcenter_year <- 2024L
  expect_identical(report_software_citation(config, "testcenter"), "IQB, 2024")
  expect_identical(report_software_citation(config, "kodierbox"), "IQB, 2026")
  expect_error(report_software_citation(config, "unknown"), "Unbekannte Softwarequelle")
  expect_error(report_software_citation(config, c("tam", "testcenter")), "Unbekannte Softwarequelle")
  expect_error(report_software_citation(config, factor("tam")), "Unbekannte Softwarequelle")
})

test_that("software metadata remain open without supplied study versions", {
  config <- completion_text_fixture()$config
  missing <- report_software_bibliography(config)
  expect_match(missing[4], "Version von TAM", fixed = TRUE)
  expect_false(grepl("4\\.3\\-25", missing[4], fixed = TRUE))
  config$editorial <- list(tam_year = 2025L, tam_version = "4.3-25")
  simulated <- report_software_bibliography(config)[4]
  expect_match(simulated, '[2025]{custom-style="EatSimulatedValue"}', fixed = TRUE)
  expect_match(simulated, '[4\\.3\\-25]{custom-style="EatSimulatedValue"}', fixed = TRUE)
  config$report$data_origin <- "observed"
  expect_false(grepl("EatSimulatedValue", report_software_bibliography(config)[4], fixed = TRUE))
})

test_that("all final chapter blocks knit for German and global mathematics", {
  text_dir <- system.file("quarto", "texts", package = "eatTechReport")
  previous_options <- options(device = function(...) grDevices::pdf(file = NULL, ...))
  on.exit(options(previous_options), add = TRUE)
  for (profile in c("v3_de_lesen_zuhoeren", "v3_ma_mg_mm")) {
    fixture <- completion_text_fixture(profile)
    env <- new.env(parent = globalenv())
    env$config <- fixture$config
    env$value <- function(x, markdown = FALSE) report_text_value(x, fixture$config, markdown)
    env$results <- list(main_test_results = fixture$main_test_results)
    sources <- file.path(text_dir, report_completion_text_names())
    source <- unlist(lapply(sources, readLines, encoding = "UTF-8"), use.names = FALSE)
    source <- gsub("(label: |\\{asis, )", paste0("\\1", profile, "_"), source)
    markdown <- paste(knitr::knit_child(text = source, envir = env,
      options = list(echo = FALSE), quiet = TRUE), collapse = "\n")
    expect_match(markdown, "{#haupttest_auswertungshinweise}", fixed = TRUE)
    expect_match(markdown, "{#literatur}", fixed = TRUE)
    expect_match(markdown, "{#eq-haupttest-persontransformation}", fixed = TRUE)
    expect_match(markdown, "{#tbl-haupttest-referenz}", fixed = TRUE)
    expect_match(markdown, 'custom-style="EatSimulatedValue"', fixed = TRUE)
    expect_false(grepl("Synthetisches Beispiel|affine|y_\\{|Itemschwierigkeit auf der jeweils", markdown))
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
