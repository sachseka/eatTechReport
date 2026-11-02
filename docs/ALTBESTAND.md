# Dokumentation des Altbestands

Dieser Text dokumentiert die historischen Quarto-Berichte vor der neuen Paketstruktur. Aussagen zu fehlenden Paketfunktionen und alten Eingabeschnittstellen beziehen sich auf diesen Altbestand. Für den aktuellen Einstieg gilt die [README](../README.md).

## Wie funktioniert das Repository?

Das Repository enthält Quarto-Dokumente für einen technischen Bericht zu
VERA-3 Mathematik. Es ist eine Sammlung von Berichtsvorlagen, kein R-Paket.
Die umfangreichen Vorlagen sind auf die Hauptstudie 2025 und die Pilotierungen
2024/2023 zugeschnitten.

Beim Rendern führt Quarto die R-Codeblöcke mit knitr aus. Diese lesen vorhandene
Auswertungsdaten, verbinden Tabellen und berechnen beschreibende Kennzahlen.
Inline-R-Ausdrücke setzen Zahlen und Bezeichnungen in den Berichtstext ein.
Tabellen werden mit `knitr::kable()` und Diagramme mit ggplot2 erzeugt.
Quarto/Pandoc erstellt daraus mit der Word-Formatvorlage ein DOCX-Dokument.

```text
Aufbereitete Daten + vorhandene Skalierungsergebnisse + Metadaten
                              |
                         R in Quarto
                              |
              Text + Kennzahlen + Tabellen + Grafiken
                              |
          Word-Formatvorlage + Literatur + Zitierstil
                              |
                       TechRep_02.docx
```

Die im Bericht beschriebenen Schritte der Rekodierung, Rasch-Skalierung und
BISTA-Transformation werden hier nicht neu ausgeführt. Deren Ergebnisse
müssen bereits vorliegen. Auch die finale Itemauswahl wird eingelesen.

## Welche Dateien sind wichtig?

| Datei | Funktion |
| --- | --- |
| `TechRep_00.qmd` | Früher, kurzer Entwurf; benötigt `tidyverse`, aber keine externen Daten. Die Aufgabenanzahl ist als Platzhalter auf 0 gesetzt. |
| `TechRep_01.qmd` | Umfangreiche Berichtsvorlage mit externen Daten. |
| `TechRep_02.qmd` | Weiterentwickelte Fassung von 01, unter anderem mit Ausschluss der Ankeritems bei Pilotitem-Zählungen und getrennten Antwortstatistiken für Anker- und Pilotitems. |
| `TechRep_00.docx`, `TechRep_01.docx`, `TechRep_02.docx` | Bereits vorhandene Word-Berichte; ohne Rendern lesbar. |
| `TechRep_style.docx` | Word-Formatvorlage für das Rendern. |
| `Titelbild.jpg` | Bild im Bericht. |
| `references.bib`, `grateful-refs.bib` | Fachliteratur und Softwarezitate. |
| `deutsche-gesellschaft-fur-psychologie.csl` | In 01/02 aktiv eingebundener Zitierstil. `deutsche-sprache.csl` liegt ebenfalls bei, ist dort aber nicht eingebunden. |
| `grateful-report.html` | Vorhandener Bericht zu Softwarezitaten. |
| `V3-2024_MA-TechReport_2024-03-07.docx` | Vorjahresbericht, laut Nachbearbeitungsnotiz auch Vorlage für manuelle Layoutarbeiten. |
| `_Doku haendische Aenderungen.txt` | Checkliste zur manuellen Nachbearbeitung des Word-Berichts. |
| `QuarTechRepO.Rproj` | RStudio-Projektdatei; kann für die Arbeit im Projekt geöffnet werden. |

00, 01 und 02 sind eigenständige Dokumente, keine nacheinander auszuführenden
Pipeline-Schritte. Eine zentrale `_quarto.yml`, eine Paketdefinition und eine
`renv.lock` zur Fixierung von Paketversionen sind nicht vorhanden.

## Input für den vollständigen Bericht

Die ausführliche [Dokumentation der Eingabeschnittstellen](INPUTS.md)
beschreibt je Objekt die Felder, geeigneten Datentypen, Codes, Schlüssel,
Spaltenreihenfolgen, Fehlwertbehandlung und Beziehungen. Sie unterscheidet
Anforderungen des Berichtscodes von Befunden aus den lokalen R-Paketen und
noch ungeprüften Eigenschaften der externen Originaldateien.

`TechRep_02.qmd`, Zeilen 37–137, definiert Pakete, Einstellungen und Datenimport.
Die zehn externen Eingabedateien liegen nicht im Repository.
Die folgenden Felder sind aus ihrer Verwendung im Code abgeleitet;
die externen Dateien selbst wurden nicht geprüft.

