layout_word_fixture <- function() {
  directory <- tempfile("layout-parts-")
  dir.create(file.path(directory, "word"), recursive = TRUE)
  ns <- word_ns()[["w"]]
  styles <- paste0('<w:styles xmlns:w="', ns, '">',
    '<w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Times New Roman" w:asciiTheme="minorHAnsi"/><w:sz w:val="18"/></w:rPr></w:rPrDefault>',
    '<w:pPrDefault><w:pPr><w:spacing w:after="120" w:line="240"/></w:pPr></w:pPrDefault></w:docDefaults>',
    '<w:style w:type="paragraph" w:styleId="Normal"><w:name w:val="Normal"/></w:style>',
    '<w:style w:type="paragraph" w:styleId="Body"><w:name w:val="Body Text"/><w:rPr><w:sz w:val="18"/></w:rPr></w:style>',
    '<w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:link w:val="CoverChar"/><w:rPr><w:sz w:val="106"/><w:color w:val="B40036"/></w:rPr></w:style>',
    '<w:style w:type="character" w:styleId="CoverChar"><w:link w:val="Title"/><w:rPr><w:sz w:val="106"/></w:rPr></w:style>',
    '<w:style w:type="paragraph" w:styleId="Untertitel1"><w:name w:val="Untertitel1"/><w:rPr><w:sz w:val="54"/></w:rPr></w:style>',
    '<w:style w:type="paragraph" w:styleId="H1"><w:name w:val="heading 1"/><w:pPr><w:spacing w:beforeLines="100" w:after="300"/></w:pPr><w:rPr><w:sz w:val="50"/></w:rPr></w:style>',
    '<w:style w:type="paragraph" w:styleId="Heading4"><w:name w:val="heading 4"/><w:pPr><w:jc w:val="both"/></w:pPr></w:style>',
    '<w:style w:type="paragraph" w:styleId="Footnote"><w:name w:val="footnote text"/><w:rPr><w:sz w:val="16"/></w:rPr></w:style>',
    '<w:style w:type="paragraph" w:styleId="TableCaption"><w:name w:val="Table Caption"/><w:pPr><w:spacing w:after="200"/></w:pPr><w:rPr><w:sz w:val="18"/></w:rPr></w:style>',
    '</w:styles>')
  document <- paste0('<w:document xmlns:w="', ns, '"><w:body>',
    '<w:p><w:pPr><w:pStyle w:val="Title"/><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:sz w:val="106"/></w:rPr><w:t>Title</w:t></w:r></w:p>',
    '<w:p><w:pPr><w:pStyle w:val="Body"/><w:widowControl w:val="0"/><w:spacing w:after="160" w:line="220" w:lineRule="exact"/></w:pPr><w:r><w:rPr><w:i/><w:sz w:val="18"/><w:szCs w:val="16"/></w:rPr><w:t>M</w:t></w:r><w:r><w:rPr><w:sz w:val="30"/></w:rPr><w:t> = 500</w:t></w:r></w:p>',
    '<w:p><w:r><w:rPr><w:b/></w:rPr><w:t>Domain label</w:t></w:r></w:p>',
    '<w:p><w:pPr><w:pStyle w:val="H1"/><w:spacing w:before="0" w:after="300"/></w:pPr><w:r><w:t>Heading</w:t></w:r></w:p>',
    '<w:p><w:pPr><w:pStyle w:val="Heading4"/><w:jc w:val="both"/></w:pPr><w:r><w:rPr><w:b w:val="0"/></w:rPr><w:t>Minor heading</w:t></w:r></w:p>',
    '<w:p><w:pPr><w:pStyle w:val="TableCaption"/><w:spacing w:after="120" w:afterLines="100"/></w:pPr><w:r><w:t>Caption</w:t></w:r></w:p>',
    '<w:tbl><w:tblPr><w:tblBorders><w:bottom w:val="single" w:sz="12"/></w:tblBorders></w:tblPr><w:tr><w:tc><w:p><w:r><w:rPr><w:sz w:val="18"/></w:rPr><w:t>Cell</w:t></w:r></w:p></w:tc></w:tr></w:tbl>',
    '<w:p><w:pPr><w:spacing w:before="0" w:after="0" w:line="120" w:lineRule="exact"/></w:pPr></w:p>',
    '<w:p><w:pPr><w:spacing w:line="600" w:lineRule="exact"/></w:pPr><w:r><w:drawing/></w:r></w:p>',
    '<w:sectPr><w:pgMar w:top="1400"/></w:sectPr></w:body></w:document>')
  footnotes <- paste0('<w:footnotes xmlns:w="', ns, '"><w:footnote w:id="1"><w:p><w:pPr><w:pStyle w:val="Footnote"/></w:pPr><w:r><w:rPr><w:sz w:val="16"/><w:vertAlign w:val="superscript"/></w:rPr><w:t>1</w:t></w:r><w:r><w:t>Footnote text</w:t></w:r></w:p></w:footnote></w:footnotes>')
  header <- paste0('<w:hdr xmlns:w="', ns, '"><w:p><w:r><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsiTheme="minorHAnsi"/><w:sz w:val="16"/></w:rPr><w:t>Header</w:t></w:r></w:p></w:hdr>')
  footer <- paste0('<w:ftr xmlns:w="', ns, '"><w:p><w:r><w:rPr><w:sz w:val="16"/></w:rPr><w:instrText> PAGE </w:instrText></w:r></w:p></w:ftr>')
  for (name in c("styles", "document", "footnotes", "header1", "footer1")) {
    text <- switch(name, styles = styles, document = document, footnotes = footnotes,
                   header1 = header, footer1 = footer)
    writeLines(text, file.path(directory, "word", paste0(name, ".xml")))
  }
  directory
}

