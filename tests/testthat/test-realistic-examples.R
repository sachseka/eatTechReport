test_that("larger examples are opt-in and respect explicit population sizes", {
  expect_identical(example_report(size = "small"), example_report())
  large <- example_report(size = "realistic", scope = "pilotierung_leistung")
  expect_equal(length(unique(large$data$population$person_id)), 2400L)
  expect_equal(nrow(large$data$pvs), 2400L * 15L * 2L)
  small_population <- example_report(size = "realistic", scope = "bericht", n_persons = 2L, n_pv = 1L)
  expect_true(validate_report_input(small_population))
  expect_equal(length(unique(small_population$data$population$person_id)), 2L)
  expect_gt(nrow(small_population$data$design$items), 200L)
  expect_error(example_report(size = "unknown"), "arg")
})

test_that("study-sized synthetic designs have coherent exposure and module counts", {
  for (profile in c("v3_de_lesen_zuhoeren", "v3_ma_mg_mm")) {
    input <- example_report(profile, size = "realistic", scope = "bericht")
    expect_true(validate_report_input(input))
    expect_equal(length(unique(input$data$population$person_id)), 2400L)
    design <- input$data$design
    expect_gt(nrow(design$items), 200L)
    expect_gte(nrow(design$booklets), 20L)
    expect_true(any(design$blocks$is_norming))
    expect_gt(nrow(design$booklet_slots), nrow(design$blocks))
    exposed <- example_realistic_exposures(input)
    counts <- input$data$sample$response_counts$n_valid
    expect_true(all(counts <= exposed))
    expect_true(all(exposed < 2400L))
    expect_true(all(exposed > 0L))
    expect_true(any(counts < exposed))
    expect_gte(sum(input$data$sample$classes$participated), 100L)
    expect_equal(nrow(input$data$sample$states), 7L)
    expect_gt(nrow(input$data$sample$persons), 2400L)
    expect_true(anyNA(input$data$sample$characteristics$age$values$value))
    main <- input$data$main_test
    expect_gte(nrow(main$items), 70L)
    expect_gt(nrow(main$module_items), nrow(main$items))
    current <- main$item_waves$item_id[main$item_waves$wave_id == "demo_current"]
    expect_true(all(current %in% design$items$item_id))
    expect_true(any(!main$items$item_id %in% design$items$item_id))
    summary <- summarise_report_input(input)
    expect_equal(sum(summary$main_test$item_levels$selection$n_items), nrow(main$items))
    expect_equal(sum(summary$main_test$item_levels$modules$n_items), nrow(main$module_items))
    # The example supplies assignments that agree with its artificial scores;
    # the report still consumes these assignments without deriving real ones.
    scores <- summary$main_test_results$item_statistics
    for (scale in unique(scores$scale_id)) {
      selected <- scores[scores$scale_id == scale, ]
      expected <- input$config$scales[[scale]]$level_labels[
        findInterval(selected$report_score, input$config$scales[[scale]]$cuts) + 1L]
      expect_identical(main$item_levels$level_label[match(selected$item_id, main$item_levels$item_id)], expected)
    }
  }
})

test_that("larger example generation is deterministic and preserves caller RNG state", {
  set.seed(123)
  before <- .Random.seed
  first <- example_report(size = "realistic", scope = "bericht", n_persons = 120L, seed = 19L)
  expect_identical(.Random.seed, before)
  expect_identical(first, example_report(size = "realistic", scope = "bericht", n_persons = 120L, seed = 19L))
  second <- example_report(size = "realistic", scope = "bericht", n_persons = 120L, seed = 20L)
  expect_false(identical(first$data$sample$characteristics, second$data$sample$characteristics))
  expect_false(identical(first$data$main_test_results$item_statistics, second$data$main_test_results$item_statistics))
  expect_identical(.Random.seed, before)
})
