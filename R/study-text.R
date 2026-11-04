# Presentation helpers used by the editable pilot-study text blocks. Values are
# formatted only here; the result tables retain their original precision.
study_number <- function(value, digits = 1L) {
  out <- rep("\u2014", length(value))
  available <- is.finite(value)
  out[available] <- formatC(value[available], format = "f", digits = digits,
                            decimal.mark = ",")
  out
}

study_table_markdown <- function(data, align = NULL, widths = NULL, config = NULL,
                                 dynamic_headers = integer(),
                                 dynamic_columns = seq_len(ncol(data))) {
  if (is.null(align)) align <- vapply(data, function(value) if (is.numeric(value)) "r" else "l", character(1))
  if (length(align) == 1L) align <- rep(align, ncol(data))
  if (!is.null(widths) && (!is.numeric(widths) || length(widths) != ncol(data) ||
                           any(!is.finite(widths) | widths <= 0))) {
    stop("widths muss je Spalte eine positive endliche Zahl enthalten.", call. = FALSE)
  }
  if (!is.numeric(dynamic_columns) || anyNA(dynamic_columns) ||
      any(dynamic_columns != floor(dynamic_columns) |
            dynamic_columns < 1L | dynamic_columns > ncol(data))) {
    stop("dynamic_columns muss gueltige Spaltennummern enthalten.", call. = FALSE)
  }
  data[] <- lapply(seq_along(data), function(j) {
    value <- data[[j]]
    value <- as.character(value)
    value[is.na(value)] <- "\u2014"
    report_text_value(value, if (j %in% dynamic_columns) config else NULL)
  })
  names(data) <- report_markdown_text(names(data))
  names(data) <- gsub("\\b(N|M|SD)\\b", "*\\1*", names(data), perl = TRUE)
  if (length(dynamic_headers)) {
    if (!is.numeric(dynamic_headers) || anyNA(dynamic_headers) ||
        any(dynamic_headers != floor(dynamic_headers) |
              dynamic_headers < 1L | dynamic_headers > ncol(data))) {
      stop("dynamic_headers muss gueltige Spaltennummern enthalten.", call. = FALSE)
    }
    names(data)[dynamic_headers] <- report_text_value(names(data)[dynamic_headers],
                                                     config, markdown = TRUE)
  }
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

# Display actual blocks in booklet order. Slot positions remain identifiers in
# the input; instructions and pauses do not increment the displayed block number.
# A shared blank column after a given block keeps pauses aligned across rows,
# including when instruction slots differ between booklets.
study_design_tables <- function(design, max_positions = 6L) {
  if (length(max_positions) != 1L || !is.numeric(max_positions) ||
      !is.finite(max_positions) || max_positions < 1 ||
      max_positions != floor(max_positions)) {
    stop("max_positions muss eine positive ganze Zahl sein.", call. = FALSE)
  }
  lapply(seq_len(nrow(design$design_rules)), function(i) {
    rule <- design$design_rules[i, , drop = FALSE]
    slots <- design$slots[design$slots$design_id == rule$design_id, , drop = FALSE]
    booklets <- design$booklets[design$booklets$design_id == rule$design_id, , drop = FALSE]
    slots <- slots[order(match(slots$booklet_id, booklets$booklet_id), slots$position), , drop = FALSE]
    if (!"is_norming" %in% names(slots)) slots$is_norming <- FALSE
    slots$block_number <- stats::ave(as.integer(slots$kind == "block"), slots$booklet_id, FUN = cumsum)
    blocks <- slots[slots$kind == "block", , drop = FALSE]
    pauses <- sort(unique(slots$block_number[slots$kind == "pause"]))
    numbers <- seq_len(max(blocks$block_number))
    groups <- split(numbers, ceiling(seq_along(numbers) / max_positions))
    parts <- lapply(groups, function(block_group) {
      table <- data.frame("Testheft" = booklets$booklet_id, check.names = FALSE)
      norming <- list(rep(FALSE, nrow(booklets)))
      pause_columns <- integer()
      add_pause <- function() {
        table[[ncol(table) + 1L]] <<- rep("", nrow(booklets))
        names(table)[ncol(table)] <<- ""
        norming[[length(norming) + 1L]] <<- rep(FALSE, nrow(booklets))
        pause_columns <<- c(pause_columns, ncol(table))
      }
      if (min(block_group) == 1L && 0L %in% pauses) add_pause()
      for (number in block_group) {
        at_position <- blocks[blocks$block_number == number, , drop = FALSE]
        index <- match(booklets$booklet_id, at_position$booklet_id)
        cell <- rep("\u2014", nrow(booklets))
        present <- !is.na(index)
        cell[present] <- at_position$block_label[index[present]]
        table[[paste("Block", number)]] <- cell
        highlighted <- rep(FALSE, nrow(booklets))
        highlighted[present] <- at_position$is_norming[index[present]]
        norming[[length(norming) + 1L]] <- highlighted
        if (number %in% pauses) add_pause()
      }
      names(table)[pause_columns] <- ""
      attr(table, "design_norming") <- do.call(cbind, norming)
      attr(table, "design_pause_columns") <- pause_columns
      attr(table, "design_block_numbers") <- block_group
      table
    })
    list(rule = rule, parts = parts, booklets = booklets, slots = slots)
  })
}

# Owned character styles survive the Pandoc-to-Word conversion and allow a
# narrowly scoped finaliser to shade cells and set a genuinely narrow pause
# column. Data labels are escaped before adding these fixed style attributes.
study_design_table_markdown <- function(data) {
  norming <- attr(data, "design_norming")
  pauses <- attr(data, "design_pause_columns")
  if (is.null(norming)) norming <- matrix(FALSE, nrow(data), ncol(data))
  if (!is.logical(norming) || anyNA(norming) ||
      !identical(dim(norming), dim(data))) {
    stop("design_norming muss eine logische Markierung je Tabellenzelle enthalten.", call. = FALSE)
  }
  if (is.null(pauses)) pauses <- integer()
  if (!is.numeric(pauses) || anyNA(pauses) || any(!is.finite(pauses)) ||
      any(pauses != floor(pauses) | pauses <= 1 | pauses > ncol(data))) {
    stop("design_pause_columns muss gueltige Pausenspalten enthalten.", call. = FALSE)
  }
  span <- function(value, style) paste0("[", report_markdown_text(value),
                                       "]{custom-style=\"", style, "\"}")
  for (j in seq_len(ncol(data))) {
    if (j %in% pauses) {
      data[[j]] <- span(rep("\u00a0", nrow(data)), "EatDesignPause")
    } else {
      values <- as.character(data[[j]])
      values[is.na(values)] <- "\u2014"
      styles <- ifelse(norming[, j], "EatDesignNorming",
                       if (j == 1L) "EatDesignBooklet" else "EatDesignBlock")
      data[[j]] <- span(values, styles)
    }
  }
  headers <- names(data)
  headers[pauses] <- "\u00a0"
  names(data) <- span(headers, ifelse(seq_len(ncol(data)) %in% pauses,
                                     "EatDesignPauseHeader", "EatDesignHeader"))
  paste(c("", knitr::kable(data, format = "pipe", align = "c", row.names = FALSE), "", ""),
         collapse = "\n")
}

# Times remain visible below the design, without repeating every duration in
# every block cell or adding a second table. Unequal times remain identified by
# booklet; missing pauses are not silently presented as pauses for every row.
study_design_timing_note <- function(part, config = NULL) {
  slots <- part$slots
  ids <- part$booklets$booklet_id
  value <- function(x) if (is.null(config)) as.character(x) else report_text_value(x, config)
  categories <- list()
  if (all(slots$module[slots$kind == "block"] %in% c("base", "supplement"))) {
    categories <- list(Basismodule = slots$kind == "block" & slots$module %in% "base",
                       "Erg\u00e4nzungsmodule" = slots$kind == "block" & slots$module %in% "supplement")
  } else categories <- list(Bearbeitungszeit = slots$kind == "block")
  categories$Pause <- slots$kind == "pause"
  categories$Instruktion <- slots$kind == "instruction"
  parts <- lapply(names(categories), function(label) {
    selected <- categories[[label]]
    if (!any(selected)) return(NULL)
    values <- vapply(ids, function(id) {
      sum(slots$duration_minutes[selected & slots$booklet_id == id])
    }, numeric(1))
    number <- function(x) value(study_number(x, if (all(x == floor(x))) 0L else 1L))
    if (length(unique(values)) == 1L) {
      paste0(label, ": ", number(values[1L]), "\u00a0min")
    } else paste0(label, ": ", paste0(value(ids), " ", number(values),
                                      "\u00a0min", collapse = ", "))
  })
  paste0(paste(unlist(parts, use.names = FALSE), collapse = "; "), ".")
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
      paste0(" im Kompetenzbereich \u201e", report_text_value(domain_label, config), "\u201c")
    } else ""
    if (row$role == "anchor") {
      paste0("F\u00fcr die Ankeritems", label, " lagen pro Item ",
             report_text_value(study_number(row$min, 0L), config), " bis ",
             report_text_value(study_number(row$max, 0L), config),
             " Antworten von Sch\u00fclerinnen und Sch\u00fclern (*Median* = ",
             report_text_value(study_number(row$median), config), ") vor.")
    } else {
      paste0("Durch das oben beschriebene Testdesign lagen f\u00fcr die im Jahr ",
             report_text_value(config$report$pilot_year, config), " pilotierten Aufgaben", label,
             " pro Item ", report_text_value(study_number(row$min, 0L), config), " bis ",
             report_text_value(study_number(row$max, 0L), config),
             " Antworten von Sch\u00fclerinnen und Sch\u00fclern (*Median* = ",
             report_text_value(study_number(row$median), config), ") vor.")
    }
  }, character(1), USE.NAMES = FALSE)
}
