main_test_text_fixture <- function() {
  list(
    totals = data.frame(n_tasks = 2L, n_items = 3L, n_modules = 2L),
    pool = data.frame(domain_id = c("DL", "DH"), scale_id = c("DL", "DH"),
                       n_tasks = c(1L, 1L), n_items = c(2L, 1L)),
    modules = data.frame(module_id = c("core", "extension"),
                          label = c("Grundlage [A]", "Zusatz | B"),
                          module_type = c("base", "supplement"),
                          position = c(1L, 2L), duration_minutes = c(12.5, 0),
                          n_tasks = c(1L, 2L), n_items = c(2L, 2L),
                          domain_ids = c("DL", "DL, DH"),
                          scale_ids = c("DL", "DL, DH")),
    tasks = data.frame(module_id = c("core", "extension", "extension"),
                        task_position = c(1L, 2L, 4L),
                        task_id = c("reading", "listening", "reading"),
                        task_label = c("Lesen | Test", "H\u00f6ren [A]", "Lesen | Test"),
                        domain_id = c("DL", "DH", "DL"), n_items = c(2L, 1L, 1L)),
    waves = data.frame(wave_id = c("old", "current"), pilot_year = c(2025L, 2026L),
                        label = c("Fr\u00fchere Pilotierung", "Aktuelle Pilotierung"),
                        n_tasks = c(1L, 2L), n_items = c(1L, 3L)),
    source_overlap = TRUE
  )
}

render_main_test_blocks <- function(source, config, main_test) {
  previous_options <- options(device = function(...) grDevices::pdf(file = NULL, ...))
  on.exit(options(previous_options), add = TRUE)
  results <- list(main_test = main_test)
  paste(knitr::knit_child(text = source, envir = environment(),
                          options = list(echo = FALSE), quiet = TRUE), collapse = "\n")
}

test_that("main-test presentation retains overlap, partial tasks and supplied positions", {
  tables <- main_test_tables(main_test_text_fixture(), example_leistung_input()$config)
  expect_equal(tables$pool$Items, c(2L, 1L))
  expect_equal(tables$modules$Items, c(2L, 2L))
  expect_equal(tables$waves$Items, c(1L, 3L))
  expect_identical(tables$modules$Bearbeitungszeit, c("12,5\u00a0min", "0,0\u00a0min"))
  expect_identical(tables$modules$Modul,
                   paste0(main_test_text_fixture()$modules$label,
                          c(" (Basismodul)", " (Erg\u00e4nzungsmodul)")))
  expect_identical(tables$task_lists[[2L]]$table$Position, c(2L, 4L))
  expect_identical(tables$task_lists[[1L]]$table$Items, 2L)
  expect_identical(tables$task_lists[[2L]]$table$Items, c(1L, 1L))
  expect_identical(tables$task_lists[[2L]]$table$Aufgabe,
                   c("H\u00f6ren [A]", "Lesen | Test"))
})

test_that("module labels already naming their type do not repeat it", {
  fixture <- main_test_text_fixture()
  fixture$modules$label <- c("DL Basismodul", "DH Erg\u00e4nzungsmodul")
  tables <- main_test_tables(fixture, example_leistung_input()$config)
  expect_identical(tables$modules$Modul, fixture$modules$label)
})

test_that("main-test Quarto blocks render separate captions and escape user labels", {
  config <- example_leistung_input()$config
  sources <- system.file("quarto", "texts",
                          c("haupttest_auswahl.qmd", "haupttest_module.qmd"),
                          package = "eatTechReport")
  source <- unlist(lapply(sources, readLines, encoding = "UTF-8"), use.names = FALSE)
  rendered <- render_main_test_blocks(source, config, main_test_text_fixture())
  expect_match(rendered, "# Informationen zur Hauptstudie 2027", fixed = TRUE)
  expect_match(rendered, "{#haupttest_auswahl}", fixed = TRUE)
  expect_match(rendered, "{#haupttest_module}", fixed = TRUE)
  expect_match(rendered, "{#tbl-haupttest-aufgaben-1}", fixed = TRUE)
  expect_match(rendered, "{#tbl-haupttest-aufgaben-2}", fixed = TRUE)
  expect_match(rendered, "Zusatz &#124; B", fixed = TRUE)
  expect_match(rendered, "H\u00f6ren \\[A\\]", fixed = TRUE)
  expect_match(rendered, "12,5\u00a0min", fixed = TRUE)
  expect_match(rendered, "mehreren Pilotierungen", fixed = TRUE)
  expect_match(rendered, "nicht zu einer Gesamtzahl addiert", fixed = TRUE)
  expect_match(rendered, "[Kriterien und Begr\u00fcndung", fixed = TRUE)
  expect_false(grepl("\\b(NA|NaN|Inf)\\b| Min", rendered))
})

test_that("mathematics text keeps global scaling and distinguishes task from item origins", {
  config <- example_leistung_input("v3_ma_mg_mm")$config
  results <- list(main_test = main_test_text_fixture())
  results$main_test$pool$domain_id <- c("MG", "MM")
  results$main_test$pool$scale_id <- c("MO", "MO")
  results$main_test$source_overlap <- FALSE
  source <- readLines(system.file("quarto", "texts", "haupttest_auswahl.qmd",
                                   package = "eatTechReport"), encoding = "UTF-8")
  source <- sub("#\\| label: ", "#| label: ma_", source)
  rendered <- render_main_test_blocks(source, config, results$main_test)
  expect_match(rendered, "Mathematik insgesamt (MO)", fixed = TRUE)
  expect_match(rendered, "Items sind jeweils einer Pilotierung zugeordnet", fixed = TRUE)
  expect_match(rendered, "Aufgaben k\u00f6nnen Items aus mehreren Pilotierungen", fixed = TRUE)
  expect_false(grepl("Einzelne Items wurden in mehreren", rendered, fixed = TRUE))
})
