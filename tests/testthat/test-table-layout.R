table_layout_report <- function(wrapped = FALSE) {
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
