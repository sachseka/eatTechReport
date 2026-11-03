test_that("booklet tables retain gaps and split wide designs without expanding position IDs", {
  config <- example_leistung_input("v3_ma_mg_mm")$config
  design <- example_design_data(config)
  design$booklet_slots$position[nrow(design$booklet_slots)] <- 1000000000
  summaries <- summarise_design_data(design, config)
  parts <- study_design_tables(summaries)[[1]]$parts

  expect_true(length(parts) >= 2L)
  expect_true(all(vapply(parts, ncol, integer(1)) <= 5L))
  expect_true(all(vapply(parts, nrow, integer(1)) == 2L))
  expect_true("Position 1000000000" %in% unlist(lapply(parts, names)))
  cells <- unlist(lapply(parts, function(part) as.character(unlist(part[-1]))))
  expect_true(any(grepl("Pause", cells, fixed = TRUE)))
  expect_true(any(cells == "\u2014"))
  expect_error(study_design_tables(summaries, max_positions = 0), "positive ganze Zahl")
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
