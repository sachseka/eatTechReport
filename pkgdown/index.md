# eatTechReport

<!-- badges: start -->
[![R-CMD-check](https://github.com/sachseka/eatTechReport/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/sachseka/eatTechReport/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/sachseka/eatTechReport/graph/badge.svg)](https://app.codecov.io/gh/sachseka/eatTechReport)
<!-- badges: end -->

eatTechReport verbindet vorhandene Auswertungsergebnisse mit redigierbaren
Quarto-Texten für Technische Berichte zu VERA-3.

Der aktuelle Entwicklungsstand umfasst **Testdesign, Stichprobe und Leistung**:
Aufgaben- und Itemzahlen, variable Testheftpläne, Rücklauf und
Stichprobenzusammensetzung, gültige Antwortzahlen sowie Plausible Values auf
der 500er-Berichtsskala. Daraus entstehen ungewichtete Kennzahlen,
Kompetenzstufenanteile, Dichtegrafiken und Word-Abschnitte nach der mitgelieferten,
freigegebenen Corporate-Vorlage. Ein vollständiger Technischer Bericht mit den weiteren
Methoden-, Itemgüte- und Haupttestkapiteln folgt schrittweise.

## Direkt ausprobieren

```r
library(eatTechReport)
demo <- example_report(n_persons = 200, seed = 42)
validate_report_input(demo)
ergebnis <- summarise_report_input(demo)
ergebnis$design$pool
ergebnis$sample$characteristics$gender
ergebnis$descriptives
plot_performance(demo, scale_id = "DL")
```

Die Beispiele verwenden synthetische Designs, Stichproben und Werte sowie
illustrative Grenzwerte.
Kennzahlen und Grafiken lassen sich direkt ausprobieren. Die Vorlage für
Word-Berichte ist bereits im Paket enthalten.

- [Einstieg](articles/einstieg.html): Beispieldaten erzeugen, prüfen und darstellen.
- [Testdesign und Stichprobe](articles/pilotierung.html): R-Eingaben für
  Aufgaben, Hefte, Rücklauf, Hintergrundmerkmale und gültige Antwortzahlen.
- [Leistungskennzahlen und PVs](articles/leistung.html): Eingabestruktur,
  Skalenkennungen und Berechnungsregeln.
- [Word-Bericht und Textredaktion](articles/textredaktion.html): Corporate-Vorlage,
  Quarto-Bausteine und lokale Renderablage.
- [Funktionsreferenz](reference/index.html): Argumente und Rückgabewerte.

## Lokal und nachvollziehbar

Die freigegebene Layoutvorlage ist Bestandteil des Pakets und wird mit
`corporate_template = NULL` automatisch verwendet. Ein eigener Pfad zu einer
freigegebenen DOTX- oder DOCX-Datei ist optional. Reale Eingaben, Altberichte,
redigierte Texte und erzeugte Corporate-Dokumente bleiben lokal.
Die Beispiele dieser Website verwenden ausschließlich
synthetische Daten; der Website-Build erzeugt keine Word-Berichte.

Das Paket schätzt keine PVs aus Itemantworten. Es prüft und verarbeitet bereits
vorliegende Ergebnisse. Für die reale Berichtserstellung sind fachlich
freigegebene Kompetenzstufengrenzen erforderlich.

Die automatisierten Tests prüfen Berechnungen, Eingaben und Berichtserzeugung
mit synthetischen Daten. R CMD check läuft auf Windows, macOS und Linux;
Codecov zeigt die Abdeckung des R-Codes. Die tatsächliche Word-Automation und
das Corporate-Layout werden zusätzlich lokal geprüft.
