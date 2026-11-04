cover_fixture <- function() {
  ns <- word_ns()[["w"]]
  list(
    doc = xml2::read_xml(paste0('<w:document xmlns:w="', ns, '"><w:body>',
      '<w:p><w:pPr><w:pStyle w:val="CoverTitle"/></w:pPr><w:r><w:t>Report title</w:t></w:r></w:p>',
      '<w:p><w:pPr><w:pStyle w:val="CoverSubtitle"/></w:pPr><w:r><w:t>Technischer Bericht</w:t></w:r></w:p>',
      '<w:p><w:r><w:t>Following report prose</w:t></w:r></w:p>',
      '<w:sectPr/></w:body></w:document>')),
    styles = xml2::read_xml(paste0('<w:styles xmlns:w="', ns, '">',
      '<w:style w:type="paragraph" w:styleId="Normal"><w:name w:val="Normal"/></w:style>',
      '<w:style w:type="paragraph" w:styleId="CoverTitle"><w:name w:val="Title"/></w:style>',
      '<w:style w:type="paragraph" w:styleId="CoverSubtitle"><w:name w:val="Subtitle"/></w:style>',
      '</w:styles>'))
  )
}

test_that("cover lookup accepts the same style-name case variants as template preparation", {
  fixture <- cover_fixture()
  ns <- word_ns()
  for (style in xml2::xml_find_all(fixture$styles, "w:style/w:name", ns)) {
    xml2::xml_set_attr(style, "w:val", tolower(xml2::xml_attr(style, "w:val", ns)))
  }
  expect_no_error(add_report_cover_authors(fixture$doc, fixture$styles,
    list(authors = "Example Author", affiliation = "Example Institute")))
  expect_match(xml2::xml_text(fixture$doc), "Example Author", fixed = TRUE)
})

test_that("report authors and affiliation are explicit inputs independent of package authors", {
  authors <- c("Beate Beispiel", "Anna Anders", "Chris Dritte")
  affiliation <- c("Institut Eins", "Universit\u00e4t Zwei")
  for (scope in c("pilotierung", "pilotierung_leistung")) {
    input <- example_report(n_persons = 2L, n_pv = 1L, scope = scope,
                              authors = authors, affiliation = affiliation)
    expect_identical(input$config$report$authors, authors)
    expect_identical(input$config$report$affiliation, affiliation)
    expect_true(validate_report_input(input))
    expect_false(any(grepl("Sachse|Schumann", input$config$report$authors)))
  }
  input <- example_leistung_input(n_persons = 2L, n_pv = 1L,
                                   authors = "Einzelne Person", affiliation = "Eigenes Institut")
  expect_identical(input$config$report$authors, "Einzelne Person")
  expect_identical(input$config$report$affiliation, "Eigenes Institut")
  defaults <- example_report(n_persons = 2L, n_pv = 1L)$config$report
  expect_true(all(grepl("^\\[.+\\]$", defaults$authors)))
  expect_identical(defaults$affiliation, "[Affiliation]")
})

test_that("older inputs use visible placeholders and supplied cover fields are validated", {
  input <- example_report(n_persons = 2L, n_pv = 1L)
  input$config$report$authors <- NULL
  input$config$report$affiliation <- NULL
  expect_true(validate_report_input(input))
  expect_identical(report_cover_data(input$config$report),
                    list(authors = "[Autorinnen und Autoren]", affiliation = "[Affiliation]"))
  for (field in c("authors", "affiliation")) {
    for (value in list(character(), "", "   ", NA_character_, c("Valid", NA_character_),
                       "Embedded\nnewline", 12, list("Valid"))) {
      changed <- input
      changed$config$report[[field]] <- value
      expect_error(validate_report_input(changed), paste0("config\\$report\\$", field))
    }
  }
  input$config$report$affiliation <- "An institute without supplied authors"
  expect_true(validate_report_input(input))
  expect_identical(report_cover_data(input$config$report)$authors, "[Autorinnen und Autoren]")
})

