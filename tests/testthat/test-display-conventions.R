render_age_paragraph <- function(age) {
  source <- system.file("quarto", "texts", "pilotierung_stichprobe_merkmale.qmd",
                         package = "eatTechReport")
  text <- readLines(source, encoding = "UTF-8")
  end <- which(text == "```")[1L]
  environment <- new.env(parent = baseenv())
  environment$results <- list(sample = list(characteristics = list(age = age)))
  paste(utils::capture.output(eval(parse(text = text[2L:(end - 1L)]),
                                   envir = environment)), collapse = "\n")
}

test_that("the age paragraph reports missing percentages within the analysis population", {
  input <- example_report(n_persons = 6L)
  ages <- input$data$sample$characteristics$age$values
  ages$value[] <- NA_real_
  analysis <- match(unique(input$data$population$person_id), ages$person_id)
  ages$value[analysis[-1L]] <- c(8, 8.5, 9, 9.5, 10)
  input$data$sample$characteristics$age$values <- ages
  age <- summarise_report_input(input)$sample$characteristics$age
  text <- render_age_paragraph(age)
  expect_match(text, "fehlende Angaben: 16,7 %", fixed = TRUE)
  expect_match(text, "*M* = 9,0", fixed = TRUE)
  expect_false(grepl("*N*", text, fixed = TRUE))
  expect_false(grepl("37,5 %", text, fixed = TRUE))
})

test_that("age text distinguishes zero, complete and unmeasurable missingness", {
  input <- example_report(n_persons = 6L)
  input$data$sample$characteristics$age$values$value[] <- 8.5
  age <- summarise_report_input(input)$sample$characteristics$age
  expect_match(render_age_paragraph(age), "fehlende Angaben: 0,0 %", fixed = TRUE)

  input$data$sample$characteristics$age$values$value[] <- NA_real_
  age <- summarise_report_input(input)$sample$characteristics$age
  text <- render_age_paragraph(age)
  expect_match(text, "fehlende Angaben: 100,0 %", fixed = TRUE)
  expect_false(grepl("*M*", text, fixed = TRUE))

  age$n_valid <- age$n_missing <- 0L
  text <- render_age_paragraph(age)
  expect_match(text, "keine Personen", fixed = TRUE)
  expect_false(grepl("NaN|Inf|[0-9],0 %", text))
  expect_match(render_age_paragraph(NULL), "nicht erhoben", fixed = TRUE)
})

test_that("booklet output uses lower-case units and literal umlauts", {
  for (profile in c("v3_de_lesen_zuhoeren", "v3_ma_mg_mm")) {
    input <- example_report(profile)
    results <- summarise_report_input(input)
    rules <- results$design$design_rules$assignment_description
    expect_true(any(grepl("erh\u00e4lt", rules, fixed = TRUE)))
    expect_false(any(grepl("erhaelt", rules, fixed = TRUE)))
    tables <- study_design_tables(results$design)
    notes <- vapply(tables, study_design_timing_note, character(1))
    expect_true(any(grepl("[0-9](,[0-9])?\u00a0min", notes)))
    expect_false(any(grepl(" Min\\.?", notes)))
  }
})
