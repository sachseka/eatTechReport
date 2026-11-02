# Eingaben für den Leistungsbaustein

Stand: 02.11.2026 · Schnittstellenentwurf `0.2.0-draft`

Dieser Entwurf konkretisiert `config` und `data` zunächst für
`pilotierung_leistung`. Er enthält ein ausführbares synthetisches Beispiel,
Eingabeprüfungen und die dazugehörigen Kennzahlen. Die Schnittstelle ist jetzt
im Entwicklungspaket implementiert, einschließlich Grafik und Word-Ausgabe
des Leistungsabschnitts. Sie deckt noch nicht alle Kapitel des Technischen
Berichts ab. PVs werden hier nicht aus empirischen Itemantworten geschätzt.

## 1. Verbindliche Grundlage

- PVs liegen bereits auf der 500er-Berichtsskala vor.
- Erwartet werden voraussichtlich 15 PVs; die tatsächlichen PV-Kennungen und
  damit ihre Anzahl werden je Skala konfiguriert.
- Alle Fälle der je Skala angegebenen Pilotierungsstichprobe werden berücksichtigt.
- Die Berechnung erfolgt ungewichtet, ohne Untergruppen.
- Deutsch kann mehrere auswertbare Skalen enthalten; Mathematik verwendet nur
  die globale Skala. Leitideen und Modulschwerpunkte sind davon getrennt.
- Im Bericht werden eine Dichte mit Kompetenzstufengrenzen und Prozentanteilen
  sowie Personenanzahl, Mittelwert und Standardabweichung benötigt.
- Vollständige PV-Datensätze sind zugesichert. Fehlende oder nicht endliche
  PV-Werte sind daher Eingabefehler. Die Prüfung dient der Datenintegrität;
  es werden weder Fälle entfernt noch PV-Werte ergänzt.

Für **jeden erzeugten DOCX-Bericht**, einschließlich Demo, ist die lokale
Corporate-Vorlage `lokal/Bericht.dotx` verbindlich. Es gibt keine alternative
allgemeine Gestaltung. Eingaben erzeugen, prüfen und zusammenfassen kann man
ohne Word-Vorlage; die Dokumenterzeugung benötigt sie zwingend.

Die Vorlage und gegebenenfalls daraus abgeleitete technische Referenzdateien
bleiben unter `lokal/`. Der Renderer erhält nur ihren Speicherort als
`corporate_template`; dieser Pfad ist keine Auswahl zwischen verschiedenen Designs.

## 2. Ausführbares Beispiel

Nach Installation des Pakets stehen die Funktionen mit `library(eatTechReport)`
zur Verfügung. Die Datei [leistung_input.R](../examples/leistung_input.R) lädt
alternativ dieselben R-Quelldateien direkt aus dem Repository. Eingabeprüfung
und Kennzahlen verwenden Base R; die Grafik benötigt ggplot2. Beim Laden werden
keine Dateien geschrieben und keine Berichte erzeugt.

Im Projektordner in R ausführen:

```r
source("examples/leistung_input.R", encoding = "UTF-8")

de <- example_leistung_input(
  profile = "v3_de_lesen_zuhoeren",
  seed = 42,
  n_persons = 24,
  n_pv = 15,
  main_year = 2027,
  pilot_year = 2026
)

str(de$config, max.level = 2)
head(de$data$population)
head(de$data$pvs)

validate_leistung_input(de)
kennzahlen_de <- summarise_leistung_input(de)
kennzahlen_de$descriptives
kennzahlen_de$percentages
```

Das Mathematikbeispiel verwendet dieselbe Struktur:

```r
ma <- example_leistung_input(
  profile = "v3_ma_mg_mm",
  seed = 42,
  n_persons = 24,
  n_pv = 15,
  main_year = 2027,
  pilot_year = 2026
)

kennzahlen_ma <- summarise_leistung_input(ma)
```

`seed` bezeichnet den Startwert des Zufallsgenerators, **kein Jahr**. Bei
gleichen Eingaben und gleichem Softwarestand erzeugt derselbe Seed dieselben
synthetischen Daten. Der Standardwert ist nun `42`; das zuvor verwendete `2027`
hatte keine fachliche Bedeutung. `main_year` und `pilot_year` legen unabhängig
davon die Jahresangaben fest. Sie verändern die simulierten PV-Werte nicht.

Die Beispielprofile stehen für die gewählten Konstellationen 2027. Das dabei
eingetragene Pilotierungsjahr **2026** ist ausschließlich eine Demoannahme,
keine Festlegung für die tatsächlichen Berichte. Ebenso sind **24 Personen**
und die unten genannten Cuts Beispieldaten. **15 PVs** sind die Beispielvorgabe
entsprechend der derzeitigen Erwartung. Die PV-Anzahl wird je Skala ausdrücklich
angegeben; der Entwurf erzwingt nicht allgemein 15 PVs.

