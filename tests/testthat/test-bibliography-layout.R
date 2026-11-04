bibliography_layout_fixture <- function() {
  directory <- tempfile("bibliography-parts-")
  dir.create(file.path(directory, "word"), recursive = TRUE)
  w <- word_ns()[["w"]]
  writeLines(paste0('<w:styles xmlns:w="', w, '">',
    '<w:style w:type="paragraph" w:styleId="Normal"><w:name w:val="Normal"/></w:style>',
    '<w:style w:type="paragraph" w:styleId="ReportBibliography"><w:name w:val="ReportBibliography"/>',
    '<w:pPr><w:spacing w:after="0" w:afterLines="100"/><w:ind w:left="720" w:hanging="720"/>',
    '<w:contextualSpacing/></w:pPr></w:style>',
    '<w:style w:type="paragraph" w:styleId="ReferenceAlias"><w:basedOn w:val="ReportBibliography"/></w:style>',
    '</w:styles>'), file.path(directory, "word/styles.xml"))
  writeLines(paste0('<w:document xmlns:w="', w, '"><w:body>',
    '<w:p><w:pPr><w:pStyle w:val="Normal"/><w:spacing w:after="40"/></w:pPr>',
    '<w:r><w:t>Ordinary prose mentions a source.</w:t></w:r></w:p>',
    '<w:p><w:pPr><w:pStyle w:val="ReportBibliography"/><w:spacing w:after="0" w:afterLines="100"/>',
    '<w:ind w:left="720" w:hanging="720"/><w:contextualSpacing/></w:pPr>',
    '<w:r><w:t>Author (2026). </w:t></w:r><w:r><w:rPr><w:i/></w:rPr><w:t>Book title.</w:t></w:r></w:p>',
    '<w:p><w:pPr><w:pStyle w:val="ReferenceAlias"/></w:pPr>',
    '<w:hyperlink w:anchor="source"><w:r><w:t>Second reference.</w:t></w:r></w:hyperlink></w:p>',
    '</w:body></w:document>'), file.path(directory, "word/document.xml"))
  writeLines('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>',
             file.path(directory, "[Content_Types].xml"))
  directory
}

test_that("bibliography entries have visible gaps without changing reference content or indents", {
  directory <- bibliography_layout_fixture()
  ns <- word_ns()
  doc_path <- file.path(directory, "word/document.xml")
  original <- xml2::read_xml(doc_path)
  apply_report_layout(directory)
  doc <- xml2::read_xml(doc_path)
  expect_identical(xml2::xml_text(doc), xml2::xml_text(original))
  entries <- xml2::xml_find_all(doc, "//w:p[w:pPr/w:pStyle[@w:val='ReportBibliography' or @w:val='ReferenceAlias']]", ns)
  for (entry in entries) {
    spacing <- xml2::xml_find_first(entry, "w:pPr/w:spacing", ns)
    expect_identical(xml2::xml_attr(spacing, "w:after", ns), "160")
    expect_identical(xml2::xml_attr(spacing, "w:line", ns), "360")
    expect_true(is.na(xml2::xml_attr(spacing, "w:afterLines", ns)))
    expect_identical(xml2::xml_attr(xml2::xml_find_first(entry, "w:pPr/w:contextualSpacing", ns), "w:val", ns), "0")
  }
  for (attribute in c("w:left", "w:hanging")) {
    expect_identical(xml2::xml_attr(xml2::xml_find_first(doc, "//w:pPr/w:ind", ns), attribute, ns),
                     xml2::xml_attr(xml2::xml_find_first(original, "//w:pPr/w:ind", ns), attribute, ns))
  }
  expect_length(xml2::xml_find_all(doc, "//w:rPr/w:i", ns), 1L)
  expect_identical(xml2::xml_attr(xml2::xml_find_first(doc, "//w:hyperlink", ns), "w:anchor", ns), "source")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(doc, "//w:p[w:pPr/w:pStyle/@w:val='Normal']/w:pPr/w:spacing", ns), "w:after", ns), "40")
  files <- list.files(file.path(directory, "word"), full.names = TRUE)
  before <- unname(tools::md5sum(files))
  apply_report_layout(directory)
  expect_identical(unname(tools::md5sum(files)), before)
})

test_that("post-Word finalisation retains spacing for references and derived styles", {
  directory <- bibliography_layout_fixture()
  path <- tempfile(fileext = ".docx")
  pack_word_package(directory, path)
  finalise_report_note_links(path)
  destination <- tempfile("bibliography-after-word-")
  extract_word_package(path, destination)
  ns <- word_ns()
  doc <- xml2::read_xml(file.path(destination, "word/document.xml"))
  styles <- xml2::read_xml(file.path(destination, "word/styles.xml"))
  paragraphs <- xml2::xml_find_all(doc, "//w:p[w:pPr/w:pStyle[@w:val='ReportBibliography' or @w:val='ReferenceAlias']]", ns)
  expect_true(all(xml2::xml_attr(xml2::xml_find_all(paragraphs, "w:pPr/w:spacing", ns), "w:after", ns) == "160"))
  for (id in c("ReportBibliography", "ReferenceAlias")) {
    style <- xml2::xml_find_first(styles, paste0("w:style[@w:styleId='", id, "']"), ns)
    expect_identical(xml2::xml_attr(xml2::xml_find_first(style, "w:pPr/w:spacing", ns), "w:after", ns), "160")
  }
})
