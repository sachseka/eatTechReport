test_that("missing corporate template is rejected without generating output", {
  input <- example_leistung_input()
  destination <- tempfile("report-missing-template-")
  expect_error(render_report(input$config, input$data,
                             corporate_template = tempfile(fileext = ".dotx"),
                             output_dir = destination), "Corporate-Vorlage fehlt")
  expect_false(dir.exists(destination))
})

test_that("editable blocks are copied and protected from accidental replacement", {
  destination <- tempfile("report-texts-")
  files <- edit_report_texts(destination)
  expect_setequal(basename(files), c("grundlagen_ueberblick.qmd",
                                    "pilotierung_leistung.qmd", "leistung_methoden.qmd"))
  writeLines("Meine redigierte Fassung", files[[1L]])
  expect_error(edit_report_texts(destination), "existieren bereits")
  expect_identical(readLines(files[[1L]]), "Meine redigierte Fassung")
  edit_report_texts(destination, overwrite = TRUE)
  expect_match(readLines(files[[1L]], encoding = "UTF-8")[[1L]], "Allgemeine Informationen")
  expect_error(report_text_files(tempfile()), "alle Textbausteine")
})

test_that("unrelated output directories are never overwritten", {
  skip_if(is.null(quarto::quarto_path()), "Quarto CLI is unavailable")
  input <- example_leistung_input()
  destination <- tempfile("report-unrelated-")
  dir.create(destination)
  unrelated <- file.path(destination, "notes.txt")
  writeLines("keep", unrelated)
  fake_template <- tempfile(fileext = ".dotx")
  file.create(fake_template)
  expect_error(render_report(input$config, input$data,
                             corporate_template = fake_template,
                             output_dir = destination, overwrite = TRUE), "nicht leer")
  expect_identical(readLines(unrelated), "keep")
})

test_that("external labels are literal Markdown text", {
  expect_identical(report_markdown_text("Lesen [A] *B* | C"), "Lesen \\[A\\] \\*B\\* &#124; C")
  expect_identical(report_markdown_text(c("Ia", "Ib", "II")), c("Ia", "Ib", "II"))
})

test_that("Word field policy is explicit and portable", {
  expect_true(resolve_field_update("auto", available = TRUE))
  expect_true(resolve_field_update("word", available = TRUE))
  expect_warning(expect_false(resolve_field_update("auto", available = FALSE)), "fields_pending")
  expect_warning(expect_false(resolve_field_update("none", available = TRUE)), "fields_pending")
  expect_error(resolve_field_update("word", available = FALSE), "benoetigt Microsoft Word")
})

test_that("failed overwrite leaves earlier output and manifest intact", {
  skip_if(is.null(quarto::quarto_path()), "Quarto CLI is unavailable")
  input <- example_leistung_input()
  destination <- tempfile("report-previous-")
  dir.create(file.path(destination, "archive"), recursive = TRUE)
  writeLines("eatTechReport", file.path(destination, ".eatTechReport-render"))
  writeLines("previous report", file.path(destination, "report.docx"))
  old_manifest <- list(status = "development_snapshot", sentinel = "previous")
  saveRDS(old_manifest, file.path(destination, "archive/manifest.rds"))
  fake_template <- tempfile(fileext = ".dotx")
  writeLines("not a Word archive", fake_template)
  expect_error(suppressWarnings(render_report(input$config, input$data,
                                               corporate_template = fake_template,
                                               output_dir = destination, overwrite = TRUE)))
  expect_identical(readLines(file.path(destination, "report.docx")), "previous report")
  expect_identical(readRDS(file.path(destination, "archive/manifest.rds")), old_manifest)
})

synthetic_word_template <- function(path) {
  directory <- tempfile("word-parts-")
  dir.create(file.path(directory, "word"), recursive = TRUE)
  writeLines('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.template.main+xml"/></Types>',
             file.path(directory, "[Content_Types].xml"))
  w <- word_ns()[["w"]]
  r <- word_ns()[["r"]]
  document <- paste0('<w:document xmlns:w="', w, '" xmlns:r="', r, '"><w:body>',
    '<w:p><w:pPr><w:pStyle w:val="TitelDeckblatt"/></w:pPr><w:r><w:rPr><w:color w:val="B40036"/></w:rPr><w:t>Private placeholder</w:t></w:r></w:p>',
    '<w:p><w:pPr><w:pStyle w:val="SubtitelDeckblatt"/></w:pPr><w:r><w:rPr><w:color w:val="000000"/></w:rPr><w:t>Private subtitle</w:t></w:r></w:p>',
    '<w:p><w:pPr><w:sectPr><w:headerReference w:type="default" r:id="rId1"/>',
    '<w:headerReference w:type="first" r:id="rId2"/><w:footerReference w:type="default" r:id="rId3"/>',
    '<w:pgSz w:w="11906" w:h="16838"/></w:sectPr></w:pPr></w:p>',
    '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1400" w:right="1400" w:bottom="1400" w:left="1400"/>',
    '</w:sectPr></w:body></w:document>')
  writeLines(document, file.path(directory, "word/document.xml"))
  styles <- paste0('<w:styles xmlns:w="', w, '">',
    '<w:style w:type="paragraph" w:styleId="Standard"><w:name w:val="Normal"/></w:style>',
    '<w:style w:type="paragraph" w:styleId="Text"><w:name w:val="Body Text"/><w:rPr><w:sz w:val="22"/></w:rPr></w:style>',
    '<w:style w:type="paragraph" w:styleId="Titel"><w:name w:val="Title"/></w:style>',
    '<w:style w:type="paragraph" w:styleId="TitelDeckblatt"><w:name w:val="Titel_Deckblatt"/><w:rPr><w:color w:val="FFFFFF"/><w:sz w:val="44"/></w:rPr></w:style>',
    '<w:style w:type="paragraph" w:styleId="SubtitelDeckblatt"><w:name w:val="Subtitel_Deckblatt"/><w:rPr><w:color w:val="FFFFFF"/></w:rPr></w:style>',
    '</w:styles>')
  writeLines(styles, file.path(directory, "word/styles.xml"))
  pack_word_package(directory, path)
}

