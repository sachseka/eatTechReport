# One plan supplies filenames, dimensions and module groups to both the renderer
# and the editable Quarto blocks. Filenames use validated scale codes, never IDs
# or labels supplied for modules.
main_test_figure_plan <- function(config, main_test) {
  result <- list(selection = list(), modules = list())
  if (is.null(main_test$item_levels)) return(result)
  levels <- main_test$item_levels
  short_labels <- item_module_short_labels(main_test$modules, config)
  for (scale_id in names(config$scales)) {
    if (!scale_id %in% levels$selection$scale_id) next
    label <- config$scales[[scale_id]]$label
    ids <- main_test$modules$module_id[
      main_test$modules$module_id %in% levels$modules$module_id[
        levels$modules$scale_id == scale_id]]
    modules <- main_test$modules[match(ids, main_test$modules$module_id), , drop = FALSE]
    groups <- item_module_groups(modules, config)
    for (group in unique(groups)) {
      selected <- modules[groups == group, , drop = FALSE]
      group_number <- match(group, unique(groups))
      legend_labels <- short_labels[selected$module_id]
      caption <- paste0("Verteilung der Items in den Testmodulen \u201e", label,
                        "\u201c auf die Kompetenzstufen")
      if (identical(config$report$subject, "ma")) {
        if (all(selected$module_type == "base")) {
          caption <- paste0("Verteilung der Items auf die Stufen des Kompetenzstufenmodells ",
                            "des VERA-3-Basismoduls ", config$report$main_year)
        } else {
          domain_ids <- unique(unlist(strsplit(selected$domain_ids, ", ", fixed = TRUE)))
          domain_labels <- config$domains$label[match(domain_ids, config$domains$domain_id)]
          caption <- paste0("Verteilung der Items auf die Stufen des Kompetenzstufenmodells ",
                            if (all(selected$module_type == "supplement"))
                              "in den VERA-3-Erg\u00e4nzungsmodulen " else "in den VERA-3-Testmodulen ",
                            config$report$main_year,
                            " zur Leitidee \u201e", paste(domain_labels, collapse = " / "), "\u201c")
        }
      }
      note <- if (identical(config$report$subject, "de") && nrow(selected) == 1L) "" else
        paste(paste0(legend_labels, " = ", selected$label), collapse = ", ")
      result$modules[[length(result$modules) + 1L]] <- list(
        scale_id = scale_id, label = label, module_ids = unname(selected$module_id),
        legend_labels = legend_labels, caption = caption, note = note,
        file = paste0("item-levels-modules-", scale_id, "-", group_number, ".png"),
        id = paste0("fig-item-levels-modules-", tolower(scale_id), "-", group_number),
        width = 15.5, height = item_module_legend_layout(selected)$height_cm)
    }
  }
  result
}

# Report grouping follows the original reports: German modules share a figure
# within a scale; mathematics separates the global base from each focus domain.
item_module_groups <- function(modules, config) {
  if (!identical(config$report$subject, "ma")) return(modules$scale_ids)
  ifelse(modules$module_type == "base", paste0("base:", modules$scale_ids),
         paste(modules$module_type, modules$domain_ids, sep = ":"))
}

# Display codes do not depend on free-form item or module identifiers. Callers
# pass the complete, ordered module summary so labels also remain stable in
# subset figures and in task matrices.
item_module_short_labels <- function(modules, config) {
  prefix <- gsub(", ", "/", modules$domain_ids, fixed = TRUE)
  if (identical(config$report$subject, "ma")) {
    prefix[modules$module_type == "base"] <- gsub(", ", "/",
      modules$scale_ids[modules$module_type == "base"], fixed = TRUE)
  }
  types <- c(base = "BM", supplement = "EM", domain = "")
  code <- unname(types[modules$module_type])
  label <- paste0(prefix, ifelse(nzchar(code), paste0("-", code), ""))
  for (value in unique(label)) {
    index <- which(label == value)
    if (length(index) > 1L) {
      suffix <- if (length(index) <= length(LETTERS)) LETTERS[seq_along(index)] else seq_along(index)
      label[index] <- paste0(value, "-", suffix)
    }
  }
  stats::setNames(label, modules$module_id)
}