Die generierten Werte sind technisch simulierte Beispielwerte mit gemeinsamem
Personenanteil über die PVs hinweg. Sie dienen der Schnittstellenentwicklung;
sie sind keine aus einem IRT-Modell geschätzten Plausible Values. Die synthetische
Stichprobe wird nicht nachträglich auf einen Mittelwert von 500 normiert.

## 3. `config`: fachliche Festlegungen

| Bestandteil | Bedeutung |
| --- | --- |
| `schema_version` | Version der Eingabeschnittstelle, derzeit `0.2.0-draft`; unabhängig von der späteren Paketversion. |
| `scope` | Hier ausdrücklich `pilotierung_leistung`, um den begrenzten Umfang zu kennzeichnen. |
| `report` | Studie (`study`), Fach (`subject`), Haupttestjahr (`main_year`), aktuelles Pilotierungsjahr (`pilot_year`) und Datenherkunft (`data_origin`). Das Beispiel ist `synthetic`; reale Daten werden mit `observed` gekennzeichnet. |
| `domains` | Tabelle mit Bereichskennung, verständlicher Bezeichnung und Zuordnung zu einer psychometrischen Skala. |
| `focus_domains` | Bei Mathematik die Modulschwerpunkte, im Beispiel `c("MG", "MM")`. Diese Angabe erzeugt keine eigenen Skalen oder Untergruppen in der Leistungsdarstellung. |
| `performance` | Festlegungen für den Baustein: alle Fälle, keine Gewichte, keine Untergruppen. |
| `scales` | Benannte Liste der tatsächlich auswertbaren Skalen mit ihren Definitionen. |

Jeder Eintrag in `scales` enthält:

| Feld | Bedeutung / Beispiel |
| --- | --- |
| `label` | Lesbare Skalenbezeichnung, beispielsweise `Lesen`. |
| `metric` | `bista_500`: PVs und Cuts liegen bereits auf derselben Berichtsskala. |
| `pv_ids` | Vollständige Liste der erwarteten PV-Kennungen, beispielsweise `pv01` bis `pv15`. |
| `cuts` | Endliche, strikt aufsteigende Grenzen zwischen den Kompetenzstufen. |
| `level_labels` | Stufenbezeichnungen; vorgesehen ist `c("Ia", "Ib", "II", "III", "IV")`. Genau eine Bezeichnung mehr als Cuts. |
| `cut_source` | Nachvollziehbarer Herkunftsnachweis der Grenzwerte. Im Beispiel `illustrative_demo_only`. |

Die voraussichtlichen Stufenbezeichnungen **Ia, Ib, II, III, IV** gelten als
Vorgabe für alle Skalen. Sie bleiben je Skalenprofil konfigurierbar.
Die Demo verwendet dazu die **rein illustrativen Cuts `400, 475, 550, 625`**.
Diese Zahlen sind keine freigegebenen Kompetenzstufengrenzen für Deutsch oder
Mathematik; auch aus den Stufenbezeichnungen folgen keine Grenzwerte.
Für reale Berichte werden fachlich freigegebene Skalenprofile benötigt.
Die Prüfung weist eine Kombination aus `data_origin = "observed"` und
`cut_source = "illustrative_demo_only"` zurück.

Die vereinbarten Kurzlabels werden direkt als Bereichs- und Skalenkennungen
verwendet. Das Deutsch-Beispiel enthält zunächst `DL` und `DH`; die Prüfung
unterstützt auch `DO` und `DS`.

| Fach | Bereichskennung (`domain_id`) | Bezeichnung | Skalenkennung (`scale_id`) |
| --- | --- | --- | --- |
| Deutsch | `DL` | Lesen | `DL` |
| Deutsch | `DH` | Zuhören | `DH` |
| Deutsch | `DO` | Orthografie | `DO` |
| Deutsch | `DS` | Sprachgebrauch | `DS` |
| Mathematik | `MZ` | Zahlen und Operationen | `MO` |
| Mathematik | `MG` | Größen und Messen | `MO` |
| Mathematik | `MM` | Muster und Strukturen / Funktionaler Zusammenhang | `MO` |
| Mathematik | `MR` | Raum und Form | `MO` |
| Mathematik | `MD` | Daten, Häufigkeit und Wahrscheinlichkeit | `MO` |

`MO` bezeichnet **Mathematik global** (overall), keine weitere Leitidee.
Die Namen in `config$scales` und die Kennungen in beiden Datentabellen verwenden
dieselben Kürzel. Die Umstellung der Kennungen ist in `0.2.0-draft` abgebildet;
die alten Kennungen des noch unveröffentlichten Entwurfs werden ersetzt.

