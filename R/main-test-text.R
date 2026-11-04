# Presentation tables for the selected main-test inventory. The summary owns
# all counts; these helpers only add labels and format displayed values.
main_test_tables <- function(main_test, config) {
  pool <- main_test$pool
  domain_labels <- config$domains$label[match(pool$domain_id,
                                              config$domains$domain_id)]
  pool_table <- data.frame(
    "Kompetenzbereich" = paste0(domain_labels, " (", pool$domain_id, ")"),
    "Skala" = pool$scale_id,
    "Aufgaben" = pool$n_tasks,
    "Items" = pool$n_items,
    check.names = FALSE
  )

  waves <- main_test$waves
  wave_table <- data.frame(
    "Pilotierung" = waves$label,
    "Jahr" = study_number(waves$pilot_year, 0L),
    "Aufgaben" = waves$n_tasks,
    "Items" = waves$n_items,
    check.names = FALSE
  )

  modules <- main_test$modules
  module_types <- c(base = "Basismodul", supplement = "Erg\u00e4nzungsmodul",
                    domain = "Kompetenzbereichsmodul")
  type_labels <- unname(module_types[modules$module_type])
  module_labels <- vapply(seq_len(nrow(modules)), function(i) {
    if (grepl(tolower(type_labels[i]), tolower(modules$label[i]), fixed = TRUE)) {
      modules$label[i]
    } else paste0(modules$label[i], " (", type_labels[i], ")")
  }, character(1))
  module_table <- data.frame(
    "Modul" = module_labels,
    "Bereiche" = modules$domain_ids,
    "Aufgaben" = modules$n_tasks,
    "Items" = modules$n_items,
    "Bearbeitungszeit" = paste0(study_number(modules$duration_minutes), "\u00a0min"),
    check.names = FALSE
  )

  task_lists <- lapply(seq_len(nrow(modules)), function(i) {
    tasks <- main_test$tasks[main_test$tasks$module_id == modules$module_id[i], ,
                             drop = FALSE]
    table <- data.frame(
      "Position" = tasks$task_position,
      "Aufgabe" = tasks$task_label,
      "Bereich" = tasks$domain_id,
      "Items" = tasks$n_items,
      check.names = FALSE
    )
    list(module_id = modules$module_id[i], label = modules$label[i], table = table)
  })
  list(pool = pool_table, waves = wave_table, modules = module_table,
       task_lists = task_lists)
}

# Historical task overview: positions are rows, modules are columns. A task may
# appear at a different position in each module; never align these rows by ID.
main_test_task_matrices <- function(main_test, max_modules = 5L, config = NULL) {
  if (length(max_modules) != 1L || !is.numeric(max_modules) ||
      !is.finite(max_modules) || max_modules < 1 || max_modules != floor(max_modules)) {
    stop("max_modules muss eine positive ganze Zahl sein.", call. = FALSE)
  }
  modules <- main_test$modules
  grouping <- if (!is.null(config) && config$report$subject == "de") modules$domain_ids else
    rep("all", nrow(modules))
  groups <- unlist(lapply(unique(grouping), function(group) {
    index <- which(grouping == group)
    split(index, ceiling(seq_along(index) / max_modules))
  }), recursive = FALSE)
  lapply(groups, function(index) {
    selected <- modules[index, , drop = FALSE]
    tasks <- main_test$tasks[main_test$tasks$module_id %in% selected$module_id, , drop = FALSE]
    positions <- sort(unique(tasks$task_position))
    table <- data.frame(Position = positions, check.names = FALSE)
    labels <- if (is.null(config)) selected$label else
      unname(item_module_short_labels(modules, config)[selected$module_id])
    repeated <- duplicated(labels) | duplicated(labels, fromLast = TRUE)
    labels[repeated] <- paste0(labels[repeated], " (", selected$module_id[repeated], ")")
    # Word can otherwise split this compound in the middle of its final syllable.
    labels <- gsub("Erg\u00e4nzungsmodul", "Erg\u00e4nzungs\u00admodul", labels, fixed = TRUE)
    for (i in seq_len(nrow(selected))) {
      rows <- tasks[tasks$module_id == selected$module_id[i], , drop = FALSE]
      values <- rows$task_label[match(positions, rows$task_position)]
      values[is.na(values)] <- "\u2014"
      table[[i + 1L]] <- values
    }
    names(table) <- c("Position", labels)
    list(module_ids = selected$module_id, module_types = selected$module_type,
         labels = selected$label, table = table)
  })
}

main_test_task_matrix_markdown <- function(part) {
  n <- ncol(part$table) - 1L
  text <- study_table_markdown(part$table, c("r", rep("l", n)),
                               widths = c(10, rep(90 / n, n)))
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  header <- which(startsWith(lines, "|"))[1L]
  types <- ifelse(part$module_types == "base", "EatTaskBase", "EatTaskSupplement")
  labels <- report_markdown_text(names(part$table))
  labels[1L] <- "Nr."
  cells <- c(paste0("[", labels[1L], "]{custom-style=\"EatTaskMatrix\"}"),
    paste0("[", labels[-1L], "]{custom-style=\"", types, "\"}"))
  lines[header] <- paste0("|", paste(cells, collapse = "|"), "|")
  paste(c(lines, "", ""), collapse = "\n")
}
