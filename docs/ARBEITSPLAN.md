# Arbeitsplan: eatTechReport

Stand: 02.11.2026 · Arbeitsfassung 0.5 · Status: erste Paketimplementierung

Dieser Plan ergänzt die [Kapitelmatrix](KAPITELMATRIX.md). Er beschreibt die
sinnvolle Reihenfolge und überprüfbare Ergebnisse der weiteren Arbeit. Das
erste Paketstand setzt den Leistungsbaustein um: Eingaben, Prüfungen, Kennzahlen,
Dichtegrafik und einen Quarto-/Word-Abschnitt mit lokalem Reproduzierbarkeitsstand.
`DESCRIPTION`, `NEWS.md`, Funktionsdokumentation und pkgdown-Quellen sind angelegt.
Die übrigen Berichtskapitel bleiben Gegenstand dieses Plans. Das bestätigte
Logomotiv liegt als bereinigte Light-/Dark-Version vor; siehe
[Logo-Dokumentation](LOGO.md).

## 1. Festgelegte Grundlage

- Erste Ausbaustufe: VERA-3 Deutsch und Mathematik, ein Bericht je Durchgang
  und Fach. Die fachlichen Varianten stehen in der Kapitelmatrix.
- Redaktion in Quarto; Daten und Konfiguration bevorzugt als R-Objekte.
  CSV nur bei einem konkreten Nutzen als zusätzliche Schnittstelle, kein XLSX.
- Personenleistung: Plausible Values auf der 500er-Berichtsskala, alle Fälle,
  keine Gewichte, Gesamtstichprobe je auswertbarer Skala. Mathematik global (`MO`).
  Voraussichtlich 15 PVs; vollständige PV-Datensätze sind garantiert.
- Bereichs-/Skalenkürzel gemäß [Schnittstellenbeschreibung](SCHNITTSTELLE_LEISTUNG.md):
  Deutsch `DL`, `DH`, `DO`, `DS`; Mathematik-Leitideen `MZ`, `MG`, `MM`, `MR`, `MD`.
  Stufenbezeichnungen voraussichtlich überall Ia, Ib, II, III, IV.
- Keine Untergruppen-Leistungsgrafiken für VERA-3. Eine mögliche spätere
  Erweiterung für VERA-8 wird bei der Struktur berücksichtigt, aber jetzt
  nicht umgesetzt.
- Ausgabeziel ist ein fertiges DOCX ohne manuelle Formatierungsnacharbeit.
- Für Demo- und reale Berichte ist das Corporate-Muster `lokal/Bericht.dotx`
  verbindlich. Es gibt keine alternative allgemeine Gestaltungsvorlage und
  keine Auswahl individueller Designs. Anpassbar ist nur der lokale Dateipfad
  zur freigegebenen Corporate-Vorlage.
- Das erste neue Berichtsjahr bildet den Archiv-Ausgangsstand; die späteren
  Vorjahresmarkierungen werden bereits strukturell vorbereitet.
- Originalberichte, die neue DOTX, vertrauliche Daten und vertrauliche
  Arbeits-/Archivdateien bleiben unter `lokal/` und außerhalb des Repos.
  Das gilt auch für technisch daraus abgeleitete Word-Referenzdateien und
  erzeugte Berichte mit Corporate-Gestaltung.

## 2. Kapitelmatrix: erste Reviewrunde erfolgt

Der Nutzer hat Abschnitt 2 der Kapitelmatrix durchgesehen. Die Rückmeldungen
zu Unterstrich-IDs, Überschriften, Zusammenführung der Kompetenzbereiche,
Tabellengestaltung, Dezimalstellen, Median-Schreibweise und Ankeritemfußnote sind
in Arbeitsfassung 0.3 der Matrix eingearbeitet. Die übrigen Inhalte wurden in
dieser Runde bestätigt. Das folgende Feedbackformat gilt für weitere Schleifen.

Die Matrix ist bereits für eine erste Prüfung geeignet. Im Vordergrund stehen:

