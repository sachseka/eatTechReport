page_break_fixture <- function(content) {
  xml2::read_xml(paste0('<w:document xmlns:w="', word_ns()[["w"]],
                        '"><w:body>', content, '</w:body></w:document>'))
}

test_that("standalone breaks become pageBreakBefore while heading content and format survive", {
  doc <- page_break_fixture(paste0(
    '<w:p><w:r><w:t>Previous page</w:t></w:r></w:p>',
    '<w:p><w:pPr><w:spacing w:after="120"/></w:pPr><w:r><w:rPr><w:b/></w:rPr>',
    '<w:lastRenderedPageBreak/><w:br w:type="page"/></w:r></w:p>',
    '<w:p><w:pPr><w:pStyle w:val="Heading1"/><w:keepNext/><w:spacing w:before="360"/>',
    '</w:pPr><w:bookmarkStart w:id="7" w:name="chapter"/><w:r><w:t>Next chapter</w:t>',
    '</w:r><w:bookmarkEnd w:id="7"/></w:p>'))
  ns <- word_ns()
  normalize_report_page_breaks(doc)
  expect_length(xml2::xml_find_all(doc, "//w:body/w:p", ns), 2L)
  expect_length(xml2::xml_find_all(doc, "//w:br|//w:lastRenderedPageBreak", ns), 0L)
  expect_identical(xml2::xml_text(doc), "Previous pageNext chapter")
  props <- xml2::xml_find_first(doc, "//w:body/w:p[2]/w:pPr", ns)
  expect_identical(xml2::xml_attr(xml2::xml_find_first(props, "w:pageBreakBefore", ns), "w:val", ns), "1")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(props, "w:pStyle", ns), "w:val", ns), "Heading1")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(props, "w:spacing", ns), "w:before", ns), "360")
  expect_identical(xml2::xml_name(xml2::xml_children(props)),
                   c("pStyle", "keepNext", "pageBreakBefore", "spacing"))
  expect_length(xml2::xml_find_all(doc, "//w:bookmarkStart|//w:bookmarkEnd", ns), 2L)
  once <- as.character(doc)
  normalize_report_page_breaks(doc)
  expect_identical(as.character(doc), once)
})

test_that("existing pageBreakBefore is enabled without duplicating the property", {
  doc <- page_break_fixture(paste0('<w:p><w:r><w:br w:type="page"/></w:r></w:p>',
    '<w:p><w:pPr><w:pageBreakBefore w:val="0"/></w:pPr><w:r><w:t>Text</w:t></w:r></w:p>'))
  normalize_report_page_breaks(doc)
  nodes <- xml2::xml_find_all(doc, "//w:pageBreakBefore", word_ns())
  expect_length(nodes, 1L)
  expect_identical(xml2::xml_attr(nodes, "w:val", word_ns()), "1")
})

test_that("content, anchors, tracked formatting and section breaks prevent deletion", {
  variants <- c(
    '<w:p><w:r><w:t>Keep</w:t><w:br w:type="page"/></w:r></w:p>',
    '<w:p><w:r><w:t/><w:br w:type="page"/></w:r></w:p>',
    '<w:p><w:bookmarkStart w:id="1" w:name="keep"/><w:r><w:br w:type="page"/></w:r></w:p>',
    '<w:p><w:r><w:br w:type="page"/><w:drawing/></w:r></w:p>',
    '<w:p><w:r><w:br w:type="page"/><w:fldChar w:fldCharType="begin"/></w:r></w:p>',
    '<w:p><w:pPr><w:sectPr/></w:pPr><w:r><w:br w:type="page"/></w:r></w:p>',
    '<w:p><w:pPr><w:pPrChange/></w:pPr><w:r><w:br w:type="page"/></w:r></w:p>',
    '<w:p><w:r><w:rPr><w:rPrChange/></w:rPr><w:br w:type="page"/></w:r></w:p>',
    '<w:p><w:r><w:br w:type="page"/><w:br/></w:r></w:p>',
    '<w:p><w:r><w:br w:type="column"/></w:r></w:p>')
  for (variant in variants) {
    doc <- page_break_fixture(paste0(variant, '<w:p><w:r><w:t>Text</w:t></w:r></w:p>'))
    before <- as.character(doc)
    normalize_report_page_breaks(doc)
    expect_identical(as.character(doc), before)
  }
})

test_that("tables, TOC containers, empty paragraphs and section boundaries are not crossed", {
  break_p <- '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'
  text_p <- '<w:p><w:r><w:t>Text</w:t></w:r></w:p>'
  obstacles <- c('<w:tbl><w:tr><w:tc><w:p/></w:tc></w:tr></w:tbl>',
    '<w:sdt><w:sdtContent><w:p><w:r><w:t>TOC</w:t></w:r></w:p></w:sdtContent></w:sdt>',
    '<w:sectPr/>', '<w:p/>', '<w:p><w:pPr><w:spacing w:after="240"/></w:pPr></w:p>',
    '<w:p><w:pPr><w:sectPr/></w:pPr></w:p>')
  for (obstacle in obstacles) {
    doc <- page_break_fixture(paste0(break_p, obstacle, text_p))
    before <- as.character(doc)
    normalize_report_page_breaks(doc)
    expect_identical(as.character(doc), before)
  }
  for (target in c('<w:p><w:pPr><w:sectPr/></w:pPr><w:r><w:t>Text</w:t></w:r></w:p>',
                   '<w:p><w:r><w:t>Text</w:t><w:drawing/></w:r></w:p>')) {
    doc <- page_break_fixture(paste0(break_p, target))
    before <- as.character(doc)
    normalize_report_page_breaks(doc)
    expect_identical(as.character(doc), before)
  }
})

