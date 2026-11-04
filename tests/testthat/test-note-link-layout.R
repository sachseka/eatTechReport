note_link_fixture <- function() {
  directory <- tempfile("note-link-parts-")
  dir.create(file.path(directory, "word"), recursive = TRUE)
  ns <- word_ns()[["w"]]
  styles <- paste0('<w:styles xmlns:w="', ns, '">',
    '<w:style w:type="paragraph" w:styleId="Normal"><w:name w:val="Normal"/></w:style>',
    '<w:style w:type="paragraph" w:styleId="ReportFigureNote"><w:name w:val="ReportFigureNote"/>',
    '<w:pPr><w:spacing w:before="120" w:after="120" w:beforeLines="100" w:afterLines="100" w:line="360"/></w:pPr>',
    '<w:rPr><w:sz w:val="24"/></w:rPr></w:style>',
    '<w:style w:type="paragraph" w:styleId="NoteAlias"><w:name w:val="Alternative note"/><w:basedOn w:val="ReportFigureNote"/></w:style>',
    '<w:style w:type="character" w:styleId="NoteChar"><w:link w:val="ReportFigureNote"/><w:rPr><w:sz w:val="30"/></w:rPr></w:style>',
    '<w:style w:type="character" w:styleId="Hyperlink"><w:name w:val="Hyperlink"/>',
    '<w:rPr><w:color w:val="0000FF" w:themeColor="hyperlink" w:themeTint="80" w:themeShade="20"/>',
    '<w:u w:val="single" w:color="0000FF" w:themeColor="hyperlink"/></w:rPr></w:style>',
    '<w:style w:type="character" w:styleId="Visited"><w:name w:val="FollowedHyperlink"/>',
    '<w:rPr><w:color w:val="800080" w:themeColor="followedHyperlink"/></w:rPr></w:style>',
    '</w:styles>')
  document <- paste0('<w:document xmlns:w="', ns, '"><w:body>',
    '<w:p><w:pPr><w:pStyle w:val="ReportFigureNote"/><w:spacing w:before="120" w:after="120" w:line="360"/>',
    '<w:rPr><w:sz w:val="30"/></w:rPr></w:pPr>',
    '<w:r><w:rPr><w:i/><w:sz w:val="22"/></w:rPr><w:t>Anmerkung.</w:t></w:r>',
    '<w:r><w:t> Figure note text.</w:t></w:r>',
    '<w:hyperlink w:anchor="figure"><w:r><w:rPr><w:rStyle w:val="Hyperlink"/><w:sz w:val="22"/>',
    '<w:color w:val="0000FF" w:themeColor="hyperlink"/></w:rPr><w:t>Abbildung 2.1</w:t></w:r></w:hyperlink>',
    '</w:p>',
    '<w:p><w:pPr><w:pStyle w:val="NoteAlias"/></w:pPr><w:r><w:t>Second note paragraph.</w:t></w:r></w:p>',
    '<w:p><w:r><w:t>Anmerkung. Ordinary table note.</w:t></w:r></w:p>',
    '<w:p><w:hyperlink w:anchor="table"><w:r><w:rPr><w:color w:val="0000FF" w:themeColor="hyperlink"/>',
    '<w:u w:val="single" w:color="0000FF" w:themeColor="hyperlink"/></w:rPr><w:t>Tabelle 2.1</w:t></w:r></w:hyperlink>',
    '<w:r><w:rPr><w:rStyle w:val="Visited"/><w:color w:val="800080" w:themeColor="followedHyperlink"/></w:rPr><w:t>Visited URL</w:t></w:r>',
    '<w:r><w:rPr><w:color w:val="00818D"/></w:rPr><w:t>Corporate text</w:t></w:r></w:p>',
    '</w:body></w:document>')
  writeLines(styles, file.path(directory, "word/styles.xml"))
  writeLines(document, file.path(directory, "word/document.xml"))
  writeLines('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>',
    file.path(directory, "[Content_Types].xml"))
  directory
}

test_that("only explicitly styled figure notes become 10 pt with single spacing", {
  directory <- note_link_fixture()
  ns <- word_ns()
  apply_report_layout(directory)
  styles <- xml2::read_xml(file.path(directory, "word/styles.xml"))
  doc <- xml2::read_xml(file.path(directory, "word/document.xml"))
  for (id in c("ReportFigureNote", "NoteAlias", "NoteChar")) {
    style <- xml2::xml_find_first(styles, paste0("w:style[@w:styleId='", id, "']"), ns)
    expect_identical(xml2::xml_attr(xml2::xml_find_first(style, "w:rPr/w:sz", ns), "w:val", ns), "20")
    expect_identical(xml2::xml_attr(xml2::xml_find_first(style, "w:rPr/w:szCs", ns), "w:val", ns), "20")
  }
  notes <- xml2::xml_find_all(doc, "//w:p[w:pPr/w:pStyle[@w:val='ReportFigureNote' or @w:val='NoteAlias']]", ns)
  expect_length(notes, 2L)
  for (note in notes) {
    spacing <- xml2::xml_find_first(note, "w:pPr/w:spacing", ns)
    expect_identical(xml2::xml_attr(spacing, "w:line", ns), "240")
    expect_identical(xml2::xml_attr(spacing, "w:lineRule", ns), "auto")
    expect_identical(xml2::xml_attr(spacing, "w:before", ns), "0")
    expect_identical(xml2::xml_attr(spacing, "w:after", ns), "0")
    expect_true(is.na(xml2::xml_attr(spacing, "w:beforeLines", ns)))
    expect_true(is.na(xml2::xml_attr(spacing, "w:afterLines", ns)))
    expect_true(all(xml2::xml_attr(xml2::xml_find_all(note, ".//w:sz|.//w:szCs", ns), "w:val", ns) == "20"))
    expect_true(all(xml2::xml_attr(xml2::xml_find_all(note, ".//w:rFonts", ns), "w:ascii", ns) == "Arial"))
  }
  expect_length(xml2::xml_find_all(notes[[1L]], ".//w:rPr/w:i", ns), 1L)
  ordinary <- xml2::xml_find_first(doc, "//w:p[w:r/w:t='Anmerkung. Ordinary table note.']", ns)
  expect_identical(xml2::xml_attr(xml2::xml_find_first(ordinary, "w:pPr/w:spacing", ns), "w:line", ns), "360")
  normal <- xml2::xml_find_first(styles, "w:docDefaults/w:rPrDefault/w:rPr/w:sz", ns)
  expect_identical(xml2::xml_attr(normal, "w:val", ns), "22")
})

