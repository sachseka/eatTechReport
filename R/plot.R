#' Plot the performance distribution and competence-level shares
#'
#' Draw an averaged PV density with competence-level cuts and empirical
#' percentages. The returned plot can be printed, saved, or used in a report.
#'
#' @inheritParams validate_leistung_input
#' @param scale_id A configured scale code, for example `"DL"` or `"MO"`.
#' @param bandwidth A positive smoothing bandwidth in reporting-scale units.
#'   If `NULL`, use the mean of [stats::bw.nrd0()] calculated separately for
#'   each PV. The same bandwidth is then used for all PVs of this scale.
#' @param font_family A single, nonempty font-family name. The device-neutral
#'   default is `"sans"`; Word reports use `"Arial"` explicitly.
#' @return A ggplot object. Attributes `population_percentages` and
#'   `descriptives` contain the unrounded results for this scale. Attributes
#'   `density_data` and `density_bandwidth` record the plotted density and its
#'   smoothing bandwidth.
#' @details A Gaussian kernel density is calculated for each PV on one common
#'   grid, then the densities are averaged. The automatic bandwidth depends on
#'   the person count within each PV, not on the artificial sample size obtained
#'   by stacking PVs. No within-person averaging is performed. With complete,
#'   equally sized PV sets and a common bandwidth, averaging these densities is
#'   equivalent to a pooled density with that bandwidth, up to grid rounding.
#'
#'   Percentages come from [summarise_leistung_input()], not from integrating
#'   the smoothed curve. Values on a cut belong to the higher level. Every level
#'   is labelled, including empty levels and both tails. Changing the bandwidth
#'   changes the curve only. The default bandwidth is an initial display rule,
#'   not a new assessment or scaling procedure.
#' @examples
#' demo <- example_report()
#' plot_performance(demo, "DL")
#' @export
plot_performance <- function(input, scale_id, bandwidth = NULL, font_family = "sans") {
  if (!is.character(font_family) || length(font_family) != 1L ||
      is.na(font_family) || !nzchar(trimws(font_family))) {
    stop("font_family muss eine nichtleere Zeichenkette sein.", call. = FALSE)
  }
  results <- summarise_leistung_input(input)
  if (!is.character(scale_id) || length(scale_id) != 1L || is.na(scale_id) ||
      !scale_id %in% names(input$config$scales)) {
    stop("scale_id muss eine konfigurierte Skalenkennung sein.", call. = FALSE)
  }
  scale <- input$config$scales[[scale_id]]
  pvs <- input$data$pvs[input$data$pvs$scale_id == scale_id, , drop = FALSE]
  by_pv <- lapply(scale$pv_ids, function(pv_id) pvs$value[pvs$pv_id == pv_id])
  if (is.null(bandwidth)) {
    bandwidth <- mean(vapply(by_pv, stats::bw.nrd0, numeric(1)))
  }
  if (!is.numeric(bandwidth) || length(bandwidth) != 1L ||
      !is.finite(bandwidth) || bandwidth <= 0) {
    stop("bandwidth muss eine positive endliche Zahl sein.", call. = FALSE)
  }

  # Show every interval, even if no observation lies below/above an outer cut.
  observed_range <- range(c(pvs$value, scale$cuts))
  padding <- max(3 * bandwidth, diff(observed_range) * 0.12)
  limits <- observed_range + c(-padding, padding)
  outer_breaks <- pretty(limits)
  outer_breaks <- outer_breaks[outer_breaks < min(scale$cuts) |
                                 outer_breaks > max(scale$cuts)]
  axis_breaks <- sort(unique(c(scale$cuts, outer_breaks)))
  axis_breaks <- axis_breaks[axis_breaks >= limits[1L] & axis_breaks <= limits[2L]]
  axis_labels <- function(values) format(values, trim = TRUE, scientific = FALSE,
                                         decimal.mark = ",")
  densities <- lapply(by_pv, function(values) {
    stats::density(values, bw = bandwidth, kernel = "gaussian", n = 1024L,
                   from = limits[1L], to = limits[2L], na.rm = FALSE)
  })
  density_data <- data.frame(
    value = densities[[1L]]$x,
    density = rowMeans(vapply(densities, `[[`, numeric(1024L), "y"))
  )
  percentages <- results$percentages[results$percentages$scale_id == scale_id, , drop = FALSE]
  descriptives <- results$descriptives[results$descriptives$scale_id == scale_id, , drop = FALSE]
  rownames(percentages) <- rownames(descriptives) <- NULL
  peak <- max(density_data$density)
  breaks <- c(limits[1L], scale$cuts, limits[2L])
  bands <- data.frame(
    lower = utils::head(breaks, -1L), upper = utils::tail(breaks, -1L),
    fill = rep(c("#FFFFFF", "#F5F1F2"), length.out = length(scale$level_labels))
  )
  labels <- data.frame(
    value = (bands$lower + bands$upper) / 2,
    density = peak * 1.26,
    level_label = percentages$level_label,
    percent_density = peak * 1.15,
    percent_label = sprintf('plain("%s")*scriptstyle(phantom("."))*plain("%%")',
      formatC(percentages$percent, format = "f", digits = 1, decimal.mark = ","))
  )
  # At the report's 15.5 cm width, adjacent 11 pt percentages need separate
  # rows in narrow bands. Keep the level labels aligned and move only every
  # second crowded percentage, without changing the density or axis limits.
  lower_row <- rep(FALSE, nrow(labels))
  for (i in seq_len(nrow(labels))[-1L]) {
    close <- labels$value[i] - labels$value[i - 1L] < diff(limits) * 0.12
    lower_row[i] <- close && !lower_row[i - 1L]
  }
  labels$percent_density[lower_row] <- peak * 1.06
  format_number <- function(x) formatC(x, format = "f", digits = 1, decimal.mark = ",")
  subtitle <- bquote(italic(N) == .(descriptives$n_persons) ~ " | " ~
                       italic(M) == .(format_number(descriptives$mean)) ~ " | " ~
                       italic(SD) == .(format_number(descriptives$sd)) ~ " | " ~
                       .(descriptives$n_pv) ~ "PVs")
  caption <- "Alle F\u00e4lle, ungewichtet. Anteile je PV berechnet und anschlie\u00dfend gemittelt."
  if (input$config$report$data_origin == "synthetic") {
    caption <- paste0("Synthetisches Beispiel; illustrative Stufengrenzen.\n", caption)
  }

  # Locally bound names keep ggplot's data-mask expressions visible to R checks.
  value <- density <- lower <- upper <- fill <- level_label <- NULL
  percent_density <- percent_label <- NULL
  plot <- ggplot2::ggplot(density_data, ggplot2::aes(x = value, y = density)) +
    ggplot2::geom_rect(
      data = bands,
      ggplot2::aes(xmin = lower, xmax = upper, ymin = 0, ymax = peak * 1.32,
                   fill = fill),
      inherit.aes = FALSE, colour = NA
    ) +
    ggplot2::scale_fill_identity() +
    ggplot2::geom_area(fill = "#B40036", alpha = 0.18) +
    ggplot2::geom_line(colour = "#B40036", linewidth = 0.8) +
    ggplot2::geom_vline(xintercept = scale$cuts, colour = "#82767B",
                       linetype = "dashed", linewidth = 0.4) +
    ggplot2::geom_text(data = labels, ggplot2::aes(label = level_label),
                       colour = "#271A2B", family = font_family, size = 11 * 25.4 / 72.27,
                       lineheight = 1.2) +
    # A small invisible spacer gives the percentage sign breathing room while
    # remaining portable to the standard PDF device (unlike Unicode thin space).
    ggplot2::geom_text(data = labels,
                       ggplot2::aes(x = value, y = percent_density, label = percent_label),
                       inherit.aes = FALSE, parse = TRUE, colour = "#271A2B",
                       family = font_family, size = 11 * 25.4 / 72.27) +
    ggplot2::scale_x_continuous(limits = limits, breaks = axis_breaks, labels = axis_labels,
                               expand = ggplot2::expansion(mult = 0)) +
    ggplot2::scale_y_continuous(labels = axis_labels,
                               expand = ggplot2::expansion(mult = c(0, 0.02))) +
    ggplot2::labs(title = scale$label, subtitle = subtitle,
                   x = "Leistung auf der 500er-Berichtsskala", y = "Dichte",
                   caption = caption) +
    ggplot2::theme_minimal(base_size = 11, base_family = font_family) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(colour = "#E7E3E5", linewidth = 0.3),
      plot.title = ggplot2::element_text(face = "bold", colour = "#271A2B"),
      plot.subtitle = ggplot2::element_text(margin = ggplot2::margin(b = 10)),
      axis.text = ggplot2::element_text(size = 11),
      axis.text.y = ggplot2::element_text(margin = ggplot2::margin(r = 2)),
      axis.title.y = ggplot2::element_text(margin = ggplot2::margin(r = 2)),
      plot.caption = ggplot2::element_text(hjust = 0, colour = "#625A5E", size = 11),
      plot.margin = ggplot2::margin(5.5, 2, 5.5, 2),
      plot.background = ggplot2::element_rect(fill = "white", colour = NA)
    )
  attr(plot, "population_percentages") <- percentages
  attr(plot, "descriptives") <- descriptives
  attr(plot, "density_data") <- density_data
  attr(plot, "density_bandwidth") <- bandwidth
  plot
}
