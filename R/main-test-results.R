# Final item statistics and explicitly supplied scale transformations. These
# inputs do not determine item selection or infer competence levels from PVs.
validate_main_test_results <- function(data, config, main_test) {
  validate_main_test_data(main_test, config)
  fail <- function(message) stop(message, call. = FALSE)
  fields <- c("item_statistics", "transformations", "definitions")
  if (!is.list(data) || is.data.frame(data) || is.null(names(data)) ||
      anyDuplicated(names(data)) || !setequal(names(data), fields)) {
    fail("data$main_test_results erwartet genau: item_statistics, transformations, definitions.")
  }
  table_fields <- list(
    item_statistics = c("item_id", "p_correct", "logit"),
    transformations = c("scale_id", "target", "intercept", "slope", "source_label")
  )
  for (name in names(table_fields)) {
    table <- data[[name]]
    if (!is.data.frame(table) || !nrow(table) || anyDuplicated(names(table)) ||
        !setequal(names(table), table_fields[[name]])) {
      fail(paste0("main_test_results$", name, " muss eine nichtleere Tabelle mit genau ",
                  paste(table_fields[[name]], collapse = ", "), " sein."))
    }
    if (any(vapply(table, function(column) {
      !is.atomic(column) || !is.null(dim(column)) || length(column) != nrow(table)
    }, logical(1)))) {
      fail(paste0("main_test_results$", name, " braucht eindimensionale Spalten mit einem Wert je Zeile."))
    }
  }
  strings <- function(value, label, unique = FALSE) {
    if (!is.character(value) || anyNA(value) || any(!nzchar(trimws(value))) ||
        any(grepl("[[:cntrl:]]", value)) || (unique && anyDuplicated(value))) {
      fail(paste0(label, " braucht nichtleere Zeichenketten ohne Fehlwerte",
                  if (unique) " und ohne Duplikate" else "", "."))
    }
  }
  numbers <- function(value, label) {
    if (!is.numeric(value) || is.complex(value) || any(!is.finite(value))) {
      fail(paste0(label, " braucht endliche reelle Zahlen."))
    }
  }
  definitions <- data$definitions
  definition_fields <- c("p_correct", "logit", "population")
  if (!is.list(definitions) || is.data.frame(definitions) || is.null(names(definitions)) ||
      anyDuplicated(names(definitions)) || !setequal(names(definitions), definition_fields)) {
    fail("main_test_results$definitions erwartet genau: p_correct, logit, population.")
  }
  for (name in definition_fields) {
    value <- definitions[[name]]
    if (length(value) != 1L || !is.null(dim(value))) {
      fail(paste0("main_test_results$definitions$", name, " braucht genau einen Beschreibungstext."))
    }
    strings(value, paste0("main_test_results$definitions$", name))
  }
  item_stats <- data$item_statistics
  strings(item_stats$item_id, "main_test_results$item_statistics$item_id", unique = TRUE)
  if (any(!item_stats$item_id %in% main_test$items$item_id)) {
    fail("main_test_results$item_statistics$item_id enthaelt unbekannte IDs.")
  }
  if (!setequal(item_stats$item_id, main_test$items$item_id)) {
    fail("main_test_results$item_statistics muss jedes ausgewaehlte Item genau einmal enthalten.")
  }
  numbers(item_stats$p_correct, "main_test_results$item_statistics$p_correct")
  if (any(item_stats$p_correct < 0 | item_stats$p_correct > 1)) {
    fail("main_test_results$item_statistics$p_correct muss zwischen 0 und 1 liegen.")
  }
  numbers(item_stats$logit, "main_test_results$item_statistics$logit")
  transforms <- data$transformations
  strings(transforms$scale_id, "main_test_results$transformations$scale_id")
  strings(transforms$target, "main_test_results$transformations$target")
  strings(transforms$source_label, "main_test_results$transformations$source_label")
  item_scales <- config$domains$scale_id[match(main_test$items$domain_id, config$domains$domain_id)]
  scale_ids <- unique(config$domains$scale_id[config$domains$scale_id %in% item_scales])
  if (any(!transforms$scale_id %in% scale_ids)) {
    fail("main_test_results$transformations enthaelt unbekannte oder ungenutzte Skalen.")
  }
  if (any(!transforms$target %in% c("person", "item"))) {
    fail("main_test_results$transformations$target erlaubt nur person und item.")
  }
  keys <- paste(transforms$scale_id, transforms$target, sep = "\r")
  if (anyDuplicated(keys)) fail("main_test_results$transformations enthaelt doppelte Skala-Ziel-Zuordnungen.")
  expected <- unlist(lapply(scale_ids, function(id) paste(id, c("person", "item"), sep = "\r")),
                     use.names = FALSE)
  if (!setequal(keys, expected)) {
    fail("main_test_results$transformations braucht person und item fuer jede verwendete Skala.")
  }
  numbers(transforms$intercept, "main_test_results$transformations$intercept")
  numbers(transforms$slope, "main_test_results$transformations$slope")
  if (any(transforms$slope <= 0)) fail("main_test_results$transformations$slope muss positiv sein.")
  item_transform <- match(paste(item_scales, "item", sep = "\r"), keys)
  logits <- item_stats$logit[match(main_test$items$item_id, item_stats$item_id)]
  scores <- transforms$intercept[item_transform] + transforms$slope[item_transform] * logits
  if (any(!is.finite(scores))) fail("Die gelieferte Itemtransformation erzeugt nichtendliche Berichtswerte.")
  invisible(TRUE)
}