1. Fehlt ein benötigter Inhalt, oder kann etwas entfallen?
2. Ist die Reihenfolge für die Leserinnen und Leser nachvollziehbar?
3. Welche Aussage soll jeder Abschnitt vermitteln?
4. Sind die vorgesehenen Kennzahlen, Tabellen und Grafiken ausreichend und
   verständlich? Wo wäre eine andere Darstellung hilfreicher?
5. Welche fachlichen Varianten oder jährlichen Besonderheiten müssen zusätzlich
   berücksichtigt werden?

Endgültige Spaltennamen, R-Klassen und technische Funktionen sind in dieser
Runde noch nicht zu entscheiden. Auch sprachlicher Feinschliff einzelner
Standardtexte kann in den späteren kapitelweisen Korrekturschleifen erfolgen.

Feedback kann stichpunktartig im Chat oder direkt in der Markdown-Datei gegeben
werden. Für die Zuordnung ist folgendes Format hilfreich:

```text
Baustein-ID | ändern / ergänzen / streichen / offen | gewünschtes Ergebnis
```

Beispiel für eine Rückmeldung:

```text
pilotierung_leistung | ergänzen | In der Grafik sollen neben den Prozenten
auch die Kompetenzstufenbezeichnungen gut lesbar stehen.
```

Die dauerhafte Baustein-ID ist hilfreicher als eine Zeilennummer, weil sie auch
bei Umstellungen erhalten bleibt. Ein einfaches „passt“ für einen Abschnitt ist
ebenfalls ausreichend; es ist kein gesondertes Formular erforderlich.

## 3. Arbeitspakete und Reihenfolge

Die folgende Reihenfolge verbindet fachliche Planung mit einem frühen Nachweis
der schwierigen Ausgabeelemente. Textkorrekturen, Gestaltung und Dokumentation
können nach Klärung ihrer jeweiligen Grundlagen parallel laufen.

