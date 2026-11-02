test_that("synthetic profiles use the agreed identifiers and defaults", {
  de <- example_leistung_input()
  ma <- example_leistung_input("v3_ma_mg_mm")
  expect_identical(example_report(), de)
  expect_identical(names(de$config$scales), c("DL", "DH"))
  expect_identical(de$config$domains$domain_id, c("DL", "DH"))
  expect_identical(de$config$domains$scale_id, c("DL", "DH"))
  expect_identical(names(ma$config$scales), "MO")
  expect_setequal(ma$config$domains$domain_id, c("MZ", "MG", "MM", "MR", "MD"))
  expect_true(all(ma$config$domains$scale_id == "MO"))
  expect_identical(ma$config$focus_domains, c("MG", "MM"))
  expect_equal(nrow(de$data$pvs), 720L)
  expect_equal(nrow(ma$data$pvs), 360L)
  for (input in list(de, ma)) {
    expect_true(validate_leistung_input(input))
    result <- summarise_leistung_input(input)
    expect_true(all(result$descriptives$n_persons == 24L))
    expect_true(all(result$descriptives$n_pv == 15L))
    for (scale in input$config$scales) {
      expect_identical(scale$level_labels, c("Ia", "Ib", "II", "III", "IV"))
      expect_identical(scale$pv_ids, sprintf("pv%02d", seq_len(15L)))
    }
    expect_equal(as.numeric(tapply(result$percentages$proportion,
                                   result$percentages$scale_id, sum)),
                 rep(1, length(input$config$scales)))
  }
})