summarise_main_test_results <- function(data, config, main_test) {
  validate_main_test_results(data, config, main_test)
  items <- main_test$items[, c("item_id", "task_id", "task_label", "domain_id"), drop = FALSE]
  items <- items[order(match(items$domain_id, config$domains$domain_id), items$task_id,
                       items$item_id, method = "radix"), , drop = FALSE]
  items$scale_id <- config$domains$scale_id[match(items$domain_id, config$domains$domain_id)]
  stats_index <- match(items$item_id, data$item_statistics$item_id)
  items$p_correct <- data$item_statistics$p_correct[stats_index]
  items$logit <- data$item_statistics$logit[stats_index]
  scale_ids <- unique(config$domains$scale_id[config$domains$scale_id %in% items$scale_id])
  transforms <- data$transformations[, c("scale_id", "target", "intercept", "slope", "source_label"), drop = FALSE]
  transforms <- transforms[order(match(transforms$scale_id, scale_ids),
                                 match(transforms$target, c("person", "item"))), , drop = FALSE]
  item_transforms <- transforms[transforms$target == "item", , drop = FALSE]
  index <- match(items$scale_id, item_transforms$scale_id)
  items$report_score <- item_transforms$intercept[index] + item_transforms$slope[index] * items$logit
  modules <- main_test$modules[order(main_test$modules$position), , drop = FALSE]
  rows <- list()
  for (i in seq_len(nrow(modules))) {
    ids <- unique(main_test$module_items$item_id[
      main_test$module_items$module_id == modules$module_id[i]])
    selected <- items[items$item_id %in% ids, , drop = FALSE]
    for (scale_id in scale_ids) {
      values <- selected[selected$scale_id == scale_id, , drop = FALSE]
      if (!nrow(values)) next
      rows[[length(rows) + 1L]] <- data.frame(
        module_id = modules$module_id[i], label = modules$label[i], scale_id = scale_id,
        n_items = nrow(values), mean_p_correct = mean(values$p_correct),
        mean_logit = mean(values$logit), min_report_score = min(values$report_score),
        max_report_score = max(values$report_score), stringsAsFactors = FALSE)
    }
  }
  result <- list(item_statistics = items, module_statistics = do.call(rbind, rows),
                 transformations = transforms,
                 definitions = data$definitions[c("p_correct", "logit", "population")])
  for (name in c("item_statistics", "module_statistics", "transformations")) {
    rownames(result[[name]]) <- NULL
  }
  result
}

example_main_test_results <- function(config, main_test) {
  validate_main_test_data(main_test, config)
  items <- main_test$items[order(main_test$items$item_id, method = "radix"), , drop = FALSE]
  n <- nrow(items)
  # Deliberately illustrative statistics, independent of person PVs and cuts.
  logits <- seq(-1.4, 1.6, length.out = n)
  stats <- data.frame(item_id = items$item_id, p_correct = seq(0.82, 0.24, length.out = n),
                       logit = logits, stringsAsFactors = FALSE)
  item_scales <- config$domains$scale_id[match(items$domain_id, config$domains$domain_id)]
  scale_ids <- unique(config$domains$scale_id[config$domains$scale_id %in% item_scales])
  # Match the report's Rasch item-location convention at p = .625, using the
  # illustrative reference mean 0 and SD 1. Real coefficients remain supplied.
  item_intercept <- 500 + 100 * stats::qlogis(0.625)
  transforms <- do.call(rbind, lapply(scale_ids, function(id) {
    data.frame(scale_id = id, target = c("person", "item"), intercept = c(500, item_intercept),
               slope = c(100, 100),
               source_label = "Synthetisches Rechenbeispiel; keine freigegebene Transformation",
               stringsAsFactors = FALSE)
  }))
  result <- list(
    item_statistics = stats, transformations = transforms,
    definitions = list(
      p_correct = paste0("Illustrativer Anteil korrekt gel\u00f6ster Antworten je Item. Der Nenner umfasst ",
        "die nach der vorgelagerten Auswertungsregel g\u00fcltigen Antworten. Bei mehrstufigen ",
        "Items sind Erfolgskriterium und Nenner vorab festzulegen. Modulmittel sind ungewichtete Itemmittel."),
      logit = "Synthetische Itemschwierigkeiten auf der gemeinsamen Logit-Metrik der jeweiligen Skala.",
      population = "Synthetische Auswertungspopulation der Pilotierungsstudie; keine realen Itemkennwerte."
    ))
  rownames(result$transformations) <- NULL
  validate_main_test_results(result, config, main_test)
  result
}
