test_that("booklet matrices number blocks and align pauses independently of instructions", {
  config <- example_leistung_input("v3_ma_mg_mm")$config
  design <- example_design_data(config)
  design$booklet_slots$position[nrow(design$booklet_slots)] <- 1000000000
  summaries <- summarise_design_data(design, config)
  parts <- study_design_tables(summaries)[[1]]$parts

  expect_length(parts, 1L)
  expect_identical(names(parts[[1L]]), c("Testheft", paste("Block", 1:5), "", "Block 6"))
  expect_true(all(vapply(parts, nrow, integer(1)) == 2L))
  expect_false(any(grepl("Position|1000000000", unlist(lapply(parts, names)))))
  expect_identical(attr(parts[[1L]], "design_pause_columns"), 7L)
  expect_identical(parts[[1L]][[7L]], c("", ""))
  cells <- unlist(lapply(parts, function(part) as.character(unlist(part[-1]))))
  expect_false(any(grepl("Pause|Instruktion|min", cells)))
  split <- study_design_tables(summaries, max_positions = 4L)[[1L]]$parts
  expect_length(split, 2L)
  expect_identical(names(split[[2L]]), c("Testheft", "Block 5", "", "Block 6"))
  expect_error(study_design_tables(summaries, max_positions = 0), "positive ganze Zahl")
})

test_that("norming flags follow cells while repeated blocks retain their input order", {
  config <- example_leistung_input()$config
  design <- example_design_data(config)
  part <- study_design_tables(summarise_design_data(design, config))[[1L]]
  table <- part$parts[[1L]]
  expect_identical(table$`Block 1`, c("DL 1", "DL 2"))
  expect_identical(table$`Block 2`, c("DL 2", "DL Anker"))
  expect_equal(which(attr(table, "design_norming"), arr.ind = TRUE),
               matrix(c(2L, 4L), nrow = 1L, dimnames = list(NULL, c("row", "col"))))
  design$booklet_slots$position <- design$booklet_slots$position * 100L
  expect_identical(study_design_tables(summarise_design_data(design, config))[[1L]]$parts,
                   part$parts)
  text <- study_design_table_markdown(table)
  expect_match(text, '[DL Anker]{custom-style="EatDesignNorming"}', fixed = TRUE)
  expect_match(text, 'custom-style="EatDesignPauseHeader"', fixed = TRUE)
  expect_false(grepl("27|21|\\bmin\\b", text))
})

test_that("multiple pause boundaries remain explicit and short booklets retain empty blocks", {
  config <- example_leistung_input()$config
  design <- example_design_data(config)
  extra <- design$booklet_slots[design$booklet_slots$kind == "pause", ][1L, ]
  extra$position <- 5L
  extra$duration_minutes <- 3
  design$booklet_slots <- rbind(design$booklet_slots, extra)
  # A further repeated block lengthens one booklet without adding inventory.
  extra <- design$booklet_slots[design$booklet_slots$kind == "block", ][1L, ]
  extra$position <- 6L
  design$booklet_slots <- rbind(design$booklet_slots, extra)
  part <- study_design_tables(summarise_design_data(design, config))[[1L]]
  expect_identical(names(part$parts[[1L]]),
                   c("Testheft", "Block 1", "", "Block 2", "", "Block 3"))
  expect_identical(part$parts[[1L]]$`Block 3`, c("DL 1", "\u2014"))
  expect_identical(attr(part$parts[[1L]], "design_pause_columns"), c(3L, 5L))
  expect_match(study_design_timing_note(part), "Pause: DL_H1 8\u00a0min, DL_H2 0\u00a0min", fixed = TRUE)
})

test_that("time notes preserve unequal durations and source labels cannot supply styles", {
  config <- example_leistung_input("v3_ma_mg_mm")$config
  design <- example_design_data(config)
  design$booklet_slots$duration_minutes[nrow(design$booklet_slots)] <- 12.5
  part <- study_design_tables(summarise_design_data(design, config))[[1L]]
  note <- study_design_timing_note(part)
  expect_match(note, "Basismodule: 25\u00a0min", fixed = TRUE)
  expect_match(note, "MA_H2 12,5\u00a0min", fixed = TRUE)
  expect_match(note, "Pause: 5\u00a0min", fixed = TRUE)
  expect_match(note, "Instruktion: MA_H1 0\u00a0min, MA_H2 2\u00a0min", fixed = TRUE)
  table <- part$parts[[1L]]
  table[[2L]][1L] <- "A | [B] {custom-style=evil}"
  text <- study_design_table_markdown(table)
  expect_match(text, "A &#124; \\[B\\] \\{custom\\-style=evil\\}", fixed = TRUE)
  attr(table, "design_norming") <- TRUE
  expect_error(study_design_table_markdown(table), "je Tabellenzelle")
  attr(table, "design_norming") <- NULL
  attr(table, "design_pause_columns") <- 0L
  expect_error(study_design_table_markdown(table), "Pausenspalten")
})