test_that("example generation preserves RNG state and separates seeds and years", {
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
  on.exit({
    if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(list = ".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)
  if (had_seed) rm(list = ".Random.seed", envir = .GlobalEnv)
  de <- example_leistung_input()
  expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
  set.seed(123)
  saved_state <- get(".Random.seed", envir = .GlobalEnv)
  expect_identical(example_leistung_input(), de)
  expect_identical(get(".Random.seed", envir = .GlobalEnv), saved_state)
  other_seed <- example_leistung_input(seed = 43L)
  other_years <- example_leistung_input(main_year = 2028L, pilot_year = 2027L)
  expect_false(identical(de$data, other_seed$data))
  expect_identical(de$config, other_seed$config)
  expect_identical(de$data, other_years$data)
  expect_identical(other_years$config$report$main_year, 2028L)
  expect_identical(other_years$config$report$pilot_year, 2027L)
  expect_error(example_leistung_input(main_year = NA_real_), "main_year")
  expect_error(example_leistung_input(pilot_year = 2026.5), "pilot_year")
})

test_that("all German domains have their own scale and configurable labels", {
  input <- example_leistung_input()
  code_map <- c(DL = "DO", DH = "DS")
  input$config$domains$domain_id <- unname(code_map[input$config$domains$domain_id])
  input$config$domains$scale_id <- unname(code_map[input$config$domains$scale_id])
  input$config$domains$label <- c("Orthografie", "Sprachgebrauch")
  names(input$config$scales) <- c("DO", "DS")
  input$config$scales$DO$label <- "Orthografie"
  input$config$scales$DS$label <- "Sprachgebrauch"
  input$data$population$scale_id <- unname(code_map[input$data$population$scale_id])
  input$data$pvs$scale_id <- unname(code_map[input$data$pvs$scale_id])
  expect_true(validate_leistung_input(input))
  expect_identical(summarise_leistung_input(input)$descriptives$scale_id, c("DO", "DS"))
  input$config$scales$DO$level_labels <- paste("Stufe", seq_len(5L))
  result <- summarise_leistung_input(input)$percentages
  expect_identical(result$level_label[result$scale_id == "DO"],
                    input$config$scales$DO$level_labels)
  input$config$domains$scale_id <- rev(input$config$domains$scale_id)
  expect_error(validate_leistung_input(input), "gleichnamige Skala")
})

test_that("PV summaries use sample variance then aggregate results", {
  toy <- example_leistung_input("v3_ma_mg_mm", n_persons = 2L, n_pv = 2L)
  toy$data$pvs$value[toy$data$pvs$pv_id == "pv01"] <- c(400, 600)
  toy$data$pvs$value[toy$data$pvs$pv_id == "pv02"] <- c(600, 400)
  result <- summarise_leistung_input(toy)
  expect_equal(result$descriptives$mean, 500)
  expect_equal(result$descriptives$sd, sqrt(20000))
  expect_equal(result$percentages$proportion, c(0, 0.5, 0, 0.5, 0))
  expect_equal(stats::var(tapply(toy$data$pvs$value, toy$data$pvs$person_id, mean)), 0)
  expect_equal(result$descriptives$n_persons, 2L)
  expect_equal(result$descriptives$n_pv, 2L)

  toy$data$pvs$value[toy$data$pvs$pv_id == "pv02"] <- c(400, 800)
  result <- summarise_leistung_input(toy)
  expect_equal(result$descriptives$mean, 550)
  expect_equal(result$descriptives$sd, sqrt(50000))
  expect_gt(abs(result$descriptives$sd - mean(sqrt(result$per_pv$variance))), 1)
})

test_that("exact cuts belong to the higher level and row order is irrelevant", {
  boundaries <- example_leistung_input("v3_ma_mg_mm", n_persons = 5L, n_pv = 1L)
  boundaries$data$pvs$value <- c(399, 400, 475, 550, 625)
  expected <- summarise_leistung_input(boundaries)
  expect_equal(expected$percentages$proportion, rep(0.2, 5L))
  boundaries$data$pvs <- boundaries$data$pvs[5:1, ]
  expect_equal(summarise_leistung_input(boundaries), expected)
})

test_that("missing cells, persons, scales and entire PV sets are detected", {
  de <- example_leistung_input()
  keep <- list(seq_len(nrow(de$data$pvs)) != 1L,
               de$data$pvs$person_id != "demo_001",
               de$data$pvs$scale_id != "DH",
               de$data$pvs$pv_id != "pv15")
  for (selection in keep) {
    incomplete <- de
    incomplete$data$pvs <- incomplete$data$pvs[selection, ]
    expect_error(validate_leistung_input(incomplete), "fehlende")
  }
  for (value in c(NA_real_, NaN, Inf, -Inf)) {
    invalid <- de
    invalid$data$pvs$value[1L] <- value
    expect_error(validate_leistung_input(invalid), "keine NA-", fixed = TRUE)
  }
})

test_that("ambiguous keys, invalid references and unsupported modes fail", {
  de <- example_leistung_input()
  duplicate <- de
  duplicate$data$pvs <- rbind(duplicate$data$pvs, duplicate$data$pvs[1L, ])
  expect_error(validate_leistung_input(duplicate), "doppelte Person-Skala-PV")
  duplicate <- de
  duplicate$data$population <- rbind(duplicate$data$population, duplicate$data$population[1L, ])
  expect_error(validate_leistung_input(duplicate), "doppelte Person-Skala")
  extra <- de
  extra$data$pvs$pv_id[1L] <- "pv99"
  expect_error(validate_leistung_input(extra), "unerwartete")
  weighted <- de
  weighted$config$performance$weighted <- TRUE
  expect_error(validate_leistung_input(weighted), "ohne Gewichte")
  weighted <- de
  weighted$data$pvs$weight <- 1
  expect_error(validate_leistung_input(weighted), "erwartet genau")
  subgroups <- de
  subgroups$config$performance$subgroups <- TRUE
  expect_error(validate_leistung_input(subgroups), "ohne Untergruppen")
  bad_cuts <- de
  bad_cuts$config$scales$DL$cuts <- c(400, 475, 475, 625)
  expect_error(validate_leistung_input(bad_cuts), "streng aufsteigend")
  observed <- de
  observed$config$report$data_origin <- "observed"
  expect_error(validate_leistung_input(observed), "Demo-Cuts")
  ma <- example_leistung_input("v3_ma_mg_mm")
  ma$config$scales$MG <- ma$config$scales$MO
  ma$config$domains$scale_id[4L] <- "MG"
  expect_error(validate_leistung_input(ma), "ausschliesslich")
})
