# Logo: eatTechReport

Stand: 02.11.2026

## Gestaltung und Varianten

Der Nutzer hat das Schreibmaschinenmotiv mit Berichtseite bestätigt und eine
etwas kleinere, ausgewogene Platzierung gewünscht. Das gesamte Schwarz-Weiß-Motiv
wurde entsprechend verkleinert. Die Wortmarke lautet `eatTechReport`.

Als Familienreferenzen dienen die aktuellen eatPrep-/eatModel-Logos sowie
die Light-/Dark-Versionen unter `D:/eat/IQB-Methods/logos/`.

- Rote Fläche: `#B40036`, einheitlich ohne Schatten oder Farbverläufe.
- Lightmode: dunkler Hexagonrand `#271A2B`.
- Darkmode: weißer Hexagonrand `#FFFFFF`.
- Motiv und Wortmarke sind in beiden Versionen gleich.
- Der Außenbereich ist transparent.

## Projektdateien

- [Lightmode](../man/figures/logo-light.png)
- [Darkmode](../man/figures/logo-dark.png)
- [Standardlogo für Paketwerkzeuge](../man/figures/logo.png)
- [Bildquelle vor geometrischer Bereinigung](logo-source.png)
- [Reproduzierbare Bereinigung](build-logo.ps1)

Die beiden finalen Varianten werden aus derselben Bildquelle abgeleitet. Damit
bleiben Motiv, Wortmarke, Größe und Position übereinstimmend.
Die PNGs haben jeweils 1200 × 1200 Pixel. Das Standardlogo ist eine identische
Kopie der Lightmode-Version.

## Herstellungsweg

Der erste Entwurf und die Verkleinerung entstanden mit dem eingebauten
Imagegen-Werkzeug, anhand der eat-Familienreferenzen. Es wurde kein API-/CLI-Fallback
verwendet. Die generative Erstellung eines weißen Rahmens führte wiederholt zu
Randartefakten. Der Nutzer hat deshalb ausdrücklich die geometrische Bereinigung
per Code beauftragt. Rahmen, rote Fläche und Transparenz werden dabei exakt
rekonstruiert; die Schwarz-Weiß-Illustration und Wortmarke stammen aus dem
bestätigten Entwurf. Die reproduzierbare Bearbeitung liegt unter `design/`.

Die folgenden Prompts dokumentieren die Herkunft der verwendeten Bildquelle.
Die verworfenen generativen Darkmode-Entwürfe sind keine Projektressourcen.

## Prompt: Erstentwurf

```text
Use case: logo-brand.
Create one finished draft logo for the R package eatTechReport, matching the existing eat package family in the two supplied reference images. References are for style and family identity, not subjects to reproduce.
Asset: square package hex sticker, transparent outside the hexagon.
Composition: a centered regular point-up hexagon with a broad flat dark outline #271A2B and solid deep red interior #B40036. Keep the whole outline visible. Match the overall proportions and flat treatment of the references.
Central motif: an upright vintage mechanical typewriter with a single prominent report sheet emerging from it, rendered as a crisp black-and-white engraved pen-and-ink illustration like the reference jar and robot. The report sheet contains a simple density curve with a few vertical cut lines, and a tiny ruled data table beneath it, with no readable prose. The motif conveys automated scientific report writing. Keep the silhouette clear at small size and avoid excessive tiny detail.
Typography: exact text "eatTechReport" in one line, horizontally centered below the motif, white, light clean sans serif, generous clear spacing from the illustration and hexagon border. Spell exactly e a t T e c h R e p o r t. No other text, no tagline.
Constraints: flat printed artwork, no 3D bevel, no gradients, no shadows, no mockup, no background outside the hexagon, no extra badges or logo variants. High contrast black/white motif and clean red negative space. Preserve the eat family visual language while making an original report-making motif.
```

## Prompt: Schattenkorrektur / Lightmode

```text
Use case: precise-object-edit. Edit ONLY the first image, the approved eatTechReport logo. The second image is a reference for the eat-family LIGHT MODE border treatment, not a new subject.
Keep the approved typewriter illustration, report sheet, density curve, table, exact "eatTechReport" lettering, typography, positions, proportions and hexagon geometry unchanged.
Remove the unwanted black cast shadow/dark smudge on the RIGHT side of the illustration and any diffuse shading on the red field. Make the entire exposed red field perfectly flat uniform #B40036 right up to the clean engraving edges. Preserve the black ink inside the engraving; remove only cast shadows and shaded background. No gradients or drop shadows anywhere.
LIGHT MODE: hexagon outline must remain a flat uniform dark #271A2B, same width on all six edges, with the red face #B40036 and white lettering. Outside the hexagon must remain genuinely transparent with no black backdrop, no shadow, no halo. Preserve the whole hexagon, no clipping. Deliver exactly one square transparent PNG logo. Do not redesign anything or change any text.
```

## Prompt: kleineres, ausgewogen platziertes Motiv

```text
Use case: precise-object-edit. Edit this approved eatTechReport LIGHT MODE logo with ONE tightly scoped layout change.
The user wants the entire black-and-white illustration a little smaller and more balanced.
Treat the complete typewriter plus emerging report paper, including its density plot and table, as a single locked group. Scale this entire group to 92 percent of its current size (a small reduction, not a redesign). Center the group horizontally precisely in the hexagon, and balance it vertically in the available area above the package name, with comfortable red space between the motif and the text. Preserve every illustration detail and relative position within that group.
Keep the exact wordmark "eatTechReport", its current size, position and typography unchanged. Keep the hexagon geometry and border width unchanged. Exposed red must be uniformly flat #B40036, with no shadows/smudges including to the right of the motif. Keep LIGHT border uniformly #271A2B. Outside the hexagon genuinely transparent, no black background, no halos. No gradients, drop shadows, bevels, additional graphics, or text. Output a single square transparent PNG.
```