test_that("internal, visited and external-link styles use corporate colour without theme overrides", {
  directory <- note_link_fixture()
  ns <- word_ns()
  original <- xml2::read_xml(file.path(directory, "word/document.xml"))
  apply_report_layout(directory)
  doc <- xml2::read_xml(file.path(directory, "word/document.xml"))
  styles <- xml2::read_xml(file.path(directory, "word/styles.xml"))
  expect_identical(xml2::xml_text(doc), xml2::xml_text(original))
  expect_identical(xml2::xml_attr(xml2::xml_find_all(doc, "//w:hyperlink", ns), "w:anchor", ns), c("figure", "table"))
  for (id in c("Hyperlink", "Visited", "FollowedHyperlink")) {
    colour <- xml2::xml_find_first(styles, paste0("w:style[@w:styleId='", id, "']/w:rPr/w:color"), ns)
    expect_identical(xml2::xml_attr(colour, "w:val", ns), "B40036")
    for (key in c("themeColor", "themeTint", "themeShade")) {
      expect_true(is.na(xml2::xml_attr(colour, paste0("w:", key), ns)))
    }
  }
  colours <- xml2::xml_find_all(doc, "//w:hyperlink//w:rPr/w:color | //w:r[w:t='Visited URL']/w:rPr/w:color", ns)
  expect_length(colours, 3L)
  expect_true(all(xml2::xml_attr(colours, "w:val", ns) == "B40036"))
  expect_true(all(is.na(xml2::xml_attr(colours, "w:themeColor", ns))))
  underlines <- xml2::xml_find_all(doc, "//w:hyperlink//w:u", ns)
  expect_true(all(xml2::xml_attr(underlines, "w:color", ns) == "B40036"))
  expect_true(all(is.na(xml2::xml_attr(underlines, "w:themeColor", ns))))
  expect_identical(xml2::xml_attr(xml2::xml_find_first(doc, "//w:r[w:t='Corporate text']/w:rPr/w:color", ns), "w:val", ns), "00818D")
  files <- list.files(file.path(directory, "word"), full.names = TRUE)
  before <- unname(tools::md5sum(files))
  apply_report_layout(directory)
  expect_identical(unname(tools::md5sum(files)), before)
})

test_that("documents without note styles gain corporate link styles without shrinking body text", {
  ns <- word_ns()
  styles <- xml2::read_xml(paste0('<w:styles xmlns:w="', ns[["w"]], '">',
    '<w:style w:type="paragraph" w:styleId="Normal"><w:name w:val="Normal"/></w:style></w:styles>'))
  format_report_note_link_styles(styles, ns)
  expect_length(report_note_style_ids(styles, ns), 0L)
  expect_setequal(report_link_style_ids(styles, ns), c("Hyperlink", "FollowedHyperlink"))
  expect_length(xml2::xml_find_all(styles, "//w:sz[@w:val='20']", ns), 0L)
})

test_that("post-Word correction retains fields and changes only note/link presentation", {
  directory <- note_link_fixture()
  ns <- word_ns()
  # This represents a field result added by Word after the general layout pass.
  doc_path <- file.path(directory, "word/document.xml")
  doc <- xml2::read_xml(doc_path)
  body <- xml2::xml_find_first(doc, "w:body", ns)
  xml2::xml_add_child(body, xml2::read_xml(paste0('<w:p xmlns:w="', ns[["w"]], '">',
    '<w:fldSimple w:instr=" REF figure \\h "><w:hyperlink w:anchor="figure">',
    '<w:r><w:rPr><w:rStyle w:val="Hyperlink"/><w:color w:val="0000FF" w:themeColor="hyperlink"/></w:rPr>',
    '<w:t>Abbildung 2.1</w:t></w:r></w:hyperlink></w:fldSimple></w:p>')))
  xml2::write_xml(doc, doc_path)
  original <- xml2::xml_text(doc)
  path <- tempfile(fileext = ".docx")
  pack_word_package(directory, path)
  expect_identical(finalise_report_note_links(path), path)
  destination <- tempfile("checked-notes-")
  extract_word_package(path, destination)
  final <- xml2::read_xml(file.path(destination, "word/document.xml"))
  expect_identical(xml2::xml_text(final), original)
  expect_identical(xml2::xml_attr(xml2::xml_find_first(final, "//w:fldSimple", ns), "w:instr", ns), " REF figure \\h ")
  expect_true(all(xml2::xml_attr(xml2::xml_find_all(final, "//w:hyperlink//w:color", ns), "w:val", ns) == "B40036"))
})