| ID / Arbeitspaket | Konkretes, überprüfbares Ergebnis | Abhängigkeit / Stand |
| --- | --- | --- |
| P1 · Kapitelmatrix prüfen | Überarbeitete Matrix mit vereinbartem Inhaltsumfang, nachvollziehbarer Reihenfolge, Darstellungen und eindeutig benannten offenen Punkten. | Erste inhaltliche Durchsicht von Abschnitt 2 erfolgt; Feedback in Matrix 0.3 eingearbeitet. Weitere Präzisierungen sind kapitelweise möglich. |
| P2 · Leistungsbaustein spezifizieren | Für `pilotierung_leistung`: Grafik/Tabelle, PV-Zusammenfassungen, Cut-Regeln, gültiges N, Rundung und Vollständigkeitsprüfung. | Im Paket umgesetzt und mit synthetischen Eingaben prüfbar. Fachliche Freigabe der echten Cuts und die Anbindung der Quellobjekte bleiben offen. |
| P3 · Gemeinsame Eingaben definieren | Dokumentierte R-Eingabestrukturen für Berichtskonfiguration, Fachdefinitionen, Aufgaben/Items, Design, Stichprobe, PVs und weitere Ergebnisse. Je Struktur: Bedeutung, Pflichtangaben, Schlüssel, Bezugsmenge, zulässige Werte und verständliche Fehler. | Aus P1/P2 vom gewünschten Berichtsergebnis her ableiten; bisherige Mathematik-Listen nicht ungeprüft verallgemeinern. |
| P4 · Paketgerüst vorbereiten | Installierbares Entwicklungsgerüst mit `DESCRIPTION`, `NEWS.md`, dokumentierten Funktionen und Ressourcenstruktur; Auslieferungsgrenzen für lokale Bestände. | Angelegt für den Leistungsbaustein. Autoren, Maintainerin und GPL (>= 2) sind bestätigt. `.Rbuildignore` schließt lokale Bestände und historische Berichtsdateien aus. |
| P5 · Word-Ausgabe früh erproben | Ein synthetischer Beispielbericht im verbindlichen Corporate-Muster `lokal/Bericht.dotx` mit Deckblatt, Verzeichnis, Text, langer Tabelle, Dichtegrafik, Formel, Fußnote, Literatur und rechtem Randzeichen. | DE-/MA-Leistungsberichte und eine Layoutprobe mit allen vier Deutsch-Domänen, 80 Tabellenzeilen und Fußnote erfolgreich erzeugt und in Word geprüft. Deckblatt, Verzeichnis, Kopf-/Fußzeilen, Dichten, Formel und Tabellen erprobt. Literatur und Randzeichen bleiben offen. Alle Corporate-Artefakte bleiben lokal. |
| P6 · Kapitelweise Berichtserstellung | Quarto-Bausteine mit stabilen IDs, gemeinsamen R-Ergebnissen und fachlicher Variantenwahl. Zunächst ein vollständiger Abschnitt, dann DE/MA-Kapitel nacheinander ergänzen und redigieren. | Leistungsabschnitt als erster redigierbarer Quarto-Baustein umgesetzt. Weitere Kapitel und ihre fachlichen Textfreigaben stehen aus. |
| P7 · Archiv und Änderungsvergleich | Reproduzierbarer Freigabestand mit Texten, Eingaben, Ergebnissen, Referenzen und Softwarestand; überprüfbare Liste fachlicher Änderungskandidaten. Erster Bericht ohne Randmarker. | Der Renderer legt einen lokalen Reproduzierbarkeitsstand an. Fachliche Freigabe, Vorjahresvergleich und bestätigte Randmarker sind noch nicht implementiert. |
| P8 · Paketdokumentation und pkgdown | Schnellstart, Eingabeübersicht, Textredaktion, Leistungsdarstellung und Archivierung mit synthetischen Beispielen; Funktionsreferenz und NEWS auf einer lokal prüfbaren Website. | Schnellstart, Leistungsdarstellung, Textredaktion, Referenz, NEWS und Suche lokal unter `_pkgdown/` gebaut. Keine automatische Website-Veröffentlichung. |
| P9 · Logo und Erscheinungsbild | eatTechReport-Logo im eat-Stil, für helle und dunkle Hintergründe geprüft; passende Dateien für README, pkgdown und Favicons. | Light-/Dark-PNGs und Standardlogo liegen vor; README und pkgdown sind eingebunden, Favicons erzeugt. Website in beiden Farbmodi visuell geprüft. |
| P10 · Gesamtabnahme | Vollständige synthetische DE-/MA-Berichte, nachvollziehbare Zahlen, geprüfte Varianten, funktionierende Installation/Dokumentation und vollständig erzeugte DOCX-Dateien. Anschließend fachlicher Abgleich mit lokalen realen Eingaben. | Nach den zugehörigen Teilergebnissen; keine realen Daten für öffentliche Beispiele oder Website-Builds. |

Tests entstehen zusammen mit den jeweiligen Berechnungen und Schnittstellen.
P10 bündelt die Ergebnisse; es ist nicht der erste Zeitpunkt für Prüfungen.

## 4. Bestätigte Vollständigkeit der PV-Datensätze

Vollständige PV-Datensätze sind zugesichert. Für alle vorgesehenen Fälle je
Skala wird ein vollständiger Satz endlicher PVs erwartet; voraussichtlich sind
es 15 PVs. Die tatsächliche Anzahl bleibt konfigurierbar.

Die Eingabeprüfung erkennt weiterhin fehlende PV-Werte oder Personen und
stoppt die Berechnung mit einer Fehlermeldung. Das schützt vor fehlerhaften
Übertragungen und erhält die Vorgabe „alle Fälle“. Es werden keine Personen
entfernt und keine PV-Werte nachgeschätzt. Eine zusätzliche fachliche Regel
für unvollständige PV-Sätze ist damit kein offener Planungspunkt mehr.

Fehlende Antworten auf einzelne Testitems sind eine andere Ebene: Ihre
Behandlung gehört zur vorgelagerten Auswertung und löst nicht automatisch
einen Ausschluss aus der Leistungsdarstellung aus.

## 5. Paketgerüst und Metadaten

Als Vorbild dienen die Struktur und Dokumentationskonventionen von eatPrep,
insbesondere `DESCRIPTION`, versionsweise `NEWS.md`, roxygen-Dokumentation,
testthat sowie pkgdown mit Bootstrap 5 und MathJax. Die Angaben werden für
eatTechReport passend festgelegt und nicht vollständig aus eatPrep kopiert.

