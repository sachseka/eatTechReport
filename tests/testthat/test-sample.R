sample_input_fixture <- function(profile = "v3_de_lesen_zuhoeren") {
  input <- example_leistung_input(profile, n_persons = 6L, n_pv = 2L)
  domains <- input$config$domains$domain_id
  input$data$design <- list(items = data.frame(
    item_id = paste0("item_", seq_len(length(domains) * 3L)),
    task_id = paste0("task_", rep(seq_along(domains), each = 3L)),
    domain_id = rep(domains, each = 3L),
    role = rep(c("pilot", "pilot", "anchor"), times = length(domains)),
    stringsAsFactors = FALSE
  ))
  input$data$sample <- example_sample_data(input)
  input
}

test_that("sample totals distinguish participants, analysis persons and scales", {
  input <- sample_input_fixture()
  sample <- input$data$sample
  expect_true(validate_sample_data(sample, input))
  result <- summarise_sample_data(sample, input)
  expect_equal(result$totals$n_participants, 8L)
  expect_equal(result$totals$n_analysis_persons, 6L)
  expect_equal(result$totals$n_not_analysed, 2L)
  expect_equal(result$by_scale$n_analysis_persons, c(6L, 6L))
  expect_equal(sum(result$by_state$n_analysis_persons), 6L)
  expect_equal(sum(result$by_state$participant_percent), 100)
  expect_equal(sum(result$by_state$analysis_percent), 100)
  expect_identical(input$data$population, example_leistung_input(n_persons = 6L, n_pv = 2L)$data$population)
})

test_that("requested and participating classes are independent counts", {
  input <- sample_input_fixture()
  result <- summarise_sample_data(input$data$sample, input)
  extra <- result$by_state[result$by_state$state_id == "demo_b", ]
  absent <- result$by_state[result$by_state$state_id == "demo_c", ]
  expect_equal(extra$n_requested_classes, 0)
  expect_equal(extra$n_participating_classes, 1)
  expect_gt(extra$n_participants, 0)
  expect_equal(absent$n_requested_classes, 1)
  expect_equal(absent$n_participating_classes, 0)
  expect_equal(absent$n_participants, 0)
  expect_equal(absent$participant_percent, 0)
})

test_that("item response summaries count each inventory item and include zero", {
  input <- sample_input_fixture()
  input$data$sample$response_counts$n_valid <- c(0, 4, 3, 2, 6, 5)
  result <- summarise_sample_data(input$data$sample, input)
  pilot <- result$responses_overall[result$responses_overall$role == "pilot", ]
  anchor <- result$responses_overall[result$responses_overall$role == "anchor", ]
  expect_equal(pilot$n_items, 4)
  expect_equal(pilot$min, 0)
  expect_equal(pilot$median, 3)
  expect_equal(pilot$max, 6)
  expect_equal(anchor$n_items, 2)
  expect_equal(anchor$median, 4)
  expect_true(all(result$response_counts$n_eligible == 6))

  # Changing a block mapping cannot duplicate the item distribution.
  input$data$design$block_items <- data.frame(block_id = c("a", "b"), item_id = rep("item_1", 2))
  expect_equal(summarise_sample_data(input$data$sample, input)$responses_overall,
               result$responses_overall)
})

test_that("mathematics response limits use its one global analysis scale", {
  input <- sample_input_fixture("v3_ma_mg_mm")
  result <- summarise_sample_data(input$data$sample, input)
  expect_identical(result$by_scale$scale_id, "MO")
  expect_equal(result$totals$n_analysis_persons, 6)
  expect_true(all(result$response_counts$n_eligible == 6))
  expect_setequal(result$responses_by_domain$domain_id, input$config$domains$domain_id)
})

test_that("sample keys, membership and response coverage are checked", {
  input <- sample_input_fixture()
  original <- input$data$sample
  sample <- original
  sample$persons <- rbind(sample$persons, sample$persons[1, ])
  expect_error(validate_sample_data(sample, input), "persons\\$person_id")
  sample <- original
  sample$persons <- sample$persons[-1, ]
  expect_error(validate_sample_data(sample, input), "Auswertungspopulation")
  sample <- original
  sample$persons$class_id[1] <- "unknown"
  expect_error(validate_sample_data(sample, input), "persons\\$class_id")
  sample <- original
  sample$persons$class_id[1] <- "demo_class_04"
  expect_error(validate_sample_data(sample, input), "teilnehmenden Klassen")
  sample <- original
  sample$classes$requested[1] <- NA
  expect_error(validate_sample_data(sample, input), "requested")
  sample <- original
  sample$classes$state_id[1] <- "unknown"
  expect_error(validate_sample_data(sample, input), "states deklarierte")
  sample <- original
  sample$response_counts <- rbind(sample$response_counts, sample$response_counts[1, ])
  expect_error(validate_sample_data(sample, input), "response_counts\\$item_id")
  sample <- original
  sample$response_counts <- sample$response_counts[-1, ]
  expect_error(validate_sample_data(sample, input), "jedes Inventaritem")
  sample <- original
  sample$response_counts$n_valid[1] <- 7
  expect_error(validate_sample_data(sample, input), "Nvalid")
  sample$response_counts$n_valid[1] <- 0.5
  expect_error(validate_sample_data(sample, input), "ganze Zahlen")
  sample$response_counts$n_valid[1] <- NA_real_
  expect_error(validate_sample_data(sample, input), "ganze Zahlen")
  sample <- original
  sample$response_definition <- ""
  expect_error(validate_sample_data(sample, input), "response_definition")
  sample <- original
  sample$persons$person_id <- matrix(rep(sample$persons$person_id, 2L), ncol = 2L)
  expect_error(validate_sample_data(sample, input), "Matrixspalten")
  sample <- original
  sample$characteristics$gender$values$value <- matrix(
    rep(sample$characteristics$gender$values$value, 2L), ncol = 2L)
  expect_error(validate_sample_data(sample, input), "Matrixspalten")
})

