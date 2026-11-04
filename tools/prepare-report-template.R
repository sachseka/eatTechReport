# Build the distributable layout from an explicitly supplied corporate DOTX.
# Run from the package source root:
# Rscript tools/prepare-report-template.R /path/to/approved.dotx inst/templates/eatTechReport.docx
# The source document must be approved for this purpose. Never pass a report.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L || !grepl("\\.dotx$", args[[1L]], ignore.case = TRUE)) {
  stop("Supply an approved source.dotx and a target.docx explicitly.")
}
if (!grepl("\\.docx$", args[[2L]], ignore.case = TRUE)) {
  stop("The target must be a .docx file.")
}
if (!file.exists("R/render.R")) stop("Run from the package source root.")
source("R/render.R", local = TRUE)
if (file.exists("R/layout.R")) source("R/layout.R", local = TRUE)
library(xml2)
target <- normalizePath(args[[2L]], winslash = "/", mustWork = FALSE)
dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
build <- tempfile("report-template-")
dir.create(build)
# Keep all intermediate files outside the distributable template directory.
reference <- file.path(build, "reference.docx")
parts <- file.path(build, "parts")
prepare_corporate_reference(args[[1L]], reference)
extract_word_package(reference, parts)
ns <- word_ns()
rel_ns <- c(pr = "http://schemas.openxmlformats.org/package/2006/relationships")
ct_ns <- c(ct = "http://schemas.openxmlformats.org/package/2006/content-types")
read_part <- function(path) read_xml(file.path(parts, path))
write_part <- function(xml, path) write_xml(xml, file.path(parts, path))

# The empty body produced by prepare_corporate_reference is the only body
# content permitted in the public layout reference.
document <- read_part("word/document.xml")
stopifnot(length(xml_find_all(document, "//w:body//w:t", ns)) == 0L)
header_ids <- xml_attr(xml_find_all(document,
  "//w:headerReference | //w:footerReference", ns), "id")
rels <- read_part("word/_rels/document.xml.rels")
relationships <- xml_find_all(rels, "/pr:Relationships/pr:Relationship", rel_ns)
kind <- sub(".*/", "", xml_attr(relationships, "Type"))
allowed <- kind %in% c("styles", "numbering", "settings", "fontTable", "theme",
                       "footnotes", "endnotes") |
  (kind %in% c("header", "footer") & xml_attr(relationships, "Id") %in% header_ids)
xml_remove(relationships[!allowed])
relationships <- xml_find_all(rels, "/pr:Relationships/pr:Relationship", rel_ns)
stopifnot(!any(xml_attr(relationships, "TargetMode") == "External", na.rm = TRUE))
write_part(rels, "word/_rels/document.xml.rels")
kept <- c("[Content_Types].xml", "_rels/.rels", "docProps/core.xml",
          "docProps/app.xml", "word/document.xml", "word/_rels/document.xml.rels",
          paste0("word/", xml_attr(relationships, "Target")))
stopifnot(!any(grepl("(^|/)\\.\\.(/|$)", kept)))

# Retain only images actually referenced by selected headers/footers. Other
# relationships (objects, linked files, comments, hyperlinks) require review.
headers <- grep("^word/(header|footer)[0-9]+[.]xml$", kept, value = TRUE)
for (part in headers) {
  header <- read_part(part)
  relpath <- file.path(dirname(part), "_rels", paste0(basename(part), ".rels"))
  if (!file.exists(file.path(parts, relpath))) next
  hr <- read_part(relpath)
  links <- xml_find_all(hr, "/pr:Relationships/pr:Relationship", rel_ns)
  ids <- xml_text(xml_find_all(header, "//@r:embed | //@r:id", ns))
  xml_remove(links[!xml_attr(links, "Id") %in% ids])
  links <- xml_find_all(hr, "/pr:Relationships/pr:Relationship", rel_ns)
  stopifnot(all(grepl("/image$", xml_attr(links, "Type"))),
            !any(xml_attr(links, "TargetMode") == "External", na.rm = TRUE))
  images <- paste0("word/", xml_attr(links, "Target"))
  stopifnot(!any(grepl("(^|/)\\.\\.(/|$)", images)))
  kept <- c(kept, relpath, images)
  write_part(hr, relpath)
}

for (part in c("word/footnotes.xml", "word/endnotes.xml")) {
  if (!part %in% kept) next
  notes <- read_part(part)
  xml_remove(xml_find_all(notes,
    "/*/*[not(@w:type='separator' or @w:type='continuationSeparator')]", ns))
  write_part(notes, part)
}