test_that("report typography replaces inherited and direct small text without losing emphasis", {
  directory <- layout_word_fixture()
  ns <- word_ns()
  original <- xml2::read_xml(file.path(directory, "word/document.xml"))
  expect_no_error(apply_report_layout(directory))
  doc <- xml2::read_xml(file.path(directory, "word/document.xml"))
  styles <- xml2::read_xml(file.path(directory, "word/styles.xml"))
  expect_identical(xml2::xml_text(doc), xml2::xml_text(original))
  expect_identical(xml2::xml_attr(xml2::xml_find_first(doc, "//w:sectPr/w:pgMar", ns), "w:top", ns), "1400")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(doc, "//w:tblBorders/w:bottom", ns), "w:sz", ns), "12")
  for (file in list.files(file.path(directory, "word"), full.names = TRUE)) {
    part <- xml2::read_xml(file)
    sizes <- as.numeric(xml2::xml_attr(xml2::xml_find_all(part, "//w:sz|//w:szCs", ns), "w:val", ns))
    expect_true(all(sizes >= 22), info = basename(file))
    fonts <- xml2::xml_find_all(part, "//w:rFonts", ns)
    expect_true(all(xml2::xml_attr(fonts, "w:ascii", ns) == "Arial"), info = basename(file))
    expect_true(all(is.na(xml2::xml_attr(fonts, "w:asciiTheme", ns))), info = basename(file))
    expect_true(all(is.na(xml2::xml_attr(fonts, "w:hAnsiTheme", ns))), info = basename(file))
    paragraphs <- xml2::xml_find_all(part, "//w:p[.//w:t or .//w:instrText]", ns)
    spacing <- xml2::xml_find_first(paragraphs, "w:pPr/w:spacing", ns)
    expect_true(all(xml2::xml_attr(spacing, "w:line", ns) == "360"), info = basename(file))
    expect_true(all(xml2::xml_attr(spacing, "w:lineRule", ns) == "auto"), info = basename(file))
    widow_control <- xml2::xml_find_first(paragraphs, "w:pPr/w:widowControl", ns)
    expect_true(all(xml2::xml_attr(widow_control, "w:val", ns) == "1"), info = basename(file))
  }
  mean_run <- xml2::xml_find_first(doc, "//w:r[w:t='M']", ns)
  expect_length(xml2::xml_find_all(mean_run, "w:rPr/w:i", ns), 1L)
  expect_identical(xml2::xml_attr(xml2::xml_find_first(doc, "//w:r[w:t=' = 500']/w:rPr/w:sz", ns), "w:val", ns), "30")
  footnotes <- xml2::read_xml(file.path(directory, "word/footnotes.xml"))
  expect_identical(xml2::xml_attr(xml2::xml_find_first(footnotes, "//w:vertAlign", ns), "w:val", ns), "superscript")
  body_gap <- xml2::xml_find_first(doc, "//w:p[w:pPr/w:pStyle/@w:val='Body']/w:pPr/w:spacing", ns)
  expect_identical(xml2::xml_attr(body_gap, "w:after", ns), "160")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(doc,
    "//w:p[w:r/w:t='Domain label']/w:pPr/w:keepNext", ns), "w:val", ns), "1")
  expect_length(xml2::xml_find_all(doc, "//w:p[w:r/w:t='M']/w:pPr/w:keepNext", ns), 0L)
  default_gap <- xml2::xml_find_first(styles, "w:docDefaults/w:pPrDefault/w:pPr/w:spacing", ns)
  expect_identical(xml2::xml_attr(default_gap, "w:after", ns), "120")
})

