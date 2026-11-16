table_layout_report <- function(wrapped = FALSE, before_style = NULL) {
  ns <- word_ns()
  template <- tempfile(fileext = ".dotx")
  synthetic_word_template(template)
  parts <- tempfile("table-layout-fixture-")
  extract_word_package(template, parts)
  document_path <- file.path(parts, "word/document.xml")
  doc <- xml2::read_xml(document_path)
  body <- xml2::xml_find_first(doc, "w:body", ns)
  cells <- function(label) paste0(
    '<w:tc><w:tcPr><w:tcMar><w:top w:w="0" w:type="dxa"/>',
    '<w:left w:w="80" w:type="dxa"/><w:bottom w:w="160" w:type="dxa"/>',
    '</w:tcMar><w:vAlign w:val="top"/></w:tcPr>',
    '<w:p><w:pPr><w:spacing w:before="0" w:after="240" w:afterLines="100"/></w:pPr>',
    '<w:r><w:t>', label, '</w:t></w:r></w:p></w:tc>')
  rows <- paste0('<w:tr>', cells(c("Long heading", "First value", "Second value")),
                 cells(c("N", "12", "24")), '</w:tr>', collapse = "")
  table <- paste0('<w:tbl>', rows, '</w:tbl>')
  if (wrapped) {
    table <- paste0('<w:tbl><w:tr><w:tc><w:tcPr><w:vAlign w:val="top"/>',
      '<w:tcMar><w:top w:w="0" w:type="dxa"/></w:tcMar></w:tcPr>',
      '<w:p><w:pPr><w:pStyle w:val="TableCaption"/></w:pPr>',
      '<w:r><w:t>Table caption</w:t></w:r></w:p>', table, '<w:p/>',
      '</w:tc></w:tr></w:tbl>')
  }
  table <- sub('<w:tbl>', paste0('<w:tbl xmlns:w="', ns[["w"]], '">'), table, fixed = TRUE)
  xml2::xml_add_child(body, xml2::read_xml(table), .where = 0)
  if (!is.null(before_style)) {
    paragraph <- paste0('<w:p xmlns:w="', ns[["w"]], '"><w:pPr><w:pStyle w:val="',
      before_style, '"/><w:keepNext/></w:pPr><w:r><w:t>Introductory paragraph</w:t></w:r></w:p>')
    xml2::xml_add_child(body, xml2::read_xml(paragraph), .where = 0)
  }
  xml2::write_xml(doc, document_path)
  report <- tempfile(fileext = ".docx")
  pack_word_package(parts, report)
  finalise_report_docx(report)
  output <- tempfile("table-layout-result-")
  extract_word_package(report, output)
  xml2::read_xml(file.path(output, "word/document.xml"))
}

test_that("data cells compensate Word line leading and retain thin row rules", {
  doc <- table_layout_report()
  ns <- word_ns()
  table <- xml2::xml_find_first(doc, "//w:tbl", ns)
  cells <- xml2::xml_find_all(table, "w:tr/w:tc", ns)
  expect_length(cells, 6L)
  expect_true(all(xml2::xml_attr(xml2::xml_find_all(cells, "w:tcPr/w:vAlign", ns), "w:val", ns) == "center"))
  for (side in c("top", "bottom")) {
    margins <- xml2::xml_find_all(cells, paste0("w:tcPr/w:tcMar/w:", side), ns)
    expect_identical(xml2::xml_attr(margins, "w:w", ns),
                     rep(if (side == "top") "130" else "0", 6L))
    expect_true(all(xml2::xml_attr(margins, "w:type", ns) == "dxa"))
  }
  expect_identical(xml2::xml_attr(xml2::xml_find_all(cells, "w:tcPr/w:tcMar/w:left", ns),
                                 "w:w", ns), rep("80", 6L))
  spacing <- xml2::xml_find_all(cells, "w:p/w:pPr/w:spacing", ns)
  expect_identical(xml2::xml_attr(spacing, "w:before", ns), rep("0", 6L))
  expect_identical(xml2::xml_attr(spacing, "w:after", ns), rep("0", 6L))
  expect_true(all(is.na(xml2::xml_attr(spacing, "w:afterLines", ns))))
  expect_identical(xml2::xml_attr(spacing, "w:line", ns), rep("360", 6L))
  expect_identical(xml2::xml_attr(spacing, "w:lineRule", ns), rep("auto", 6L))
  header_rule <- xml2::xml_find_all(table, "w:tr[1]/w:tc/w:tcPr/w:tcBorders/w:bottom", ns)
  body_rule <- xml2::xml_find_all(table, "w:tr[2]/w:tc/w:tcPr/w:tcBorders/w:bottom", ns)
  expect_identical(xml2::xml_attr(header_rule, "w:sz", ns), c("4", "4"))
  expect_identical(xml2::xml_attr(header_rule, "w:color", ns), c("000000", "000000"))
  expect_identical(xml2::xml_attr(body_rule, "w:sz", ns), c("4", "4"))
  expect_identical(xml2::xml_attr(body_rule, "w:color", ns), c("B3B3B3", "B3B3B3"))
  expect_true(all(c(xml2::xml_attr(header_rule, "w:val", ns),
                    xml2::xml_attr(body_rule, "w:val", ns)) == "single"))
  outer <- xml2::xml_find_all(table,
    "w:tr[1]/w:tc/w:tcPr/w:tcBorders/w:top | w:tr[last()]/w:tc/w:tcPr/w:tcBorders/w:bottom", ns)
  expect_identical(xml2::xml_attr(outer, "w:sz", ns), rep("12", 4L))
  verticals <- xml2::xml_find_all(cells, "w:tcPr/w:tcBorders/w:left | w:tcPr/w:tcBorders/w:right", ns)
  expect_true(all(xml2::xml_attr(verticals, "w:val", ns) == "nil"))
  expect_identical(xml2::xml_text(table), "Long headingNFirst value12Second value24")
})