test_that("cover names retain order, Unicode, brackets and XML metacharacters literally", {
  fixture <- cover_fixture()
  ns <- word_ns()
  report <- list(authors = c("\u00d6zlem M\u00fcller", "A & B <Team>", "[Person 3]"),
                 affiliation = c("Institut f\u00fcr \u00d6kologie & Bildung", "Universit\u00e4t <Nord>"))
  add_report_cover_authors(fixture$doc, fixture$styles, report)
  paragraphs <- xml2::xml_find_all(fixture$doc, "w:body/w:p", ns)
  texts <- xml2::xml_text(paragraphs)
  expect_identical(texts, c("Report title", "Technischer Bericht",
    "\u00d6zlem M\u00fcller, A & B <Team> & [Person 3]",
    "Institut f\u00fcr \u00d6kologie & BildungUniversit\u00e4t <Nord>", "Following report prose"))
  affiliation <- xml2::xml_find_first(fixture$doc,
    "//w:p[w:pPr/w:pStyle/@w:val='ReportAffiliation']", ns)
  expect_length(xml2::xml_find_all(affiliation, ".//w:br", ns), 1L)
  expect_length(xml2::xml_find_all(fixture$doc, "//*[local-name()='Team' or local-name()='Nord']"), 0L)
  expect_no_error(xml2::read_xml(as.character(fixture$doc)))
  report$authors <- "Replacement person"
  report$affiliation <- "[Affiliation]"
  add_report_cover_authors(fixture$doc, fixture$styles, report)
  authors <- xml2::xml_find_all(fixture$doc,
    "//w:p[w:pPr/w:pStyle/@w:val='ReportAuthors']", ns)
  expect_length(authors, 1L)
  expect_identical(xml2::xml_text(authors), "Replacement person")
  expect_length(xml2::xml_find_all(fixture$styles, "w:style[@w:styleId='ReportAuthors']", ns), 1L)
  expect_length(xml2::xml_find_all(fixture$doc, "//w:br", ns), 0L)
})

test_that("cover layout keeps names and multiline affiliation together below the subtitle", {
  fixture <- cover_fixture()
  ns <- word_ns()
  add_report_cover_authors(fixture$doc, fixture$styles,
                            list(authors = c("First", "Second"), affiliation = c("Line one", "Line two")))
  directory <- tempfile("cover-layout-")
  dir.create(file.path(directory, "word"), recursive = TRUE)
  xml2::write_xml(fixture$doc, file.path(directory, "word/document.xml"))
  xml2::write_xml(fixture$styles, file.path(directory, "word/styles.xml"))
  apply_report_layout(directory)
  doc <- xml2::read_xml(file.path(directory, "word/document.xml"))
  paragraphs <- xml2::xml_find_all(doc,
    "//w:p[w:pPr/w:pStyle/@w:val='ReportAuthors' or w:pPr/w:pStyle/@w:val='ReportAffiliation']", ns)
  expect_identical(xml2::xml_text(paragraphs[[1L]]), "First & Second")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(paragraphs, "w:pPr/w:jc", ns), "w:val", ns),
                    c("left", "left"))
  expect_identical(xml2::xml_attr(xml2::xml_find_first(paragraphs, "w:pPr/w:spacing", ns), "w:before", ns),
                    c("480", "0"))
  expect_identical(xml2::xml_attr(xml2::xml_find_first(paragraphs, "w:pPr/w:spacing", ns), "w:after", ns),
                    c("120", "0"))
  expect_identical(xml2::xml_attr(xml2::xml_find_first(paragraphs, "w:pPr/w:keepNext", ns), "w:val", ns),
                    c("1", "0"))
  expect_true(all(xml2::xml_attr(xml2::xml_find_all(paragraphs, ".//w:rPr/w:sz", ns), "w:val", ns) == "22"))
  expect_true(all(xml2::xml_attr(xml2::xml_find_all(paragraphs, ".//w:rPr/w:rFonts", ns), "w:ascii", ns) == "Arial"))
})

test_that("a missing cover subtitle cannot silently discard the supplied authors", {
  fixture <- cover_fixture()
  xml2::xml_remove(xml2::xml_find_all(fixture$doc,
    "//w:p[w:pPr/w:pStyle/@w:val='CoverSubtitle']", word_ns()))
  expect_error(add_report_cover_authors(fixture$doc, fixture$styles,
                                        list(authors = "Author", affiliation = "Institute")),
                 "Untertitel.*fehlt")
})
