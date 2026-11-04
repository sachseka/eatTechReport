header_guard_fixture <- function(content, property = "title") {
  ns <- word_ns()
  xml2::read_xml(paste0('<w:hdr xmlns:w="', ns[["w"]], '">',
    '<w:sdt><w:sdtPr><w:dataBinding w:xpath="/cp:coreProperties[1]/dc:', property,
    '[1]"/><w:text/></w:sdtPr><w:sdtContent>', content,
    '</w:sdtContent></w:sdt></w:hdr>'))
}

test_that("missing report metadata leaves bound header content untouched", {
  content <- '<w:p><w:r><w:t>Vergleichsarbeiten 2027 3. Jahrgangsstufe Mathematik</w:t></w:r></w:p>'
  for (report in list(NULL, list(main_year = 2027L), list(subject = "ma"))) {
    header <- header_guard_fixture(content)
    before <- as.character(header)
    mark_report_header_values(header, report)
    expect_identical(as.character(header), before)
  }
})

test_that("a different or unmaterialised property control is never rewritten as a report title", {
  report <- list(main_year = 2027L, subject = "ma")
  cases <- list(
    '<w:p><w:r><w:t>Vergleichsarbeiten 2026 3. Jahrgangsstufe Mathematik</w:t></w:r></w:p>',
    '<w:p><w:r><w:t>Vergleichsarbeiten 2027 3. Jahrgangsstufe Deutsch</w:t></w:r></w:p>',
    '<w:p><w:r><w:t>Institutional header</w:t></w:r></w:p>',
    '<w:p/>', '')
  for (content in cases) {
    header <- header_guard_fixture(content)
    before <- as.character(header)
    mark_report_header_values(header, report)
    expect_identical(as.character(header), before)
  }
  # Equal visible text alone does not give the renderer ownership of another
  # document property: its binding must also remain unchanged.
  header <- header_guard_fixture(
    '<w:p><w:r><w:t>Vergleichsarbeiten 2027 3. Jahrgangsstufe Mathematik</w:t></w:r></w:p>',
    property = "subject")
  before <- as.character(header)
  mark_report_header_values(header, report)
  expect_identical(as.character(header), before)
})

test_that("nested title content retains hyperlinks and field bindings without duplication", {
  report <- list(main_year = 2027L, subject = "ma")
  cases <- list(
    paste0('<w:p><w:hyperlink w:anchor="title"><w:r>',
      '<w:t>Vergleichsarbeiten 2027 3. Jahrgangsstufe Mathematik</w:t>',
      '</w:r></w:hyperlink></w:p>'),
    paste0('<w:p><w:r><w:t>Vergleichsarbeiten </w:t></w:r>',
      '<w:hyperlink w:anchor="year"><w:r><w:t>2027</w:t></w:r></w:hyperlink>',
      '<w:r><w:t> 3. Jahrgangsstufe Mathematik</w:t></w:r></w:p>'))
  for (content in cases) {
    header <- header_guard_fixture(content)
    before <- as.character(header)
    mark_report_header_values(header, report)
    expect_identical(as.character(header), before)
  }
})

test_that("observed reports preserve the original title control and style definitions", {
  ns <- word_ns()
  header <- header_guard_fixture(
    '<w:p><w:r><w:rPr><w:i/></w:rPr><w:t>Vergleichsarbeiten 2027 3. Jahrgangsstufe Mathematik</w:t></w:r></w:p>')
  styles <- xml2::read_xml(paste0('<w:styles xmlns:w="', ns[["w"]], '"/>'))
  before_header <- as.character(header)
  before_styles <- as.character(styles)
  apply_report_value_highlights(header, styles,
    list(data_origin = "observed", main_year = 2027L, subject = "ma"), ns)
  expect_identical(as.character(header), before_header)
  expect_identical(as.character(styles), before_styles)
})