test_that("consecutive explicit page breaks retain intentionally empty pages", {
  break_p <- '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'
  for (separation in c('', '<w:p/>', '<w:p/><w:p/>')) {
    doc <- page_break_fixture(paste0(break_p, separation, break_p,
      '<w:p><w:r><w:t>Text</w:t></w:r></w:p>'))
    before <- as.character(doc)
    normalize_report_page_breaks(doc)
    expect_identical(as.character(doc), before)
  }
  doc <- page_break_fixture(paste0('<w:p><w:r><w:br w:type="page"/><w:br w:type="page"/></w:r></w:p>',
                                  '<w:p><w:r><w:t>Text</w:t></w:r></w:p>'))
  before <- as.character(doc)
  normalize_report_page_breaks(doc)
  expect_identical(as.character(doc), before)
  doc <- page_break_fixture(paste0('<w:p><w:r><w:br w:type="page"/><w:br w:type="page"/></w:r></w:p>',
    break_p, '<w:p><w:r><w:t>Text</w:t></w:r></w:p>'))
  before <- as.character(doc)
  normalize_report_page_breaks(doc)
  expect_identical(as.character(doc), before)
})

test_that("page breaks inside tables or structured content are left untouched", {
  content <- paste0('<w:p><w:r><w:br w:type="page"/></w:r></w:p>',
                    '<w:p><w:r><w:t>Text</w:t></w:r></w:p>')
  for (wrapper in c(paste0('<w:tbl><w:tr><w:tc>', content, '</w:tc></w:tr></w:tbl>'),
                     paste0('<w:sdt><w:sdtContent>', content, '</w:sdtContent></w:sdt>'))) {
    doc <- page_break_fixture(wrapper)
    before <- as.character(doc)
    normalize_report_page_breaks(doc)
    expect_identical(as.character(doc), before)
  }
})

test_that("Quarto pre-Word section bookmarks do not hide the following heading", {
  # Reproduces Quarto's actual DOCX for two labelled headings separated by
  # {{< pagebreak >}}. Word later relocates these bookmarks into paragraphs.
  doc <- page_break_fixture(paste0(
    '<w:bookmarkStart w:id="20" w:name="previous"/>',
    '<w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t>Previous</w:t></w:r></w:p>',
    '<w:p><w:r><w:t>Previous text</w:t></w:r></w:p>',
    '<w:p><w:r><w:br w:type="page"/></w:r></w:p>',
    '<w:bookmarkEnd w:id="20"/><w:bookmarkStart w:id="21" w:name="following"/>',
    '<w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t>Following</w:t></w:r></w:p>',
    '<w:p><w:r><w:t>Following text</w:t></w:r></w:p>',
    '<w:bookmarkEnd w:id="21"/><w:sectPr/>'))
  ns <- word_ns()
  bookmark_path <- "//w:bookmarkStart | //w:bookmarkEnd"
  bookmarks <- as.character(xml2::xml_find_all(doc, bookmark_path, ns))
  text <- xml2::xml_text(doc)
  normalize_report_page_breaks(doc)
  expect_length(xml2::xml_find_all(doc, "//w:br[@w:type='page']", ns), 0L)
  expect_length(xml2::xml_find_all(doc, "//w:p[w:r/w:t='Following']/w:pPr/w:pageBreakBefore[@w:val='1']", ns), 1L)
  expect_identical(as.character(xml2::xml_find_all(doc, bookmark_path, ns)), bookmarks)
  expect_identical(xml2::xml_text(doc), text)
  expect_length(xml2::xml_find_all(doc, "//w:body/w:sectPr", ns), 1L)
  once <- as.character(doc)
  normalize_report_page_breaks(doc)
  expect_identical(as.character(doc), once)
})

test_that("bookmarks do not permit crossing content barriers or collapsing repeated breaks", {
  break_p <- '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'
  bookmarks <- '<w:bookmarkEnd w:id="20"/><w:bookmarkStart w:id="21" w:name="following"/>'
  text_p <- '<w:p><w:r><w:t>Text</w:t></w:r></w:p>'
  obstacles <- c('<w:p/>', '<w:sectPr/>', '<w:tbl/>', '<w:sdt/>',
                 '<w:bookmarkStart w:id="22" w:name="nonempty"><w:r><w:t>Keep</w:t></w:r></w:bookmarkStart>')
  for (obstacle in obstacles) {
    doc <- page_break_fixture(paste0(break_p, bookmarks, obstacle, text_p))
    before <- as.character(doc)
    normalize_report_page_breaks(doc)
    expect_identical(as.character(doc), before)
  }
  for (blank in c('', '<w:p/>')) {
    doc <- page_break_fixture(paste0(break_p, bookmarks, blank, break_p, text_p))
    before <- as.character(doc)
    normalize_report_page_breaks(doc)
    expect_identical(as.character(doc), before)
  }
})
