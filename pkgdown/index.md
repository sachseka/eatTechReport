# eatTechReport

eatTechReport verbindet vorhandene Auswertungsergebnisse mit redigierbaren
Quarto-Texten für Technische Berichte zu VERA-3.

Der erste Entwicklungsstand umfasst den **Leistungsabschnitt der
Pilotierungsstichprobe**: vollständige Plausible Values auf der
500er-Berichtsskala, ungewichtete Kennzahlen, Kompetenzstufenanteile,
Dichtegrafiken und einen Word-Prototyp nach der lokalen Corporate-Vorlage.
Die übrigen Berichtskapitel werden schrittweise ergänzt.

## Direkt ausprobieren

```r
library(eatTechReport)
demo <- example_report(n_persons = 200, seed = 42)
summarise_leistung_input(demo)$descriptives
plot_performance(demo, scale_id = "DL")
```

Die Beispiele verwenden simulierte Werte und illustrative Grenzwerte.
Kennzahlen und Grafiken lassen sich ohne Word-Vorlage ausprobieren.

- [Einstieg](articles/einstieg.html): Beispieldaten erzeugen, prüfen und darstellen.
- [Leistungskennzahlen und PVs](articles/leistung.html): Eingabestruktur,
  Skalenkennungen und Berechnungsregeln.
- [Word-Bericht und Textredaktion](articles/textredaktion.html): Corporate-Vorlage,
  Quarto-Bausteine und lokale Renderablage.
- [Funktionsreferenz](reference/index.html): Argumente und Rückgabewerte.

## Lokal und nachvollziehbar

Die freigegebene Vorlage `lokal/Bericht.dotx` ist für jeden Word-Bericht
verbindlich. Sie bleibt ebenso lokal wie reale Eingaben und erzeugte
Corporate-Dokumente. Die Beispiele dieser Website verwenden ausschließlich
synthetische Daten; der Website-Build erzeugt keine Word-Berichte.

Das Paket schätzt keine PVs aus Itemantworten. Es prüft und verarbeitet bereits
vorliegende Ergebnisse. Für die reale Berichtserstellung sind fachlich
freigegebene Kompetenzstufengrenzen erforderlich.
