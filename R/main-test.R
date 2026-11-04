# Final main-test selections are independent of the current pilot inventory.
# Module positions order the presentation; they do not compose a test booklet.
validate_main_test_data <- function(data, config) {
  fail <- function(message) stop(message, call. = FALSE)
  tables <- list(
    items = c("item_id", "task_id", "task_label", "domain_id"),
    modules = c("module_id", "label", "module_type", "position", "duration_minutes"),
    module_items = c("module_id", "item_id", "task_position", "item_position"),
    waves = c("wave_id", "pilot_year", "label"),
    item_waves = c("item_id", "wave_id")
  )
  if (is.list(data) && "item_levels" %in% names(data)) {
    tables$item_levels <- c("item_id", "level_label")
  }
  if (!is.list(data) || is.data.frame(data) || is.null(names(data)) ||
      anyDuplicated(names(data)) || !setequal(names(data), names(tables))) {
    fail(paste0("data$main_test erwartet genau: ", paste(names(tables), collapse = ", "), "."))
  }
  for (name in names(tables)) {
    value <- data[[name]]
    if (!is.data.frame(value) || !nrow(value) || anyDuplicated(names(value)) ||
        !setequal(names(value), tables[[name]])) {
      fail(paste0("data$main_test$", name, " muss eine nichtleere Tabelle mit genau ",
                  paste(tables[[name]], collapse = ", "), " sein."))
    }
    if (any(vapply(value, function(column) {
      !is.atomic(column) || !is.null(dim(column)) || length(column) != nrow(value)
    }, logical(1)))) {
      fail(paste0("data$main_test$", name, " braucht eindimensionale Spalten mit einem Wert je Zeile."))
    }
  }
  strings <- function(value, label, unique = FALSE) {
    if (!is.character(value) || !is.null(dim(value)) || anyNA(value) ||
        any(!nzchar(trimws(value))) || any(grepl("[[:cntrl:]]", value)) ||
        (unique && anyDuplicated(value))) {
      fail(paste0(label, " braucht nichtleere Zeichenketten ohne Fehlwerte",
                  if (unique) " und ohne Duplikate" else "", "."))
    }
  }
  integers <- function(value, label) {
    if (!is.numeric(value) || !is.null(dim(value)) || any(!is.finite(value)) ||
        any(value < 1 | value > .Machine$integer.max | value != floor(value))) {
      fail(paste0(label, " braucht positive ganze Zahlen."))
    }
  }
  foreign <- function(value, allowed, label) {
    if (any(!value %in% allowed)) fail(paste0(label, " enthaelt unbekannte IDs."))
  }
  complete <- function(actual, expected, label) {
    if (!setequal(actual, expected)) fail(paste0(label, ": Jede definierte ID muss verwendet werden."))
  }
  key <- function(...) paste(..., sep = "\r")
  if (!is.list(config) || !is.data.frame(config$domains) ||
      !all(c("domain_id", "scale_id") %in% names(config$domains)) ||
      !nrow(config$domains)) {
    fail("config$domains muss domain_id und scale_id enthalten.")
  }
  strings(config$domains$domain_id, "config$domains$domain_id", TRUE)
  strings(config$domains$scale_id, "config$domains$scale_id")
  if (!is.list(config$report) || length(config$report$main_year) != 1L) {
    fail("config$report$main_year muss eine Jahreszahl enthalten.")
  }
  integers(config$report$main_year, "config$report$main_year")

  items <- data$items
  modules <- data$modules
  links <- data$module_items
  waves <- data$waves
  sources <- data$item_waves
  strings(items$item_id, "main_test$items$item_id", TRUE)
  strings(items$task_id, "main_test$items$task_id")
  strings(items$task_label, "main_test$items$task_label")
  strings(items$domain_id, "main_test$items$domain_id")
  foreign(items$domain_id, config$domains$domain_id, "main_test$items$domain_id")
  for (task in unique(items$task_id)) {
    selected <- items[items$task_id == task, , drop = FALSE]
    if (length(unique(selected$task_label)) != 1L ||
        length(unique(selected$domain_id)) != 1L) {
      fail("main_test$items braucht je task_id dieselbe task_label und domain_id.")
    }
  }
  strings(modules$module_id, "main_test$modules$module_id", TRUE)
  strings(modules$label, "main_test$modules$label")
  strings(modules$module_type, "main_test$modules$module_type")
  if (any(!modules$module_type %in% c("base", "supplement", "domain"))) {
    fail("main_test$modules$module_type erlaubt nur: base, supplement, domain.")
  }
  integers(modules$position, "main_test$modules$position")
  if (anyDuplicated(modules$position)) fail("main_test$modules enthaelt doppelte Positionen.")
  if (!is.numeric(modules$duration_minutes) || any(!is.finite(modules$duration_minutes)) ||
      any(modules$duration_minutes < 0)) {
    fail("main_test$modules$duration_minutes braucht endliche, nichtnegative Minuten.")
  }
  strings(links$module_id, "main_test$module_items$module_id")
  strings(links$item_id, "main_test$module_items$item_id")
  if (anyDuplicated(key(links$module_id, links$item_id))) {
    fail("main_test$module_items enthaelt doppelte Modul-Item-Zuordnungen.")
  }
  foreign(links$module_id, modules$module_id, "main_test$module_items$module_id")
  foreign(links$item_id, items$item_id, "main_test$module_items$item_id")
  complete(links$module_id, modules$module_id, "main_test$module_items$module_id")
  complete(links$item_id, items$item_id, "main_test$module_items$item_id")
  integers(links$task_position, "main_test$module_items$task_position")
  integers(links$item_position, "main_test$module_items$item_position")
  task_ids <- items$task_id[match(links$item_id, items$item_id)]
  task_positions <- unique(data.frame(module_id = links$module_id,
                                      task_id = task_ids,
                                      task_position = links$task_position))
  if (anyDuplicated(key(task_positions$module_id, task_positions$task_id))) {
    fail("main_test$module_items braucht je Modul und Aufgabe genau eine task_position.")
  }
  if (anyDuplicated(key(task_positions$module_id, task_positions$task_position))) {
    fail("main_test$module_items enthaelt doppelte Aufgabenpositionen innerhalb eines Moduls.")
  }
  if (anyDuplicated(key(links$module_id, task_ids, links$item_position))) {
    fail("main_test$module_items enthaelt doppelte Itempositionen innerhalb einer Modul-Aufgabe.")
  }
  strings(waves$wave_id, "main_test$waves$wave_id", TRUE)
  strings(waves$label, "main_test$waves$label")
  integers(waves$pilot_year, "main_test$waves$pilot_year")
  if (any(waves$pilot_year > config$report$main_year)) {
    fail("main_test$waves$pilot_year darf nicht nach main_year liegen.")
  }
  strings(sources$item_id, "main_test$item_waves$item_id")
  strings(sources$wave_id, "main_test$item_waves$wave_id")
  if (anyDuplicated(key(sources$item_id, sources$wave_id))) {
    fail("main_test$item_waves enthaelt doppelte Item-Wellen-Zuordnungen.")
  }
  foreign(sources$item_id, items$item_id, "main_test$item_waves$item_id")
  foreign(sources$wave_id, waves$wave_id, "main_test$item_waves$wave_id")
  complete(sources$item_id, items$item_id, "main_test$item_waves$item_id")
  complete(sources$wave_id, waves$wave_id, "main_test$item_waves$wave_id")
  if ("item_levels" %in% names(data)) {
    levels <- data$item_levels
    strings(levels$item_id, "main_test$item_levels$item_id", TRUE)
    strings(levels$level_label, "main_test$item_levels$level_label")
    foreign(levels$item_id, items$item_id, "main_test$item_levels$item_id")
    complete(levels$item_id, items$item_id, "main_test$item_levels$item_id")
    item_scales <- config$domains$scale_id[match(items$domain_id, config$domains$domain_id)]
    assigned <- levels$level_label[match(items$item_id, levels$item_id)]
    for (scale_id in unique(item_scales)) {
      labels <- config$scales[[scale_id]]$level_labels
      if (is.null(labels) || !length(labels)) {
        fail(paste0("config$scales$", scale_id, "$level_labels muss Stufenbezeichnungen enthalten."))
      }
      strings(labels, paste0("config$scales$", scale_id, "$level_labels"), TRUE)
      if (any(!assigned[item_scales == scale_id] %in% labels)) {
        fail(paste0("main_test$item_levels$level_label enthaelt unbekannte Stufen fuer Skala ",
                    scale_id, "."))
      }
    }
  }
  invisible(TRUE)
}

