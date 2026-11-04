test_that("only simulated values get markup and literal input stays literal", {
  config <- example_report()$config
  marker <- 'custom-style="EatSimulatedValue"'
  marked <- report_text_value(c("2027", "[Name] & A_B", ""), config)
  expect_match(marked[1L], marker, fixed = TRUE)
  expect_identical(marked[2L], '[\\[Name\\] & A\\_B]{custom-style="EatSimulatedValue"}')
  expect_identical(marked[3L], "")
  expect_identical(report_text_value(marked, config, markdown = TRUE), marked)
  config$report$data_origin <- "observed"
  expect_identical(report_text_value("A_B", config), "A\\_B")
  expect_identical(report_text_value("*M* = 500", config, markdown = TRUE), "*M* = 500")
  expect_identical(report_text_value("fixed", NULL), "fixed")
})

test_that("the inline hook marks output without rewriting fixed text or IDs", {
  config <- example_report()$config
  previous <- knitr::knit_hooks$get("inline")
  on.exit(knitr::knit_hooks$set(inline = previous), add = TRUE)
  knitr::knit_hooks$set(inline = report_inline_value_hook(config, previous))
  env <- new.env(parent = globalenv())
  env$year <- 2027L
  rendered <- paste(knitr::knit_child(text = "# Fixed 2027 and `r year` {#fixed-id}",
    envir = env, quiet = TRUE), collapse = "\n")
  expect_match(rendered, '# Fixed 2027 and [2027]{custom-style="EatSimulatedValue"} {#fixed-id}', fixed = TRUE)
  config$report$data_origin <- "observed"
  knitr::knit_hooks$set(inline = report_inline_value_hook(config, previous))
  rendered <- paste(knitr::knit_child(text = "# Fixed 2027 and `r year` {#fixed-id}",
    envir = env, quiet = TRUE), collapse = "\n")
  expect_false(grepl("EatSimulatedValue", rendered, fixed = TRUE))
})

value_word_fixture <- function() {
  ns <- word_ns()[["w"]]
  list(doc = xml2::read_xml(paste0('<w:document xmlns:w="', ns, '"><w:body>',
    '<w:p><w:r><w:t>Fixed 2027</w:t></w:r><w:r><w:rPr><w:rStyle w:val="EatSimulatedValue"/><w:i/></w:rPr><w:t>2027</w:t></w:r></w:p>',
    '<w:p><w:pPr><w:pStyle w:val="ReportAuthors"/></w:pPr><w:r><w:t>Author</w:t></w:r></w:p>',
    '<w:tbl><w:tr><w:tc><w:p><w:r><w:rPr><w:rStyle w:val="EatTaskMatrix"/></w:rPr><w:t>Nr.</w:t></w:r></w:p></w:tc>',
    '<w:tc><w:p><w:r><w:rPr><w:rStyle w:val="EatTaskBase"/><w:color w:val="FFFFFF"/></w:rPr><w:t>MO-BM</w:t></w:r></w:p></w:tc></w:tr>',
    '<w:tr><w:tc><w:p><w:r><w:t>1</w:t></w:r></w:p></w:tc><w:tc><w:p><w:r><w:t>Task</w:t></w:r></w:p></w:tc></w:tr></w:tbl>',
    '<w:tbl><w:tr><w:tc><w:p><w:r><w:t>Unowned table</w:t></w:r></w:p></w:tc></w:tr></w:tbl>',
    '</w:body></w:document>')),
    styles = xml2::read_xml(paste0('<w:styles xmlns:w="', ns, '"/>')))
}

