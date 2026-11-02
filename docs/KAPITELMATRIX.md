# Kapitelmatrix: eatTechReport für VERA-3

Stand: 02.11.2026 · Arbeitsfassung 0.6 · Status: Zielstruktur, erster Baustein umgesetzt

Diese Matrix beschreibt das gewünschte Ergebnis und die dafür benötigten
Informationen. Sie legt noch keine endgültigen R-Klassen, Spaltennamen oder
öffentlichen Funktionen für sämtliche Kapitel fest. Der Leistungsbaustein ist
inzwischen im ersten Entwicklungspaket umgesetzt; die vollständige
Berichtsimplementierung und fachliche Textfreigaben stehen noch aus.

## 1. Vereinbarter Rahmen

| Thema | Festlegung |
| --- | --- |
| Berichtseinheit | Ein Technischer Bericht je Durchgang und Fach in VERA-3. |
| Fächer | Deutsch und Mathematik. VERA-8, Englisch, Französisch und GER gehören nicht zu dieser Ausbaustufe. |
| Deutsch | Lesen (`DL`), Zuhören (`DH`), Orthografie (`DO`) und Sprachgebrauch (`DS`) können vorkommen. Die Auswahl ist konfigurierbar; zwei Domänen sind der Regelfall, keine feste technische Begrenzung. 2027: Lesen und Zuhören. |
| Mathematik | Basis- und Ergänzungsmodule; Ergänzungsmodule zu zwei der fünf Leitideen. 2027: Größen und Messen (`MG`) sowie Muster und Strukturen / Funktionaler Zusammenhang (`MM`). Ausschließlich globale Skalierung (`MO`). |
| Kompetenzstufen | Voraussichtlich für alle Skalen: Ia, Ib, II, III, IV. Die zugehörigen numerischen Cuts und Referenzversionen sind noch freizugeben. |
| Äquivalenztabellen | Entfallen. |
| Neue Personenleistungsdarstellung | Dichten mit Kompetenzstufengrenzen, Prozentangaben zwischen den Grenzen und passenden Deskriptiva; ohne Raterdimension. |
| Personenkennwerte und Metrik | Plausible Values (PVs), bereits auf der 500er-Berichtsskala; voraussichtlich 15 PVs, Anzahl je Skala konfigurierbar. Keine erneute Standardisierung der Pilotierungsstichprobe auf Mittelwert 500. |
| Population und Gewichtung | Alle Fälle der Pilotierungsstichprobe je Skala, ungewichtet. Vollständige PV-Datensätze sind garantiert; unerwartete Lücken führen zu einem Eingabefehler. Keine zusätzlichen fachlichen Fallfilter in der Berichtserstellung. |
| Untergruppen | Für VERA-3 ausschließlich Gesamtstichprobe je Skala in der Leistungsdarstellung. Untergruppen frühestens bei einer späteren Erweiterung auf VERA-8 prüfen. |
| Redaktion | Texte werden in Quarto redigiert, nach Kapiteln und fachlich zusammengehörigen Bausteinen gegliedert. |
| Eingaben | R-Objekte werden bevorzugt. CSV nur für einfache Tabellen, wenn die zusätzliche Dateischnittstelle einen konkreten Nutzen hat. Keine XLSX-Eingabeschnittstelle für das neue System. |
| Ausgabe | Vollständig erzeugtes DOCX nach dem verbindlichen Corporate-Muster `lokal/Bericht.dotx`, mit dem Ziel ohne manuelle Formatierungsnacharbeit auszukommen. Für Demo und Realdaten gilt dieselbe Gestaltung; es gibt keine allgemeine Ersatzvorlage oder individuelle Designauswahl. Fachliche Prüfschleifen bleiben vorgesehen. |
| Vorjahresänderungen | Erster neuer Bericht ohne Vorjahresmarker, aber bereits mit Archivstand. Ab Folgejahr bestätigte Änderungen mit Ausrufezeichen rechts am betroffenen Abschnitt markieren. |
| Lokale Bestände | Originalberichte, die neue DOTX, vertrauliche Daten und daraus abgeleitete Arbeits-, Referenz-, Berichts- und Archivdateien bleiben unter `lokal/` und außerhalb der Versionierung. Die Corporate-Vorlage wird nicht mit dem Paket oder der Website ausgeliefert. |