summarise_main_test_data <- function(data, config) {
  validate_main_test_data(data, config)
  items <- data$items
  links <- data$module_items
  modules <- data$modules[order(data$modules$position),
                          c("module_id", "label", "module_type", "position", "duration_minutes"),
                          drop = FALSE]
  waves <- data$waves[order(data$waves$pilot_year, data$waves$wave_id, method = "radix"),
                     c("wave_id", "pilot_year", "label"), drop = FALSE]
  pool <- do.call(rbind, lapply(seq_len(nrow(config$domains)), function(i) {
    selected <- items[items$domain_id == config$domains$domain_id[i], , drop = FALSE]
    data.frame(domain_id = config$domains$domain_id[i],
               scale_id = config$domains$scale_id[i],
               n_tasks = length(unique(selected$task_id)), n_items = nrow(selected),
               stringsAsFactors = FALSE)
  }))
  module_rows <- task_rows <- vector("list", nrow(modules))
  for (i in seq_len(nrow(modules))) {
    assigned <- links[links$module_id == modules$module_id[i], , drop = FALSE]
    assigned <- assigned[order(assigned$task_position, assigned$item_position), , drop = FALSE]
    selected <- items[match(assigned$item_id, items$item_id), , drop = FALSE]
    domains <- config$domains[config$domains$domain_id %in% selected$domain_id, , drop = FALSE]
    module_rows[[i]] <- data.frame(
      modules[i, , drop = FALSE], n_tasks = length(unique(selected$task_id)),
      n_items = nrow(selected), domain_ids = paste(domains$domain_id, collapse = ", "),
      scale_ids = paste(unique(domains$scale_id), collapse = ", "), stringsAsFactors = FALSE)
    task_rows[[i]] <- do.call(rbind, lapply(unique(selected$task_id), function(task) {
      index <- which(selected$task_id == task)
      first <- index[1L]
      data.frame(module_id = modules$module_id[i], task_position = assigned$task_position[first],
                 task_id = task, task_label = selected$task_label[first],
                 domain_id = selected$domain_id[first], n_items = length(index),
                 stringsAsFactors = FALSE)
    }))
  }
  wave_rows <- lapply(seq_len(nrow(waves)), function(i) {
    ids <- data$item_waves$item_id[data$item_waves$wave_id == waves$wave_id[i]]
    selected <- items[items$item_id %in% ids, , drop = FALSE]
    data.frame(waves[i, , drop = FALSE], n_tasks = length(unique(selected$task_id)),
               n_items = nrow(selected), stringsAsFactors = FALSE)
  })
  result <- list(
    totals = data.frame(n_tasks = length(unique(items$task_id)), n_items = nrow(items),
                        n_modules = nrow(modules)),
    pool = pool, modules = do.call(rbind, module_rows),
    tasks = do.call(rbind, task_rows), waves = do.call(rbind, wave_rows),
    source_overlap = anyDuplicated(data$item_waves$item_id) > 0L
  )
  for (name in names(result)[vapply(result, is.data.frame, logical(1))]) {
    rownames(result[[name]]) <- NULL
  }
  if ("item_levels" %in% names(data)) {
    # These are supplied item assignments, not levels inferred from person cuts.
    item_scales <- config$domains$scale_id[match(items$domain_id, config$domains$domain_id)]
    assigned <- data$item_levels$level_label[match(items$item_id, data$item_levels$item_id)]
    scale_ids <- unique(config$domains$scale_id[config$domains$scale_id %in% item_scales])
    selection_levels <- module_levels <- list()
    for (scale_id in scale_ids) {
      labels <- config$scales[[scale_id]]$level_labels
      selected <- which(item_scales == scale_id)
      selection_levels[[scale_id]] <- data.frame(
        scale_id = scale_id, level_label = labels,
        n_items = tabulate(match(assigned[selected], labels), nbins = length(labels)),
        stringsAsFactors = FALSE)
      for (module_id in modules$module_id) {
        ids <- links$item_id[links$module_id == module_id]
        module_selected <- selected[items$item_id[selected] %in% ids]
        if (!length(module_selected)) next
        module_levels[[length(module_levels) + 1L]] <- data.frame(
          scale_id = scale_id, module_id = module_id, level_label = labels,
          n_items = tabulate(match(assigned[module_selected], labels), nbins = length(labels)),
          stringsAsFactors = FALSE)
      }
    }
    result$item_levels <- list(selection = do.call(rbind, selection_levels),
                              modules = do.call(rbind, module_levels))
    result$item_levels <- lapply(result$item_levels, function(table) {
      rownames(table) <- NULL
      table
    })
  }
  result
}

