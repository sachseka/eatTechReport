# Quarto keeps a captioned image in a one-cell layout table. These owned
# item-level figures must not receive data-table rules, shading or cell padding.
report_figure_ns <- function(ns = word_ns()) {
  ns[c("wp", "a", "pic")] <- c(
    "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing",
    "http://schemas.openxmlformats.org/drawingml/2006/main",
    "http://schemas.openxmlformats.org/drawingml/2006/picture")
  ns
}

report_figure_caption_ids <- function(styles, ns) {
  ids <- "ImageCaption"
  if (!is.null(styles)) {
    nodes <- xml2::xml_find_all(styles, "w:style", ns)
    style_ids <- xml2::xml_attr(nodes, "w:styleId", ns)
    names <- xml2::xml_attr(xml2::xml_find_first(nodes, "w:name", ns), "w:val", ns)
    key <- function(x) tolower(gsub("[ _-]", "", x))
    matches <- key(style_ids) %in% "imagecaption" | key(names) %in% "imagecaption"
    ids <- c(ids, style_ids[matches & !is.na(style_ids)])
  }
  unique(ids)
}

is_report_figure_table <- function(table, styles = NULL, ns = word_ns()) {
  ns <- report_figure_ns(ns)
  if (length(xml2::xml_find_all(table, "w:tr", ns)) != 1L ||
      length(xml2::xml_find_all(table, "w:tr/w:tc", ns)) != 1L ||
      length(xml2::xml_find_all(table, ".//w:tbl", ns)) ||
      length(xml2::xml_find_all(table, ".//w:drawing", ns)) != 1L) return(FALSE)
  descriptions <- xml2::xml_attr(xml2::xml_find_all(table, ".//pic:cNvPr", ns), "descr")
  if (length(descriptions) != 1L || is.na(descriptions) ||
      !grepl("^figures/item-levels-[^/\\\\]+[.]png$", descriptions)) return(FALSE)
  paragraphs <- xml2::xml_find_all(table, "w:tr/w:tc/w:p", ns)
  ids <- xml2::xml_attr(xml2::xml_find_first(paragraphs, "w:pPr/w:pStyle", ns), "w:val", ns)
  caption <- !is.na(ids) & ids %in% report_figure_caption_ids(styles, ns)
  if (sum(caption) != 1L) return(FALSE)
  # A table with additional textual content is not the narrow figure wrapper.
  other_text <- vapply(paragraphs[!caption], function(p) {
    paste(xml2::xml_text(xml2::xml_find_all(p, ".//w:t", ns)), collapse = "")
  }, character(1))
  !any(nzchar(trimws(other_text)))
}