Die Auswahl der Pilotierungsjahre folgt nicht automatisch aus dem Haupttestjahr.
Aktuelle Pilotierung, frühere Pilotierungswellen und die Herkunft einzelner Items
werden getrennt angegeben. Konkrete Pilotierungszeiträume für 2027 sind noch offen.

Die vollständige Zuordnung der Bereichs- und Skalenkürzel steht in der
[Schnittstellenbeschreibung](SCHNITTSTELLE_LEISTUNG.md#3-config-fachliche-festlegungen).
Die fünf Mathematik-Leitideen `MZ`, `MG`, `MM`, `MR` und `MD` verweisen alle auf
die globale Skala `MO`; dadurch entstehen keine zusätzlichen Leistungsskalen.

## 2. Aufbau und Kapitelmatrix

Das bekannte Gerüst bleibt erhalten: Grundlagen → Pilotierung → Haupttest und
Auswertungshinweise → Literatur. Die Nummerierung unten ist ein Vorschlag.
Baustein-IDs verwenden Unterstriche (`snake_case`) und bleiben bei späterer
Umordnung oder Umbenennung der Überschriften erhalten. Die technischen IDs sind
von den gedruckten Überschriften getrennt; `grundlagen_ueberblick` erscheint
beispielsweise als „Allgemeine Informationen“. Die bisher verwendeten Punkt-IDs
werden bereits in der Planungsphase ersetzt, bevor Freigabearchive entstehen.

Die erste inhaltliche Durchsicht dieses Abschnitts ist erfolgt. Die nachstehenden
Änderungen zu Überschriften, Kompetenzbereichen und Stichprobenbeschreibung
berücksichtigen das Feedback vom 02.11.2026. Die übrigen Matrixinhalte wurden in
dieser Runde bestätigt; konkrete Eingabestrukturen und Textfreigaben folgen.

Inhaltsarten:

- **A – Durchgangsangaben:** beispielsweise Jahre, Zeitraum, Zuständigkeiten.
- **E – Fachliche Einstellungen:** beispielsweise Skalen, Testdesign und Methoden.
- **K – Berechnete Ergebnisse:** beispielsweise Anzahlen, Mittelwerte und Verteilungen.
- **T – Standardtexte:** wiederverwendbare, fachlich geprüfte Beschreibungen.
- **R – Redaktionelle Besonderheiten:** Ausnahmen, Änderungen und Begründungen.

Ein Baustein kann mehrere Arten verbinden. Ein Standardtext mit Platzhaltern
für Durchgangsangaben muss beispielsweise nicht in getrennte Texte zerlegt werden.

| Kapitel / Baustein-ID | Aussage und geplante Darstellung | Benötigte Informationen | Gültigkeit / Arten |
| --- | --- | --- | --- |
| Vorspann · `bericht_titel` | Titel, Durchgang, Fach, Verantwortliche und Berichtsversion; automatisch erzeugtes Inhaltsverzeichnis. | Berichtskonfiguration und Gestaltungsvorgaben. | Immer · A |
| 1 · `grundlagen_ueberblick` | Überschrift **„Allgemeine Informationen“**. Zweck und Gegenstand des Berichts; Überblick über die berücksichtigten Domänen und Module. | Quarto-Text, Fach, Durchgang und gewählte Domänen/Module. | Immer · T, A, E |
| 1.1, 1.2, … · `grundlagen_skalen` + `grundlagen_kompetenzstufen` | DE: je Bereich ein gemeinsames Unterkapitel **Kompetenzstufen im Kompetenzbereich „[Bezeichnung]“**. MA: **Kompetenzstufen im Fach Mathematik**. Jeweils kurze Einordnung von Bereich, Skala und Bezugsrahmen, anschließend Stufentabelle und Kompetenzbeschreibungen. | Ausgewählte Bereiche, auswertbare Skalen, Referenzversionen, freigegebene Cuts, Stufenbezeichnungen, Beschreibungen und Quellen. | DE: je gewähltem Bereich; MA: ein gemeinsamer globaler Abschnitt · T, E |
| 2 · `pilotierung_titel` | Überschrift **„Informationen zur Pilotierungsstudie [Jahr1]“**. `[Jahr1]` wird aus dem ausdrücklich angegebenen Pilotierungsjahr eingesetzt. | Pilotierungsjahr der beschriebenen Studie; unabhängig vom Haupttestjahr und von älteren Herkunftsjahren wiederverwendeter Items. | Immer · A |
| 2.1 · `pilotierung_design` | Pilotierungswellen, Testhefte und Blöcke; Art und Anzahl der Aufgaben/Items, getrennt nach definierten Rollen. Tabellen und gegebenenfalls Designübersicht. | Aufgaben-/Itembestand, Rollen, Wellen, Testheft-/Blockzuordnung und Testzeiten. | DE-/MA-spezifische Darstellung · A, E, K, T |
| 2.2 · `pilotierung_stichprobe` | Größe und Zusammensetzung der Pilotierungsstichprobe; Teilnahme und tatsächliche Auswertungspopulation nachvollziehbar abgrenzen. Text und Tabelle; eine Nachkommastelle für Dezimalangaben. Median als *Median* = … . Bearbeitungszahlen der Ankeritems in gesonderter Fußnote. | Rücklauf, Personen-/Klassenbezug, benötigte Merkmale, Ausschlüsse, gültige Nenner und Fehlwerte; getrennte Bearbeitungszahlen für Pilot- und Ankeritems; Schulbezug, soweit verfügbar und vorgesehen. | Immer; Detailgliederung noch festzulegen · K, T, R |
| 2.3 · `pilotierung_durchfuehrung` | Zeitraum, Zuständigkeiten, Durchführung und Testzeiten beschreiben. | Quarto-Text sowie strukturierte Angaben zum tatsächlichen Durchgang. | Immer · T, A, E, R |
| 2.4.1 · `auswertung_kodierung` | Datenerfassung und Kodierung erklären; bei entsprechender Kodierung empirische Übereinstimmung berichten. | Tatsächliche Verfahren, Kodierumfang, Kennwerte und dokumentierte Ausnahmen. | Verfahrensabhängig · T, E, K, R |
| 2.4.2 · `auswertung_methoden` | Rekodierung, Aggregation, Fehlwertbehandlung, Skalierung und Verankerung nachvollziehbar beschreiben. | Freigegebene Methodenbausteine, tatsächlich verwendete Verfahren und relevante Software-/Referenzstände. | MA ausschließlich globale Skalierung · T, E, R |
| 2.4.3 · `auswertung_guete` | Kriterien und Befunde zur empirischen Aufgaben-/Itemgüte darstellen; Ausnahmen begründen. | Gütekriterien, Kennwerte, Bezugsmenge und redaktionelle Begründungen. | Immer · T, E, K, R |
| **2.5 · `pilotierung_leistung`** | **Neu:** je auswertbarer Skala eine Dichte mit Cuts und Prozentanteilen; dazu eine kompakte Tabelle mit Personenanzahl N, Mittelwert und SD. Unerwartete PV-Lücken werden geprüft. | PVs auf der 500er-Berichtsskala für alle Fälle, ungewichtet; eindeutiger Personen-/Skalenbezug, Cuts und vereinbarte Vollständigkeitsregeln. | DE: je auswertbarer Skala; MA: global. Gesamtstichprobe, keine Untergruppen und keine Raterdimension · K, E, T |
| 3.1 · `haupttest_auswahl` | Übergang vom pilotierten Pool zur finalen Auswahl erläutern; Herkunft wiederverwendeter Aufgaben und besondere Auswahlentscheidungen benennen. | Finale Auswahl, Herkunft/Pilotierungswellen und redaktionelle Entscheidungen. | Immer · K, T, R |
| 3.2 · `haupttest_module` | Aufbau der Haupttestmodule, Bearbeitungszeiten, Aufgaben-/Itemzahlen und Aufgabenreihenfolge übersichtlich darstellen. | Moduldefinitionen, Zuordnungen und Reihenfolgen, Aufgabenbezeichnungen und Zeiten. | DE domänenspezifisch; MA Basis-/Ergänzungsmodule · A, E, K |
| 3.3 · `haupttest_itemprofil` | Itemkennwerte zusammenfassen und Verteilung der ausgewählten Items auf Kompetenzstufen zeigen; vergleichbare Darstellung der Module. | Finale Itemkennwerte, Stufen, Modulzuordnung und definierte Zähl-/Aggregationsregeln. | MA durchgehend Kennwerte auf globaler Skala, auch bei Leitideenmodulen · K, E, T |
| 3.4 · `haupttest_transformation` | Umrechnung Logit → Berichtsskala für alle auswertbaren Skalen mit Konstanten, Symbolerklärung und Referenz angeben. Personen- und Itemtransformation unterscheiden, soweit erforderlich. | Verbindliche Transformationsdefinitionen und deren Gültigkeit je Skala und Verwendungszweck. | DE: alle auswertbaren Skalen; MA: global · T, E |
| 3.5 · `haupttest_auswertungshinweise` | Verwendung der bereitgestellten Kennwerte und praktische Hinweise zur Auswertung erläutern. | Fachlich freigegebene Texte passend zu Verfahren, Skalen und Testdesign. | Immer · T, E, R |
| 3.6 · `rueckmeldung_empfehlungen` | Interpretation und Rückmeldung an Schulen verständlich einordnen. | Freigegebene Texte und Quellen. | Immer · T, R |
| 4 · `literatur` | Verwendete Fachliteratur und relevante Softwarequellen konsistent ausgeben. | Literaturdatenbank, tatsächliche Zitate und relevante Softwarestände. | Immer · T, E |

### Zusammenführung der Kompetenzbereiche

Als Arbeitsentscheidung wird die angeregte Zusammenführung umgesetzt: Die
Einordnung des Kompetenzbereichs und dessen Kompetenzstufen stehen unter einer
gemeinsamen Überschrift. Es gibt kein zusätzliches nummeriertes Skalenkapitel
vor den bereichsspezifischen Abschnitten. Inhaltlich können kurze Einordnung,
Stufentabelle und Beschreibungen weiterhin einzeln redigierbare Quarto-Bausteine
sein.

Für Deutsch 2027 ergibt sich damit:

- **1 Allgemeine Informationen**
- **1.1 Kompetenzstufen im Kompetenzbereich „Lesen“**
- **1.2 Kompetenzstufen im Kompetenzbereich „Zuhören“**

Die Auswahl und Reihenfolge der Bereiche bestimmt die Unterkapitel. Bei weiteren
Deutsch-Domänen setzt sich diese Struktur fort. Mathematik erhält einen Abschnitt
**Kompetenzstufen im Fach Mathematik** mit ausdrücklicher Einordnung des
Globalmodells; das Fach wird sprachlich nicht als einzelne Domäne bezeichnet.
Es werden keine getrennten Leitideenskalen eingeführt.

Wiederholte Bausteine erhalten intern eindeutige Instanzkennungen, beispielsweise
`grundlagen_kompetenzstufen_lesen` und `grundlagen_kompetenzstufen_zuhoeren`.
Die Bereichskennung bleibt von der automatisch erzeugten Kapitelnummer getrennt.

### Darstellung von Tabellen und Stichprobenangaben

- Tabellen verwenden Linien sparsam zur Gliederung, standardmäßig horizontale
  und keine vertikalen Linien. Dezente Schattierungen können die Übersichtlichkeit
  ergänzen. Das gilt auch für Kompetenzstufentabellen und wird im Word-Layoutversuch
  mit langen Tabellen überprüft.
- Dezimalangaben in der Stichprobenbeschreibung werden mit **einer Nachkommastelle**
  und deutschem Dezimalkomma ausgegeben, beispielsweise `51,3 %` oder `9,2 Jahre`.
  Absolute Personen-, Klassen- und Itemanzahlen bleiben ganze Zahlen. Diese Regel
  legt nicht automatisch die Präzision von Itemparametern oder anderen Kapiteln fest.
- Bei Medianangaben steht die Bezeichnung kursiv und anschließend ein Gleichheitszeichen,
  beispielsweise *Median* = 123,0. Berechnet wird mit ungerundeten Werten.
- Bearbeitungszahlen pro Pilotitem werden im Haupttext beschrieben. Die entsprechenden
  Zahlen der Ankeritems stehen in einer **gesonderten Fußnote**, mit klar benannter
  Bezugsmenge und passender Zusammenfassung, etwa Minimum, *Median* = … und Maximum.
  Pilot- und Ankeritembearbeitungen werden nicht zu einer gemeinsamen Kennzahl vermischt.

Die neue Leistungsgrafik beschreibt Personen der Pilotierungsstichprobe.
Die Itemgrafiken in 3.3 beschreiben ausgewählte Aufgabenitems der Haupttestmodule.
Beide Darstellungen erhalten eindeutige Beschriftungen und Bezugsgrößen.
Der Ausschluss einer Raterdimension in 2.5 berührt einen fachlich notwendigen
Bericht zur Kodierübereinstimmung in 2.4.1 nicht.

## 3. Neuer Baustein: Leistung der Pilotierungsstichprobe

### Geplantes Ergebnis

Festgelegt ist eine Darstellung der Gesamtstichprobe je auswertbarer Skala,
mit allen Fällen und ohne Gewichte. Geliefert werden PVs auf der
500er-Berichtsskala. In Mathematik entstehen durch Leitideen oder
Ergänzungsmodule keine zusätzlichen psychometrischen Skalen. Untergruppen
gehören nicht zum VERA-3-Umfang; sie können bei der späteren VERA-8-Erweiterung
erneut betrachtet werden.

- Dichte auf der ausdrücklich benannten 500er-Berichtsskala. Der empirische
  Mittelwert darf von 500 abweichen; die Stichprobe wird nicht neu normiert.
- Vertikale Cuts, Kompetenzstufenbezeichnungen und Prozentanteile in allen
  Intervallen einschließlich der beiden äußeren Intervalle.
- Passende Deskriptiva: Personenanzahl N, Mittelwert und Standardabweichung.
  N zählt Personen, nicht die Summe aller PV-Werte.
- Eine gemeinsame Berechnungsgrundlage für Grafik, Tabelle und Fließtext.
- Anmerkung zur Gesamtstichprobe, ungewichteten Berechnung und PV-Verarbeitung.
- Farben, Schrift und Abmessungen nach den Gestaltungsvorgaben; Prozentangaben
  müssen auch ohne Farberkennung verständlich zuzuordnen sein.

Median und Quantile der Personenleistungsverteilung sind mögliche Ergänzungen,
derzeit keine Pflichtangaben. Die oben festgelegte Schreibweise von Medianangaben
in der Stichprobenbeschreibung bleibt davon unberührt.
Standardfehler oder Konfidenzintervalle sind mit diesem Vorschlag noch nicht
beauftragt oder fachlich spezifiziert.

### Vorhandener Kandidat in eatPrep

Ausgangspunkt ist die vom Nutzer benannte
[IDM-Populationsgrafik](https://sachseka.github.io/eatPrep/reference/plotPopulationCutsIDM.html).
Die lokal installierte eatPrep-Version **1.0.16** bietet bereits die Funktion
`plotPopulationCuts()` für numerisch vorgegebene Cuts ohne IDM-Objekt/Rater.
Lokale Hilfe und Funktionskörper wurden während der Planung lesend geprüft.
Der erste Paketstand verwendet nun eine eigene schlanke ggplot2-Darstellung
mit denselben vereinbarten Berechnungsregeln, ohne eatPrep als Abhängigkeit.

Für die Planung relevante Eigenschaften der geprüften lokalen Version:

- Dokumentierte Eingabe sind Plausible Values (PVs) als R-`data.frame`, in breiter
  oder langer Form; Gewichte und Populationsgruppen sind optional.
- Personenwerte und Cuts müssen bereits auf derselben Metrik vorliegen.
- Die Prozentanteile werden je PV direkt aus Beobachtungen beziehungsweise
  Gewichten ermittelt und anschließend über die PVs gemittelt. Sie werden
  unabhängig von der Glättung der gezeichneten Dichte berechnet.
- Werte genau auf einem Cut gehören zum höheren Intervall.
- Mittelwert und SD werden über die PV-Ergebnisse zusammengefasst; die SD ist
  die Wurzel der gemittelten PV-Varianzen. Es werden keine Standardfehler berechnet.
- Das ggplot-Ergebnis trägt ungerundete Intervallanteile im Attribut
  `population_percentages`, die eine konsistente Tabellendarstellung ermöglichen.
- Fehlende Werte führen standardmäßig zu einem Fehler. Die optionale Behandlung
  durch Weglassen wird für diesen Bericht nicht verwendet, da vollständige
  PV-Datensätze zugesichert sind.

Mit der Entscheidung für PVs auf der 500er-Berichtsskala passt die dokumentierte
Eingabe grundsätzlich zum Bedarf. Zu klären bleibt die konkrete R-Struktur.
Die optionalen Gewichte und Populationsgruppen der Funktion werden für VERA-3
nicht verwendet. PVs werden nicht vorab je Person zu einem einzigen Wert
gemittelt; Zusammenfassungen erfolgen je PV und anschließend über die PVs.

Im Paket stellt `plot_performance()` die gemittelte Dichte je Skala dar.
Alle PV-Dichten verwenden dasselbe Raster und eine gemeinsame Bandbreite,
standardmäßig das Mittel der je PV bestimmten `bw.nrd0()`-Bandbreiten. Die
Prozentanteile stammen direkt aus `summarise_leistung_input()` und ändern sich
nicht mit der Glättung. Weitere Details stehen in der Funktionsreferenz und
der [Schnittstellenbeschreibung](SCHNITTSTELLE_LEISTUNG.md).

### Vollständigkeit der PV-Datensätze

Vollständige PV-Datensätze sind zugesichert. Damit ist die frühere Missing-Frage
geklärt: Für jede erwartete Person und Skala liegt der konfigurierte PV-Satz vor.
Die Prüfung betrifft **gelieferte PV-Werte**. Die Behandlung fehlender
Itemantworten gehört zur vorgelagerten Skalierung und wird im Methodenabschnitt
beschrieben. Sie führt im Bericht nicht automatisch zum Ausschluss einer Person
mit vorhandenen PVs.

Die Eingabeprüfung bleibt bestehen, um etwa Übertragungsfehler zu erkennen:
Bei 15 erwarteten PVs wären 14 vorhandene Werte und ein `NA`, ein vollständig
fehlender PV-Satz oder fehlende Person-PV-Zeilen im langen Format Eingabefehler.
Ebenso werden versehentliche `Inf`-Werte oder doppelte Person-PV-Zuordnungen
erkannt.

Lücken lösen eine verständliche Eingabefehlermeldung aus; es werden weder
Personen entfernt noch PVs ergänzt. So bleibt die Vorgabe „alle Fälle“ erhalten
und Grafik, Prozentanteile, N und Deskriptiva beziehen sich auf dieselbe
Personengruppe. Eine zusätzliche fachliche Regel zur Auswertung unvollständiger
PV-Sätze ist für den vereinbarten Umfang nicht erforderlich.

Quellenstand: Die verlinkte Webdokumentation war beim Abruf nicht verfügbar.
Die obigen Funktionsangaben beruhen auf der lokalen Hilfe und Implementierung
von eatPrep 1.0.16. Der öffentliche Projekteinstieg ist
[sachseka/eatPrep](https://github.com/sachseka/eatPrep).

## 4. Eingaben vom Berichtsergebnis her definieren

Die folgende Zuordnung beschreibt Informationsgruppen, keine endgültige API.
Die historische Mathematik-Liste ist keine Vorgabe für das neue Eingabeformat.

| Informationsgruppe | Bevorzugte Übergabe | Dient insbesondere |
| --- | --- | --- |
| Berichtskonfiguration | Verständlich aufgebautes R-Objekt: Durchgang, Fach, Domänen, Pilotierungswellen, Durchführung, Verantwortliche. | Titel, Überblick und Durchführung. |
| Fachliche Definitionen | Versionierte R-Objekte für Skalen, Cuts, Transformationen und Methodenentscheidungen. Beschreibende Prosa in Quarto. | Kompetenzstufen, Methoden, Gütekriterien und Formeln. |
| Aufgaben-/Itembestand und Design | R-Tabellen mit eindeutigen Kennungen, Zuordnungen, Rollen und Herkunft. | Pilotierungsdesign, Zählungen und Haupttestmodule. |
| Stichprobe und Personenleistung | R-Objekte mit erforderlichen Personenmerkmalen und PVs auf der 500er-Berichtsskala; alle Fälle, ungewichtet. | Stichprobentabellen, Dichten und Deskriptiva. |
| Item- und Kodierergebnisse | R-Tabellen mit Kennwerten, Modell-/Skalenbezug, finaler Auswahl und gegebenenfalls Kodierübereinstimmung. | Güte, Haupttestprofile und Kodierung. |
| Redaktionelle Inhalte | Quarto-Bausteine; strukturierte Zuordnung von Besonderheiten und Änderungsentscheidungen. | Standardtexte, begründete Ausnahmen und spätere Randhinweise. |

CSV wird nur ergänzt, wenn eine dieser Tabellen außerhalb von R sinnvoll
gepflegt oder ausgetauscht werden soll. Dieselben Angaben werden nicht parallel
in R und CSV als konkurrierende Quellen gepflegt. Vorhandene historische
Importe aus Excel sind kein Beschluss für eine neue XLSX-Schnittstelle.

Vor Berechnungen müssen insbesondere folgende Begriffe getrennt sein:

- Domäne/Leitidee, psychometrische Skala und Testmodul.
- Aufgabe und Item sowie deren jeweilige Zählregeln.
- Pilotierungswelle und Haupttestdurchgang.
- Angefragte, teilnehmende und tatsächlich ausgewertete Stichprobe.
- Personen-, Klassen- und gegebenenfalls Schulbezug.
- Referenzpopulation der Skala und empirische Pilotierungsstichprobe.

Jede Kennzahl braucht eine nachvollziehbare Bezugsmenge, Einheit, Fehlwertregel
und Datenquelle. Routinemäßige Rundung erfolgt erst für die Darstellung.

## 5. Redaktion und Archivierung

### Kapitelweise Korrekturschleifen

1. Fachlich zusammengehörige Quarto-Bausteine mit dauerhaften IDs anlegen.
2. Pro Baustein Titel, Kapitelzuordnung, Gültigkeit, Inhaltsarten, benötigte
   Eingaben und Bearbeitungsstatus an einer verbindlichen Stelle führen.
3. Text bearbeiten und mit passenden Beispielwerten im Kapitelkontext prüfen.
4. Fachliche Korrekturen in die Quarto-Quelle übernehmen und erneut erzeugen.
5. Freigabe dokumentieren. Entwürfe dürfen offene Stellen zeigen; die finale
   Ausgabe darf keine unaufgelösten Pflichtangaben oder Platzhalter enthalten.

Eine Datei je Satz ist nicht vorgesehen. Die genaue Dateigröße richtet sich
nach der sinnvollen redaktionellen Einheit und Wiederverwendung. Berechnungen
und Zusammenstellungslogik werden aus der zu redigierenden Prosa herausgehalten.
Tabellen, Zahlen und Grafiken entstehen aus den gemeinsamen R-Ergebnissen.

### Freigabestände und Vorjahresvergleich

Der erste neue Bericht wird bereits mit seinen verwendeten Texten, Eingaben,
R-Ergebnissen, Definitionen, Literatur, Gestaltungsvorlagen, Softwareständen und
dem erzeugten DOCX archiviert. Freigegebene Stände sind unveränderlich; fachliche
Korrekturen bekommen eine neue Revision. Vertrauliche Archive bleiben lokal.

Für spätere Vergleiche werden Quarto-Bausteine vor dem Einsetzen jährlicher
Werte sowie die fachlichen Einstellungen getrennt betrachtet. Jahreszahlen,
Stichprobenumfänge und neue Messwerte sind regulär wechselnde Angaben. Geänderte
Methoden, Güteschwellen, Cuts oder Referenzmetriken bleiben fachlich relevante
Änderungskandidaten, auch wenn sie als Parameter gespeichert sind.

Die Redaktion bestätigt, welche Kandidaten ein Ausrufezeichen erhalten. Die
Markierung selbst wird anschließend automatisch beim zugehörigen Baustein
erzeugt. Dafür wird kein zusätzliches Änderungskapitel vorausgesetzt.
Vergleichsbasis ist eine freigegebene Fassung, nicht der vorherige Renderlauf.
Die genaue Vergleichsregel bei wechselnden Domänen bleibt offen.

## 6. Entscheidungsstand und nächster Planungsschritt

Die folgenden Punkte verhindern die erste Kapitelmatrix nicht. Sie müssen
jeweils vor der Umsetzung beziehungsweise Freigabe des betroffenen Bausteins
geklärt werden.

| ID | Entscheidung / offener Punkt | Benötigt vor |
| --- | --- | --- |
| O1 | PVs und 500er-Metrik sind festgelegt, voraussichtlich 15 PVs. Ein ausführbarer erster Eingabevertrag mit Population und langer PV-Tabelle liegt vor. Offen bleiben die Anbindung der tatsächlichen R-Quellobjekte und ihre Personen-/PV-Kennungen. Die Bereichs-/Skalenkürzel sind festgelegt. | Freigabe des Datenvertrags und Anbindung realer Eingaben für `pilotierung_leistung`. |
| O2 | **Geklärt:** alle Fälle, keine Gewichte und garantierte vollständige PV-Sätze. Unerwartete Lücken stoppen die Berechnung mit einer Eingabefehlermeldung. | Keine weitere fachliche Entscheidung; die Vollständigkeitsprüfung ist im Prototyp umgesetzt. |
| O3 | Vorgesehene Stufenbezeichnungen: Ia, Ib, II, III, IV. Welche freigegebenen Cuts, Kompetenzbeschreibungen und Transformationen gelten je Skala/Referenzversion? | Freigabe der Grundlagen, Leistungsgrafiken und Formeln. |
| O4 | Leistungsdarstellung ist geklärt: Gesamtstichprobe je Skala, keine Untergruppen für VERA-3. Offen bleibt die Detailauswahl der Merkmale in der Stichprobenzusammensetzung (2.2). | Verbindlichem Umfang der Stichprobentabelle. |
| O5 | Welche Zählregeln gelten für Aufgaben/Items, Rollen und Wiederverwendung über Wellen oder Module hinweg? | Design- und Auswahltabellen sowie automatischen Konsistenzprüfungen. |
| O6 | Welche historischen Texte dienen jeweils als Ausgangsfassung? Welche Formulierungen bleiben, ändern sich oder entfallen zusätzlich? | Kapitelweiser redaktioneller Freigabe; die Antwort kann im Arbeitsprozess entstehen. |
| O7 | Das Corporate-Muster `lokal/Bericht.dotx` ist für Demo und Realdaten verbindlich. Offen bleiben die technische Abbildung der Vorlage und die Umgebung zur vollständigen DOCX-Erzeugung einschließlich Verzeichnissen und Randzeichen. | Layout-Machbarkeitsnachweis. |
| O8 | Wie werden Domänenwechsel und fachlich relevante Änderungen bei späteren Vergleichen behandelt? | Erstem Bericht mit Vorjahresmarkierungen; stabile IDs und Archivierung werden von Beginn an berücksichtigt. |

Für `pilotierung_leistung` ist die Kette Aussage → Tabelle/Grafik/Text →
R-Eingaben → fachliche Regeln im ersten Paketstand umgesetzt. Die übrigen
Kapitel werden anschließend nach demselben Muster konkretisiert. Als nächste
Schwerpunkte bieten sich Testdesign und Stichprobenzusammensetzung an.

Die erste Konkretisierung von `config` und `data` ist in der
[Schnittstellenskizze zum Leistungsbaustein](SCHNITTSTELLE_LEISTUNG.md) und dem
[synthetischen R-Eingabebeispiel](../examples/leistung_input.R) beschrieben.
Sie bildet den Eingabevertrag des ersten Leistungsabschnitts, noch keine
vollständige Berichtsschnittstelle. Datenerzeugung und Kennzahlprüfung benötigen die DOTX nicht;
für jeden vollständigen Demo- oder Realbericht ist die Corporate-Vorlage
dagegen zwingend erforderlich. Fehlt sie, wird die Dokumenterzeugung beendet.

Ein erster Layoutnachweis mit synthetischen Daten ist durchgeführt: Deckblatt,
automatisch aktualisiertes Inhaltsverzeichnis, Dichten, Formel, Fußnote und eine
lange Tabelle wurden mit der verbindlichen Corporate-Vorlage in Word geprüft.
Die erweiterte Probe enthält alle vier Deutsch-Domänen. Literatur und spätere
Randzeichen stehen noch aus; die Gestaltung längerer vollständiger Kapitel
wird weiter geprüft. Vorlage, abgeleitete Referenzdateien und erzeugte
DOCX-Dateien bleiben lokal.

Reviewablauf, Paketgerüst, NEWS, pkgdown und die Reihenfolge der weiteren
Arbeitsschritte stehen im [Arbeitsplan](ARBEITSPLAN.md).
