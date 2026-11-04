# Word does not repeat the header row of a table nested in Quarto's caption
# wrapper. Promote only long, explicitly owned matrices to body-level tables;
# their caption/bookmark nodes and complete data table retain their contents.
unwrap_report_table_wrappers <- function(doc, styles = NULL, ns = word_ns()) {
  for (wrapper in xml2::xml_find_all(doc, "//w:body/w:tbl", ns)) {
    if (length(xml2::xml_find_all(wrapper, "w:tr", ns)) != 1L ||
        length(xml2::xml_find_all(wrapper, "w:tr/w:tc", ns)) != 1L ||
        length(xml2::xml_find_all(wrapper, ".//w:tbl", ns)) != 1L ||
        length(xml2::xml_find_all(wrapper, ".//w:drawing | .//w:pict | .//w:object | .//w:tblpPr", ns))) next
    if (length(xml2::xml_find_all(wrapper, paste0(
      "*[not(self::w:tblPr or self::w:tblGrid or self::w:tr)] | ",
      "w:tr/*[not(self::w:trPr or self::w:tc)] | w:tblPr/w:tblCaption | w:tblPr/w:tblDescription"), ns))) next
    cell <- xml2::xml_find_first(wrapper, "w:tr/w:tc", ns)
    content <- xml2::xml_find_all(cell, "*[not(self::w:tcPr)]", ns)
    shape <- xml2::xml_name(content)
    if (identical(shape, c("p", "tbl", "p"))) {
      caption <- content[[1L]]
      table <- content[[2L]]
      own_bookmark <- length(xml2::xml_find_all(caption,
        ".//w:bookmarkStart[starts-with(@w:name, 'tbl-')]", ns)) == 1L
    } else if (identical(shape, c("bookmarkStart", "p", "tbl", "bookmarkEnd", "p"))) {
      # Before Word opens Quarto output, the caption/table bookmark is stored
      # as cell-level siblings. Keep these boundary nodes in the same order.
      caption <- content[[2L]]
      table <- content[[3L]]
      start_id <- xml2::xml_attr(content[[1L]], "w:id", ns)
      end_id <- xml2::xml_attr(content[[4L]], "w:id", ns)
      name <- xml2::xml_attr(content[[1L]], "w:name", ns)
      own_bookmark <- !is.na(start_id) && identical(start_id, end_id) &&
        !is.na(name) && startsWith(name, "tbl-") &&
        !length(xml2::xml_children(content[[1L]])) && !length(xml2::xml_children(content[[4L]]))
    } else next
    trailing <- content[[length(content)]]
    if (length(xml2::xml_find_all(table, "w:tr", ns)) <= 8L) next
    markers <- xml2::xml_attr(xml2::xml_find_all(table, "w:tr[1]//w:rStyle", ns), "w:val", ns)
    if (!any(markers %in% c("EatTaskMatrix", "EatDesignHeader"))) next
    id <- xml2::xml_attr(xml2::xml_find_first(caption, "w:pPr/w:pStyle", ns), "w:val", ns)
    name <- character()
    if (!is.null(styles) && !is.na(id)) {
      nodes <- xml2::xml_find_all(styles, "w:style", ns)
      selected <- xml2::xml_attr(nodes, "w:styleId", ns) %in% id
      name <- xml2::xml_attr(xml2::xml_find_first(nodes[selected], "w:name", ns), "w:val", ns)
    }
    if (!identical(layout_style_role(c(id, name)), "caption") || !own_bookmark) next
    # The mandatory empty paragraph after a nested Word table is structural.
    # Do not delete it if it carries text, bookmarks, fields or page/section
    # instructions; such a wrapper is not the narrow layout shape we own.
    if (length(xml2::xml_find_all(trailing, paste0(
      "*[not(self::w:pPr)] | ",
      "w:pPr/*[not(self::w:pStyle or self::w:spacing or self::w:rPr)]"), ns))) next
    # Preserve outside text gaps while the wrapper still has direct paragraph
    # neighbours; the retained bookmarkEnd may separate table and note later.
    space_report_table(wrapper, styles, ns)
    for (node in content[-length(content)]) {
      xml2::xml_add_sibling(wrapper, node, .where = "before")
    }
    xml2::xml_remove(wrapper)
  }
  invisible(doc)
}
