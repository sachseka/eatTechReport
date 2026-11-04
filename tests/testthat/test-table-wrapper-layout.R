long_matrix_wrapper_fixture <- function(marker = "EatTaskMatrix", n_rows = 10L, raw = FALSE) {
  cell <- function(text, style = NULL) paste0('<w:tc><w:tcPr><w:tcW w:w="3000" w:type="dxa"/></w:tcPr>',
    '<w:p><w:r>', if (!is.null(style)) paste0('<w:rPr><w:rStyle w:val="', style, '"/></w:rPr>'),
    '<w:t>', text, '</w:t></w:r></w:p></w:tc>')
  header <- paste0('<w:tr><w:trPr><w:tblHeader/></w:trPr>', cell("Nr.", marker),
                    cell("Module", "EatTaskSupplement"), '</w:tr>')
  rows <- vapply(seq_len(n_rows - 1L), function(i) paste0('<w:tr>', cell(i), cell(paste("Task", i)), '</w:tr>'), "")
  table <- paste0('<w:tbl><w:tblPr><w:tblW w:w="5000" w:type="pct"/></w:tblPr>',
    '<w:tblGrid><w:gridCol w:w="3000"/><w:gridCol w:w="3000"/></w:tblGrid>',
    header, paste(rows, collapse = ""), '</w:tbl>')
  doc <- xml2::read_xml(paste0('<w:document xmlns:w="', word_ns()[["w"]], '"><w:body>',
    '<w:p><w:r><w:t>See the task matrix.</w:t></w:r></w:p>',
    '<w:tbl><w:tr><w:tc><w:p><w:pPr><w:pStyle w:val="ImageCaption"/></w:pPr>',
    '<w:bookmarkStart w:id="7" w:name="tbl-long-matrix"/><w:r><w:t>Table caption.</w:t></w:r>',
    '</w:p>', table, '<w:p/></w:tc></w:tr></w:tbl>',
    '<w:p><w:bookmarkEnd w:id="7"/><w:r><w:t>Table note.</w:t></w:r></w:p>',
    '</w:body></w:document>'))
  if (raw) {
    ns <- word_ns()
    cell <- xml2::xml_find_first(doc, "//w:body/w:tbl/w:tr/w:tc", ns)
    caption <- xml2::xml_find_first(cell, "w:p[1]", ns)
    start <- xml2::xml_find_first(caption, "w:bookmarkStart", ns)
    end <- xml2::xml_find_first(doc, "//w:body/w:p/w:bookmarkEnd", ns)
    xml2::xml_add_sibling(caption, start, .where = "before")
    xml2::xml_add_sibling(xml2::xml_find_first(cell, "w:tbl", ns), end, .where = "after")
    xml2::xml_remove(start)
    xml2::xml_remove(end)
  }
  doc
}

test_that("long owned matrices become body tables with original captions, bookmarks and widths", {
  ns <- word_ns()
  for (marker in c("EatTaskMatrix", "EatDesignHeader")) {
    doc <- long_matrix_wrapper_fixture(marker)
    before_text <- xml2::xml_text(doc)
    inner <- xml2::xml_find_first(doc, "//w:tbl/w:tr/w:tc/w:tbl", ns)
    widths <- xml2::xml_attr(xml2::xml_find_all(inner, "w:tblGrid/w:gridCol", ns), "w:w", ns)
    unwrap_report_table_wrappers(doc)
    expect_length(xml2::xml_find_all(doc, "//w:body/w:tbl", ns), 1L)
    expect_length(xml2::xml_find_all(doc, "//w:tbl//w:tbl", ns), 0L)
    expect_identical(xml2::xml_text(doc), before_text)
    expect_identical(xml2::xml_name(xml2::xml_children(xml2::xml_find_first(doc, "w:body", ns))),
                     c("p", "p", "tbl", "p"))
    expect_identical(xml2::xml_attr(xml2::xml_find_all(doc, "//w:tbl/w:tblGrid/w:gridCol", ns), "w:w", ns), widths)
    expect_identical(xml2::xml_attr(xml2::xml_find_first(doc, "//w:bookmarkStart", ns), "w:name", ns), "tbl-long-matrix")
    expect_identical(xml2::xml_attr(xml2::xml_find_first(doc, "//w:bookmarkEnd", ns), "w:id", ns), "7")
    expect_length(xml2::xml_find_all(doc, "//w:body/w:tbl/w:tr[1]/w:trPr/w:tblHeader", ns), 1L)
    once <- as.character(doc)
    unwrap_report_table_wrappers(doc)
    expect_identical(as.character(doc), once)
  }
})

