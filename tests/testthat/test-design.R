test_that("synthetic designs cover configured domains without extra scales", {
  for (profile in c("v3_de_lesen_zuhoeren", "v3_ma_mg_mm")) {
    config <- example_leistung_input(profile)$config
    design <- example_design_data(config)
    expect_true(validate_design_data(design, config))
    expect_identical(example_design_data(config), design)
    expect_setequal(design$items$domain_id, config$domains$domain_id)
    summary <- summarise_design_data(design, config)
    expect_equal(summary$totals$n_items, nrow(design$items))
    expect_equal(summary$totals$n_tasks, length(unique(design$items$task_id)))
    expect_true(all(summary$booklets$total_minutes >= summary$booklets$test_minutes))
    expect_true(length(unique(table(design$booklet_slots$booklet_id))) > 1L)
    if (config$report$subject == "ma") {
      expect_identical(names(config$scales), "MO")
      expect_equal(sum(design$blocks$module == "base"), 5L)
      expect_equal(sum(design$blocks$module == "supplement"), 2L)
    }
  }
})

test_that("reused items and tasks are counted once in total inventories", {
  config <- example_leistung_input("v3_ma_mg_mm")$config
  design <- example_design_data(config)
  summary <- summarise_design_data(design, config)
  expect_equal(summary$totals$n_items, 24L)
  expect_equal(summary$totals$n_tasks, 12L)
  expect_equal(summary$booklets$n_items, c(22L, 22L))
  expect_equal(summary$booklets$test_minutes, c(40, 45))
  expect_equal(summary$booklets$total_minutes, c(45, 52))
  expect_true(sum(summary$blocks$n_items) > summary$totals$n_items)
  expect_equal(sum(summary$pool$n_items), summary$totals$n_items)
  # A task can have items in different roles or domains. Grouped task counts
  # must not be added to calculate the total number of distinct tasks.
  design$items$task_id[c(1, 3, 5)] <- "shared_task"
  summary <- summarise_design_data(design, config)
  expect_equal(summary$totals$n_tasks, length(unique(design$items$task_id)))
  expect_gt(sum(summary$pool$n_tasks), summary$totals$n_tasks)
})

test_that("pause and instruction times are excluded from test minutes", {
  config <- example_leistung_input()$config
  design <- example_design_data(config)
  result <- summarise_design_data(design, config)
  expect_equal(result$booklets$test_minutes, c(27, 21, 27, 21))
  expect_equal(result$booklets$total_minutes, c(34, 21, 34, 21))
  expect_true(all(is.na(result$slots$module[result$slots$kind != "block"])))
  expect_true(all(result$slots$n_items[result$slots$kind != "block"] == 0))
  expect_setequal(result$slots$block_label[result$slots$kind != "block"],
                  c("Pause", "Instruktion"))
  # Slots need not be contiguous; an empty column can represent a gap.
  design$booklet_slots$position <- design$booklet_slots$position * 2L
  expect_true(validate_design_data(design, config))
  expect_equal(summarise_design_data(design, config)$booklets, result$booklets)
})

test_that("the same block may recur without multiplying distinct booklet items", {
  config <- example_leistung_input()$config
  design <- example_design_data(config)
  original <- summarise_design_data(design, config)
  extra <- design$booklet_slots[design$booklet_slots$booklet_id == "DL_H1" &
                                design$booklet_slots$kind == "block", ][1L, ]
  extra$position <- 5L
  design$booklet_slots <- rbind(design$booklet_slots, extra)
  result <- summarise_design_data(design, config)
  expect_equal(result$booklets$n_items, original$booklets$n_items)
  expect_equal(result$booklets$n_tasks, original$booklets$n_tasks)
  expect_equal(result$booklets$n_blocks[1], original$booklets$n_blocks[1] + 1L)
  expect_equal(result$booklets$test_minutes[1],
               original$booklets$test_minutes[1] + extra$duration_minutes)
})