test_that("reference conversion retains geometry and inherited corporate styles", {
  template <- tempfile(fileext = ".dotx")
  reference <- tempfile(fileext = ".docx")
  synthetic_word_template(template)
  original_hash <- tools::md5sum(template)
  prepare_corporate_reference(template, reference)
  expect_identical(tools::md5sum(template), original_hash)
  extracted <- tempfile("reference-inspection-")
  extract_word_package(reference, extracted)
  ns <- word_ns()
  doc <- xml2::read_xml(file.path(extracted, "word/document.xml"))
  final <- xml2::xml_find_first(doc, "(//w:sectPr)[last()]", ns)
  expect_length(xml2::xml_find_all(doc, "//w:sectPr", ns), 1L)
  expect_length(xml2::xml_find_all(doc, "//w:t", ns), 0L)
  expect_length(xml2::xml_find_all(final, "w:headerReference", ns), 2L)
  expect_identical(xml2::xml_attr(xml2::xml_find_first(final, "w:headerReference[@w:type='default']", ns),
                                 "r:id", ns), "rId1")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(final, "w:pgMar", ns), "w:left", ns), "1400")
  styles <- xml2::read_xml(file.path(extracted, "word/styles.xml"))
  first <- xml2::xml_find_first(styles, "w:style[w:name/@w:val='First Paragraph']/w:rPr/w:sz", ns)
  expect_identical(xml2::xml_attr(first, "w:val", ns), "22")
  title <- xml2::xml_find_first(styles, "w:style[w:name/@w:val='Title']/w:rPr/w:sz", ns)
  expect_identical(xml2::xml_attr(title, "w:val", ns), "44")
  title_color <- xml2::xml_find_first(styles, "w:style[w:name/@w:val='Title']/w:rPr/w:color", ns)
  subtitle_color <- xml2::xml_find_first(styles, "w:style[w:name/@w:val='Subtitle']/w:rPr/w:color", ns)
  expect_identical(xml2::xml_attr(title_color, "w:val", ns), "B40036")
  expect_identical(xml2::xml_attr(subtitle_color, "w:val", ns), "000000")
  content <- xml2::read_xml(file.path(extracted, "[Content_Types].xml"))
  expect_match(xml2::xml_attr(xml2::xml_find_first(content, "//*[local-name()='Override']"), "ContentType"),
               "document.main+xml", fixed = TRUE)
})

test_that("table postprocessing uses horizontal rules and repeated headings", {
  template <- tempfile(fileext = ".dotx")
  synthetic_word_template(template)
  directory <- tempfile("table-fixture-")
  extract_word_package(template, directory)
  doc_path <- file.path(directory, "word/document.xml")
  doc <- xml2::read_xml(doc_path)
  body <- xml2::xml_find_first(doc, "w:body", word_ns())
  table <- xml2::read_xml(paste0('<w:tbl xmlns:w="', word_ns()[["w"]],
                               '"><w:tr><w:tc><w:p><w:r><w:t>Heading</w:t></w:r></w:p></w:tc></w:tr>',
                               '<w:tr><w:tc><w:p><w:r><w:t>Value</w:t></w:r></w:p></w:tc></w:tr></w:tbl>'))
  xml2::xml_add_child(body, table, .where = 0)
  xml2::write_xml(doc, doc_path)
  report <- tempfile(fileext = ".docx")
  pack_word_package(directory, report)
  finalise_report_docx(report)
  result <- tempfile("table-result-")
  extract_word_package(report, result)
  doc <- xml2::read_xml(file.path(result, "word/document.xml"))
  border <- xml2::xml_find_first(doc, "//w:tblBorders/w:insideV", word_ns())
  expect_identical(xml2::xml_attr(border, "w:val", word_ns()), "nil")
  expect_length(xml2::xml_find_all(doc, "//w:trPr/w:tblHeader", word_ns()), 1L)
  expect_identical(xml2::xml_attr(xml2::xml_find_all(doc, "//w:tbl/w:tr//w:keepNext", word_ns()),
                                 "w:val", word_ns()), c("1", "0"))
  expect_length(xml2::xml_find_all(doc, "//w:trPr/w:cantSplit", word_ns()), 2L)
})
