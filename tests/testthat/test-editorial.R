test_that("editorial values are optional and never change numerical inputs", {
  for (scope in c("pilotierung_leistung", "pilotierung", "haupttest_struktur", "bericht")) {
    input <- example_report(scope = scope, n_persons = 4L, n_pv = 1L)
    before <- summarise_report_input(input)
    input$config$editorial <- report_editorial(study_period = "Mai 2026",
      coding_training_sessions = 2L, agreement_percent = 95.5, cohen_kappa = 0.85)
    expect_true(validate_report_input(input))
    expect_identical(summarise_report_input(input), before)
  }
  expect_identical(report_editorial(study_period = NULL), list())
  expect_true(validate_report_editorial(NULL))
  expect_true(validate_report_editorial(list()))
})

test_that("editorial validation rejects malformed values instead of printing them", {
  for (bad in list(TRUE, list(1), list(typo = "text"), data.frame(study_period = "May"),
                   list(study_period = "May", study_period = "June"))) {
    expect_error(validate_report_editorial(bad), "config\\$editorial")
  }
  for (bad in list(NA, "", "a\nb", c("a", "b"), 1, matrix("May"))) {
    expect_error(report_editorial(study_period = bad), "config\\$editorial")
  }
  for (bad in list(NA, Inf, -1, 1.5, "2", 1+0i, matrix(2))) {
    expect_error(report_editorial(coding_training_sessions = bad), "config\\$editorial")
  }
  expect_error(report_editorial(double_coding_percent = 101), "Wertebereich")
  expect_error(report_editorial(cohen_kappa = -1.1), "Wertebereich")
  expect_error(report_editorial(tam_year = 0), "Wertebereich")
  expect_error(report_editorial(changed_conditions_included = 1), "TRUE oder FALSE")
  expect_error(report_editorial(changed_conditions_included = matrix(TRUE)), "Dimensionen")
  expect_error(report_editorial(ds_linking_items = 2, ds_dependent_items = 3), "ds_dependent_items")
  expect_no_error(report_editorial(cohen_kappa = -1, double_coding_percent = 100,
                                  ds_linking_items = 3L, ds_dependent_items = 2L))
})

test_that("open and supplied editorial values have no visible wrapper brackets", {
  config <- example_report()$config
  config$editorial <- report_editorial(study_period = "Mai <2026>",
    agreement_percent = 96.5, cohen_kappa = 0.876, coding_training_sessions = 2L)
  expect_identical(report_editorial_value(config, "coding_training_sessions"),
                   '[2]{custom-style="EatSimulatedValue"}')
  expect_match(report_editorial_value(config, "print_provider"),
               '[Druckdienstleister]{custom-style="EatSimulatedValue"}', fixed = TRUE)
  expect_match(report_editorial_value(config, "study_period"), "\\<2026\\>", fixed = TRUE)
  expect_match(report_editorial_value(config, "cohen_kappa"), "0,88", fixed = TRUE)
  config$report$data_origin <- "observed"
  expect_identical(report_editorial_value(config, "agreement_percent"), "96,5")
  expect_identical(report_editorial_value(config, "print_provider", "Offene Angabe"), "Offene Angabe")
  expect_identical(report_editorial_value(config, "cohen_kappa", digits = 3), "0,876")
  expect_error(report_editorial_value(config, "typo"), "Unbekanntes")
  expect_error(report_editorial_value(config, "study_period", placeholder = NA), "placeholder")
  expect_error(report_editorial_value(config, "agreement_percent", digits = 1.5), "digits")
  expect_error(report_editorial_value(config, "agreement_percent", digits = matrix(1)), "digits")
})

