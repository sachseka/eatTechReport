# Report layout

`eatTechReport.docx` is the package's approved Word layout reference. It contains
the corporate cover artwork, page geometry, headers, footers and paragraph
styles. It contains no report chapters, personal document properties, revision
history or links to an external template. Metadata embedded in the cover image
has also been removed without recompressing the image.

The reference is supplied with the package so reports do not depend on a local
template file. The rendering code also enforces Arial, a minimum body-text size
of 11 pt and 1.5 line spacing. Figure notes use the dedicated `ReportFigureNote`
style with 10 pt Arial and single spacing. Hyperlinks and cross-references use
the corporate burgundy colour. Bibliography entries use `ReportBibliography`
with an 8 pt paragraph gap between sources and retain 1.5 line spacing within
each entry.

To rebuild the reference from an approved corporate DOTX, run
`tools/prepare-report-template.R` from the source repository and supply both the
source DOTX and destination DOCX paths explicitly. Source templates and historical
reports are not distributed. Corporate artwork and logos remain those of their
respective owners.
