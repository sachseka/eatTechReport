test_that("participation tables pair displayed N with the same percentage denominator", {
  input <- example_report(n_persons = 6L)
  result <- summarise_sample_data(input$data$sample, input)
  table <- study_sample_table(result)
  expect_equal(ncol(table), 5L)
  expect_false("Personen Auswertung" %in% names(table))
  expect_identical(names(table)[5L], "Anteil an der Pilotierungsstichprobe (%)")
  expect_identical(table[[5L]][-nrow(table)],
                   study_number(100 * result$by_state$n_participants /
                                  result$totals$n_participants))
  expect_false(identical(table[[5L]][-nrow(table)], study_number(result$by_state$analysis_percent)))

  input$config$report$data_origin <- "observed"
  input$config$editorial <- list(exclusion_reasons = "Es lagen keine auswertbaren Testdaten vor.")
  note <- study_sample_note(result, input$config)
  expect_match(note, "alle teilnehmenden", fixed = TRUE)
  expect_match(note, "2 Personen nicht in die Auswertung", fixed = TRUE)
  expect_match(note, "keine auswertbaren Testdaten", fixed = TRUE)
  expect_match(note, "Hintergrundmerkmale beziehen sich auf die ausgewerteten", fixed = TRUE)
  input$config$report$data_origin <- "synthetic"
  expect_match(study_sample_note(result, input$config),
               '[Es lagen keine auswertbaren Testdaten vor\\.]{custom-style="EatSimulatedValue"}', fixed = TRUE)
  result$totals$n_not_analysed <- 0L
  expect_false(grepl("keine auswertbaren|nicht in die Auswertung", study_sample_note(result, input$config)))
})

test_that("revised characteristic prose retains all categories and optional inclusion rule", {
  input <- example_report(n_persons = 6L)
  input$config$report$data_origin <- "observed"
  result <- summarise_sample_data(input$data$sample, input)
  text <- study_characteristic_sentences(result, input$config)
  expect_match(text[1L], "Weiterhin waren", fixed = TRUE)
  expect_match(text[1L], "divers und", fixed = TRUE)
  expect_match(text[1L], "% machten keine Angabe.", fixed = TRUE)
  expect_match(text[2L], "Bezüglich ihrer Familiensprache", fixed = TRUE)
  expect_false(any(grepl("regulär|ausgeschlossen", text)))
  input$config$editorial <- list(changed_conditions_included = TRUE)
  text <- study_characteristic_sentences(result, input$config)
  expect_match(text[3L], "mit veränderten Testbedingungen wurden regulär in die Auswertung einbezogen", fixed = TRUE)
  input$config$report$data_origin <- "synthetic"
  expect_match(study_characteristic_sentences(result, input$config)[3L],
    '[Schülerinnen und Schüler mit veränderten Testbedingungen wurden regulär in die Auswertung einbezogen\\.]{custom-style="EatSimulatedValue"}', fixed = TRUE)

  input$config$report$data_origin <- "observed"
  input$data$sample$characteristics$changed_conditions$values$value[] <- "nein"
  result <- summarise_sample_data(input$data$sample, input)
  text <- study_characteristic_sentences(result, input$config)
  expect_match(text[3L], "Veränderte Testbedingungen waren kein Ausschlussgrund", fixed = TRUE)
  expect_false(grepl("wurden regulär in die Auswertung", text[3L], fixed = TRUE))
})

test_that("excluded test conditions are reported for participants without filtering supplied data", {
  input <- example_report(n_persons = 6L)
  input$config$report$data_origin <- "observed"
  input$config$editorial <- list(changed_conditions_included = FALSE)
  original_population <- input$data$population
  values <- input$data$sample$characteristics$changed_conditions$values
  values$value <- ifelse(values$person_id %in% input$data$population$person_id, "nein", "ja")
  input$data$sample$characteristics$changed_conditions$values <- values
  expect_true(validate_sample_data(input$data$sample, input))
  result <- summarise_sample_data(input$data$sample, input)
  expect_identical(input$data$population, original_population)
  expect_equal(result$characteristics$changed_conditions$percent, c(0, 100, 0))
  expect_equal(result$changed_conditions_participants$percent, c(25, 75, 0))
  text <- study_characteristic_sentences(result, input$config)
  expect_match(text[3L], "25,0 % der Teilnehmenden", fixed = TRUE)
  expect_match(text[3L], "mit veränderten Testbedingungen wurden von der Auswertung ausgeschlossen", fixed = TRUE)
  expect_equal(result$characteristics$gender$denominator, rep(6L, 4L))

  missing_participant <- input$data$sample
  missing_participant$characteristics$changed_conditions$values <- values[-nrow(values), ]
  expect_error(validate_sample_data(missing_participant, input), "alle Teilnehmenden")
  contradictory <- input$data$sample
  contradictory$characteristics$changed_conditions$values$value[1L] <- "ja"
  expect_error(validate_sample_data(contradictory, input), "widerspricht der Auswertungspopulation")
  no_characteristic <- input$data$sample
  no_characteristic$characteristics["changed_conditions"] <- list(NULL)
  expect_error(validate_sample_data(no_characteristic, input), "erhobene Testbedingungen")
})

test_that("uncaptured and custom condition categories keep explicit prose", {
  input <- example_report(n_persons = 6L)
  input$config$report$data_origin <- "observed"
  input$data$sample$characteristics["gender"] <- list(NULL)
  input$data$sample$characteristics$changed_conditions$categories <- c("verändert", "unverändert")
  original <- input$data$sample$characteristics$changed_conditions$values$value
  input$data$sample$characteristics$changed_conditions$values$value <-
    c("verändert", "unverändert")[match(original, c("ja", "nein"))]
  result <- summarise_sample_data(input$data$sample, input)
  text <- study_characteristic_sentences(result, input$config)
  expect_match(text[1L], "Geschlecht wurde für diesen Durchgang nicht erhoben", fixed = TRUE)
  expect_match(text[3L], "folgende Angaben gemacht: verändert", fixed = TRUE)

  input <- example_report(n_persons = 6L)
  input$config$report$data_origin <- "observed"
  input$data$sample$characteristics$changed_conditions$categories <- c("ja", "nein", "teilweise")
  input$data$sample$characteristics$changed_conditions$values$value[1L] <- "teilweise"
  result <- summarise_sample_data(input$data$sample, input)
  text <- study_characteristic_sentences(result, input$config)
  expect_match(text[3L], "teilweise (16,7 %)", fixed = TRUE)
  input$config$editorial <- list(changed_conditions_included = TRUE)
  expect_error(validate_sample_data(input$data$sample, input), "genau den Kategorien")
})
