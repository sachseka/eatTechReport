figure_layout_fixture <- function(caption_id = "ImageCaption", caption_name = "Image Caption") {
  ns <- report_figure_ns()
  declarations <- paste0('xmlns:', names(ns), '="', ns, '"', collapse = " ")
  doc <- xml2::read_xml(paste0('<w:document ', declarations, '><w:body>',
    '<w:tbl><w:tblPr><w:tblW w:w="5000" w:type="pct"/>',
    '<w:tblStyle w:val="TestTable"/><w:tblBorders><w:top w:val="single"/>',
    '</w:tblBorders></w:tblPr><w:tblGrid><w:gridCol w:w="9070"/></w:tblGrid>',
    '<w:tr><w:trPr><w:tblHeader/><w:trHeight w:val="100"/></w:trPr>',
    '<w:tc><w:tcPr><w:tcW w:w="7920" w:type="dxa"/>',
    '<w:tcBorders><w:top w:val="single"/></w:tcBorders><w:shd w:fill="F2F2F2"/>',
    '<w:tcMar><w:top w:w="130" w:type="dxa"/></w:tcMar></w:tcPr>',
    '<w:p><w:pPr><w:pStyle w:val="Compact"/></w:pPr>',
    '<w:bookmarkStart w:id="42" w:name="fig-item-levels-selection-dl"/>',
    '<w:r><w:drawing><wp:inline><wp:extent cx="5334000" cy="2820024"/>',
    '<a:graphic><a:graphicData><pic:pic><pic:nvPicPr>',
    '<pic:cNvPr descr="figures/item-levels-selection-DL.png"/>',
    '</pic:nvPicPr><pic:spPr><a:xfrm><a:ext cx="5334000" cy="2820024"/>',
    '</a:xfrm></pic:spPr></pic:pic></a:graphicData></a:graphic>',
    '</wp:inline></w:drawing></w:r></w:p>',
    '<w:p><w:pPr><w:pStyle w:val="', caption_id, '"/>',
    '<w:keepNext w:val="1"/></w:pPr><w:r><w:t>Figure caption</w:t></w:r></w:p>',
    '</w:tc><w:bookmarkEnd w:id="42"/></w:tr></w:tbl>',
    '<w:tbl><w:tr><w:tc><w:p><w:r><w:t>Data table</w:t></w:r></w:p>',
    '</w:tc></w:tr></w:tbl></w:body></w:document>'))
  styles <- xml2::read_xml(paste0('<w:styles xmlns:w="', ns[["w"]], '">',
    '<w:style w:type="paragraph" w:styleId="', caption_id, '">',
    '<w:name w:val="', caption_name, '"/></w:style></w:styles>'))
  list(doc = doc, styles = styles, ns = ns)
}

