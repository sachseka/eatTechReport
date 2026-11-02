# eatTechReport

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="man/figures/logo-dark.png">
  <img src="man/figures/logo-light.png" alt="eatTechReport-Logo: Schreibmaschine mit Berichtseite" align="right" width="160">
</picture>

eatTechReport entwickelt Technische Berichte für VERA-3 aus vorhandenen
Auswertungsergebnissen und redigierbaren Quarto-Textbausteinen. Der erste
Paketstand umfasst die **Leistung der Pilotierungsstichprobe**: Eingabeprüfung,
PV-Kennzahlen, Kompetenzstufenanteile, Dichtegrafiken und einen Word-Prototyp
nach der verbindlichen Corporate-Vorlage. Die weiteren Kapitel folgen dem
[Arbeitsplan](docs/ARBEITSPLAN.md).

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

validate_leistung_input(demo)
kennzahlen <- summarise_leistung_input(demo)
kennzahlen$descriptives
kennzahlen$percentages
plot_performance(demo, scale_id = "DL")
```

`seed` steuert die reproduzierbare Simulation; Haupttest- und Pilotierungsjahr
sind separate Angaben. Die Daten und Cuts des Beispiels sind rein illustrativ.
Für Mathematik steht das Profil `v3_ma_mg_mm` mit der globalen Skala `MO` bereit.

## Word-Bericht und Textredaktion

Für die Dokumenterzeugung wird zusätzlich [Quarto](https://quarto.org/) benötigt.
Die freigegebene Corporate-Vorlage liegt lokal unter `lokal/Bericht.dotx`.
Sie wird mit keinem Paket ausgeliefert. Demo und reale Daten verwenden dieselbe
Gestaltung.

Für die automatische Aktualisierung von Inhaltsverzeichnis und Seitenzahlen
verwendet dieser Stand unter Windows zusätzlich ein installiertes Microsoft
Word. Mit der Voreinstellung `update_fields = "auto"` erfolgt dieser Schritt
ohne sichtbares Word-Fenster. Ohne verfügbare Word-Automatisierung wird das DOCX
erzeugt, aber die noch ausstehende Feldaktualisierung ausdrücklich gemeldet.

```r
bericht <- render_report(
  config = demo$config,
  data = demo$data,
  corporate_template = "lokal/Bericht.dotx",
  output_dir = "lokal/demo-de"
)
bericht$path
bericht$manifest$fields_updated
```

Der Bericht enthält derzeit den Leistungsabschnitt und kennzeichnet simulierte
Daten sichtbar. Ein vollständiger Technischer Bericht mit Testdesign,
Itemkennwerten und Haupttestkapiteln ist noch nicht umgesetzt. Bestehende
Ausgaben werden standardmäßig nicht überschrieben.

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

Vorlage, reale Eingaben, redigierte Texte, Corporate-Berichte und ihre
Archivdateien bleiben lokal. Der erste Stand schreibt eine nachvollziehbare
Renderablage; fachliche Vorjahresvergleiche und Randmarkierungen folgen später.

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

Der [Eingabevertrag](docs/SCHNITTSTELLE_LEISTUNG.md) beschreibt `config` und `data`.
Die [Kapitelmatrix](docs/KAPITELMATRIX.md) hält den vereinbarten Gesamtumfang fest.

## Dokumentation und Entwicklung

Die pkgdown-Website wird lokal mit synthetischen Beispielen erzeugt:

```r
# Falls noch nicht vorhanden:
install.packages("pkgdown")
pkgdown::build_site(preview = FALSE)
```

Das Ausgabeziel ist `_pkgdown/`; `docs/` enthält die Planungsquellen.
Website-Beispiele greifen nicht auf die private Word-Vorlage oder reale Daten
zu. Der Website-Build veröffentlicht nichts.

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

Die historischen Quarto-Berichte sind in der
[Dokumentation des Altbestands](docs/ALTBESTAND.md) beschrieben. Sie gehören
nicht zur neuen Paket-API. [Logo-Varianten und Herkunft](docs/LOGO.md) sind
separat dokumentiert.