# Run after apply_report_layout(), which applies generic caption keep-with-next.
finalise_report_figures <- function(doc, styles = NULL, ns = word_ns()) {
  ns <- report_figure_ns(ns)
  width_emu <- 5580000 # 15.5 cm, the report's intended full figure width.
  width_twips <- as.character(round(width_emu / 635))
  for (table in xml2::xml_find_all(doc, "//w:tbl", ns)) {
    if (!is_report_figure_table(table, styles, ns)) next
    clear_report_layout_table(table, ns)
    props <- layout_child(table, "tblPr", ns, first = TRUE)
    # Remove inherited table styling, then explicitly clear all layout borders.
    xml2::xml_remove(xml2::xml_find_all(props, "w:tblStyle|w:tblCellSpacing|w:tblInd", ns))
    layout_set_attributes(layout_child(props, "tblW", ns),
                          c("w:w" = width_twips, "w:type" = "dxa"), ns)
    xml2::xml_set_attr(layout_child(props, "tblLayout", ns), "w:type", "fixed")
    xml2::xml_set_attr(layout_child(props, "jc", ns), "w:val", "center")
    margins <- layout_child(props, "tblCellMar", ns)
    for (side in c("top", "left", "bottom", "right", "start", "end")) {
      layout_set_attributes(layout_child(margins, side, ns), c("w:w" = "0", "w:type" = "dxa"), ns)
    }
    layout_order_children(margins, c("top", "start", "left", "bottom", "end", "right"))
    layout_order_children(props, c("tblStyle", "tblpPr", "tblOverlap", "bidiVisual",
                                  "tblStyleRowBandSize", "tblStyleColBandSize", "tblW", "jc",
                                  "tblCellSpacing", "tblInd", "tblBorders", "shd", "tblLayout",
                                  "tblCellMar", "tblLook", "tblCaption", "tblDescription", "tblPrChange"))
    grid <- layout_child(table, "tblGrid", ns)
    xml2::xml_remove(xml2::xml_children(grid))
    xml2::xml_set_attr(xml2::xml_add_child(grid, "w:gridCol"), "w:w", width_twips)
    layout_order_children(table, c("tblPr", "tblGrid", "tr"))
    row <- xml2::xml_find_first(table, "w:tr", ns)
    row_props <- layout_child(row, "trPr", ns, first = TRUE)
    xml2::xml_remove(xml2::xml_find_all(row_props, "w:trHeight|w:tblHeader", ns))
    layout_child(row_props, "cantSplit", ns)
    cell <- xml2::xml_find_first(row, "w:tc", ns)
    cell_props <- layout_child(cell, "tcPr", ns, first = TRUE)
    layout_set_attributes(layout_child(cell_props, "tcW", ns),
                          c("w:w" = width_twips, "w:type" = "dxa"), ns)
    xml2::xml_set_attr(layout_child(cell_props, "vAlign", ns), "w:val", "top")
    borders <- layout_child(cell_props, "tcBorders", ns)
    for (side in c("top", "left", "bottom", "right", "insideH", "insideV")) {
      xml2::xml_set_attr(layout_child(borders, side, ns), "w:val", "nil")
    }
    margins <- layout_child(cell_props, "tcMar", ns)
    for (side in c("top", "left", "bottom", "right", "start", "end")) {
      layout_set_attributes(layout_child(margins, side, ns), c("w:w" = "0", "w:type" = "dxa"), ns)
    }
    layout_order_children(margins, c("top", "start", "left", "bottom", "end", "right"))
    layout_order_children(cell_props, c("cnfStyle", "tcW", "gridSpan", "hMerge", "vMerge",
                                      "tcBorders", "shd", "noWrap", "tcMar", "textDirection",
                                      "tcFitText", "vAlign", "hideMark", "headers", "tcPrChange"))
    for (paragraph in xml2::xml_find_all(cell, "w:p", ns)) {
      paragraph_props <- layout_child(paragraph, "pPr", ns, first = TRUE)
      id <- xml2::xml_attr(xml2::xml_find_first(paragraph_props, "w:pStyle", ns), "w:val", ns)
      is_caption <- !is.na(id) && id %in% report_figure_caption_ids(styles, ns)
      xml2::xml_set_attr(layout_child(paragraph_props, "keepNext", ns), "w:val", if (is_caption) "0" else "1")
      xml2::xml_set_attr(layout_child(paragraph_props, "keepLines", ns), "w:val", "1")
      xml2::xml_remove(xml2::xml_find_all(paragraph_props, "w:shd|w:pBdr", ns))
      layout_set_attributes(layout_child(paragraph_props, "ind", ns),
                            c("w:left" = "0", "w:right" = "0", "w:firstLine" = "0"), ns)
      layout_order_children(paragraph_props, c("pStyle", "keepNext", "keepLines", "pageBreakBefore",
        "framePr", "widowControl", "numPr", "suppressLineNumbers", "pBdr", "shd", "tabs",
        "suppressAutoHyphens", "kinsoku", "wordWrap", "overflowPunct", "topLinePunct", "autoSpaceDE",
        "autoSpaceDN", "bidi", "adjustRightInd", "snapToGrid", "spacing", "ind", "contextualSpacing",
        "mirrorIndents", "suppressOverlap", "jc", "textDirection", "textAlignment", "textboxTightWrap",
        "outlineLvl", "divId", "cnfStyle", "rPr", "sectPr", "pPrChange"))
    }
    drawing <- xml2::xml_find_first(cell, ".//w:drawing", ns)
    extent <- xml2::xml_find_first(drawing, ".//wp:extent", ns)
    dimensions <- suppressWarnings(as.numeric(xml2::xml_attrs(extent)[c("cx", "cy")]))
    if (length(dimensions) == 2L && all(is.finite(dimensions)) && all(dimensions > 0)) {
      target <- c(cx = as.character(width_emu),
                  cy = as.character(round(dimensions[2L] * width_emu / dimensions[1L])))
      xml2::xml_set_attrs(extent, target)
      for (picture_extent in xml2::xml_find_all(drawing, ".//pic:spPr/a:xfrm/a:ext", ns)) {
        xml2::xml_set_attrs(picture_extent, target)
      }
    }
  }
  invisible(doc)
}
