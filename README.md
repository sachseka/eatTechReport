# eatTechReport

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="man/figures/logo-dark.png">
  <img src="man/figures/logo-light.png" alt="eatTechReport-Logo: Schreibmaschine mit Berichtseite" align="right" width="160">
</picture>

<!-- badges: start -->
[![R-CMD-check](https://github.com/sachseka/eatTechReport/actions/workflows/R-CMD-check.yaml/badge.svg?branch=main)](https://github.com/sachseka/eatTechReport/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/sachseka/eatTechReport/graph/badge.svg)](https://app.codecov.io/gh/sachseka/eatTechReport)
[![pkgdown](https://github.com/sachseka/eatTechReport/actions/workflows/pkgdown.yaml/badge.svg?branch=main)](https://github.com/sachseka/eatTechReport/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

[Website und Funktionsreferenz](https://sachseka.github.io/eatTechReport/)

eatTechReport entwickelt Technische Berichte für VERA-3 aus vorhandenen
Auswertungsergebnissen und redigierbaren Quarto-Textbausteinen. Der aktuelle
Paketstand erzeugt mit `scope = "bericht"` einen **durchgängigen Beispielbericht
bis zum Literaturverzeichnis**: Grundlagen, Testdesign, Stichprobenbeschreibung
und Kompetenz der Pilotierungsstichprobe, Haupttest-Auswahl und Module,
Itemkennwerte, Umrechnungsformeln sowie Hinweise zur Auswertung und Rückmeldung.
Die Word-Ausgabe verwendet die mitgelieferte, freigegebene Corporate-Vorlage.
Die Aufgabenmatrix stellt die Aufgabenfolgen der Module nebeneinander dar.
Die Stufengrafiken folgen den bisherigen Berichten: In Deutsch stehen die
Module einer Skala zusammen; in Mathematik steht das Basismodul separat und
die Ergänzungsmodule werden je Leitidee verglichen. Schmale Balken, kurze
Legenden rechts und dieselben Corporate-Farben werden wiederverwendet.
Die bisherigen Teilumfänge bleiben verfügbar; die fachliche Textredaktion
wird weitergeführt.

## Installation und erster Einstieg

Den Entwicklungsstand von GitHub in R installieren:

```r
# Falls noch nicht vorhanden:
install.packages("remotes")
remotes::install_github("sachseka/eatTechReport", dependencies = NA)

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

In einem lokalen Checkout stattdessen `remotes::install_local(".", dependencies = NA)`
verwenden. Die folgenden Beispiele arbeiten mit dem installierten Paket.

`seed` steuert die reproduzierbare Simulation; Haupttest- und Pilotierungsjahr
sind separate Angaben. Alle Beispielangaben sind synthetisch, einschließlich
Testdesign, Stichprobe, Antwortzahlen und illustrativer Cuts.
Für Mathematik steht das Profil `v3_ma_mg_mm` mit der globalen Skala `MO` bereit.

`example_report()` erzeugt standardmäßig `scope = "pilotierung"` mit Schema
`0.3.0-draft`. Für die Kompetenzdarstellung allein bleiben
`example_leistung_input()` und `example_report(scope = "pilotierung_leistung")`
verfügbar. Die Funktionen für Kompetenzkennwerte können auch vollständige Berichtsobjekte
verarbeiten; `validate_leistung_input()` prüft dabei den PV-Teil.
`validate_report_input()` prüft zusätzlich Testdesign und Stichprobe.
Der erweiterte Umfang `haupttest_struktur` verwendet Schema `0.4.0-draft`
und prüft außerdem `data$main_test`:

```r
demo_haupttest <- example_report(scope = "haupttest_struktur")
haupttest <- summarise_report_input(demo_haupttest)$main_test
haupttest$modules
haupttest$tasks
plot_item_levels(demo_haupttest, "DL", by = "module")
```

Die optionale R-Tabelle `data$main_test$item_levels` enthält `item_id` und
`level_label` für jedes ausgewählte Item. Die Stufenzuordnung stammt aus der
vorgelagerten Auswertung; die Beispieldaten enthalten illustrative Zuordnungen.
Die zusätzliche API-Ansicht `plot_item_levels(demo_haupttest, "DL")` zählt die
eindeutigen Items der Gesamtauswahl; sie wird nicht zusätzlich in den Bericht
aufgenommen. Aufgabentitel werden als `data$main_test$items$task_label` in R
übergeben und müssen innerhalb jeder `task_id` übereinstimmen. Der
[Haupttest-Artikel](vignettes/haupttest.qmd) zeigt die Zuordnung eigener Titel.

Für den vollständigen Beispielbericht steht Schema `0.5.0-draft` bereit:

```r
demo_bericht <- example_report(scope = "bericht")
validate_report_input(demo_bericht)
ergebnisse <- summarise_report_input(demo_bericht)
ergebnisse$main_test_results$module_statistics
ergebnisse$main_test_results$transformations
```

Für einen umfangreicheren Beispielbericht mit mehreren hundert Pilotierungsitems,
zahlreichen Heftversionen und größeren Haupttestmodulen:

```r
demo_gross <- example_report(scope = "bericht", size = "realistic", seed = 42)
```

Dieser Modus verwendet standardmäßig 2.400 Personen je Skala und 15 PVs.
`n_persons` und `n_pv` bleiben frei wählbar. Das kompakte Beispiel bleibt mit
`size = "small"` der Standard. Auch die größeren Daten sind vollständig simuliert.

Auswertungskonventionen werden separat als R-Objekt übergeben. Zum Beispiel:

```r
demo_gross$config$conventions <- report_conventions(
  discrimination_target = 0.30,
  discrimination_min = 0.15,
  infit_max = 1.15,
  infit_exception_max = 1.30
)
validate_report_input(demo_gross)
```

Dies sind Beispielwerte, keine Vorgaben für einen Durchgang. Die gelieferten
Schwellen erscheinen im Text ohne zusätzliche Klammern, etwa `0,30`, und werden im
Simulationsmodus gelb markiert. Die Konventionen steuern die Beschreibung;
die Itemauswahl und die Auswertung erfolgen weiterhin vorgelagert. Sie sind
von den Kompetenzstufengrenzen in `config$scales` getrennt. Die
[Konventionen-Anleitung](vignettes/konventionen.qmd) erläutert Wertebereiche,
Vergleichsoperatoren und die optionalen Angaben zur Verlinkung.

Dieser Umfang benötigt zusätzlich `data$main_test_results` mit den Tabellen
`item_statistics` (`item_id`, `p_correct`, `logit`) und `transformations`
(`scale_id`, `target`, `intercept`, `slope`, `source_label`) sowie den
Beschreibungstexten `definitions$p_correct`, `definitions$logit` und
`definitions$population`. Je Skala werden eigene Koeffizienten für Personen
(`target = "person"`) und Items (`target = "item"`) geliefert. Die Umrechnung
lautet `Berichtswert = intercept + slope * Logitwert`.
**Die Demokoeffizienten sind rein synthetisch.** Reale Itemkennwerte und
freigegebene Transformationen kommen aus der vorgelagerten Auswertung.
Bereits auf der Berichtsskala vorliegende Personen-PVs werden nicht erneut
umgerechnet. Die Word-Ausgabe bündelt Auswahl, Module, Itemkennwerte,
Aufgabenmatrix und Stufengrafiken in Abschnitt 3.1. Abschnitt 3.2 enthält die
Auswertungshinweise mit der allgemeinen Personentransformation und einer
Tabelle der Referenzmittelwerte und -standardabweichungen; Abschnitt 3.3 die
Rückmeldungsempfehlungen. Die Referenzwerte werden rechnerisch aus den
gelieferten Personenkoeffizienten dargestellt. Die R-Eingaben und Ergebnisse
enthalten weiterhin die getrennten Personen- und Itemkoeffizienten.

## Word-Bericht und Textredaktion

Für die Dokumenterzeugung wird zusätzlich [Quarto](https://quarto.org/) benötigt.
Die freigegebene Corporate-Vorlage wird mit dem Paket ausgeliefert und automatisch
verwendet (`corporate_template = NULL`). Im Quellpaket liegt sie unter
`inst/templates/eatTechReport.docx`. Demo und reale Daten verwenden dieselbe
Gestaltung mit Arial ab 11 pt und 1,5-fachem Zeilenabstand im Fließtext.
Abbildungsanmerkungen verwenden Arial 10 pt und einfachen Zeilenabstand.
Bei Bedarf kann
`corporate_template` auf eine andere freigegebene DOTX- oder DOCX-Datei verweisen.

Abbildungen und Tabellen erhalten Beschriftungen mit Kapitelnummern und
Verweise im Fließtext. Verknüpfte Verweise erscheinen in Corporate-Weinrot.
Erläuterungen stehen als *Anmerkungen* außerhalb der Grafiken.
Die Kompetenzverteilung zeigt *N*, *M*, *SD* und die Stufenanteile;
zusätzliche Tabellen mit denselben PV-Kennwerten entfallen im Word-Bericht.
Die Heftdesign-Matrix zeigt Blockbezeichnungen ohne Minutenangaben in den
Zellen, schmale leere Pausenspalten und ausdrücklich angegebene
Normierungsblöcke (`data$design$blocks$is_norming`). Zeiten stehen in der
Anmerkung. Die Aufgabenmatrix verwendet kurze Modulüberschriften und
Corporate-Schattierungen.

Für die automatische Aktualisierung von Inhaltsverzeichnis und Seitenzahlen
verwendet dieser Stand unter Windows zusätzlich ein installiertes Microsoft
Word. Mit der Voreinstellung `update_fields = "auto"` erfolgt dieser Schritt
ohne sichtbares Word-Fenster. Ohne verfügbare Word-Automatisierung wird das DOCX
erzeugt, aber die noch ausstehende Feldaktualisierung ausdrücklich gemeldet.

```r
# Angaben für das Deckblatt vor dem Rendern setzen:
demo_bericht$config$report$authors <- c("Erika Muster", "Max Muster")
demo_bericht$config$report$affiliation <- "Institut für Beispielstudien an der Universität Musterstadt"

bericht <- render_report(
  config = demo_bericht$config,
  data = demo_bericht$data,
  output_dir = "lokal/demo-de"
)
bericht$path
bericht$manifest$fields_updated
```

Alternativ können Autoren und gemeinsame Affiliation direkt an `example_report()` übergeben werden.
Ohne Angaben erscheinen Platzhalter in eckigen Klammern auf dem Deckblatt.

Der Umfang `bericht` enthält alle vorgesehenen Kapitel bis zur Literatur.
Im Modus „Simulierte Daten“ (`config$report$data_origin = "synthetic"`)
werden daten- und konfigurationsabhängige Angaben im Word-Text gelb hinterlegt,
einschließlich Tabellenwerten und Deckblattangaben. Bei realen Eingaben
(`"observed"`) entfällt diese Markierung. Noch auszufüllende Textstellen
stehen weiterhin in eckigen Klammern.
Die fachliche Prüfung und Redaktion der Texte bleiben Teil der Vorbereitung
eines realen Berichts. Bestehende Ausgaben werden standardmäßig nicht überschrieben.

Die Texte lassen sich als Quarto-Dateien in einen eigenen Arbeitsordner kopieren:

```r
edit_report_texts("lokal/redaktion", scope = "bericht")

# Quarto-Texte in lokal/redaktion bearbeiten, dann erneut erzeugen:
bericht <- render_report(
  config = demo_bericht$config,
  data = demo_bericht$data,
  text_dir = "lokal/redaktion",
  output_dir = "lokal/demo-redigiert"
)
```

Für `scope = "bericht"` werden 15 öffentliche Quarto-Bausteine kopiert,
einschließlich Itemkennwerten, Transformationen, Auswertungshinweisen,
Rückmeldungsempfehlungen und Literatur. Die Voreinstellung ohne `scope`
kopiert weiterhin acht Bausteine für `scope = "pilotierung"`.
Mit `scope = "haupttest_struktur"` werden zehn Bausteine kopiert, darunter
`haupttest_auswahl.qmd` und `haupttest_module.qmd`.
Mit `scope = "pilotierung_leistung"` werden die drei bisherigen Bausteine für
eine reine Kompetenzdarstellung kopiert. Der Textordner muss alle Bausteine
des beim Rendern verwendeten Umfangs enthalten.

Reale Eingaben, Altberichte, redigierte Texte, Corporate-Berichte und ihre
Archivdateien in einem privaten, von Git ausgeschlossenen Ordner wie `lokal/`
ablegen. Der Renderer schreibt in das angegebene `output_dir`; er richtet
keinen Git-Ausschluss ein. Die freigegebene Layoutvorlage ist Bestandteil
des Pakets. Der Renderer legt einen nachvollziehbaren
Arbeitsstand ab; fachliche Vorjahresvergleiche und Randmarkierungen folgen später.

## Eingaben und fachliche Regeln

- PVs liegen bereits auf der 500er-Berichtsskala vor. Die Beispiele erzeugen
  standardmäßig 15 PVs; die Anzahl ist konfigurierbar. Erforderlich sind
  vollständige PV-Sätze und mindestens zwei Personen je Skala.
- Die Kompetenzdarstellung berücksichtigt alle angegebenen Personen,
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
[Kompetenzkennwerte und Plausible Values](vignettes/leistung.qmd) beschreibt
die PV-Eingaben und ihre Berechnungsregeln.
[Haupttest-Auswahl und Module](vignettes/haupttest.qmd) beschreibt das separate
Haupttestinventar, Wiederverwendungen, Herkunftswellen, Aufgabenmatrix und
Stufengrafiken sowie die Eingaben für den vollständigen Beispielbericht.

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
Die [App-Konfiguration](https://github.com/apps/codecov/installations/select_target)
erlaubt unter **Only select repositories** eine Freigabe nur für dieses
Repository. Ein Repository-Secret ersetzt diese App-Freigabe nicht; auch nach
einem erfolgreichen Upload kann Codecov auf die noch fehlende App hinweisen.

Die tatsächliche Word-Automation und die visuelle Kontrolle der Corporate-Ausgabe
werden zusätzlich lokal geprüft. Eine hohe R-Testabdeckung ersetzt diese
Integrationsprüfung nicht.

Die Website wird mit pkgdown ab Version 2.1.0 und Quarto ab Version 1.5
lokal aus synthetischen Beispielen erzeugt:

```r
# Falls noch nicht vorhanden:
install.packages("pkgdown")
pkgdown::build_site(preview = FALSE)
```

Das Ausgabeziel ist `_pkgdown/`. Interne Arbeitsunterlagen werden im von Git
ausgeschlossenen Projektordner `lokal/planung/` gepflegt.
Website-Beispiele greifen nicht auf private Dateien oder reale Daten zu.
Dieser lokale Website-Build veröffentlicht nichts. Der GitHub-Workflow
`pkgdown.yaml` baut und prüft die Website bei Pull Requests. Ein erfolgreicher
Lauf auf `main` veröffentlicht sie über GitHub Pages. Dafür ist in den
Repository-Einstellungen **Pages → Build and deployment → GitHub Actions**
erforderlich. Der Workflow nutzt die bereits freigegebenen Actions und die
GitHub-Pages-API; zusätzliche Secrets werden nicht benötigt. Die Badges zeigen
den Stand von `main`. Private Originalberichte und lokale Renderablagen werden
auch dabei nicht verwendet.

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
