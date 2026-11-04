# Apply corporate column shades only to the owned task matrix. The marker styles
# survive Pandoc's DOCX conversion without changing the supplied task labels.
format_report_task_matrices <- function(doc, ns = word_ns()) {
  for (table in xml2::xml_find_all(doc, "//w:tbl[not(.//w:tbl)]", ns)) {
    header <- xml2::xml_find_all(table, "w:tr[1]/w:tc", ns)
    if (!length(xml2::xml_find_all(header,
      ".//w:rStyle[@w:val='EatTaskMatrix']", ns))) next
    types <- vapply(header, function(cell) {
      markers <- xml2::xml_attr(xml2::xml_find_all(cell, ".//w:rStyle", ns), "w:val", ns)
      if ("EatTaskBase" %in% markers) "base" else if ("EatTaskSupplement" %in% markers) "supplement" else "position"
    }, character(1))
    rows <- xml2::xml_find_all(table, "w:tr", ns)
    for (i in seq_along(rows)) {
      cells <- xml2::xml_find_all(rows[[i]], "w:tc", ns)
      for (j in seq_along(cells)) {
        type <- types[j]
        fill <- if (i == 1L) {
          if (type == "base") "B40036" else if (type == "supplement") "00818D" else "534856"
        } else if (type == "base") "FBEFF3" else if (type == "supplement") "EAF4F5" else "FFFFFF"
        props <- layout_child(cells[[j]], "tcPr", ns, first = TRUE)
        layout_set_attributes(layout_child(props, "shd", ns),
          c("w:val" = "clear", "w:fill" = fill), ns)
        if (i == 1L) for (run in xml2::xml_find_all(cells[[j]], ".//w:r[w:t]", ns)) {
          rprops <- layout_child(run, "rPr", ns, first = TRUE)
          xml2::xml_set_attr(layout_child(rprops, "color", ns), "w:val", "FFFFFF")
          xml2::xml_set_attr(layout_child(rprops, "b", ns), "w:val", "1")
          layout_run_properties(rprops, ns)
        }
        layout_order_children(props, c("cnfStyle", "tcW", "gridSpan", "hMerge", "vMerge",
          "tcBorders", "shd", "noWrap", "tcMar", "textDirection", "tcFitText", "vAlign",
          "hideMark", "headers", "tcPrChange"))
      }
    }
  }
  invisible(doc)
}
