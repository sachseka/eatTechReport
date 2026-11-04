design_layout_fixture <- function() {
  cell <- function(label, style) paste0('<w:tc><w:tcPr><w:tcW w:w="1000" w:type="dxa"/>',
    '<w:shd w:fill="FFFF00"/></w:tcPr><w:p><w:r><w:rPr><w:rStyle w:val="',
    style, '"/></w:rPr><w:t>', label, '</w:t></w:r></w:p></w:tc>')
  headers <- c("Testheft", "Block 1", " ", "Block 2")
  header_styles <- c("EatDesignHeader", "EatDesignHeader", "EatDesignPauseHeader", "EatDesignHeader")
  contents <- c("H1", "A", " ", "Link B")
  styles <- c("EatDesignBooklet", "EatDesignBlock", "EatDesignPause", "EatDesignNorming")
  xml2::read_xml(paste0('<w:document xmlns:w="', word_ns()[["w"]], '"><w:body>',
    '<w:tbl><w:tblPr/><w:tblGrid><w:gridCol w:w="1000"/></w:tblGrid><w:tr>',
    paste(mapply(cell, headers, header_styles), collapse = ""), '</w:tr><w:tr>',
    paste(mapply(cell, contents, styles), collapse = ""), '</w:tr></w:tbl>',
    '<w:tbl><w:tr><w:tc><w:p><w:r><w:t>Block 1</w:t></w:r></w:p></w:tc></w:tr></w:tbl>',
    '</w:body></w:document>'))
}

test_that("owned design matrices shade norming cells and keep a narrow blank pause", {
  doc <- design_layout_fixture()
  ns <- word_ns()
  unrelated <- as.character(xml2::xml_find_all(doc, "//w:tbl", ns)[[2L]])
  format_report_design_tables(doc)
  tables <- xml2::xml_find_all(doc, "//w:tbl", ns)
  expect_identical(as.character(tables[[2L]]), unrelated)
  table <- tables[[1L]]
  widths <- as.integer(xml2::xml_attr(xml2::xml_find_all(table, "w:tblGrid/w:gridCol", ns), "w:w", ns))
  expect_equal(widths[3L], round(0.25 / 2.54 * 1440))
  expect_true(all(widths[-3L] > 8 * widths[3L]))
  expect_equal(sum(widths), as.integer(xml2::xml_attr(xml2::xml_find_first(table, "w:tblPr/w:tblW", ns), "w:w", ns)))
  rows <- xml2::xml_find_all(table, "w:tr", ns)
  for (row in rows) {
    cells <- xml2::xml_find_all(row, "w:tc", ns)
    expect_length(xml2::xml_find_all(cells[[3L]], ".//w:t", ns), 0L)
    expect_identical(xml2::xml_attr(xml2::xml_find_first(cells[[3L]], "w:tcPr/w:shd", ns), "w:fill", ns), "FFFFFF")
    expect_identical(xml2::xml_attr(xml2::xml_find_first(cells[[3L]], "w:tcPr/w:tcMar/w:left", ns), "w:w", ns), "0")
  }
  cells <- xml2::xml_find_all(rows[[2L]], "w:tc", ns)
  fills <- xml2::xml_attr(xml2::xml_find_first(cells, "w:tcPr/w:shd", ns), "w:fill", ns)
  expect_identical(fills, c("FFFFFF", "FFFFFF", "FFFFFF", "C9C9C9"))
  expect_true(all(xml2::xml_attr(xml2::xml_find_first(cells, "w:tcPr/w:vAlign", ns), "w:val", ns) == "center"))
  expect_identical(xml2::xml_attr(xml2::xml_find_first(rows[[1L]], "w:trPr/w:tblHeader", ns), "w:val", ns), "1")
  expect_length(xml2::xml_find_all(table, "w:tr/w:trPr/w:cantSplit", ns), 2L)
  final <- as.character(doc)
  format_report_design_tables(doc)
  expect_identical(as.character(doc), final)
})

test_that("design recognition does not style a Quarto wrapper and rejects broken marked grids", {
  ns <- word_ns()
  doc <- design_layout_fixture()
  outer <- xml2::read_xml(paste0('<w:tbl xmlns:w="', ns[["w"]],
    '"><w:tr><w:tc><w:p><w:r><w:t>Caption</w:t></w:r></w:p></w:tc></w:tr></w:tbl>'))
  inner <- xml2::xml_find_first(doc, "//w:tbl", ns)
  xml2::xml_add_child(xml2::xml_find_first(outer, "w:tr/w:tc", ns), inner)
  format_report_design_tables(outer)
  expect_length(xml2::xml_find_all(outer, "w:tblPr|w:tblGrid", ns), 0L)
  expect_length(xml2::xml_find_all(outer, ".//w:tbl/w:tblGrid/w:gridCol", ns), 4L)
  broken <- design_layout_fixture()
  xml2::xml_remove(xml2::xml_find_first(broken, "//w:tbl[1]/w:tr[2]/w:tc[4]", ns))
  expect_error(format_report_design_tables(broken), "gleich viele unverbundene Zellen")
})