# Illustrative selections only: no real module counts, times or selection rules.
example_main_test_data <- function(config) {
  items <- do.call(rbind, lapply(config$domains$domain_id, function(domain) {
    data.frame(item_id = paste0(domain, c("_P01", "_P02", "_ALT01", "_ALT02")),
               task_id = paste0(domain, c("_T1", "_T1", "_T_ALT", "_T_ALT")),
               task_label = paste("Beispielaufgabe", domain, c("A", "A", "B", "B")),
               domain_id = domain, stringsAsFactors = FALSE)
  }))
  modules <- links <- list()
  add_module <- function(id, label, type, minutes, item_ids) {
    modules[[length(modules) + 1L]] <<- data.frame(
      module_id = id, label = label, module_type = type,
      position = length(modules) + 1L, duration_minutes = minutes, stringsAsFactors = FALSE)
    tasks <- items$task_id[match(item_ids, items$item_id)]
    links[[length(links) + 1L]] <<- data.frame(
      module_id = id, item_id = item_ids, task_position = match(tasks, unique(tasks)),
      item_position = as.integer(stats::ave(seq_along(tasks), tasks, FUN = seq_along)),
      stringsAsFactors = FALSE)
  }
  if (identical(config$report$subject, "de")) {
    for (domain in config$domains$domain_id) {
      add_module(paste0(domain, "_BM"), paste(domain, "Basismodul"), "base", 18,
                  paste0(domain, c("_P01", "_P02", "_ALT01")))
      add_module(paste0(domain, "_EM"), paste(domain, "Erg\u00e4nzungsmodul"), "supplement", 9,
                  paste0(domain, c("_P02", "_ALT02")))
    }
  } else if (identical(config$report$subject, "ma")) {
    base_items <- unlist(lapply(config$domains$domain_id, function(domain) {
      suffixes <- c("_P01", "_P02", "_ALT01")
      if (!domain %in% config$focus_domains) suffixes <- c(suffixes, "_ALT02")
      paste0(domain, suffixes)
    }), use.names = FALSE)
    add_module("MA_BM", "Mathematik Basismodul", "base", 35, base_items)
    for (domain in config$focus_domains) {
      add_module(paste0(domain, "_EM"), paste(domain, "Erg\u00e4nzungsmodul"), "supplement", 15,
                  paste0(domain, c("_P02", "_ALT02")))
    }
  } else stop("Haupttestbeispiel unterstuetzt subject = 'de' oder 'ma'.", call. = FALSE)
  waves <- data.frame(wave_id = c("demo_current", "demo_previous"),
                      pilot_year = c(config$report$pilot_year, max(1, config$report$pilot_year - 2)),
                      label = c("Beispielwelle aktuell", "Beispielwelle fr\u00fcher"),
                      stringsAsFactors = FALSE)
  item_waves <- data.frame(item_id = items$item_id,
                           wave_id = ifelse(grepl("_ALT", items$item_id, fixed = TRUE),
                                            "demo_previous", "demo_current"),
                           stringsAsFactors = FALSE)
  item_waves <- rbind(item_waves, data.frame(item_id = items$item_id[2L], wave_id = "demo_previous"))
  result <- list(items = items, modules = do.call(rbind, modules),
                 module_items = do.call(rbind, links), waves = waves, item_waves = item_waves)
  # Illustrative assignments cycle through the configured labels. They are not
  # derived from real item parameters or the illustrative population cuts.
  item_scales <- config$domains$scale_id[match(items$domain_id, config$domains$domain_id)]
  assigned <- character(nrow(items))
  for (scale_id in unique(item_scales)) {
    index <- which(item_scales == scale_id)
    labels <- config$scales[[scale_id]]$level_labels
    if (is.null(labels) || !length(labels)) {
      stop("Das Haupttestbeispiel braucht level_labels fuer Skala ", scale_id, ".", call. = FALSE)
    }
    assigned[index] <- rep(labels, length.out = length(index))
  }
  result$item_levels <- data.frame(item_id = items$item_id, level_label = assigned,
                                   stringsAsFactors = FALSE)
  result <- lapply(result, function(table) { rownames(table) <- NULL; table })
  validate_main_test_data(result, config)
  result
}