| Eingabe | Erwartete Struktur / Verwendung |
| --- | --- |
| `V3-MA-2025_Pilot2024_Daten_2024-09-03.Rdata` | Muss `ls_data_save` mit mindestens fünf Elementen enthalten. Diese werden nach Position als `df_merged`, `df_recoded`, `df_aggregated`, `df_scored`, `df_mcoll` übernommen. Für die Berichtszahlen wird `df_merged` mit `idstud`, `ADaten_Alter`, `ADaten_BedingVeraendert`, `ADaten_Geschlecht`, `ADaten_Sprache` verwendet. |
| `GL_persons.csv` | Semikolon-CSV, über `read_csv2()` gelesen. `idstud` bestimmt, welche Personen zur ausgewerteten Stichprobe gehören. |
| `V3-MA-2025_Pilot2024_transformToBistaResults_2024-09-05.rds` | Liste `tf24`: `itemparsVera` mit unter anderem `iqbitem_id`, `domain`, `lh`, `logit`, `kstufe`; `itempars` mit `item` und `Nvalid`. |
| `V3-MA-2025_Pilot2024_transformToBistaResults_KA3a_2024-09-05.rds` | Liste `tf24a` mit `itemparsVera`; ergänzt fehlende Kennwerte der KA3a-Items. |
| `V3-MA-2024_Pilot2023_transformToBistaResults_2023-08-31.rds` | Liste `tf23` mit `itemparsVera`; Kennwerte für wiederverwendete Items aus der vorherigen Pilotierung. |
| `V3-MA-2025_Pilot2024_Itemparameter_2024-09-05.xlsx` | Blatt `Items`, verwendet werden `Modul`, `iqbitem_id`, `AufgID`. `Link` im Modulnamen identifiziert Ankeritems. |
| `V3-MA-2025-Pilot24_Inputliste_aus_R_240903.xlsx` | eatPrep-Inputliste im von `readDaemonXlsx()` erwarteten Format. Verwendet wird `$booklets` mit `booklet` und `block1` bis `block7`. |
| `Itemparameter VERA3-Mathematik-2025 Ma Modularisierung.csv` | Semikolon-CSV in Latin-1 mit `iqbitem_id`, `model`, `domain`, `iqbmodul_id`, `itemnr_mod`, `name`; liefert die Haupttestauswahl und Aufgabenreihenfolge. |
| `MA_VERA-3_Pilo2024_Rücklauf_100%_aus_Scanmanager.xlsx` | Erstes Blatt, Bereich `A4:G189`; verwendet werden `BL-ID` und `IST`. Zeilen werden als angefragte Klassen gezählt, `IST > 0` als realisierte Klassen. |
| `V3-MA-2025_Pilo2024_Hauptkodierung_uebereinstimmung.xlsx` | Blatt `Übereinstimmung_gesamt` mit `Variable`, `meankappa`, `meanagree`; liefert Angaben zur Kodierübereinstimmung. |

Zusätzlich werden die lokalen Dateien für Formatvorlage, Titelbild, Literatur
und Zitierstil benötigt. Fachliche Einstellungen wie `year`, `kb1`, `kb2`,
ihre Kürzel und `versanddienst` stehen direkt im Setup-Code.

### Annahmen, die bei anderen Daten angepasst werden müssen

- `pt_ausw` und `pt_ikw` zeigen auf `R:/VERA3/...`. Weitere absolute Pfade
  für die Vorjahresdaten, den Rücklauf und die Kodierübereinstimmung stehen
  separat im Code. Nur die beiden Basisverzeichnisse zu ändern reicht nicht.
- `idstud` muss zwischen Personendaten und Skalierungsdaten zusammenpassen.
  Die ersten zwei Zeichen werden als Bundeslandcode und die ersten acht als
  Klassen-ID interpretiert. Zwei Klassen werden durch einen fest eingebauten
  Hotfix Niedersachsen zugeordnet.
- `iqbitem_id` verbindet Itemtabellen. Modulbezeichnungen werden ab Zeichen 10
  aus `iqbmodul_id` extrahiert; erwartet werden etwa `GL-BM`, `GM-EM-A`,
  `GM-EM-B`, `DH-EM-A`, `DH-EM-B`.
- Die Kennwerttabellen verwenden `GL`, `GM`, `DH` (mit Umbenennung von `DHW`
  in `DH`); die Haupttestauswahl verwendet unter anderem `global`, `gm`, `dh`.
- Für die Zusammenführung werden jeweils die ersten acht Spalten von
  `itemparsVera` verwendet. Auch deren Reihenfolge und kompatible Struktur
  sind damit relevant.
- Fragebogencodes, erwartete Kategorien, Testheftaufbau und mehrere Textangaben
  sind fest eingebaut. Titel und Dateinamen folgen nicht automatisch `year`.
  Ein neues Erhebungsjahr erfordert deshalb auch eine Prüfung der Texte.

## Vollständigen Bericht rendern

Benötigt werden R, Quarto sowie `knitr`, `rmarkdown`, `tidyverse`, `glue`,
`grateful`, `eatPrep`, `eatModel`, `TAM`, `here` und `readxl` einschließlich
ihrer Abhängigkeiten. RStudio ist optional. Die Vorlagen verwenden die native
R-Pipe und die Kurzschreibweise für anonyme Funktionen aus R 4.1 oder neuer.
Zusätzliche Versionsanforderungen hängen von den installierten Paketen ab.