test_that("sample examples are deterministic and preserve RNG state", {
  input <- sample_input_fixture()
  set.seed(19)
  before <- .Random.seed
  sample <- example_sample_data(input)
  expect_identical(.Random.seed, before)
  expect_identical(sample, input$data$sample)
})

test_that("composition uses analysis persons once and includes missing categories", {
  input <- sample_input_fixture()
  sample <- input$data$sample
  sample$characteristics$gender$values$value <- c("männlich", "weiblich", "divers", NA,
                                                 "männlich", "weiblich", "divers", "divers")
  sample$characteristics$age$values$value <- c(8, 9, NA, 8, 9, 10, 40, 50)
  result <- summarise_sample_data(sample, input)$characteristics
  expect_identical(result$gender$category, c("männlich", "weiblich", "divers", "keine Angabe"))
  expect_equal(result$gender$n, c(2, 2, 1, 1))
  expect_equal(result$gender$denominator, rep(6L, 4L))
  expect_equal(result$gender$percent, 100 * c(2, 2, 1, 1) / 6)
  expect_equal(result$age$n, 6)
  expect_equal(result$age$n_valid, 5)
  expect_equal(result$age$n_missing, 1)
  expect_equal(result$age$mean, mean(c(8, 9, 8, 9, 10)))
  expect_equal(result$age$sd, stats::sd(c(8, 9, 8, 9, 10)))
})

test_that("family language by state has explicit denominators and empty-state percentages", {
  input <- sample_input_fixture()
  result <- summarise_sample_data(input$data$sample, input)$characteristics
  by_state <- result$family_language_by_state
  absent <- by_state[by_state$state_id == "demo_c", ]
  expect_true(all(absent$n == 0))
  expect_true(all(absent$denominator == 0))
  expect_true(all(is.na(absent$percent)))
  present <- by_state[by_state$state_id != "demo_c", ]
  expect_equal(as.numeric(tapply(present$percent, present$state_id, sum)), c(100, 100))
  expect_equal(sum(by_state$n), 6)
})

test_that("not collected is distinct from collected with all missing answers", {
  input <- sample_input_fixture()
  sample <- input$data$sample
  sample$characteristics["changed_conditions"] <- list(NULL)
  sample$characteristics$gender$values$value[] <- NA_character_
  sample$characteristics$age$values$value[] <- NA_real_
  result <- summarise_sample_data(sample, input)$characteristics
  expect_null(result$changed_conditions)
  expect_equal(result$gender$percent, c(0, 0, 0, 100))
  expect_equal(result$age$n_valid, 0)
  expect_true(is.na(result$age$mean))
  expect_true(is.na(result$age$sd))
  sample$characteristics$age$values$value[1] <- 8.5
  one_age <- summarise_sample_data(sample, input)$characteristics$age
  expect_equal(one_age$mean, 8.5)
  expect_true(is.na(one_age$sd))
  sample$characteristics["family_language"] <- list(NULL)
  result <- summarise_sample_data(sample, input)$characteristics
  expect_null(result$family_language)
  expect_null(result$family_language_by_state)
})

test_that("background codes and person coverage are explicit", {
  input <- sample_input_fixture()
  sample <- input$data$sample
  sample$characteristics$gender$values$value[1] <- "1"
  expect_error(validate_sample_data(sample, input), "nicht automatisch")
  sample <- input$data$sample
  sample$characteristics$gender$categories <- c("weiblich", "männlich", "divers")
  expect_error(validate_sample_data(sample, input), "Geschlechtskategorien")
  sample <- input$data$sample
  sample$characteristics$family_language$values <- sample$characteristics$family_language$values[-1, ]
  expect_error(validate_sample_data(sample, input), "alle Auswertungspersonen")
  sample <- input$data$sample
  sample$characteristics$age$values$value[1] <- Inf
  expect_error(validate_sample_data(sample, input), "Altersangaben")
  sample <- input$data$sample
  sample$characteristics$family_language$categories <- c("Deutsch", "keine Angabe")
  expect_error(validate_sample_data(sample, input), "wird aus NA erzeugt")
  sample <- input$data$sample
  sample$characteristics$age <- NULL
  expect_error(validate_sample_data(sample, input), "characteristics braucht")
})
