#' Plot selected items across competence levels
#'
#' Draw item counts for a scale's complete main-test selection or separately
#' for its test modules. Counts use the supplied item-to-level assignments.
#'
#' @inheritParams validate_report_input
#' @param scale_id A configured scale code, for example `"DL"` or `"MO"`.
#' @param by Plot the complete `"selection"` or individual `"module"` panels.
#' @param module_ids Optional character vector selecting modules for `by =
#'   "module"`. Their configured presentation order is retained. NULL shows
#'   every module containing items of the selected scale.
#' @param font_family A single nonempty font-family name. The device-neutral
#'   default is `"sans"`; Word reports use `"Arial"`.
#' @return A ggplot object. Attribute `item_level_counts` contains the exact
#'   counts shown; `scale_id` and `by` identify the selected view.
#'   `suggested_height_cm` provides a useful height when saving at 15.5 cm width.
#' @details Requires the optional `data$main_test$item_levels` table with one
#'   `item_id` and `level_label` per selected item. Assignments are supplied by
#'   the upstream analysis; the function does not infer them from person PVs,
#'   item difficulties or reporting-scale cuts. Counts include empty levels in
#'   the configured order. Reused items count once in the complete selection
#'   and once in each module containing them. Module views use a common count
#'   axis across all modules of the scale, including when only a subset is
#'   plotted. Mathematics modules use the global scale `MO`.
#' @examples
#' demo <- example_report(scope = "haupttest_struktur")
#' plot_item_levels(demo, "DL")
#' plot_item_levels(demo, "DL", by = "module")
#' @export
plot_item_levels <- function(input, scale_id, by = c("selection", "module"),
                              module_ids = NULL, font_family = "sans") {
  by <- match.arg(by)
  if (!is.character(font_family) || length(font_family) != 1L ||
      is.na(font_family) || !nzchar(trimws(font_family))) {
    stop("font_family muss eine nichtleere Zeichenkette sein.", call. = FALSE)
  }
  results <- summarise_report_input(input)
  if (is.null(results$main_test$item_levels)) {
    stop("Fuer Itemgrafiken wird data$main_test$item_levels mit gelieferten Stufenzuordnungen benoetigt.",
         call. = FALSE)
  }
  if (!is.character(scale_id) || length(scale_id) != 1L || is.na(scale_id) ||
      !scale_id %in% names(input$config$scales)) {
    stop("scale_id muss eine konfigurierte Skalenkennung sein.", call. = FALSE)
  }
  if (by == "selection" && !is.null(module_ids)) {
    stop("module_ids ist nur fuer by = 'module' vorgesehen.", call. = FALSE)
  }
  scale <- input$config$scales[[scale_id]]
  if (by == "selection") {
    counts <- results$main_test$item_levels$selection
  } else {
    counts <- results$main_test$item_levels$modules
  }
  counts <- counts[counts$scale_id == scale_id, , drop = FALSE]
  if (!nrow(counts) || sum(counts$n_items) == 0) {
    stop("Fuer diese Skala sind keine Haupttestitems ausgewaehlt.", call. = FALSE)
  }
  # Keep count axes comparable when a long module list spans several figures.
  maximum <- max(counts$n_items)
  modules <- results$main_test$modules
  if (by == "module") {
    available <- modules$module_id[modules$module_id %in% counts$module_id]
    if (!is.null(module_ids) &&
        (!is.character(module_ids) || !length(module_ids) || anyNA(module_ids) ||
         anyDuplicated(module_ids) || any(!module_ids %in% available))) {
      stop("module_ids muss unterschiedliche Module mit Items der gewaehlten Skala enthalten.",
           call. = FALSE)
    }
    selected <- if (is.null(module_ids)) available else available[available %in% module_ids]
    counts <- counts[counts$module_id %in% selected, , drop = FALSE]
    modules <- modules[match(selected, modules$module_id), , drop = FALSE]
    counts <- counts[order(match(counts$module_id, selected),
                            match(counts$level_label, scale$level_labels)), , drop = FALSE]
  } else {
    counts <- counts[order(match(counts$level_label, scale$level_labels)), , drop = FALSE]
  }
  rownames(counts) <- NULL
  plotting <- counts
  plotting$level_label <- factor(plotting$level_label, levels = scale$level_labels)
  if (by == "module") {
    plotting$module_id <- factor(plotting$module_id, levels = modules$module_id)
    plotting$module_type <- modules$module_type[match(plotting$module_id, modules$module_id)]
  } else plotting$module_type <- "base"
  y_breaks <- pretty(c(0, maximum), n = 4L)
  y_breaks <- y_breaks[y_breaks >= 0 & y_breaks <= maximum & y_breaks == floor(y_breaks)]
  if (length(y_breaks) < 2L) y_breaks <- unique(c(0, maximum))
  caption <- if (by == "module") {
    "Wiederverwendete Items werden in jedem zugeordneten Modul gez\u00e4hlt."
  } else "Jedes ausgew\u00e4hlte Item wird einmal gez\u00e4hlt."
  if (identical(input$config$report$data_origin, "synthetic")) {
    caption <- paste0("Synthetisches Beispiel; illustrative Stufenzuordnungen.\n", caption)
  }
  level_label <- n_items <- module_type <- module_id <- NULL
  plot <- ggplot2::ggplot(plotting, ggplot2::aes(x = level_label, y = n_items, fill = module_type)) +
    ggplot2::geom_col(width = 0.58, show.legend = FALSE) +
    ggplot2::geom_text(ggplot2::aes(label = n_items), vjust = -0.45,
                       family = font_family, size = 11 * 25.4 / 72.27,
                       colour = "#271A2B", show.legend = FALSE) +
    ggplot2::scale_fill_manual(values = c(base = "#B40036", supplement = "#008698", domain = "#6A5165")) +
    ggplot2::scale_x_discrete(limits = scale$level_labels, drop = FALSE,
                              expand = ggplot2::expansion(add = 0.65)) +
    ggplot2::scale_y_continuous(breaks = y_breaks, limits = c(0, maximum + max(0.35, maximum * 0.23)),
                               labels = function(x) format(x, trim = TRUE, scientific = FALSE),
                               expand = ggplot2::expansion(mult = 0)) +
    ggplot2::labs(title = scale$label,
                   subtitle = if (by == "selection") paste0("Ausgew\u00e4hlte Items: ", sum(counts$n_items)) else "Items je Testmodul",
                   x = "Kompetenzstufe", y = "Anzahl der Items", caption = caption) +
    ggplot2::theme_minimal(base_size = 11, base_family = font_family) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(colour = "#E7E3E5", linewidth = 0.3),
      axis.line.x = ggplot2::element_line(colour = "#82767B", linewidth = 0.35),
      axis.text = ggplot2::element_text(size = 11, colour = "#40383C"),
      axis.title = ggplot2::element_text(size = 11),
      axis.title.x = ggplot2::element_text(margin = ggplot2::margin(t = 8)),
      axis.title.y = ggplot2::element_text(margin = ggplot2::margin(r = 8)),
      plot.title = ggplot2::element_text(face = "bold", colour = "#271A2B"),
      plot.subtitle = ggplot2::element_text(margin = ggplot2::margin(b = 10), size = 11),
      plot.caption = ggplot2::element_text(hjust = 0, colour = "#625A5E", size = 11,
                                            margin = ggplot2::margin(t = 10)),
      strip.text = ggplot2::element_text(hjust = 0, face = "bold", size = 11,
                                          colour = "#271A2B", margin = ggplot2::margin(7, 7, 7, 7)),
      strip.background = ggplot2::element_rect(fill = "#F5F1F2", colour = NA),
      panel.spacing.y = ggplot2::unit(9, "pt"),
      plot.margin = ggplot2::margin(5.5, 5.5, 5.5, 5.5),
      plot.background = ggplot2::element_rect(fill = "white", colour = NA)
    )
  if (by == "module") {
    module_labels <- stats::setNames(vapply(modules$label, function(label) {
      paste(strwrap(label, width = 58L), collapse = "\n")
    }, character(1)), modules$module_id)
    # Separate x axes repeat the level labels in every panel; explicit limits
    # keep their order and positions identical. The count axis stays shared.
    plot <- plot + ggplot2::facet_wrap(~module_id, ncol = 1L, scales = "free_x",
                                       labeller = ggplot2::as_labeller(module_labels))
  }
  attr(plot, "item_level_counts") <- counts
  attr(plot, "scale_id") <- scale_id
  attr(plot, "by") <- by
  attr(plot, "suggested_height_cm") <- if (by == "selection") 8.2 else 4.2 + 4 * nrow(modules)
  plot
}