| Bestandteil | Geplante Aufgabe |
| --- | --- |
| `DESCRIPTION` | Paketname, Version, englischer Titel und Zweck, Autoren/Maintainer, Lizenz, erforderliche R-Version sowie tatsächliche Paket-/Systemabhängigkeiten. |
| `R/`, `man/`, `NAMESPACE` | Eingabeprüfung, Ergebnisberechnungen und Berichtserzeugung mit dokumentierter öffentlicher Schnittstelle. Hilfeseiten und Namespace aus der Dokumentation erzeugen. |
| `inst/` | Auslieferbare Quarto-Bausteine und allgemeine Ressourcen. Die private DOTX, daraus abgeleitete Word-Referenzdateien und Originalberichte werden nicht hineinkopiert. Die verbindliche Corporate-Vorlage wird über ihren lokalen Pfad eingebunden; eine Ersatzgestaltung wird nicht ausgeliefert. |
| `tests/testthat/` | Fachlich aussagekräftige Prüfungen für PV-Zusammenfassungen, Cut-Grenzen, Zählungen, Variantenwahl und Eingabefehler; gezielte Prüfungen der Berichtserzeugung. |
| Synthetische Beispiele | Kleine DE-/MA-Beispiele für Entwicklung, Tests, Schnellstart und Website, unabhängig von lokalen Originaldaten. |
| `NEWS.md` | Bereits umgesetzte Änderungen je Paketversion. Planung und offene Aufgaben bleiben im Arbeitsplan. |
| `_pkgdown.yml`, Artikel | Website-Konfiguration, geführte Anwendungsbeispiele und Funktionsübersicht. Quarto-Artikel können für die Dokumentation verwendet werden. |
| `man/figures/` | Für README und Website geeignete Logo-/Abbildungsdateien; geeignete bearbeitbare Logoquelle zusätzlich aufbewahren. |

Ein möglicher Titel und Beschreibungstext zur späteren Prüfung:

```text
Title: Generate Technical Reports for Educational Assessments
Description: Assemble modular technical reports from existing assessment
    results and structured metadata. Combine editable Quarto text blocks
    with validated summaries, tables and figures, and generate reproducible
    Word documents for VERA assessments.
```

Dieser Text beschreibt den Zielumfang. Die tatsächliche `DESCRIPTION` ist enger
auf den umgesetzten Leistungsbaustein zugeschnitten. Die Entwicklungsversion
lautet `0.0.0.9000`; ein Release ist damit nicht erfolgt.

Bestätigt sind Karoline A. Sachse als Autorin/Maintainerin, Kilian-Kristoph
Schumann als weiterer Autor und GPL (>= 2) als Lizenz. Das Repository ist
`sachseka/eatTechReport`. Der erste Stand verwendet englische Paketmetadaten und
Funktionsreferenzen sowie deutsche Anwenderartikel. Eine Veröffentlichung der
Website ist ein eigener späterer Schritt.

## 6. Website-Ausgabe und Schutz lokaler Bestände