test_that("design QMD supplies a caption and cross-reference for every compact matrix", {
  previous_options <- options(device = function(...) grDevices::pdf(file = NULL, ...))
  on.exit(options(previous_options), add = TRUE)
  for (profile in c("v3_de_lesen_zuhoeren", "v3_ma_mg_mm")) {
    input <- example_report(profile)
    config <- input$config
    value <- function(x, markdown = FALSE) report_text_value(x, config, markdown)
    results <- summarise_report_input(input)
    source <- readLines(system.file("quarto", "texts", "pilotierung_design_hefte.qmd",
                                    package = "eatTechReport"), encoding = "UTF-8")
    source <- sub("#\\| label: ", paste0("#| label: ", profile, "_"), source)
    text <- paste(knitr::knit_child(text = source, envir = environment(),
                                   options = list(echo = FALSE), quiet = TRUE), collapse = "\n")
    for (i in seq_len(nrow(results$design$design_rules))) {
      id <- paste0("tbl-pilotierung-design-", i, "-1")
      expect_match(text, paste0("@", id, " zeigt"), fixed = TRUE)
      expect_match(text, paste0("{#", id, "}"), fixed = TRUE)
    }
    expect_match(text, '*Anmerkungen.*', fixed = TRUE)
    expect_match(text, 'custom-style="TableNote"', fixed = TRUE)
    expect_false(grepl("Gesamtdauer \\(min\\)|Vorgesehener Einsatz|Position [0-9]", text))
  }
})

test_that("source labels cannot introduce Markdown formatting or extra table cells", {
  data <- data.frame("Land | Code" = c("A | B", "`r stop('x')`", "**Fett**"),
                     "Anteil (%)" = c("0,0", "\u2014", "100,0"), check.names = FALSE)
  rendered <- study_table_markdown(data)
  expect_match(rendered, "Land &#124; Code", fixed = TRUE)
  expect_match(rendered, "A &#124; B", fixed = TRUE)
  expect_match(rendered, "\\`r stop\\('x'\\)\\`", fixed = TRUE)
  expect_match(rendered, "\\*\\*Fett\\*\\*", fixed = TRUE)
})

test_that("country language tables distinguish zero shares from absent denominators", {
  data <- data.frame(
    state_id = rep(c("A", "B"), each = 4),
    state_label = rep(c("Land A", "Land B"), each = 4),
    category = rep(c("deutsch", "mehrsprachig", "andere", "keine Angabe"), 2),
    denominator = rep(c(10L, 0L), each = 4),
    percent = c(80, 0, 10, 10, rep(NA_real_, 4)),
    stringsAsFactors = FALSE
  )
  parts <- study_language_tables(data)
  expect_length(parts, 2L)
  expect_equal(parts[[1]]$`Personen (N)`, c(10L, 0L))
  expect_identical(parts[[1]]$`mehrsprachig (%)`, c("0,0", "\u2014"))
  expect_identical(parts[[2]]$`keine Angabe (%)`, c("10,0", "\u2014"))
  expect_length(study_language_tables(NULL), 0L)
  expect_error(study_language_tables(data, NA_real_), "positive ganze Zahl")
})

test_that("response descriptions keep zero counts and show an italic median with equals sign", {
  config <- example_leistung_input()$config
  config$report$data_origin <- "observed"
  config$domains$label[1] <- "Lesen [Probe]"
  rows <- data.frame(domain_id = "DL", role = "pilot", n_items = 4L,
                      min = 0L, median = 1.5, max = 4L)
  sentence <- study_response_sentences(rows, config)
  expect_match(sentence, "Lesen \\[Probe\\]", fixed = TRUE)
  expect_match(sentence, "pro Item 0 bis 4 Antworten", fixed = TRUE)
  expect_match(sentence, "*Median* = 1,5", fixed = TRUE)
  expect_match(sentence, "pilotierten Aufgaben", fixed = TRUE)
  expect_length(study_response_sentences(rows[FALSE, ], config), 0L)
})