Die Kennzahlen werden je Eintrag in `scales` berechnet. Die fünf Mathematik-
Leitideen vervielfachen daher weder Personen noch Leistungsdarstellungen.

## 4. `data`: Population und PV-Werte

### `data$population`

Eine Zeile beschreibt eine erwartete Person in einer berichteten Skala:

| Feld | Typ | Bedeutung |
| --- | --- | --- |
| `person_id` | Text | Eindeutige Personenkennung; führende Nullen müssen erhalten bleiben. |
| `scale_id` | Text | Verweis auf einen Eintrag in `config$scales`. |

Der Schlüssel ist `(person_id, scale_id)`. Dieselbe Person darf in mehreren
Skalen vorkommen; innerhalb einer Skala ist sie genau einmal aufgeführt.

Diese Tabelle legt die erwartete Population **unabhängig von der PV-Tabelle**
fest. Bei realen Eingaben muss sie aus dem vollständigen Personenbestand kommen.
Wenn sie erst aus den vorhandenen PV-Zeilen abgeleitet würde, blieben vollständig
fehlende Personen unbemerkt. Der Baustein wählt keine Teilmenge daraus aus.

### `data$pvs`

Eine Zeile enthält genau einen PV-Wert einer Person in einer Skala:

| Feld | Typ | Bedeutung |
| --- | --- | --- |
| `person_id` | Text | Verweis auf die erwartete Population. |
| `scale_id` | Text | Skalenkennung. |
| `pv_id` | Text | Eine der für diese Skala definierten PV-Kennungen. |
| `value` | Numerisch | Endlicher PV-Wert auf der 500er-Berichtsskala. |

Der Schlüssel ist `(person_id, scale_id, pv_id)`. Für jedes erwartete
Person-Skala-Paar muss jede konfigurierte PV-Kennung genau einmal vorkommen.
Es gibt keine Gewichts- oder Untergruppenspalte in diesem Entwurf.

Mit 24 Personen und 15 PVs ergeben sich:

- Deutsch mit zwei Skalen: 48 Populationseinträge und 720 PV-Zeilen.
- Mathematik global: 24 Populationseinträge und 360 PV-Zeilen.

Die lange Tabellenform ist ein erster gemeinsamer Eingabevertrag. Vorhandene
breite R-Objekte mit Spalten wie `PV1`, `PV2` usw. können später durch eine
gezielte Überführung daran angeschlossen werden. Eine CSV-Datei ist dafür
nicht erforderlich.

## 5. Berechnungsregeln und Ergebnistabellen

Zunächst werden die Personenwerte für jede PV-Kennung getrennt ausgewertet.
Anschließend werden diese Ergebnisse über die PV-Kennungen zusammengefasst:

- **N:** Anzahl erwarteter Personen je Skala, nicht Anzahl aller PV-Zeilen.
- **Mittelwert:** arithmetisches Mittel der Mittelwerte je PV.
- **SD:** Quadratwurzel des Mittels der Stichprobenvarianzen je PV. Pro PV wird
  die Stichprobenvarianz mit dem Nenner `N - 1` verwendet.
- **Kompetenzstufenanteile:** ungewichteter Anteil je Intervall und PV, danach
  Mittelung dieser Anteile über die PVs.
- **Intervallgrenzen:** Ein Wert genau auf einem Cut gehört zur höheren Stufe.
  Das erste Intervall ist nach unten, das letzte nach oben offen.

Die PVs werden dafür nicht zuerst je Person gemittelt. Eine solche Mittelung
würde insbesondere Streuung und Stufenanteile verändern. Die Kennzahlen werden
ungerundet zurückgegeben; Darstellung und Rundung erfolgen erst im Bericht.

`summarise_leistung_input()` liefert insbesondere:

| Ergebnis | Verwendung |
| --- | --- |
| `descriptives` | Je Skala: Personenanzahl, PV-Anzahl, Mittelwert und SD. Grundlage für Tabelle und Fließtext. |
| `percentages` | Je Skala und Kompetenzstufe: Grenzen, Bezeichnung und Anteil beziehungsweise Prozentwert. Grundlage für Beschriftungen und Tabelle. |
| `per_pv` | Personenanzahl, Mittelwert und Varianz je Skala und PV; ermöglicht die Kontrolle der Zusammenfassung. |

`plot_performance()` verwendet genau diese Population und Intervallkonventionen.
Die Prozentwerte werden aus den PV-Beobachtungen berechnet und hängen nicht von
der Glättung der Dichte ab:

```r
plot_performance(de, "DL")
plot_performance(ma, "MO")
```

