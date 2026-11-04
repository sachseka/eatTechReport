test_that("reference mean and SD reproduce the supplied person transformation", {
  input <- example_report(scope = "bericht")
  results <- summarise_report_input(input)$main_test_results
  person <- results$transformations$target == "person"
  results$transformations$intercept[person] <- c(493.2, 602.5)
  results$transformations$slope[person] <- c(91.3, 77.1)
  results$transformations$intercept[!person] <- 999
  before <- results
  reference <- report_reference_parameters(results)
  logits <- c(-2, 0, 1.7)
  for (i in seq_len(nrow(reference))) {
    row <- results$transformations[person &
      results$transformations$scale_id == reference$scale_id[i], ]
    expect_equal(500 + 100 / reference$sd[i] * (logits - reference$mean[i]),
                 row$intercept + row$slope * logits)
  }
  expect_identical(results, before)
  expect_identical(reference$scale_id, c("DL", "DH"))
  expect_error(report_reference_parameters(results, "item"), "Personentransformation")
})

test_that("table value marking preserves escaping and static headers", {
  config <- example_leistung_input()$config
  data <- data.frame("Gruppe" = "A | [B]", "Anteil" = "12,3", check.names = FALSE)
  source <- data
  synthetic <- study_table_markdown(data, config = config)
  expect_match(synthetic, '[A &#124; \\[B\\]]{custom-style="EatSimulatedValue"}', fixed = TRUE)
  expect_match(synthetic, '[12,3]{custom-style="EatSimulatedValue"}', fixed = TRUE)
  expect_false(grepl('[Gruppe]{custom-style="EatSimulatedValue"}', synthetic, fixed = TRUE))
  expect_identical(data, source)
  header <- study_table_markdown(data, config = config, dynamic_headers = 2L)
  expect_match(header, '[Anteil]{custom-style="EatSimulatedValue"}', fixed = TRUE)
  expect_error(study_table_markdown(data, dynamic_headers = 3L), "Spaltennummern")
  selective <- study_table_markdown(data, config = config, dynamic_columns = 2L)
  expect_false(grepl('[A &#124; \\[B\\]]{custom-style="EatSimulatedValue"}', selective, fixed = TRUE))
  expect_match(selective, '[12,3]{custom-style="EatSimulatedValue"}', fixed = TRUE)
  expect_identical(study_table_markdown(data, config = config, dynamic_columns = integer()),
                   study_table_markdown(data))
  expect_error(study_table_markdown(data, dynamic_columns = NA_real_), "Spaltennummern")
  expect_error(study_table_markdown(data, dynamic_columns = 1.5), "Spaltennummern")
  config$report$data_origin <- "observed"
  expect_identical(study_table_markdown(data, config = config), study_table_markdown(data))
})

test_that("response values are marked separately from the fixed sentence", {
  config <- example_leistung_input()$config
  rows <- data.frame(domain_id = "DL", role = "pilot", n_items = 4L,
                      min = 0L, median = 1.5, max = 4L)
  sentence <- study_response_sentences(rows, config)
  expect_match(sentence, 'pro Item [0]{custom-style="EatSimulatedValue"} bis [4]', fixed = TRUE)
  expect_match(sentence, '*Median* = [1,5]{custom-style="EatSimulatedValue"}', fixed = TRUE)
  expect_false(startsWith(sentence, "[Durch das"))
})

test_that("reference tables preserve fixed math stubs and safely mark supplied values", {
  input <- example_report(scope = "bericht")
  results <- summarise_report_input(input)$main_test_results
  config <- input$config
  config$scales$DL$label <- "Lesen | [Entwurf]"
  before <- results
  synthetic <- report_reference_table_markdown(results, config)
  expect_match(synthetic, "$M_{\\mathrm{ref}}$", fixed = TRUE)
  expect_match(synthetic, "$\\mathit{SD}_{\\mathrm{ref}}$", fixed = TRUE)
  expect_false(grepl('[$M_', synthetic, fixed = TRUE))
  expect_match(synthetic, '[Lesen &#124; \\[Entwurf\\]]{custom-style="EatSimulatedValue"}', fixed = TRUE)
  expect_match(synthetic, '[0,000]{custom-style="EatSimulatedValue"}', fixed = TRUE)
  expect_match(synthetic, '[1,000]{custom-style="EatSimulatedValue"}', fixed = TRUE)
  config$report$data_origin <- "observed"
  observed <- report_reference_table_markdown(results, config)
  expect_false(grepl('EatSimulatedValue', observed, fixed = TRUE))
  expect_match(observed, "$M_{\\mathrm{ref}}$", fixed = TRUE)
  expect_match(observed, 'Lesen &#124; \\[Entwurf\\]', fixed = TRUE)
  expect_identical(results, before)
})