test_that("design table keys and foreign keys protect inventory counts", {
  config <- example_leistung_input()$config
  original <- example_design_data(config)
  bad <- original
  bad$items <- rbind(bad$items, bad$items[1, ])
  expect_error(validate_design_data(bad, config), "item_id.*Duplikate")
  bad <- original
  bad$block_items <- rbind(bad$block_items, bad$block_items[1, ])
  expect_error(validate_design_data(bad, config), "doppelte Block-Item")
  bad <- original
  bad$booklet_slots <- rbind(bad$booklet_slots, bad$booklet_slots[1, ])
  expect_error(validate_design_data(bad, config), "doppelte Heft-Positionen")
  for (field in c("item_id", "block_id")) {
    bad <- original
    bad$block_items[[field]][1] <- "unknown"
    expect_error(validate_design_data(bad, config), "unbekannte IDs")
  }
  bad <- original
  bad$items$domain_id[1] <- "XX"
  expect_error(validate_design_data(bad, config), "domain_id.*unbekannte")
  bad <- original
  bad$booklets$design_id[1] <- "unknown"
  expect_error(validate_design_data(bad, config), "design_id.*unbekannte")
  bad <- original
  bad$booklet_slots$booklet_id[1] <- "unknown"
  expect_error(validate_design_data(bad, config), "booklet_id.*unbekannte")
  bad <- original
  bad$booklet_slots$block_id[bad$booklet_slots$kind == "block"][1] <- "unknown"
  expect_error(validate_design_data(bad, config), "block_id.*unbekannte")
})

test_that("undefined values and unrepresented inventory entries are rejected", {
  config <- example_leistung_input()$config
  original <- example_design_data(config)
  for (value in list(NA_real_, Inf, -1, 0.5)) {
    bad <- original
    bad$booklet_slots$position[1] <- value
    expect_error(validate_design_data(bad, config), "position.*positive ganze")
  }
  for (value in list(NA_real_, Inf, -1)) {
    bad <- original
    bad$booklet_slots$duration_minutes[1] <- value
    expect_error(validate_design_data(bad, config), "duration_minutes")
  }
  bad <- original
  bad$booklet_slots$block_id[1] <- "DL_B1"
  expect_error(validate_design_data(bad, config), "Pausen und Instruktionen")
  bad <- original
  bad$booklet_slots$block_id[2] <- NA_character_
  expect_error(validate_design_data(bad, config), "block_id.*Fehlwerte")
  bad <- original
  bad$block_items <- bad$block_items[bad$block_items$item_id != "DL_P01", ]
  expect_error(validate_design_data(bad, config), "Jede definierte ID")
  bad <- original
  bad$booklet_slots <- bad$booklet_slots[bad$booklet_slots$booklet_id != "DL_H2", ]
  expect_error(validate_design_data(bad, config), "Jede definierte ID")
  bad <- original
  bad$items$role[1] <- "new"
  expect_error(validate_design_data(bad, config), "role erlaubt nur")
  bad <- original
  bad$blocks$module[1] <- "global"
  expect_error(validate_design_data(bad, config), "module erlaubt nur")
  bad <- original
  bad$design_rules$assignment_unit[1] <- "inferred"
  expect_error(validate_design_data(bad, config), "assignment_unit erlaubt nur")
  bad <- original
  bad$items$source_year <- 2026L
  expect_error(validate_design_data(bad, config), "items muss.*genau")
  expect_error(validate_design_data(original[-1], config), "data\\$design erwartet genau")
})

test_that("German examples also support orthography and language usage", {
  config <- example_leistung_input()$config
  config$domains <- data.frame(domain_id = c("DO", "DS"),
                               label = c("Orthografie", "Sprachgebrauch"),
                               scale_id = c("DO", "DS"))
  design <- example_design_data(config)
  expect_setequal(design$items$domain_id, c("DO", "DS"))
  expect_true(validate_design_data(design, config))
  expect_equal(nrow(summarise_design_data(design, config)$pool), 4L)
})

test_that("matrix columns cannot multiply durations or expand identifiers", {
  config <- example_leistung_input()$config
  original <- example_design_data(config)
  bad <- original
  bad$booklet_slots$duration_minutes <- matrix(1, nrow(bad$booklet_slots), 2L)
  expect_error(validate_design_data(bad, config), "eindimensionale Spalten")
  bad <- original
  bad$items$item_id <- matrix(rep(bad$items$item_id, 2L), ncol = 2L)
  expect_error(validate_design_data(bad, config), "eindimensionale Spalten")
})
