# A separate paragraph containing only a manual page break can itself overflow
# onto a fresh page. Keeping the break on the following text paragraph avoids
# that extra blank page. Only adjacent top-level text paragraphs are changed;
# Pandoc's empty bookmark boundary nodes may occur between them and are kept.
# Layout spacing, section boundaries, TOC containers and tables are untouched.
normalize_report_page_breaks <- function(doc, ns = word_ns()) {
  is_paragraph <- function(node) {
    !inherits(node, "xml_missing") &&
      length(xml2::xml_find_all(node, "self::w:p", ns)) == 1L
  }
  is_break_paragraph <- function(node) {
    if (!is_paragraph(node)) return(FALSE)
    # Paragraph/run formatting is harmless. Word can also insert the purely
    # informational lastRenderedPageBreak next to the actual manual break.
    invalid <- xml2::xml_find_all(node, paste0(
      "*[not(self::w:pPr or self::w:r)] | ",
      "w:r/*[not(self::w:rPr or self::w:br or self::w:lastRenderedPageBreak)] | ",
      "w:r/w:br[not(@w:type='page')] | ",
      ".//w:sectPr | .//w:bookmarkStart | .//w:bookmarkEnd | ",
      ".//w:pPrChange | .//w:rPrChange"), ns)
    !length(invalid) &&
      length(xml2::xml_find_all(node, "w:r/w:br[@w:type='page']", ns)) == 1L
  }
  is_empty_paragraph <- function(node) {
    if (!is_paragraph(node)) return(FALSE)
    # Used only to detect consecutive manual breaks; these paragraphs are never
    # deleted or crossed when choosing a target for the conversion.
    !length(xml2::xml_find_all(node, paste0(
      "*[not(self::w:pPr or self::w:r)] | ",
      "w:r/*[not(self::w:rPr or self::w:lastRenderedPageBreak)] | ",
      ".//w:sectPr | .//w:pPrChange | .//w:rPrChange"), ns))
  }
  content_sibling <- function(node, direction) {
    path <- paste0(direction, "-sibling::*[1]")
    result <- xml2::xml_find_first(node, path, ns)
    # Before Word opens a Quarto document, section bookmarks are siblings of
    # paragraphs. They are metadata, not printable paragraphs or section breaks.
    # Skip only empty bookmark elements; never move, delete or change the ranges.
    while (!inherits(result, "xml_missing") &&
           length(xml2::xml_find_all(result, "self::w:bookmarkStart | self::w:bookmarkEnd", ns)) &&
           !length(xml2::xml_children(result)) && !nzchar(trimws(xml2::xml_text(result)))) {
      result <- xml2::xml_find_first(result, path, ns)
    }
    result
  }
  for (paragraph in xml2::xml_find_all(doc, "//w:body/w:p", ns)) {
    if (!is_break_paragraph(paragraph)) next
    following <- content_sibling(paragraph, "following")
    if (!is_paragraph(following) ||
        !length(xml2::xml_find_all(following, ".//w:t[normalize-space(.) != '']", ns)) ||
        length(xml2::xml_find_all(following,
          ".//w:sectPr | .//w:br[@w:type='page'] | .//w:drawing | .//w:pict", ns))) next
    # Multiple explicit page breaks may intentionally create a blank page.
    # Do not collapse them, including when separated by empty paragraphs.
    previous <- content_sibling(paragraph, "preceding")
    while (is_empty_paragraph(previous)) {
      previous <- content_sibling(previous, "preceding")
    }
    if (is_paragraph(previous) &&
        length(xml2::xml_find_all(previous, ".//w:br[@w:type='page']", ns))) next
    props <- layout_child(following, "pPr", ns, first = TRUE)
    existing <- xml2::xml_find_all(props, "w:pageBreakBefore", ns)
    if (length(existing) > 1L) xml2::xml_remove(existing[-1L])
    xml2::xml_set_attr(layout_child(props, "pageBreakBefore", ns), "w:val", "1")
    layout_order_children(props, c("pStyle", "keepNext", "keepLines", "pageBreakBefore",
      "framePr", "widowControl", "numPr", "suppressLineNumbers", "pBdr", "shd", "tabs",
      "suppressAutoHyphens", "kinsoku", "wordWrap", "overflowPunct", "topLinePunct",
      "autoSpaceDE", "autoSpaceDN", "bidi", "adjustRightInd", "snapToGrid", "spacing",
      "ind", "contextualSpacing", "mirrorIndents", "suppressOverlap", "jc",
      "textDirection", "textAlignment", "textboxTightWrap", "outlineLvl", "divId",
      "cnfStyle", "rPr", "sectPr", "pPrChange"))
    xml2::xml_remove(paragraph)
  }
  invisible(doc)
}