test_that("raw Quarto cell-level bookmark boundaries move with the complete matrix", {
  ns <- word_ns()
  doc <- long_matrix_wrapper_fixture(raw = TRUE)
  before_text <- xml2::xml_text(doc)
  unwrap_report_table_wrappers(doc)
  expect_identical(xml2::xml_name(xml2::xml_children(xml2::xml_find_first(doc, "w:body", ns))),
                   c("p", "bookmarkStart", "p", "tbl", "bookmarkEnd", "p"))
  expect_identical(xml2::xml_text(doc), before_text)
  expect_identical(xml2::xml_attr(xml2::xml_find_first(doc, "//w:body/w:bookmarkStart", ns), "w:name", ns),
                   "tbl-long-matrix")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(doc, "//w:body/w:bookmarkEnd", ns), "w:id", ns), "7")
  after <- xml2::xml_find_first(doc, "//w:body/w:p[last()]/w:pPr/w:spacing", ns)
  expect_identical(xml2::xml_attr(after, "w:before", ns), "120")
  mismatched <- long_matrix_wrapper_fixture(raw = TRUE)
  xml2::xml_set_attr(xml2::xml_find_first(mismatched, "//w:bookmarkEnd", ns), "w:id", "9")
  before <- as.character(mismatched)
  unwrap_report_table_wrappers(mismatched)
  expect_identical(as.character(mismatched), before)
})

test_that("short, unowned, nested and content-bearing layout tables remain untouched", {
  ns <- word_ns()
  cases <- list(short = long_matrix_wrapper_fixture(n_rows = 8L),
                unowned = long_matrix_wrapper_fixture(marker = "OtherHeader"))
  for (variant in c("extra", "bookmark", "wrapper_bookmark", "figure", "nested", "foreign_caption", "multiple_cells")) {
    doc <- long_matrix_wrapper_fixture()
    outer <- xml2::xml_find_first(doc, "//w:body/w:tbl", ns)
    cell <- xml2::xml_find_first(outer, "w:tr/w:tc", ns)
    if (variant == "extra") xml2::xml_add_child(cell, "w:p")
    if (variant == "bookmark") xml2::xml_add_child(xml2::xml_find_first(cell, "w:p[last()]", ns), "w:bookmarkEnd")
    if (variant == "wrapper_bookmark") xml2::xml_add_child(outer, "w:bookmarkEnd")
    if (variant == "figure") xml2::xml_add_child(xml2::xml_find_first(cell, "w:p/w:r", ns), "w:drawing")
    if (variant == "foreign_caption") xml2::xml_set_attr(xml2::xml_find_first(cell, "w:p/w:bookmarkStart", ns), "w:name", "foreign-table")
    if (variant == "multiple_cells") xml2::xml_add_child(xml2::xml_find_first(outer, "w:tr", ns), "w:tc")
    if (variant == "nested") {
      wrapper <- xml2::xml_add_child(xml2::xml_find_first(doc, "w:body", ns), "w:tbl")
      target <- xml2::xml_add_child(xml2::xml_add_child(wrapper, "w:tr"), "w:tc")
      xml2::xml_add_child(target, outer)
      xml2::xml_remove(outer)
    }
    cases[[variant]] <- doc
  }
  for (doc in cases) {
    before <- as.character(doc)
    unwrap_report_table_wrappers(doc)
    expect_identical(as.character(doc), before)
  }
})

test_that("document finalisation formats promoted matrices with native repeating headers", {
  ns <- word_ns()
  report <- tempfile(fileext = ".docx")
  synthetic_word_template(report)
  parts <- tempfile("long-table-parts-")
  extract_word_package(report, parts)
  xml2::write_xml(long_matrix_wrapper_fixture(raw = TRUE), file.path(parts, "word/document.xml"))
  pack_word_package(parts, report)
  finalise_report_docx(report)
  final <- tempfile("long-table-final-")
  extract_word_package(report, final)
  doc <- xml2::read_xml(file.path(final, "word/document.xml"))
  expect_length(xml2::xml_find_all(doc, "//w:body/w:tbl/w:tr", ns), 10L)
  expect_length(xml2::xml_find_all(doc, "//w:tbl//w:tbl", ns), 0L)
  expect_length(xml2::xml_find_all(doc, "//w:body/w:tbl/w:tr[1]/w:trPr/w:tblHeader", ns), 1L)
  caption <- xml2::xml_find_first(doc, "//w:body/w:p[w:pPr/w:pStyle/@w:val='ImageCaption']", ns)
  expect_identical(xml2::xml_attr(xml2::xml_find_first(caption, "w:pPr/w:keepNext", ns), "w:val", ns), "1")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(caption, "w:pPr/w:spacing", ns), "w:after", ns), "40")
  expect_identical(xml2::xml_attr(xml2::xml_find_all(doc, "//w:body/w:tbl/w:tr[1]/w:tc/w:tcPr/w:shd", ns), "w:fill", ns),
                   c("534856", "00818D"))
})