Nach Bereitstellung aller Daten und Anpassung der Pfade im Repository-Ordner:

```powershell
quarto render TechRep_02.qmd --to docx
```

Dies schreibt `TechRep_02.docx` und ersetzt einen vorhandenen Bericht gleichen
Namens. Zum Vergleich mit der vorhandenen Datei kann ein anderer Name verwendet
werden:

```powershell
quarto render TechRep_02.qmd --to docx --output TechRep_02_neu.docx
```

Der letzte R-Block ruft `grateful::cite_packages()` auf und schreibt
Softwarezitate im Repository-Ordner. Dabei können vorhandene grateful-Dateien
aktualisiert werden. Der feste Literaturverweis `@TAM_4.2-21` sollte mit den
tatsächlich erzeugten BibTeX-Schlüsseln abgeglichen werden.

Der Word-Bericht enthält allgemeine Informationen und Kompetenzstufen,
Testdesign und Stichprobenstatistiken, Angaben zur Kodierübereinstimmung,
Methodenbeschreibung, Haupttestmodule, Tabellen mit Itemkennwert-Zusammenfassungen
und Aufgabenlisten, drei Diagramme zur Kompetenzstufenverteilung sowie
Auswertungshinweise und Literatur.
Es werden keine neuen Skalierungsergebnisse oder Rückmeldungen für einzelne
Schulen erzeugt.

Für das endgültige Layout dokumentiert `_Doku haendische Aenderungen.txt`
Nacharbeiten an Titelseite, Tabellen, Beschriftungen, Silbentrennung,
Seitenumbrüchen, Fußzeile und Inhaltsverzeichnis. Diese Notiz bezieht sich
ausdrücklich auf `TechRep_01.docx`; auch 02 enthält noch entsprechende Layout-TODOs.

## Minimal Working Example ohne externe Studiendaten

Dieser Abschnitt hält ein zusätzliches lokales Arbeitsexperiment fest.
`TechRep_minimal.qmd` und `examples/items_minimal.csv` gehören nicht zum neuen
Paketstand; die folgenden Aufrufe setzen diese lokalen Dateien voraus.
Der aktuelle, mitgelieferte Einstieg ist `example_report()` aus dem R-Paket.

Das ergänzte `TechRep_minimal.qmd` demonstriert denselben Ablauf mit einer
kleinen CSV und der vorhandenen Word-Formatvorlage. Es benötigt nur R, Quarto,
`knitr` und `rmarkdown` einschließlich ihrer Abhängigkeiten.
Falls die beiden R-Pakete fehlen, einmal in R ausführen:

```r
install.packages(c("knitr", "rmarkdown"))
```

Im Repository-Ordner ausführen:

```powershell
quarto render TechRep_minimal.qmd --to docx
```

Alternativ `TechRep_minimal.qmd` in RStudio öffnen und **Render** anklicken.

Input ist `examples/items_minimal.csv`: fünf frei erfundene Items mit den
Spalten `iqbitem_id`, `modul`, `lh`, `logit`, `kstufe`. Das CSV-Format verwendet
Semikolon als Trennzeichen und Komma als Dezimalzeichen. `lh` ist ein Anteil
zwischen 0 und 1; `logit` und `kstufe` sind bereits vorliegende Kennwerte.

Output ist `TechRep_minimal.docx` mit:

- automatisch eingesetzten Angaben: **5 Items**, **60 %** mittlere
  Lösungshäufigkeit und **0 Logits** mittlere Schwierigkeit;
- einer Tabelle mit allen fünf Items;
- einem Balkendiagramm mit je einem Item auf den Kompetenzstufen I–V;
- nummerierten Abschnitten und einem Inhaltsverzeichnis.

Zum Experimentieren die CSV ändern und erneut rendern: Zahlen, Tabelle und
Diagramm werden aus den neuen Eingaben erzeugt. Das Minimalbeispiel demonstriert
die Berichtserstellung, nicht die vollständige Datenverarbeitung von
`TechRep_02.qmd` oder eine psychometrische Kalibrierung.

Das Minimalbeispiel wurde lokal mit R 4.5.1 und Quarto 1.8.26 erfolgreich nach
DOCX gerendert. In der geprüften Windows-Umgebung war zunächst eine ungültige
R-Ländereinstellung aktiv (`Setting LC_CTYPE=C.UTF-8 failed`), wodurch Umlaute
in R-Ausgaben beschädigt wurden. Für den erfolgreichen Prüflauf wurde in
PowerShell vor dem Rendern `$env:LC_ALL = 'German_Germany.utf8'` gesetzt.
Die erzeugten Kennzahlen, die Datentabelle, die eingebettete Abbildung, das
Inhaltsverzeichnis und die Umlaute wurden im DOCX-Inhalt geprüft.
Der vollständige Bericht wurde nicht neu gerendert: Die externen
Eingabedateien sind nicht Bestandteil des Repositories; außerdem fehlt in der
geprüften lokalen R-Installation `grateful`.
