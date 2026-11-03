test_that("main-test examples support domains, global mathematics and older items", {
  for (profile in c("v3_de_lesen_zuhoeren", "v3_ma_mg_mm")) {
    config <- example_leistung_input(profile)$config
    data <- example_main_test_data(config)
    expect_true(validate_main_test_data(data, config))
    expect_identical(example_main_test_data(config), data)
    expect_true(any(!data$items$item_id %in% example_design_data(config)$items$item_id))
    result <- summarise_main_test_data(data, config)
    expect_true(result$source_overlap)
    expect_gt(sum(result$waves$n_items), result$totals$n_items)
    expect_gt(sum(result$modules$n_items), result$totals$n_items)
    expect_equal(sum(result$pool$n_items), result$totals$n_items)
    expect_identical(result$pool$domain_id, config$domains$domain_id)
    if (config$report$subject == "ma") {
      expect_equal(result$totals, data.frame(n_tasks = 10L, n_items = 20L, n_modules = 3L))
      expect_true(all(result$modules$scale_ids == "MO"))
      expect_equal(result$modules$n_items, c(18L, 2L, 2L))
    } else {
      expect_equal(result$totals, data.frame(n_tasks = 4L, n_items = 8L, n_modules = 4L))
      expect_equal(result$modules$n_items, c(3L, 2L, 3L, 2L))
      expect_equal(result$tasks$n_items[result$tasks$task_id == "DL_T1"], c(2L, 1L))
    }
  }
})

test_that("summary ordering is independent of input row order", {
  config <- example_leistung_input()$config
  data <- example_main_test_data(config)
  expected <- summarise_main_test_data(data, config)
  shuffled <- lapply(data, function(table) table[rev(seq_len(nrow(table))), , drop = FALSE])
  expect_identical(summarise_main_test_data(shuffled, config), expected)
  shuffled <- lapply(shuffled, function(table) table[, rev(names(table)), drop = FALSE])
  expect_identical(summarise_main_test_data(shuffled, config), expected)
  data$modules$position <- data$modules$position * 3L
  data$module_items$task_position <- data$module_items$task_position * 2L
  data$module_items$item_position <- data$module_items$item_position * 4L
  data$modules$duration_minutes[1L] <- 0
  expect_true(validate_main_test_data(data, config))
  expect_equal(summarise_main_test_data(data, config)$totals, expected$totals)
  # The same source year may describe several explicitly distinct waves.
  data$waves$pilot_year <- config$report$main_year
  expect_true(validate_main_test_data(data, config))
})

test_that("a wave need not equal the separately described pilot year", {
  config <- example_leistung_input(pilot_year = 2024L, main_year = 2027L)$config
  data <- example_main_test_data(config)
  data$waves$pilot_year[1] <- 2026L
  expect_true(validate_main_test_data(data, config))
  data$waves$pilot_year[1] <- 2028L
  expect_error(validate_main_test_data(data, config), "nach main_year")
  for (value in list(NA_real_, Inf, -1, 0, 2026.5)) {
    data$waves$pilot_year[1] <- value
    expect_error(validate_main_test_data(data, config), "pilot_year.*positive ganze")
  }
})

test_that("unused configured domains have zero counts and domain modules are permitted", {
  config <- example_leistung_input()$config
  data <- example_main_test_data(config)
  config$domains <- rbind(config$domains, data.frame(domain_id = "DO", label = "Orthografie", scale_id = "DO"))
  data$modules$module_type <- "domain"
  result <- summarise_main_test_data(data, config)
  expect_equal(result$pool$n_items, c(4L, 4L, 0L))
  expect_equal(result$pool$n_tasks, c(2L, 2L, 0L))
  data$item_waves <- data$item_waves[!duplicated(data$item_waves$item_id), ]
  expect_false(summarise_main_test_data(data, config)$source_overlap)
  config$domains <- data.frame(domain_id = c("DO", "DS"), label = c("Orthografie", "Sprachgebrauch"),
                               scale_id = c("DO", "DS"))
  expect_setequal(example_main_test_data(config)$items$domain_id, c("DO", "DS"))
})