Die Dichten werden je PV auf einem gemeinsamen Raster mit derselben Bandbreite
berechnet und anschließend gemittelt. Standardmäßig ist die Bandbreite das
Mittel der je PV mit `stats::bw.nrd0()` bestimmten Bandbreiten; sie kann für die
Darstellung explizit vorgegeben werden. Zusätzliche PVs erhöhen nicht künstlich
die Personenzahl, die der automatischen Glättung zugrunde liegt. Die Umsetzung
nutzt ggplot2 direkt und benötigt keine vollständige eatPrep-Abhängigkeit.
Die Grafik trägt ihre ungerundeten Anteile im Attribut `population_percentages`.

## 6. Prüfungen und verbleibende Festlegungen

Der Prototyp prüft unter anderem gültige Skalen-/Bereichsbezüge, eindeutige
Schlüssel, vollständige Person-Skala-PV-Kombinationen, endliche Werte sowie
aufsteigende Cuts und passende Stufenbezeichnungen. Auch komplett fehlende
PV-Sätze werden anhand der Population erkannt. Die Fehlerbehandlung ergänzt
keine Werte und entfernt keine Fälle.

Die [Prüfdatei](../examples/check_leistung_input.R) startet die Pakettests für
Kennzahlen und Grafik. Diese enthalten kleine handrechenbare Fälle für
Mittelwert, Varianzaggregation und Cut-Zuordnung sowie Prüfungen für
Wiederholbarkeit und fehlerhafte Eingaben. Dafür werden testthat und ggplot2
benötigt:

```powershell
$env:LC_ALL = "German_Germany.utf8"
Rscript --vanilla examples/check_leistung_input.R
```

Die erste Zeile berücksichtigt die bereits bekannte ungültige `C.UTF-8`-
Ländereinstellung in der hier verwendeten Windows-Umgebung. Sie gilt nur für
die aktuelle PowerShell-Sitzung. In einer korrekt eingerichteten R-Umgebung
ist diese Korrektur nicht erforderlich.

Vor der Anbindung echter Daten bleiben insbesondere offen:

1. Konkrete vorhandene R-Objekte und Spaltennamen für Personenkennungen, Skalen
   und PVs; die tatsächlichen PV-Kennungen bei voraussichtlich 15 PVs.
2. Freigegebene Kompetenzstufengrenzen und deren Referenzversionen.
3. Tatsächliches Pilotierungsjahr und weitere Durchgangsangaben.

Die Vollständigkeit der PV-Sätze ist bestätigt und kein offener Planungspunkt.

Die vollständige Berichtsschnittstelle ergänzt anschließend die Informationsgruppen
für Testdesign, Aufgaben/Items, Stichprobenzusammensetzung, Kodierung und Haupttest.
Der hier erprobte Leistungsbaustein bleibt dabei eine klar abgegrenzte Komponente.

Die Hauptfunktion `render_report()` ist für diesen Leistungsabschnitt
implementiert. Für Demo und Echtbetrieb gilt dieselbe Corporate-Vorgabe:

```r
library(eatTechReport)
de <- example_report()

render_report(
  config = de$config,
  data = de$data,
  corporate_template = "lokal/Bericht.dotx",
  output_dir = "lokal/demo"
)
```

Der aktuelle Renderer befüllt nur den Leistungsabschnitt. Fehlt die
Corporate-Vorlage, bricht die Dokumenterzeugung mit einer verständlichen Meldung
ab. Die redigierbaren Quarto-Dateien können mit
`edit_report_texts("lokal/redaktion")` in einen lokalen Arbeitsordner kopiert
und über `text_dir = "lokal/redaktion"` eingebunden werden.

Der Renderer speichert die verwendeten Eingaben, Ergebnisse, Textquellen und
ein Manifest im lokalen Ausgabeordner. Dieser Stand dient der Reproduzierbarkeit;
er ist noch kein fachlich freigegebenes Archiv und enthält keinen automatischen
Vorjahresvergleich. Die weiteren Kapitel werden auf diesem ersten Modul aufgebaut.

Für die Reproduzierbarkeit wird der **gesamte Ausgabeordner** aufbewahrt; das
Manifest verweist auch auf Dateien außerhalb des Unterordners `archive/`.
Bei `overwrite = TRUE` wird zunächst separat gerendert und erst bei Erfolg
umgestellt. Der vorherige Stand bleibt unter `previous_output_dir` erhalten.

Mit `update_fields = "auto"` aktualisiert vorhandenes Microsoft Word unter
Windows das Verzeichnis und die Felder einschließlich Kopf-/Fußzeilen und
speichert das fertige DOCX. `"word"` verlangt diesen Schritt; `"none"` lässt
ihn aus. Ohne erfolgreiche Aktualisierung bleibt der explizite Manifeststatus
`fields_pending`; `fields_updated` zeigt den tatsächlichen Zustand.
