# Presentation helpers used by the editable pilot-study text blocks. Values are
# formatted only here; the result tables retain their original precision.
study_number <- function(value, digits = 1L) {
  out <- rep("\u2014", length(value))
  available <- is.finite(value)
  out[available] <- formatC(value[available], format = "f", digits = digits,
                            decimal.mark = ",")
  out
}

study_table_markdown <- function(data, align = NULL, widths = NULL) {
  if (is.null(align)) align <- vapply(data, function(value) if (is.numeric(value)) "r" else "l", character(1))
  if (length(align) == 1L) align <- rep(align, ncol(data))
  if (!is.null(widths) && (!is.numeric(widths) || length(widths) != ncol(data) ||
                           any(!is.finite(widths) | widths <= 0))) {
    stop("widths muss je Spalte eine positive endliche Zahl enthalten.", call. = FALSE)
  }
  data[] <- lapply(data, function(value) {
    value <- as.character(value)
    value[is.na(value)] <- "\u2014"
    report_markdown_text(value)
  })
  names(data) <- report_markdown_text(names(data))
  names(data) <- gsub("\\b(N|M|SD)\\b", "*\\1*", names(data), perl = TRUE)
  table <- knitr::kable(data, format = "pipe", align = align, row.names = FALSE)
  if (!is.null(widths)) {
    # Pandoc uses separator lengths as relative widths for wide pipe tables.
    # Explicit widths prevent long labels from squeezing count/ID columns.
    sizes <- pmax(3L, round(100 * widths / sum(widths)))
    separators <- vapply(seq_along(sizes), function(i) {
      colons <- if (align[i] == "c") 2L else 1L
      paste0(if (align[i] %in% c("l", "c")) ":" else "",
             strrep("-", sizes[i] - colons),
             if (align[i] %in% c("r", "c")) ":" else "")
    }, character(1))
    table[2L] <- paste0("|", paste(separators, collapse = "|"), "|")
  }
  paste(c("", table, "", ""), collapse = "\n")
}

# Split wide designs into successive position groups. A large position number
# does not allocate empty intermediate columns; actual position numbers remain
# visible in their headings and empty slots are represented by an em dash.
study_design_tables <- function(design, max_positions = 4L) {
  if (length(max_positions) != 1L || !is.numeric(max_positions) ||
      !is.finite(max_positions) || max_positions < 1 ||
      max_positions != floor(max_positions)) {
    stop("max_positions muss eine positive ganze Zahl sein.", call. = FALSE)
  }
  lapply(seq_len(nrow(design$design_rules)), function(i) {
    rule <- design$design_rules[i, , drop = FALSE]
    slots <- design$slots[design$slots$design_id == rule$design_id, , drop = FALSE]
    booklets <- design$booklets[design$booklets$design_id == rule$design_id, , drop = FALSE]
    positions <- sort(unique(slots$position))
    groups <- split(positions, ceiling(seq_along(positions) / max_positions))
    parts <- lapply(groups, function(position_group) {
      table <- data.frame("Testheft" = booklets$booklet_id, check.names = FALSE)
      for (position in position_group) {
        at_position <- slots[slots$position == position, , drop = FALSE]
        index <- match(booklets$booklet_id, at_position$booklet_id)
        cell <- rep("\u2014", nrow(booklets))
        present <- !is.na(index)
        cell[present] <- paste0(at_position$block_label[index[present]], " \u00b7 ",
                                 study_number(at_position$duration_minutes[index[present]]),
                                 " Min.")
        table[[paste("Position", study_number(position, 0L))]] <- cell
      }
      table
    })
    list(rule = rule, parts = parts, booklets = booklets)
  })
}

study_language_tables <- function(data, max_categories = 3L) {
  if (is.null(data) || !nrow(data)) return(list())
  if (length(max_categories) != 1L || !is.numeric(max_categories) ||
      !is.finite(max_categories) || max_categories < 1 ||
      max_categories != floor(max_categories)) {
    stop("max_categories muss eine positive ganze Zahl sein.", call. = FALSE)
  }
  categories <- unique(data$category)
  groups <- split(categories, ceiling(seq_along(categories) / max_categories))
  states <- data[!duplicated(data$state_id), c("state_id", "state_label", "denominator"),
                 drop = FALSE]
  lapply(groups, function(category_group) {
    table <- data.frame("Land" = states$state_label,
                        "Personen (N)" = states$denominator, check.names = FALSE)
    for (category in category_group) {
      selected <- data[data$category == category, , drop = FALSE]
      table[[paste0(category, " (%)")]] <- study_number(
        selected$percent[match(states$state_id, selected$state_id)])
    }
    table
  })
}

study_response_sentences <- function(rows, config) {
  if (!nrow(rows)) return(character())
  vapply(seq_len(nrow(rows)), function(i) {
    row <- rows[i, , drop = FALSE]
    label <- if ("domain_id" %in% names(row)) {
      domain_label <- config$domains$label[match(row$domain_id, config$domains$domain_id)]
      paste0(" im Kompetenzbereich \u201e", report_markdown_text(domain_label), "\u201c")
    } else ""
    if (row$role == "anchor") {
      paste0("F\u00fcr die Ankeritems", label, " lagen pro Item ",
             study_number(row$min, 0L), " bis ", study_number(row$max, 0L),
             " Antworten von Sch\u00fclerinnen und Sch\u00fclern (*Median* = ",
             study_number(row$median), ") vor.")
    } else {
      paste0("Durch das oben beschriebene Testdesign lagen f\u00fcr die im Jahr ",
             config$report$pilot_year, " pilotierten Aufgaben", label,
             " pro Item ", study_number(row$min, 0L), " bis ", study_number(row$max, 0L),
             " Antworten von Sch\u00fclerinnen und Sch\u00fclern (*Median* = ",
             study_number(row$median), ") vor.")
    }
  }, character(1), USE.NAMES = FALSE)
}