test_that("main-test references and unique IDs reject inconsistent selections", {
  config <- example_leistung_input()$config
  original <- example_main_test_data(config)
  for (table in c("items", "modules", "waves")) {
    bad <- original
    bad[[table]] <- rbind(bad[[table]], bad[[table]][1L, ])
    expect_error(validate_main_test_data(bad, config), "Duplikate")
  }
  for (table in c("module_items", "item_waves")) {
    bad <- original
    bad[[table]] <- rbind(bad[[table]], bad[[table]][1L, ])
    expect_error(validate_main_test_data(bad, config), "doppelte.*Zuordnungen")
  }
  for (reference in list(c("items", "domain_id"), c("module_items", "module_id"),
                         c("module_items", "item_id"), c("item_waves", "item_id"),
                         c("item_waves", "wave_id"))) {
    bad <- original
    bad[[reference[1]]][[reference[2]]][1L] <- "unknown"
    expect_error(validate_main_test_data(bad, config), "unbekannte IDs")
  }
  for (reference in list(c("module_items", "module_id"), c("module_items", "item_id"),
                         c("item_waves", "item_id"), c("item_waves", "wave_id"))) {
    bad <- original
    table <- reference[1]
    column <- reference[2]
    bad[[table]] <- bad[[table]][bad[[table]][[column]] != bad[[table]][[column]][1L], ]
    expect_error(validate_main_test_data(bad, config), "Jede definierte ID")
  }
})

test_that("task labels, domains and module positions preserve task identity", {
  config <- example_leistung_input()$config
  original <- example_main_test_data(config)
  bad <- original
  bad$items$task_label[1] <- "Different task"
  expect_error(validate_main_test_data(bad, config), "dieselbe task_label und domain_id")
  bad <- original
  bad$items$domain_id[1] <- "DH"
  expect_error(validate_main_test_data(bad, config), "dieselbe task_label und domain_id")
  bad <- original
  bad$module_items$task_position[2] <- 3L
  expect_error(validate_main_test_data(bad, config), "genau eine task_position")
  bad <- original
  bad$module_items$task_position[3] <- 1L
  expect_error(validate_main_test_data(bad, config), "doppelte Aufgabenpositionen")
  bad <- original
  bad$module_items$item_position[2] <- 1L
  expect_error(validate_main_test_data(bad, config), "doppelte Itempositionen")
  bad <- original
  bad$modules$position[2] <- 1L
  expect_error(validate_main_test_data(bad, config), "doppelte Positionen")
})

test_that("main-test schema rejects missing, malformed and unsupported input", {
  config <- example_leistung_input()$config
  original <- example_main_test_data(config)
  expect_error(validate_main_test_data(original[-1], config), "main_test erwartet genau")
  bad <- original
  bad$items$extra <- 1L
  expect_error(validate_main_test_data(bad, config), "items muss.*genau")
  bad <- original
  bad$waves <- bad$waves[FALSE, ]
  expect_error(validate_main_test_data(bad, config), "nichtleere Tabelle")
  bad <- original
  bad$modules$duration_minutes <- matrix(1, nrow(bad$modules), 2L)
  expect_error(validate_main_test_data(bad, config), "eindimensionale Spalten")
  for (value in list(NA_real_, Inf, -1, 0, 0.5)) {
    for (reference in list(c("modules", "position"), c("module_items", "task_position"),
                           c("module_items", "item_position"))) {
      bad <- original
      bad[[reference[1]]][[reference[2]]][1] <- value
      expect_error(validate_main_test_data(bad, config), "positive ganze Zahlen")
    }
  }
  for (value in list(NA_real_, Inf, -1)) {
    bad <- original
    bad$modules$duration_minutes[1] <- value
    expect_error(validate_main_test_data(bad, config), "nichtnegative Minuten")
  }
  for (value in list(NA_character_, "", " ", "bad\nlabel")) {
    bad <- original
    bad$modules$label[1] <- value
    expect_error(validate_main_test_data(bad, config), "Zeichenketten ohne Fehlwerte")
  }
  bad <- original
  bad$modules$module_type[1] <- "inferred"
  expect_error(validate_main_test_data(bad, config), "module_type erlaubt nur")
  bad_config <- config
  bad_config$domains <- NULL
  expect_error(validate_main_test_data(original, bad_config), "config.*domains")
  bad_config <- config
  bad_config$report$main_year <- NULL
  expect_error(validate_main_test_data(original, bad_config), "main_year.*Jahreszahl")
  bad_config <- config
  bad_config$report$main_year <- "2027"
  expect_error(validate_main_test_data(original, bad_config), "main_year.*positive ganze")
})