test_that("cover, heading and caption spacing wins over template overrides and remains stable", {
  directory <- layout_word_fixture()
  ns <- word_ns()
  apply_report_layout(directory)
  doc <- xml2::read_xml(file.path(directory, "word/document.xml"))
  styles <- xml2::read_xml(file.path(directory, "word/styles.xml"))
  style_size <- function(id) xml2::xml_attr(xml2::xml_find_first(styles,
    paste0("w:style[@w:styleId='", id, "']/w:rPr/w:sz"), ns), "w:val", ns)
  expect_identical(style_size("Title"), "44")
  expect_identical(style_size("CoverChar"), "44")
  expect_identical(style_size("Untertitel1"), "36")
  expect_identical(style_size("H1"), "32")
  expect_identical(style_size("Heading4"), "22")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(styles, "w:style[@w:styleId='Title']/w:rPr/w:color", ns), "w:val", ns), "B40036")
  heading <- xml2::xml_find_first(doc, "//w:p[w:pPr/w:pStyle/@w:val='H1']", ns)
  spacing <- xml2::xml_find_first(heading, "w:pPr/w:spacing", ns)
  expect_identical(xml2::xml_attr(spacing, "w:before", ns), "480")
  expect_identical(xml2::xml_attr(spacing, "w:after", ns), "120")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(heading, "w:pPr/w:keepNext", ns), "w:val", ns), "1")
  minor <- xml2::xml_find_first(doc, "//w:p[w:pPr/w:pStyle/@w:val='Heading4']", ns)
  expect_identical(xml2::xml_attr(xml2::xml_find_first(minor, "w:pPr/w:jc", ns), "w:val", ns), "left")
  expect_identical(xml2::xml_attr(xml2::xml_find_first(minor, "w:r/w:rPr/w:b", ns), "w:val", ns), "1")
  caption <- xml2::xml_find_first(doc, "//w:p[w:pPr/w:pStyle/@w:val='TableCaption']/w:pPr/w:spacing", ns)
  expect_identical(xml2::xml_attr(caption, "w:after", ns), "40")
  expect_true(is.na(xml2::xml_attr(caption, "w:afterLines", ns)))
  separator <- xml2::xml_find_first(doc, "//w:p[not(w:r)]/w:pPr/w:spacing", ns)
  expect_identical(xml2::xml_attr(separator, "w:line", ns), "120")
  expect_identical(xml2::xml_attr(separator, "w:lineRule", ns), "exact")
  picture <- xml2::xml_find_first(doc, "//w:p[w:r/w:drawing]/w:pPr/w:spacing", ns)
  expect_identical(xml2::xml_attr(picture, "w:line", ns), "600")
  files <- list.files(file.path(directory, "word"), full.names = TRUE)
  first <- unname(tools::md5sum(files))
  apply_report_layout(directory)
  expect_identical(unname(tools::md5sum(files)), first)
})

test_that("performance plot text meets the report minimum including inherited axis text", {
  plot <- plot_performance(example_report(), "DL", font_family = "Arial")
  built <- ggplot2::ggplot_build(plot)
  for (labels in built$data[c(5L, 6L)]) {
    expect_true(all(labels$family == "Arial"))
    expect_true(all(labels$size * 72.27 / 25.4 >= 11 - 1e-8))
  }
  expect_length(unique(built$data[[5L]]$y), 1L)
  expect_gt(built$data[[6L]]$y[2L], built$data[[6L]]$y[3L])
  expect_gt(built$data[[6L]]$y[4L], built$data[[6L]]$y[3L])
  for (name in c("axis.text.x", "axis.text.y", "axis.title.x", "axis.title.y",
                 "plot.title", "plot.subtitle", "plot.caption")) {
    text <- ggplot2::calc_element(name, plot$theme)
    expect_true(text$size >= 11, info = name)
    expect_identical(text$family, "Arial", info = name)
  }
})

test_that("plot font defaults remain portable and reject unusable family inputs", {
  demo <- example_report()
  expect_identical(plot_performance(demo, "DL")$theme$text$family, "sans")
  for (family in list(NULL, character(), "", "  ", NA_character_, c("Arial", "sans"), 11)) {
    expect_error(plot_performance(demo, "DL", font_family = family), "font_family")
  }
})

test_that("corporate bullet glyphs keep their symbol font while numbering text uses Arial", {
  directory <- layout_word_fixture()
  ns <- word_ns()
  path <- file.path(directory, "word/numbering.xml")
  writeLines(paste0('<w:numbering xmlns:w="', ns[["w"]], '"><w:abstractNum w:abstractNumId="1">',
    '<w:lvl w:ilvl="0"><w:numFmt w:val="bullet"/><w:lvlText w:val="&#xF0B7;"/><w:rPr><w:rFonts w:ascii="Symbol"/><w:sz w:val="16"/></w:rPr></w:lvl>',
    '<w:lvl w:ilvl="1"><w:numFmt w:val="decimal"/><w:lvlText w:val="%1."/><w:rPr><w:rFonts w:ascii="Times New Roman"/><w:sz w:val="16"/></w:rPr></w:lvl>',
    '</w:abstractNum></w:numbering>'), path)
  apply_report_layout(directory)
  numbering <- xml2::read_xml(path)
  expect_identical(xml2::xml_attr(xml2::xml_find_all(numbering, "//w:rFonts", ns), "w:ascii", ns),
                   c("Symbol", "Arial"))
  expect_identical(xml2::xml_attr(xml2::xml_find_all(numbering, "//w:sz", ns), "w:val", ns), c("22", "22"))
})