test_that("design prose describes supplied blocks, timing and explicit overrides", {
  input <- example_report("v3_ma_mg_ms", n_persons = 3, n_pv = 1)
  config <- input$config
  config$report$data_origin <- "observed"
  design <- summarise_report_input(input)$design
  expect_match(report_design_structure_text(design, config), "6 Bl")
  expect_match(report_design_structure_text(design, config), "ersten 5 Bl")
  expect_match(report_design_structure_text(design, config), "letzte Block")
  expect_match(report_design_timing_text(design, config), "42,5 min", fixed = TRUE)
  expect_match(report_design_timing_text(design, config), "Nach Block 5", fixed = TRUE)
  design$slots$duration_minutes[design$slots$kind == "pause"] <- 2.5
  expect_match(report_design_timing_text(design, config), "2,5 min", fixed = TRUE)
  design$booklets$n_blocks[1] <- 4
  expect_match(report_design_structure_text(design, config), "zwischen 4 und 6", fixed = TRUE)
  config$editorial <- report_editorial(booklet_structure = "Abweichender Aufbau.",
                                     pause_description = "Individuelle Pausen.")
  expect_identical(report_design_structure_text(design, config), "Abweichender Aufbau\\.")
  expect_match(report_design_timing_text(design, config), "Individuelle Pausen\\.", fixed = TRUE)
  config$editorial$include_booklet_structure <- FALSE
  expect_identical(report_design_structure_text(design, config), "")
  config$editorial <- NULL
  design$slots <- design$slots[design$slots$kind != "pause", ]
  expect_match(report_design_timing_text(design, config), "keine Pausen", fixed = TRUE)
  expect_lt(match("pilotierung_stichprobe_bearbeitungen.qmd", study_text_names()),
            match("pilotierung_stichprobe_ruecklauf.qmd", study_text_names()))
})

test_that("MS is preferred while existing MM inputs remain supported", {
  for (size in c("small", "realistic")) {
    input <- example_report("v3_ma_mg_ms", scope = "bericht", size = size, n_persons = 12, n_pv = 2)
    expect_true(validate_report_input(input))
    expect_identical(input$config$domains$domain_id, c("MZ", "MG", "MS", "MR", "MD"))
    expect_identical(input$config$focus_domains, c("MG", "MS"))
    expect_identical(unique(input$config$domains$scale_id), "MO")
  }
  legacy <- example_report("v3_ma_mg_mm")
  expect_true(validate_report_input(legacy))
  expect_true("MM" %in% legacy$config$domains$domain_id)
  legacy$config$domains$domain_id[1] <- "MS"
  expect_error(validate_report_input(legacy), "Mathematik")
})

test_that("mathematics presentation orders domains without changing supplied inputs", {
  input <- example_report("v3_ma_mg_ms", scope = "haupttest_struktur")
  expected <- summarise_report_input(input)
  input$config$domains <- input$config$domains[c(5, 4, 3, 2, 1), ]
  before <- input
  expect_identical(report_presentation_config(input$config)$domains$domain_id,
                   c("MZ", "MG", "MS", "MR", "MD"))
  expect_identical(summarise_report_input(input), expected)
  expect_identical(input, before)
})

test_that("main-test prose counts distinct tasks even across mixed supplements", {
  config <- example_report("v3_ma_mg_ms")$config
  config$report$data_origin <- "observed"
  main <- list(
    modules = data.frame(module_id = c("base", "a", "b"),
      module_type = c("base", "supplement", "supplement"),
      domain_ids = c("MZ, MG, MS, MR, MD", "MG, MS", "MG, MS")),
    tasks = data.frame(module_id = c("base", "base", "a", "a", "b", "b"),
      task_id = c("core", "core", "geometry", "structure", "geometry", "structure2"),
      domain_id = c("MZ", "MZ", "MG", "MS", "MG", "MS")))
  text <- main_test_task_count_text(main, config)
  expect_match(text, "Basismodul 1 Aufgabe", fixed = TRUE)
  expect_match(text, "Messen\u201c 1 Aufgabe", fixed = TRUE)
  expect_match(text, "Zusammenhang\u201c 2 Aufgaben", fixed = TRUE)
  expect_match(text, "VERA-3 2027", fixed = TRUE)
  config$report$data_origin <- "synthetic"
  expect_match(main_test_task_count_text(main, config), '[2027]{custom-style="EatSimulatedValue"}', fixed = TRUE)
  config$report$subject <- "de"
  expect_identical(main_test_task_count_text(main, config), "")
})