test_that("Word highlights preserve fixed prose, matrix styles, italics and readable text", {
  fixture <- value_word_fixture()
  ns <- word_ns()
  apply_report_value_highlights(fixture$doc, fixture$styles, list(data_origin = "synthetic"))
  expect_length(xml2::xml_find_all(fixture$styles, "//w:highlight", ns), 0L)
  highlighted <- xml2::xml_find_all(fixture$doc, "//w:r[w:rPr/w:highlight/@w:val='yellow']", ns)
  expect_identical(xml2::xml_text(highlighted), c("2027", "Author", "MO-BM", "1", "Task"))
  expect_length(xml2::xml_find_all(highlighted[[1L]], "w:rPr/w:i", ns), 1L)
  base <- xml2::xml_find_first(fixture$doc, "//w:r[w:rPr/w:rStyle/@w:val='EatTaskBase']", ns)
  expect_identical(xml2::xml_attr(xml2::xml_find_first(base, "w:rPr/w:color", ns), "w:val", ns), "000000")
  before <- as.character(fixture$doc)
  apply_report_value_highlights(fixture$doc, fixture$styles, list(data_origin = "synthetic"))
  expect_identical(as.character(fixture$doc), before)
  real <- value_word_fixture()
  apply_report_value_highlights(real$doc, real$styles, list(data_origin = "observed"))
  expect_length(xml2::xml_find_all(real$doc, "//w:highlight", ns), 0L)
  expect_length(xml2::xml_find_all(real$styles, "//w:highlight", ns), 0L)
})

test_that("figure captions mark supplied labels and years without marking fixed wording", {
  input <- example_report("v3_ma_mg_mm", scope = "bericht")
  plan <- main_test_figure_plan(input$config, summarise_report_input(input)$main_test)
  expect_match(plan$modules[[1L]]$caption_markdown,
    'VERA-3-Basismoduls [2027]{custom-style="EatSimulatedValue"}', fixed = TRUE)
  expect_false(startsWith(plan$modules[[1L]]$caption_markdown, "[Verteilung"))
  expect_match(plan$modules[[2L]]$note_markdown, "EatSimulatedValue", fixed = TRUE)
  input$config$report$data_origin <- "observed"
  real <- main_test_figure_plan(input$config, summarise_report_input(example_report(
    "v3_ma_mg_mm", scope = "bericht"))$main_test)
  expect_false(any(grepl("EatSimulatedValue", vapply(real$modules, `[[`, "", "caption_markdown"))))
})

test_that("materialised corporate title controls keep only supplied fragments highlighted", {
  ns <- word_ns()
  report <- list(data_origin = "synthetic", main_year = 2027L, subject = "ma")
  xml <- paste0('<w:hdr xmlns:w="', ns[["w"]], '"><w:sdt><w:sdtPr>',
    '<w:dataBinding w:xpath="/cp:coreProperties[1]/dc:title[1]"/><w:text/></w:sdtPr>',
    '<w:sdtContent><w:p><w:r><w:rPr><w:i/><w:color w:val="00818D"/></w:rPr>',
    '<w:t>Vergleichsarbeiten 2027 3. Jahrgangsstufe Mathematik</w:t></w:r>',
    '</w:p></w:sdtContent></w:sdt></w:hdr>')
  doc <- xml2::read_xml(xml)
  styles <- value_word_fixture()$styles
  apply_report_value_highlights(doc, styles, report, ns)
  values <- xml2::xml_find_all(doc, "//w:r[w:rPr/w:highlight/@w:val='yellow']", ns)
  expect_identical(xml2::xml_text(values), c("2027", "Mathematik"))
  expect_length(xml2::xml_find_all(doc, "//w:dataBinding|//w:sdtPr/w:text", ns), 0L)
  expect_identical(xml2::xml_text(doc), "Vergleichsarbeiten 2027 3. Jahrgangsstufe Mathematik")
  expect_length(xml2::xml_find_all(doc, "//w:sdtContent/w:p/w:r/w:rPr/w:i", ns), 4L)
  expect_identical(xml2::xml_attr(xml2::xml_find_all(doc,
    "//w:sdtContent/w:p/w:r/w:rPr/w:color", ns), "w:val", ns), rep("00818D", 4L))
  before <- as.character(doc)
  apply_report_value_highlights(doc, styles, report, ns)
  expect_identical(as.character(doc), before)
  real <- xml2::read_xml(xml)
  report$data_origin <- "observed"
  apply_report_value_highlights(real, styles, report, ns)
  expect_length(xml2::xml_find_all(real, "//w:dataBinding", ns), 1L)
  expect_length(xml2::xml_find_all(real, "//w:highlight", ns), 0L)
})