test_that("caption wrapper tables stay unpadded and unruled around formatted data", {
  doc <- table_layout_report(wrapped = TRUE)
  ns <- word_ns()
  wrapper <- xml2::xml_find_first(doc, "//w:tbl[.//w:tbl]", ns)
  expect_true(all(xml2::xml_attr(xml2::xml_find_all(wrapper, "w:tblPr/w:tblBorders/*", ns),
                                "w:val", ns) == "nil"))
  expect_identical(xml2::xml_attr(xml2::xml_find_first(wrapper, "w:tr/w:tc/w:tcPr/w:vAlign", ns),
                                 "w:val", ns), "top")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(wrapper, "w:tr/w:tc/w:tcPr/w:tcMar/w:top", ns),
                                 "w:w", ns), "0")
  expect_length(xml2::xml_find_all(wrapper, "w:tr/w:tc/w:tcPr/w:tcBorders", ns), 0L)
  inner <- xml2::xml_find_first(wrapper, ".//w:tbl", ns)
  expect_length(xml2::xml_find_all(inner, "w:tr/w:tc/w:tcPr/w:vAlign[@w:val='center']", ns), 6L)
  expect_length(xml2::xml_find_all(inner, "w:tr/w:tc/w:tcPr/w:tcBorders/w:bottom[@w:sz='4']", ns), 4L)
  caption <- xml2::xml_find_first(wrapper, "w:tr/w:tc/w:p[w:r/w:t='Table caption']", ns)
  expect_identical(xml2::xml_attr(xml2::xml_find_first(caption, "w:pPr/w:spacing", ns),
                                 "w:after", ns), "40")
})

test_that("body introductions can end before a table while captions and headings stay attached", {
  ns <- word_ns()
  for (wrapped in c(FALSE, TRUE)) {
    doc <- table_layout_report(wrapped = wrapped, before_style = "FirstParagraph")
    paragraph <- xml2::xml_find_first(doc, "//w:body/w:p[w:r/w:t='Introductory paragraph']", ns)
    expect_identical(xml2::xml_attr(xml2::xml_find_first(paragraph, "w:pPr/w:keepNext", ns), "w:val", ns), "0")
    expect_identical(xml2::xml_attr(xml2::xml_find_first(paragraph, "w:pPr/w:spacing", ns), "w:after", ns), "120")
    if (wrapped) {
      caption <- xml2::xml_find_first(doc, "//w:p[w:r/w:t='Table caption']", ns)
      expect_identical(xml2::xml_attr(xml2::xml_find_first(caption, "w:pPr/w:keepNext", ns), "w:val", ns), "1")
    }
  }
  for (style in c("TableCaption", "Heading2", "Heading", "CustomHeading")) {
    doc <- table_layout_report(before_style = style)
    paragraph <- xml2::xml_find_first(doc, "//w:body/w:p[w:r/w:t='Introductory paragraph']", ns)
    expect_identical(xml2::xml_attr(xml2::xml_find_first(paragraph, "w:pPr/w:keepNext", ns), "w:val", ns), "1")
  }
})

test_that("table spacing respects custom bindings and standalone bold labels", {
  ns <- word_ns()
  make_paragraph <- function(style, keep, runs) {
    xml2::read_xml(paste0('<w:body xmlns:w="', ns[["w"]], '"><w:p><w:pPr>',
      if (!is.null(style)) paste0('<w:pStyle w:val="', style, '"/>') else "",
      keep, '</w:pPr>', runs, '</w:p><w:tbl/></w:body>'))
  }
  text <- '<w:r><w:t>Introduction</w:t></w:r>'
  for (keep in c("", '<w:keepNext w:val="0"/>', '<w:keepNext w:val="true"/>')) {
    doc <- make_paragraph("CustomParagraph", keep, text)
    before <- as.character(xml2::xml_find_first(doc, "w:p/w:pPr/w:keepNext", ns))
    space_report_table(xml2::xml_find_first(doc, "w:tbl", ns), NULL, ns)
    expect_identical(as.character(xml2::xml_find_first(doc, "w:p/w:pPr/w:keepNext", ns)), before)
  }
  for (style in list(NULL, "Normal", "Standard", "BodyText", "FirstParagraph")) {
    doc <- make_paragraph(style, '<w:keepNext/>', text)
    space_report_table(xml2::xml_find_first(doc, "w:tbl", ns), NULL, ns)
    expect_identical(xml2::xml_attr(xml2::xml_find_first(doc, "w:p/w:pPr/w:keepNext", ns), "w:val", ns), "0")
  }
  for (bold in c("", ' w:val="false"')) {
    label <- paste0('<w:r><w:rPr><w:b', bold, '/></w:rPr><w:t>Domain label</w:t></w:r>')
    doc <- make_paragraph("BodyText", '<w:keepNext/>', label)
    space_report_table(xml2::xml_find_first(doc, "w:tbl", ns), NULL, ns)
    expect_identical(xml2::xml_attr(xml2::xml_find_first(doc, "w:p/w:pPr/w:keepNext", ns), "w:val", ns),
                     if (bold == "") "1" else "0")
  }
})