test_that("captioned item figures retain their requested size without table decoration", {
  fixture <- figure_layout_fixture()
  ns <- fixture$ns
  doc <- fixture$doc
  untouched <- as.character(xml2::xml_find_all(doc, "//w:tbl", ns)[[2L]])
  finalise_report_figures(doc, fixture$styles)
  table <- xml2::xml_find_all(doc, "//w:tbl", ns)[[1L]]
  expect_true(is_report_figure_table(table, fixture$styles))
  expect_length(xml2::xml_find_all(table, "w:tblPr/w:tblStyle|w:tr/w:trPr/w:tblHeader|w:tr/w:trPr/w:trHeight", ns), 0L)
  borders <- xml2::xml_find_all(table, "w:tblPr/w:tblBorders/*|w:tr/w:tc/w:tcPr/w:tcBorders/*", ns)
  expect_length(borders, 12L)
  expect_true(all(xml2::xml_attr(borders, "w:val", ns) == "nil"))
  shade <- xml2::xml_find_first(table, "w:tr/w:tc/w:tcPr/w:shd", ns)
  expect_identical(xml2::xml_attr(shade, "w:fill", ns), "auto")
  margins <- xml2::xml_find_all(table, "w:tblPr/w:tblCellMar/*|w:tr/w:tc/w:tcPr/w:tcMar/*", ns)
  expect_length(margins, 12L)
  expect_true(all(xml2::xml_attr(margins, "w:w", ns) == "0"))
  widths <- xml2::xml_find_all(table, "w:tblPr/w:tblW|w:tblGrid/w:gridCol|w:tr/w:tc/w:tcPr/w:tcW", ns)
  expect_identical(xml2::xml_attr(widths, "w:w", ns), rep("8787", 3L))
  extents <- xml2::xml_find_all(table, ".//wp:extent|.//pic:spPr/a:xfrm/a:ext", ns)
  expect_identical(xml2::xml_attr(extents, "cx"), rep("5580000", 2L))
  expect_equal(as.numeric(xml2::xml_attr(extents, "cy")), rep(round(2820024 * 5580000 / 5334000), 2L))
  keep <- xml2::xml_find_all(table, "w:tr/w:tc/w:p/w:pPr/w:keepNext", ns)
  expect_identical(xml2::xml_attr(keep, "w:val", ns), c("1", "0"))
  expect_length(xml2::xml_find_all(table, "w:tr/w:trPr/w:cantSplit", ns), 1L)
  expect_identical(xml2::xml_attr(xml2::xml_find_all(table, ".//w:keepLines", ns), "w:val", ns), c("1", "1"))
  expect_identical(xml2::xml_attr(xml2::xml_find_first(table, ".//w:bookmarkStart", ns), "w:name", ns),
                   "fig-item-levels-selection-dl")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(table, ".//w:bookmarkEnd", ns), "w:id", ns), "42")
  expect_identical(xml2::xml_text(table), "Figure caption")
  expect_identical(as.character(xml2::xml_find_all(doc, "//w:tbl", ns)[[2L]]), untouched)
  once <- as.character(doc)
  finalise_report_figures(doc, fixture$styles)
  expect_identical(as.character(doc), once)
})

test_that("figure recognition resolves caption style names and avoids unrelated tables", {
  fixture <- figure_layout_fixture("LocalImageLabel", "iMaGe cApTiOn")
  table <- xml2::xml_find_first(fixture$doc, "//w:tbl", fixture$ns)
  expect_true(is_report_figure_table(table, fixture$styles))
  expect_false(is_report_figure_table(table, NULL))
  data <- xml2::xml_find_all(fixture$doc, "//w:tbl", fixture$ns)[[2L]]
  expect_false(is_report_figure_table(data, fixture$styles))
  picture <- xml2::xml_find_first(table, ".//pic:cNvPr", fixture$ns)
  xml2::xml_set_attr(picture, "descr", "figures/unrelated-picture.png")
  before <- as.character(fixture$doc)
  expect_false(is_report_figure_table(table, fixture$styles))
  finalise_report_figures(fixture$doc, fixture$styles)
  expect_identical(as.character(fixture$doc), before)
  xml2::xml_set_attr(picture, "descr", "figures/item-levels-selection-DL.png")
  paragraph <- xml2::xml_find_first(table, "w:tr/w:tc/w:p", fixture$ns)
  run <- xml2::xml_add_child(paragraph, "w:r")
  text_node <- xml2::xml_add_child(run, "w:t")
  xml2::xml_text(text_node) <- "Additional data content"
  expect_false(is_report_figure_table(table, fixture$styles))
  xml2::xml_remove(run)
  cell <- xml2::xml_find_first(table, "w:tr/w:tc", fixture$ns)
  xml2::xml_add_child(cell, data)
  expect_false(is_report_figure_table(table, fixture$styles))
})

test_that("missing image dimensions do not alter the picture or break figure cleanup", {
  fixture <- figure_layout_fixture()
  extent <- xml2::xml_find_first(fixture$doc, ".//wp:extent", fixture$ns)
  xml2::xml_set_attr(extent, "cx", "0")
  expect_no_error(finalise_report_figures(fixture$doc, fixture$styles))
  expect_identical(xml2::xml_attr(extent, "cx"), "0")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(fixture$doc, ".//a:xfrm/a:ext", fixture$ns), "cx"),
                   "5334000")
})
