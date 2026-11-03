# eatTechReport

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="man/figures/logo-dark.png">
  <img src="man/figures/logo-light.png" alt="eatTechReport-Logo: Schreibmaschine mit Berichtseite" align="right" width="160">
</picture>

<!-- badges: start -->
[![R-CMD-check](https://github.com/sachseka/eatTechReport/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/sachseka/eatTechReport/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/sachseka/eatTechReport/graph/badge.svg)](https://app.codecov.io/gh/sachseka/eatTechReport)
<!-- badges: end -->

eatTechReport entwickelt Technische Berichte für VERA-3 aus vorhandenen
Auswertungsergebnissen und redigierbaren Quarto-Textbausteinen. Der aktuelle
Paketstand umfasst **Testdesign, Stichprobenbeschreibung und Leistung der
Pilotierungsstichprobe**: Eingabeprüfung, Aufgaben- und Itemzahlen,
Testheftaufbau, Rücklauf, Hintergrundmerkmale, gültige Antwortzahlen,
PV-Kennzahlen und Dichtegrafiken. Die Word-Ausgabe verwendet die mitgelieferte,
freigegebene Corporate-Vorlage. Weitere Kapitel werden schrittweise ergänzt.
Mit `scope = "haupttest_struktur"` kommen die Haupttest-Auswahl, ihre
Pilotierungswellen sowie Modulübersichten und Aufgabenreihenfolgen hinzu.

## Installation und erster Einstieg

Im ausgecheckten Projekt in R:

```r
# Falls noch nicht vorhanden:
install.packages("remotes")
remotes::install_local(".", dependencies = NA)

library(eatTechReport)
demo <- example_report(
  profile = "v3_de_lesen_zuhoeren",
  seed = 42,
  n_persons = 200,
  n_pv = 15,
  main_year = 2027,
  pilot_year = 2026  # Demoannahme
)

validate_report_input(demo)
kennzahlen <- summarise_report_input(demo)
kennzahlen$design$pool
kennzahlen$sample$characteristics$gender
kennzahlen$descriptives
kennzahlen$percentages
plot_performance(demo, scale_id = "DL")
```

`seed` steuert die reproduzierbare Simulation; Haupttest- und Pilotierungsjahr
sind separate Angaben. Alle Beispielangaben sind synthetisch, einschließlich
Testdesign, Stichprobe, Antwortzahlen und illustrativer Cuts.
Für Mathematik steht das Profil `v3_ma_mg_mm` mit der globalen Skala `MO` bereit.

`example_report()` erzeugt standardmäßig `scope = "pilotierung"` mit Schema
`0.3.0-draft`. Für die Leistungsdarstellung allein bleiben
`example_leistung_input()` und `example_report(scope = "pilotierung_leistung")`
verfügbar. Die Leistungsfunktionen können auch vollständige Berichtsobjekte
verarbeiten; `validate_leistung_input()` prüft dabei den PV-Teil.
`validate_report_input()` prüft zusätzlich Testdesign und Stichprobe.
Der erweiterte Umfang `haupttest_struktur` verwendet Schema `0.4.0-draft`
und prüft außerdem `data$main_test`:

```r
demo_haupttest <- example_report(scope = "haupttest_struktur")
haupttest <- summarise_report_input(demo_haupttest)$main_test
haupttest$modules
haupttest$tasks
```

## Word-Bericht und Textredaktion

Für die Dokumenterzeugung wird zusätzlich [Quarto](https://quarto.org/) benötigt.
Die freigegebene Corporate-Vorlage wird mit dem Paket ausgeliefert und automatisch
verwendet (`corporate_template = NULL`). Im Quellpaket liegt sie unter
`inst/templates/eatTechReport.docx`. Demo und reale Daten verwenden dieselbe
Gestaltung mit Arial ab 11 pt und 1,5-fachem Zeilenabstand. Bei Bedarf kann
`corporate_template` auf eine andere freigegebene DOTX- oder DOCX-Datei verweisen.

Für die automatische Aktualisierung von Inhaltsverzeichnis und Seitenzahlen
verwendet dieser Stand unter Windows zusätzlich ein installiertes Microsoft
Word. Mit der Voreinstellung `update_fields = "auto"` erfolgt dieser Schritt
ohne sichtbares Word-Fenster. Ohne verfügbare Word-Automatisierung wird das DOCX
erzeugt, aber die noch ausstehende Feldaktualisierung ausdrücklich gemeldet.

```r
bericht <- render_report(
  config = demo$config,
  data = demo$data,
  output_dir = "lokal/demo-de"
)
bericht$path
bericht$manifest$fields_updated
```

Autoren und gemeinsame Affiliation vor dem Rendern in der Berichtskonfiguration setzen:

```r
demo$config$report$authors <- c("Erika Muster", "Max Muster")
demo$config$report$affiliation <- "Institut für Beispielstudien an der Universität Musterstadt"
```

Alternativ können beide Angaben direkt an `example_report()` übergeben werden.
Ohne Angaben erscheinen Platzhalter in eckigen Klammern auf dem Deckblatt.

Der Bericht enthält derzeit die Abschnitte Testdesign, Stichprobe und Leistung
und kennzeichnet synthetische Eingaben sichtbar. Ein vollständiger Technischer
Bericht mit empirischer Itemgüte, Itemprofilen und Umrechnungsformeln ist noch
nicht umgesetzt. Auswahl und Modulstruktur der Hauptstudie sind optional verfügbar.
Bestehende Ausgaben werden standardmäßig nicht überschrieben.

Die Texte lassen sich als Quarto-Dateien in einen eigenen Arbeitsordner kopieren:

```r
edit_report_texts("lokal/redaktion")

# Quarto-Texte in lokal/redaktion bearbeiten, dann erneut erzeugen:
bericht <- render_report(
  config = demo$config,
  data = demo$data,
  text_dir = "lokal/redaktion",
  output_dir = "lokal/demo-redigiert"
)
```

Die Voreinstellung kopiert acht Bausteine für `scope = "pilotierung"`.
Mit `scope = "haupttest_struktur"` werden zehn Bausteine kopiert, darunter
`haupttest_auswahl.qmd` und `haupttest_module.qmd`.
Mit `scope = "pilotierung_leistung"` werden die drei bisherigen Bausteine für
eine reine Leistungsdarstellung kopiert. Der Textordner muss alle Bausteine
des beim Rendern verwendeten Umfangs enthalten.

Reale Eingaben, Altberichte, redigierte Texte, Corporate-Berichte und ihre
Archivdateien bleiben lokal. Die freigegebene Layoutvorlage ist Bestandteil
des Pakets. Der Renderer legt einen nachvollziehbaren
Arbeitsstand ab; fachliche Vorjahresvergleiche und Randmarkierungen folgen später.

## Eingaben und fachliche Regeln

- PVs liegen bereits auf der 500er-Berichtsskala vor; erwartet werden
  voraussichtlich 15 vollständige PVs je Person und Skala.
- Die Leistungsdarstellung berücksichtigt alle angegebenen Personen,
  ungewichtet und ohne Untergruppen.
- Deutsch verwendet `DL`, `DH`, `DO`, `DS`. Die Mathematik-Leitideen `MZ`, `MG`,
  `MM`, `MR`, `MD` verweisen auf die gemeinsame Skala `MO`.
- Kennzahlen werden zunächst je PV berechnet und danach zusammengefasst.
  Die PVs werden nicht vorab je Person gemittelt.
- Die vorgesehenen Stufen heißen Ia, Ib, II, III, IV. Reale Grenzwerte benötigen
  ein fachlich freigegebenes Skalenprofil.
- Aufgaben und Items werden über eindeutige IDs gezählt; Wiederverwendungen
  in Blöcken und Heften erhöhen ihre Gesamtanzahl nicht.
- Teilnahme und Auswertungspopulation werden getrennt beschrieben. Die
  Hintergrundmerkmale beziehen sich auf eindeutige Auswertungspersonen;
  fehlende kategoriale Angaben erscheinen als „keine Angabe“ im Prozentnenner.
- Itembearbeitungszahlen bezeichnen gültige beziehungsweise bewertbare
  Antworten (`Nvalid`) nach einer ausdrücklich dokumentierten Auswertungsregel.
  Die Kennwerte der Ankeritems stehen in einer eigenen Fußnote.

Der Artikel [Testdesign und Stichprobenbeschreibung](vignettes/pilotierung.qmd)
erläutert die zusätzlichen R-Objekte `data$design` und `data$sample`.
[Leistungskennzahlen und Plausible Values](vignettes/leistung.qmd) beschreibt
die PV-Eingaben und ihre Berechnungsregeln.
[Haupttest-Auswahl und Module](vignettes/haupttest.qmd) beschreibt das separate
Haupttestinventar, Wiederverwendungen, Herkunftswellen und Aufgabenreihenfolgen.

## Dokumentation und Entwicklung

GitHub Actions prüft das Paket auf Windows, macOS und Linux sowie mit R-release,
R-devel und R-oldrel-1. Ein eigener Workflow misst die R-Testabdeckung mit `covr`
und übermittelt den Bericht an Codecov. Die Tests verwenden ausschließlich
synthetische Daten und Word-XML-Beispiele; Microsoft Word ist keine
Voraussetzung für diese Prüfungen.

Codecov ist für das öffentliche Repository eingerichtet. Der Upload verwendet
[OIDC-Authentifizierung](https://github.com/codecov/codecov-action#using-oidc)
und benötigt kein zusätzliches Upload-Secret. Für ein neues Repository muss
die [Codecov-GitHub-App](https://docs.codecov.com/docs/quick-start) zunächst
Zugriff erhalten.

Die tatsächliche Word-Automation und die visuelle Kontrolle der Corporate-Ausgabe
werden zusätzlich lokal geprüft. Eine hohe R-Testabdeckung ersetzt diese
Integrationsprüfung nicht.

Die pkgdown-Website wird lokal mit synthetischen Beispielen erzeugt:

```r
# Falls noch nicht vorhanden:
install.packages("pkgdown")
pkgdown::build_site(preview = FALSE)
```

Das Ausgabeziel ist `_pkgdown/`. Interne Arbeitsunterlagen werden außerhalb
des Repositories unter `lokal/planung/` gepflegt.
Website-Beispiele greifen nicht auf private Dateien oder reale Daten zu.
Der Website-Build veröffentlicht nichts.

Unter Windows außerhalb von RStudio benötigt R gegebenenfalls den Pfad zum
mit Quarto gelieferten Pandoc. Liegen Projekt und temporärer Ordner auf
unterschiedlichen Laufwerken, kann Quarto außerdem einen ungültigen
Ausgabepfad bilden. Für diesen Fall im Projektordner in PowerShell ausführen:

```powershell
$quartoBin = Split-Path (Get-Command quarto).Source
$env:RSTUDIO_PANDOC = Join-Path $quartoBin 'tools'
$pkgdownTemp = Join-Path (Get-Location) 'lokal/pkgdown-tmp'
New-Item -ItemType Directory -Path $pkgdownTemp -Force | Out-Null
$env:TMPDIR = $pkgdownTemp
$env:TMP = $pkgdownTemp
$env:TEMP = $pkgdownTemp
Rscript --vanilla -e "pkgdown::build_site(preview = FALSE)"
```

Die Einstellungen gelten nur für diese PowerShell-Sitzung und ihre
Unterprozesse. Das Paket muss vor dem Website-Build installiert sein. Falls
R bereits eine ungültige `C.UTF-8`-Ländereinstellung meldet, kann in der hier
geprüften deutschen Windows-Umgebung zusätzlich vor dem R-Aufruf
`$env:LC_ALL = 'German_Germany.utf8'` gesetzt werden.

Die historischen Quarto-Berichte gehören nicht zur neuen Paket-API.
[Logo-Varianten und Herkunft](design/README.md) sind separat dokumentiert.