# Remove editing history, personal identifiers, hidden objects and external
# template bindings. Keep the visible corporate drawing and its VML fallback.
for (part in grep("[.]xml$", kept, value = TRUE)) {
  if (grepl("^docProps/|^\\[Content_Types\\]", part)) next
  xml <- read_part(part)
  remove <- paste0("//*[local-name()='", c("rsids", "rsid", "commentRangeStart",
    "commentRangeEnd", "commentReference", "del", "moveFrom", "pPrChange",
    "rPrChange", "sectPrChange", "tblPrChange", "tblGridChange", "trPrChange",
    "tcPrChange", "numberingChange", "attachedTemplate", "mailMerge",
    "trackRevisions", "revisionView", "docId", "printerSettings"), "']")
  xml_remove(xml_find_all(xml, paste(remove, collapse = " | ")))
  additions <- xml_find_all(xml, "//w:ins | //w:moveTo", ns)
  for (node in additions) {
    for (child in xml_children(node)) xml_add_sibling(node, child, .where = "before")
    xml_remove(node)
  }
  # gfxdata is an encoded auxiliary Office package, not required to display
  # the fallback shape. Removing it avoids a second, hidden metadata store.
  attrs <- xml_find_all(xml, paste0("//@*[starts-with(local-name(), 'rsid')",
    " or local-name()='gfxdata' or local-name()='paraId'",
    " or local-name()='textId' or local-name()='durableId'",
    " or local-name()='author' or local-name()='date']"))
  xml_remove(attrs)
  picture_names <- xml_find_all(xml, "//*[local-name()='cNvPr']/@name")
  if (length(picture_names)) xml_text(picture_names) <- "Corporate cover artwork"
  write_part(xml, part)
}

core <- read_xml(paste0('<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/',
  'package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/">',
  '<dc:title>eatTechReport report layout</dc:title>',
  '<dc:creator>eatTechReport</dc:creator></cp:coreProperties>'))
write_part(core, "docProps/core.xml")
app <- read_xml(paste0('<Properties xmlns="http://schemas.openxmlformats.org/',
  'officeDocument/2006/extended-properties">',
  '<Application>eatTechReport</Application></Properties>'))
write_part(app, "docProps/app.xml")
root <- read_part("_rels/.rels")
root_links <- xml_find_all(root, "/pr:Relationships/pr:Relationship", rel_ns)
xml_remove(root_links[!xml_attr(root_links, "Target") %in%
  c("docProps/core.xml", "docProps/app.xml", "word/document.xml")])
write_part(root, "_rels/.rels")

# Remove EXIF/XMP/IPTC/comments without recompressing the approved cover image.
# Preserve ICC colour profiles, JPEG decoding segments and the entropy stream.
strip_jpeg_metadata <- function(path) {
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  stopifnot(identical(as.integer(bytes[1:2]), c(255L, 216L)))
  chunks <- list(bytes[1:2])
  i <- 3L
  while (i <= length(bytes)) {
    stopifnot(bytes[[i]] == as.raw(255L))
    marker <- as.integer(bytes[[i + 1L]])
    if (marker == 217L) {
      chunks[[length(chunks) + 1L]] <- bytes[i:(i + 1L)]
      break
    }
    size <- as.integer(bytes[[i + 2L]]) * 256L + as.integer(bytes[[i + 3L]])
    end <- i + size + 1L
    stopifnot(size >= 2L, end <= length(bytes))
    private <- marker %in% c(225L, 227L:237L, 239L, 254L)
    if (!private) chunks[[length(chunks) + 1L]] <- bytes[i:end]
    i <- end + 1L
    if (marker == 218L) {
      start <- i
      while (i < length(bytes)) {
        if (bytes[[i]] == as.raw(255L) &&
            !as.integer(bytes[[i + 1L]]) %in% c(0L, 208L:215L, 255L)) break
        i <- i + 1L
      }
      if (i > start) chunks[[length(chunks) + 1L]] <- bytes[start:(i - 1L)]
    }
  }
  writeBin(do.call(c, chunks), path)
}
for (part in grep("^word/media/", kept, value = TRUE)) {
  if (!grepl("[.]jpe?g$", part, ignore.case = TRUE)) {
    stop("Review image metadata before adding this media format: ", part)
  }
  strip_jpeg_metadata(file.path(parts, part))
}

# Content-type entries and ZIP members must agree exactly; no unreferenced
# glossary, custom XML, thumbnails, printer information or media are shipped.
types <- read_part("[Content_Types].xml")
overrides <- xml_find_all(types, "/ct:Types/ct:Override", ct_ns)
xml_remove(overrides[!sub("^/", "", xml_attr(overrides, "PartName")) %in% kept])
write_part(types, "[Content_Types].xml")
all_files <- list.files(parts, recursive = TRUE, all.files = TRUE, no.. = TRUE)
unlink(file.path(parts, setdiff(all_files, kept)))
if (exists("apply_report_layout", mode = "function")) apply_report_layout(parts)
pack_word_package(parts, target)
stopifnot(identical(dirname(normalizePath(build, winslash = "/")),
                    normalizePath(tempdir(), winslash = "/")))
unlink(build, recursive = TRUE)
message("Prepared the sanitized layout: ", target)
