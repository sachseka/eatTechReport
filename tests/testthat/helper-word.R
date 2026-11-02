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
