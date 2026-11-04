#' Plot selected items across competence levels
#'
#' Draw item counts for a scale's complete main-test selection or compare its
#' test modules in one grouped bar chart. Counts use the supplied assignments.
#'
#' @inheritParams validate_report_input
#' @param scale_id A configured scale code, for example `"DL"` or `"MO"`.
#' @param by Plot the complete `"selection"` or a grouped `"module"` comparison.
#' @param module_ids Optional character vector selecting modules for `by =
#'   "module"`. Their configured presentation order is retained. NULL shows
#'   every module containing items of the selected scale.
#' @param font_family A single nonempty font-family name. The device-neutral
#'   default is `"sans"`; Word reports use `"Arial"`.
#' @return A ggplot object. Attribute `item_level_counts` contains the exact
#'   counts shown; `scale_id` and `by` identify the selected view.
#'   `suggested_height_cm` provides a useful height when saving at 15.5 cm width.
#'   `data_origin` records whether the supplied input is synthetic or observed.
#' @details Requires the optional `data$main_test$item_levels` table with one
#'   `item_id` and `level_label` per selected item. Assignments are supplied by
#'   the upstream analysis; the function does not infer them from person PVs,
#'   item difficulties or reporting-scale cuts. Counts include empty levels in
#'   the configured order. Reused items count once in the complete selection
#'   and once in each module containing them. Module views use a common count
#'   axis across all modules of the scale, including when only a subset is
#'   plotted. Mathematics modules use the global scale `MO`.
#'   Report figures follow the original grouping: all German modules within a
#'   scale; the mathematics base module separately from each group of
#'   supplementary modules. Short display labels and corporate colours are
#'   reused consistently across these groups. Captions and notes belong to the
#'   surrounding report rather than the plot itself.
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
  # Keep count axes and colours comparable when the caller selects a subset.
  maximum <- max(counts$n_items)
  modules <- results$main_test$modules
  all_modules <- modules
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
    plotting$series <- plotting$module_id
    colours <- item_module_colours(all_modules, input$config)
    short_labels <- item_module_short_labels(all_modules, input$config)[modules$module_id]
    legend <- item_module_legend_layout(modules)
    dodge <- ggplot2::position_dodge(width = if (nrow(modules) == 2L) 0.34 else 0.62,
                                      preserve = "single")
    bar_width <- if (nrow(modules) == 1L) 0.32 else if (nrow(modules) == 2L) 0.34 else 0.52
    show_legend <- nrow(modules) > 1L || identical(input$config$report$subject, "ma")
  } else {
    plotting$series <- factor("selection")
    colours <- c(selection = "#B40036")
    dodge <- ggplot2::position_identity()
    bar_width <- 0.32
    show_legend <- FALSE
  }
  axis_top <- if (maximum < 3) maximum + 0.2 else ceiling(maximum * 1.1)
  y_breaks <- pretty(c(0, axis_top), n = 8L)
  y_breaks <- unique(round(y_breaks[y_breaks >= 0 & y_breaks <= axis_top &
                                     abs(y_breaks - round(y_breaks)) < 1e-8]))
  if (length(y_breaks) < 2L) y_breaks <- unique(c(0, maximum))
  level_label <- n_items <- series <- NULL
  plot <- ggplot2::ggplot(plotting,
                         ggplot2::aes(x = level_label, y = n_items, fill = series, group = series)) +
    ggplot2::geom_col(width = bar_width, position = dodge, show.legend = show_legend) +
    ggplot2::scale_fill_manual(values = colours,
      breaks = if (by == "module") modules$module_id else "selection",
      labels = if (by == "module") short_labels else NULL) +
    ggplot2::scale_x_discrete(limits = scale$level_labels, drop = FALSE,
                              expand = ggplot2::expansion(add = 0.65)) +
    ggplot2::scale_y_continuous(breaks = y_breaks, limits = c(0, axis_top),
                               labels = function(x) format(x, trim = TRUE, scientific = FALSE),
                               expand = ggplot2::expansion(mult = 0)) +
    ggplot2::labs(x = if (identical(input$config$report$subject, "de")) {
      paste("Kompetenzstufen", scale$label)
    } else "Kompetenzstufe",
    y = if (identical(input$config$report$subject, "ma")) "Anzahl Items" else NULL,
    fill = NULL) +
    ggplot2::theme_minimal(base_size = 11, base_family = font_family) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(colour = "#DEDBDF", linewidth = 0.3),
      axis.line.x = ggplot2::element_line(colour = "#746978", linewidth = 0.35),
      axis.line.y = if (identical(input$config$report$subject, "ma")) {
        ggplot2::element_line(colour = "#746978", linewidth = 0.35)
      } else ggplot2::element_blank(),
      axis.text = ggplot2::element_text(size = 11, colour = "#534856"),
      axis.title = ggplot2::element_text(size = 11,
        face = if (identical(input$config$report$subject, "ma")) "bold" else "plain"),
      axis.title.x = ggplot2::element_text(margin = ggplot2::margin(t = 8)),
      axis.title.y = ggplot2::element_text(margin = ggplot2::margin(r = 8)),
      legend.position = if (show_legend) "right" else "none",
      legend.justification = "center",
      legend.text = ggplot2::element_text(size = 11, colour = "#534856"),
      legend.key.width = ggplot2::unit(12, "pt"),
      legend.key.height = ggplot2::unit(12, "pt"),
      legend.margin = ggplot2::margin(t = 0, r = 0, b = 0, l = 4),
      plot.margin = ggplot2::margin(5.5, 5.5, 5.5, 5.5),
      plot.background = ggplot2::element_rect(fill = "white", colour = "#DEDBDF", linewidth = 0.35)
    )
  if (by == "module") {
    plot <- plot + ggplot2::guides(fill = ggplot2::guide_legend(ncol = 1L, byrow = TRUE))
  }
  attr(plot, "item_level_counts") <- counts
  attr(plot, "scale_id") <- scale_id
  attr(plot, "by") <- by
  attr(plot, "suggested_height_cm") <- if (by == "selection") 8.4 else legend$height_cm
  attr(plot, "data_origin") <- input$config$report$data_origin
  plot
}

# These are the accent colours of the bundled corporate Word theme. Every
# report group starts with the same palette, including subsequent DE scales.
item_module_colours <- function(modules, config) {
  palette <- c("#B40036", "#00818D", "#EFA7C0", "#CAC5CD", "#534856", "#271A2B")
  groups <- item_module_groups(modules, config)
  colours <- character(nrow(modules))
  for (group in unique(groups)) {
    index <- which(groups == group)
    colours[index] <- rep(palette, length.out = length(index))
  }
  stats::setNames(colours, modules$module_id)
}

item_module_legend_layout <- function(modules) {
  list(height_cm = 8.4 + 0.55 * max(0L, nrow(modules) - 6L))
}