pkgdown erzeugt seine Website standardmäßig unter `docs/`. Dort liegen in
diesem Projekt bereits die Eingabedokumentation, die Kapitelmatrix und dieser
Arbeitsplan. Daher wird ein separates Ausgabeziel vorgesehen, beispielsweise
`_pkgdown/`. Die Planungsquellen werden nicht als Website-Ausgabeverzeichnis
verwendet. Die Einstellung `destination` ist in der
[pkgdown-Dokumentation](https://pkgdown.r-lib.org/reference/build_site.html)
beschrieben.

`lokal/` ist durch `.gitignore` von der normalen Versionierung und durch
`.Rbuildignore` vom Paket-Build ausgeschlossen. Dort werden auch Planungsquellen,
generierte Website-Dateien und sonstige nicht auslieferbare Arbeitsbestände
berücksichtigt. `.Rbuildignore` steuert den
Inhalt des R-Paketarchivs, wie in
[Writing R Extensions](https://stat.ethz.ch/R-manual/R-devel/doc/manual/R-exts.html#Building-package-tarballs)
dokumentiert.

Für die Website gilt unabhängig davon: Artikel und Beispiele lesen ausschließlich
die vorgesehenen synthetischen Ressourcen. Ein Paket-Ausschluss verhindert
nicht automatisch, dass ausgeführter Dokumentationscode lokale Daten lesen
könnte. Paketarchiv und Website-Ausgabe werden deshalb vor einer Veröffentlichung
inhaltlich kontrolliert.

Öffentliche Beispiele können Eingabestrukturen, Prüfungen, Kennzahlen und
einzelne Grafiken aus synthetischen Daten zeigen, ohne die private DOTX zu
benötigen. Ein vollständiger DOCX-Renderlauf wird mit seiner lokalen
Corporate-Voraussetzung dokumentiert und nicht automatisch im öffentlichen
Website-Build ausgeführt. Corporate-Vorlage und daraus erzeugte Dokumente
werden nicht in die Website aufgenommen.

Weitere geprüfte Dokumentationsgrundlagen:

- [DESCRIPTION und Paketstruktur](https://stat.ethz.ch/R-manual/R-devel/doc/manual/R-exts.html#The-DESCRIPTION-file).
- [Quarto-Artikel in pkgdown](https://pkgdown.r-lib.org/articles/quarto.html):
  HTML-Artikel werden unterstützt; pkgdown verwendet seine eigene Seitengestaltung
  und unterstützt nicht jede Quarto-Funktion.
- [NEWS in pkgdown](https://pkgdown.r-lib.org/reference/build_news.html):
  Versionsüberschriften liefern die Gliederung des Changelogs.
- [README und Logo in pkgdown](https://pkgdown.r-lib.org/reference/build_home.html):
  `man/figures/` ist der vorgesehene Ort für README-Abbildungen und das Paketlogo.

## 7. Nächster gemeinsamer Schritt

Der erste Leistungsabschnitt kann jetzt mit synthetischen Eingaben geprüft und
redigiert werden. Als nächste fachliche Schritte folgen die echten Cuts und
R-Quellobjekte sowie die Eingabestrukturen für Testdesign und Stichprobe. Deren
Texte und Tabellen werden anschließend kapitelweise ergänzt. Der vollständige
Layoutnachweis aus P5 bleibt eine eigene Abnahme; insbesondere lange Tabellen,
Literatur und spätere Randmarker werden dadurch nicht als erledigt betrachtet.

Der erste konkrete Entwurf für die beiden Eingabeobjekte steht in
[SCHNITTSTELLE_LEISTUNG.md](SCHNITTSTELLE_LEISTUNG.md). Das zugehörige
[R-Beispiel](../examples/leistung_input.R) macht die Struktur mit synthetischen
Daten überprüfbar. Das Paket erzeugt den Leistungsabschnitt, noch keinen
vollständigen Technischen Bericht.

## 8. Bedienkonzept: Zielumfang und erste Implementierung

`example_report()` und `render_report()` sind für den Umfang
`pilotierung_leistung` implementiert. Die folgenden Beschreibungen der weiteren
Informationsgruppen und der vollständigen Berichtskette bleiben Zielumfang.
Der Beispielgenerator liefert derzeit Population, PVs und die zugehörige
Konfiguration; er simuliert noch keine Aufgaben, Items oder Testdesigns.

### Hauptfunktion

`render_report(config, data, ...)` ist der zentrale Einstieg. Zwei strukturierte
R-Objekte bündeln die fachlichen Eingaben:

| Argument | Inhalt |
| --- | --- |
| `config` | Durchgangsangaben, Fach, Bereichsauswahl und Reihenfolge, Pilotierungsjahr(e), fachliche Entscheidungen und freigegebene Referenzprofile. |
| `data` | Zusammenpassende R-Ergebnistabellen für Aufgaben/Items, Testdesign, Stichprobe, PVs, Itemkennwerte, Haupttestauswahl und gegebenenfalls Kodierung. Dazu Bearbeitungszahlen getrennt für Pilot- und Ankeritems. |
| `text_dir` | Optionaler Arbeitsordner mit redigierbaren Quarto-Bausteinen. Ohne Angabe werden die mitgelieferten Standardbausteine verwendet. |
| `corporate_template` | Pfad zur verbindlichen freigegebenen Corporate-Vorlage; vorgesehen ist `lokal/Bericht.dotx`. Dies ist keine Wahl individueller Gestaltungen. |
| `output_dir` | Expliziter Zielordner für den erzeugten Bericht und seine Begleitinformationen. |
| `update_fields` | `"auto"` aktualisiert Verzeichnis und Seitenzahlen mit vorhandenem Microsoft Word unter Windows; `"word"` verlangt diesen Abschluss, `"none"` lässt die Felder ausdrücklich offen. Der tatsächliche Zustand steht im Manifest. |

Für den Corporate-Vorlagenpfad wird `lokal/Bericht.dotx` vorgesehen. Auf einem
anderen Rechner kann der Pfad zur gleichen freigegebenen Vorlage angepasst
werden; dies ist keine Designauswahl. Eine gegebenenfalls erforderliche
technische Aufbereitung in eine Word-Referenzdatei wird im Layoutversuch
geklärt. Auch diese abgeleitete Datei bleibt lokal.

Der Vorlagenpfad gehört zum Renderaufruf und nicht zu den fachlichen
`config`-/`data`-Objekten. Damit können Eingabe- und Berechnungsbeispiele ohne
Dateipfad oder Zugriff auf die private Vorlage verwendet werden.

Jede fachliche Angabe hat eine maßgebliche Quelle. Beispielsweise werden
Modulzuordnungen nicht in `config` und `data` unabhängig voneinander gepflegt.
Die Hauptfunktion prüft die Übereinstimmung zwischen Konfiguration und Daten.

Für den vollständigen Bericht ist folgende Verarbeitung vorgesehen:

1. Eingaben und Beziehungen prüfen; verständliche Fehler oder Hinweise ausgeben.
2. Gemeinsame Berichtsergebnisse aus den R-Objekten berechnen.
3. Quarto-Bausteine und fachliche Varianten auswählen und zusammenstellen.
4. Verfügbarkeit der verbindlichen Corporate-Vorlage prüfen und Tabellen,
   Grafiken, Texte und Formatierung als DOCX erzeugen. Fehlt die Vorlage,
   endet die Dokumenterzeugung mit einer verständlichen Fehlermeldung; es gibt
   keinen Rückfall auf eine andere Gestaltung.
5. Ausgabepfad, Prüfbericht und verwendete Eingaben/Versionen dokumentieren.

Diese Schritte bleiben intern getrennt prüfbar. Anwenderinnen und Anwender
müssen sie für einen vollständigen Bericht nicht einzeln aufrufen. Als Ergebnis
wird ein R-Objekt mit Ausgabepfad, Prüfbericht und verwendeter Konfiguration
vorgesehen. Regeln zum Überschreiben vorhandener Dateien werden ausdrücklich
festgelegt. Eine Entwurfserzeugung ersetzt keinen freigegebenen Archivstand.

### Demo mit synthetischen Eingaben

Ein expliziter Generator `example_report(profile, seed, main_year, pilot_year)` liefert dieselbe
Struktur aus `config` und `data`, die später mit realen Ergebnissen befüllt wird.
Ein Profil legt eine vollständige Beispielkonstellation fest, etwa Deutsch
Lesen/Zuhören oder Mathematik mit MG/MM und ausschließlich globaler Skala MO.
Die synthetischen Tabellen des ersten Moduls stimmen in Personenkennungen,
Skalen und PV-Sätzen überein. Für spätere Kapitel müssen auch Aufgaben/Items,
Rollen, Module und Berichtszahlen konsistent ergänzt werden.

Ausführbarer Aufruf für den ersten Leistungsabschnitt nach Paketinstallation:

```r
demo <- example_report(
  profile = "v3_de_lesen_zuhoeren",
  seed = 42,
  main_year = 2027,
  pilot_year = 2026  # Demoannahme, tatsächliches Pilotierungsjahr noch offen
)

ergebnis <- render_report(
  config = demo$config,
  data = demo$data,
  corporate_template = "lokal/Bericht.dotx",
  output_dir = "lokal/demo"
)
```

Für Realdaten werden die beiden Eingabeobjekte ersetzt:

```r
ergebnis <- render_report(
  config = berichtskonfiguration,
  data = auswertungsergebnisse,
  text_dir = "lokal/redaktion",
  corporate_template = "lokal/Bericht.dotx",
  output_dir = "lokal/berichte"
)
```

Der Seed ist der Startwert des Zufallsgenerators und macht die Beispielerzeugung
bei gleichem Softwarestand reproduzierbar. Er ist keine Jahresangabe.
Haupttestjahr und Pilotierungsjahr werden unabhängig davon angegeben.
Die generierten PVs liegen auf der 500er-Skala, sind ungewichtet und decken die
gesamte synthetische Stichprobe je Skala ab. Sie dienen der Entwicklung und der
Demonstration; sie ersetzen keine empirische Skalierung oder Methodenvalidierung.

Demo-Eingaben tragen eine ausdrückliche Herkunftskennzeichnung. Der daraus
erzeugte Bericht wird sichtbar als **synthetisches Beispiel** gekennzeichnet.
Die Hauptfunktion schaltet bei fehlenden oder fehlerhaften Realdaten nicht
automatisch auf Simulation um und ergänzt solche Daten auch nicht synthetisch.

Der Demo-Modus ersetzt ausschließlich die Daten durch synthetische Beispiele.
Für das fertige DOCX ist `lokal/Bericht.dotx` genauso erforderlich wie bei
realen Berichten. Die Vorlage wird weder dem Paket beigelegt noch durch eine
allgemeine Vorlage ersetzt. Ein Demo-Datensatz kann dagegen unabhängig von der
Vorlage erzeugt, geprüft und numerisch zusammengefasst werden.

Die Standardtexte können für redaktionelle Arbeit in einen Arbeitsordner
kopiert werden; die Paketinstallation selbst wird nicht redigiert. Diese
Textredaktion ändert nicht die verbindlichen Corporate-Gestaltungsregeln.

Für den ersten Funktionsumfang genügen Hauptfunktion und Beispielgenerator.
Ein zusätzlicher Einzeiler wie `render_demo()` kann später ergänzt werden,
wenn sich dafür im Gebrauch ein Bedarf zeigt. Die Umsetzung weiterer Kapitel
erweitert diese Bedienung um die jeweiligen Eingaben.

## 9. Prüfung des ersten Paketstands

- Entwicklungsstand `0.0.0.9000` mit R 4.5.1 und Quarto 1.8.26 lokal gebaut
  und installiert. `R CMD check --no-manual --no-build-vignettes` endet mit
  **Status: OK**, einschließlich Beispiele und testthat-Prüfungen.
- Zwei normale Demo-Berichte mit je 600 Personen und 15 PVs sowie die erweiterte
  Layoutprobe wurden mit der Originalvorlage erzeugt. Word aktualisiert und
  speichert Verzeichnis und Felder automatisch; `manifest$fields_updated` ist
  `TRUE`. PDFs zur Sichtprüfung wurden ohne zusätzliche Feldaktualisierung erzeugt.
- Die Original-DOTX blieb unverändert. Archivierte Eingaben liefern identische
  Kennzahlen; erfolgreiche erneute Läufe erhalten den bisherigen Ordner als
  Sicherung. Der gesamte Ausgabeordner ist aufzubewahren, nicht nur `archive/`.
- Paketarchiv auf lokale/vertrauliche und historische Berichtsdateien geprüft.
  Die pkgdown-Website wurde vollständig gebaut; ihre 18 HTML-Seiten und 505
  lokalen Datei-/Assetverweise wurden geprüft. Light-/Dark-Logos visuell geprüft.
- Lokale Ergebnisse: `lokal/demo-de/report.docx`, `lokal/demo-ma/report.docx`,
  `lokal/layout-probe/report.docx` und `_pkgdown/index.html`.

Diese Prüfung belegt den technischen Durchlauf des ersten Leistungsbausteins. Sie ersetzt
keine fachliche Freigabe realer Cuts, Texte oder der noch fehlenden Kapitel.
