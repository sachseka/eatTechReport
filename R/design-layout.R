# Design cells use owned character styles rather than matching their displayed
# text. The finaliser therefore never guesses from block labels or touches an
# unrelated table that happens to contain a column called "Block 1".
format_report_design_tables <- function(doc, ns = word_ns()) {
  style_values <- function(node) xml2::xml_attr(
    xml2::xml_find_all(node, ".//w:rPr/w:rStyle", ns), "w:val", ns)
  for (table in xml2::xml_find_all(doc, "//w:tbl", ns)) {
    if (length(xml2::xml_find_all(table, ".//w:tbl", ns))) next
    rows <- xml2::xml_find_all(table, "w:tr", ns)
    if (!length(rows)) next
    headers <- xml2::xml_find_all(rows[[1L]], "w:tc", ns)
    if (!any(vapply(headers, function(cell) "EatDesignHeader" %in% style_values(cell), logical(1)))) next
    n <- length(headers)
    if (n < 2L || any(vapply(rows, function(row) {
      length(xml2::xml_find_all(row, "w:tc", ns)) != n
    }, logical(1))) || length(xml2::xml_find_all(table, "w:tr/w:tc/w:tcPr/w:gridSpan|w:tr/w:tc/w:tcPr/w:vMerge", ns))) {
      stop("Die markierte Designmatrix braucht gleich viele unverbundene Zellen je Zeile.", call. = FALSE)
    }
    pauses <- which(vapply(headers, function(cell) "EatDesignPauseHeader" %in% style_values(cell), logical(1)))
    # Two-block designs remain compact. A six-block modular design uses the
    # available text width; the pause stays 0.25 cm regardless of column count.
    regular <- n - length(pauses)
    width_cm <- min(15.5, regular * 2.2 + length(pauses) * 0.25)
    widths_cm <- rep((width_cm - length(pauses) * 0.25) / regular, n)
    widths_cm[pauses] <- 0.25
    widths <- round(widths_cm / 2.54 * 1440)
    props <- layout_child(table, "tblPr", ns, first = TRUE)
    layout_set_attributes(layout_child(props, "tblW", ns),
                          c("w:w" = as.character(sum(widths)), "w:type" = "dxa"), ns)
    xml2::xml_set_attr(layout_child(props, "tblLayout", ns), "w:type", "fixed")
    xml2::xml_set_attr(layout_child(props, "jc", ns), "w:val", "left")
    grid <- layout_child(table, "tblGrid", ns)
    xml2::xml_remove(xml2::xml_children(grid))
    for (width in widths) xml2::xml_set_attr(xml2::xml_add_child(grid, "w:gridCol"), "w:w", as.character(width))
    layout_order_children(table, c("tblPr", "tblGrid", "tr"))
    for (i in seq_along(rows)) {
      row <- rows[[i]]
      row_props <- layout_child(row, "trPr", ns, first = TRUE)
      layout_child(row_props, "cantSplit", ns)
      if (i == 1L) xml2::xml_set_attr(layout_child(row_props, "tblHeader", ns), "w:val", "1")
      cells <- xml2::xml_find_all(row, "w:tc", ns)
      for (j in seq_along(cells)) {
        cell <- cells[[j]]
        cell_props <- layout_child(cell, "tcPr", ns, first = TRUE)
        layout_set_attributes(layout_child(cell_props, "tcW", ns),
                              c("w:w" = as.character(widths[j]), "w:type" = "dxa"), ns)
        xml2::xml_set_attr(layout_child(cell_props, "vAlign", ns), "w:val", "center")
        norming <- "EatDesignNorming" %in% style_values(cell)
        fill <- if (j %in% pauses) "FFFFFF" else if (i == 1L) "F2F2F2" else if (norming) "C9C9C9" else "FFFFFF"
        layout_set_attributes(layout_child(cell_props, "shd", ns),
                              c("w:val" = "clear", "w:color" = "auto", "w:fill" = fill), ns)
        if (j %in% pauses) {
          # A pause is an empty separation, not a labelled or shaded block.
          xml2::xml_remove(xml2::xml_find_all(cell, ".//w:t", ns))
          margins <- layout_child(cell_props, "tcMar", ns)
          for (side in c("left", "right", "start", "end")) {
            layout_set_attributes(layout_child(margins, side, ns),
                                  c("w:w" = "0", "w:type" = "dxa"), ns)
          }
          layout_order_children(margins, c("top", "start", "left", "bottom", "end", "right"))
        }
        for (paragraph in xml2::xml_find_all(cell, "w:p", ns)) {
          pprops <- layout_child(paragraph, "pPr", ns, first = TRUE)
          xml2::xml_set_attr(layout_child(pprops, "jc", ns), "w:val", "center")
          layout_set_attributes(layout_child(pprops, "ind", ns),
                                c("w:left" = "0", "w:right" = "0", "w:firstLine" = "0"), ns)
        }
        # Preserve character styles as nonprinting metadata for idempotence;
        # they do not introduce marker text into the finished report.
        layout_order_children(cell_props, c("cnfStyle", "tcW", "gridSpan", "hMerge", "vMerge",
          "tcBorders", "shd", "noWrap", "tcMar", "textDirection", "tcFitText", "vAlign",
          "hideMark", "headers", "tcPrChange"))
      }
    }
    layout_order_children(props, c("tblStyle", "tblpPr", "tblOverlap", "bidiVisual",
      "tblStyleRowBandSize", "tblStyleColBandSize", "tblW", "jc", "tblCellSpacing",
      "tblInd", "tblBorders", "shd", "tblLayout", "tblCellMar", "tblLook", "tblCaption",
      "tblDescription", "tblPrChange"))
  }
  invisible(doc)
}
