# Rebuild the approved eatTechReport illustration on a clean family hexagon.
# Run from any working directory: powershell -File design/build-logo.ps1
# The image-generation source is preserved in logo-source.png. Only the neutral
# illustration and white wordmark are extracted; none of its colored field,
# border, shadow, or near-transparent outer pixels are reused.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$projectDirectory = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $PSScriptRoot 'logo-source.png'
$outputDirectory = Join-Path $projectDirectory 'man/figures'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

if (-not ('EatTechReportLogo' -as [type])) {
    Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Collections.Generic;

public static class EatTechReportLogo
{
    const int Size = 1200;
    const double OuterRadius = 596;
    const double InnerRadius = 564;
    static readonly Color Red = Color.FromArgb(180, 0, 54);
    static readonly Color LightBorder = Color.FromArgb(39, 26, 43);

    static PointF[] Hexagon(double radius)
    {
        PointF[] points = new PointF[6];
        for (int i = 0; i < 6; i++) {
            double angle = (-90 + 60 * i) * Math.PI / 180;
            points[i] = new PointF((float)(Size / 2.0 + radius * Math.Cos(angle)),
                                   (float)(Size / 2.0 + radius * Math.Sin(angle)));
        }
        return points;
    }

    static int Clamp(double value)
    {
        return Math.Max(0, Math.Min(255, (int)Math.Round(value)));
    }

    static Bitmap ExtractArtwork(Bitmap source)
    {
        if (source.Width != 1254 || source.Height != 1254)
            throw new InvalidOperationException("Expected the approved 1254 x 1254 source.");

        var art = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb);
        bool[,] neutral = new bool[source.Width, source.Height];

        // The approved illustration's bounds; the rest of the source is ignored.
        Rectangle motif = Rectangle.FromLTRB(348, 184, 891, 802);
        for (int y = motif.Top; y < motif.Bottom; y++) {
            for (int x = motif.Left; x < motif.Right; x++) {
                Color p = source.GetPixel(x, y);
                int chroma = Math.Max(p.R, Math.Max(p.G, p.B)) -
                             Math.Min(p.R, Math.Min(p.G, p.B));
                if (chroma <= 34) {
                    neutral[x, y] = true;
                }
            }
        }

        // Keep the connected illustration, not isolated corners of the old
        // dark hexagon that happen to intersect the rectangular search area.
        bool[,] visited = new bool[source.Width, source.Height];
        var largest = new List<Point>();
        for (int y = motif.Top; y < motif.Bottom; y++) {
            for (int x = motif.Left; x < motif.Right; x++) {
                if (!neutral[x, y] || visited[x, y]) continue;
                var component = new List<Point>();
                var pending = new Queue<Point>();
                pending.Enqueue(new Point(x, y));
                visited[x, y] = true;
                while (pending.Count > 0) {
                    Point p = pending.Dequeue();
                    component.Add(p);
                    for (int dy = -1; dy <= 1; dy++) {
                        for (int dx = -1; dx <= 1; dx++) {
                            int nx = p.X + dx, ny = p.Y + dy;
                            if (!motif.Contains(nx, ny) || visited[nx, ny] || !neutral[nx, ny]) continue;
                            visited[nx, ny] = true;
                            pending.Enqueue(new Point(nx, ny));
                        }
                    }
                }
                if (component.Count > largest.Count) largest = component;
            }
        }
        neutral = new bool[source.Width, source.Height];
        foreach (Point at in largest) {
            Color p = source.GetPixel(at.X, at.Y);
            int gray = Clamp((p.R + p.G + p.B) / 3.0);
            neutral[at.X, at.Y] = true;
            art.SetPixel(at.X, at.Y, Color.FromArgb(255, gray, gray, gray));
        }

        // Recover a one-pixel antialias fringe only immediately adjoining the
        // neutral artwork. Unmix the old red matte, rather than retaining it.
        for (int y = motif.Top + 1; y < motif.Bottom - 1; y++) {
            for (int x = motif.Left + 1; x < motif.Right - 1; x++) {
                if (neutral[x, y]) continue;
                bool adjoining = false;
                for (int dy = -1; dy <= 1; dy++)
                    for (int dx = -1; dx <= 1; dx++)
                        adjoining |= neutral[x + dx, y + dy];
                if (!adjoining) continue;
                Color p = source.GetPixel(x, y);
                double alpha = 1.0 - (p.R - p.G) / 170.0;
                if (alpha <= 0.10 || alpha >= 1.0) continue;
                int gray = Clamp((p.G - (1 - alpha)) / alpha);
                art.SetPixel(x, y, Color.FromArgb(Clamp(alpha * 255), gray, gray, gray));
            }
        }

        // The wordmark is white. Green-channel coverage removes the red matte
        // while preserving the approved glyphs, spacing and original location.
        Rectangle label = Rectangle.FromLTRB(215, 820, 1040, 965);
        for (int y = label.Top; y < label.Bottom; y++) {
            for (int x = label.Left; x < label.Right; x++) {
                Color p = source.GetPixel(x, y);
                if (p.G <= 10 || p.R < 150) continue;
                int alpha = Clamp((p.G - 1) * 255.0 / 254.0);
                art.SetPixel(x, y, Color.FromArgb(alpha, 255, 255, 255));
            }
        }
        return art;
    }

    static Bitmap ResizeArtwork(Bitmap source)
    {
        var result = new Bitmap(Size, Size, PixelFormat.Format32bppArgb);
        result.SetResolution(144, 144);
        using (var g = Graphics.FromImage(result)) {
            g.Clear(Color.Transparent);
            g.CompositingMode = CompositingMode.SourceCopy;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            using (var attributes = new ImageAttributes()) {
                attributes.SetWrapMode(WrapMode.TileFlipXY);
                g.DrawImage(source, new Rectangle(0, 0, Size, Size),
                            0, 0, source.Width, source.Height, GraphicsUnit.Pixel, attributes);
            }
        }
        return result;
    }

    static Bitmap Compose(Bitmap artwork, Color border)
    {
        var result = new Bitmap(Size, Size, PixelFormat.Format32bppArgb);
        result.SetResolution(144, 144);
        using (var g = Graphics.FromImage(result)) {
            g.Clear(Color.Transparent);
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            using (var pen = new SolidBrush(border)) g.FillPolygon(pen, Hexagon(OuterRadius));
            using (var pen = new SolidBrush(Red)) g.FillPolygon(pen, Hexagon(InnerRadius));
            // Artwork must never overwrite the geometric border, even if a
            // future source or extraction region includes unrelated pixels.
            using (var clip = new GraphicsPath()) {
                clip.AddPolygon(Hexagon(InnerRadius));
                g.SetClip(clip);
                g.DrawImageUnscaled(artwork, 0, 0);
                g.ResetClip();
            }
        }
        return result;
    }

    static bool InsideInnerHexagon(int x, int y, double inset)
    {
        double dx = Math.Abs(x + 0.5 - Size / 2.0);
        double dy = Math.Abs(y + 0.5 - Size / 2.0);
        double radius = InnerRadius - inset;
        return dx <= Math.Sqrt(3) * radius / 2 &&
               dy <= radius - dx / Math.Sqrt(3);
    }

    static void Validate(Bitmap light, Bitmap dark, Bitmap artwork)
    {
        int cleanFieldPixels = 0;
        int interiorDifferences = 0;
        int changedPixels = 0;
        for (int y = 0; y < Size; y++) {
            for (int x = 0; x < Size; x++) {
                Color l = light.GetPixel(x, y);
                Color d = dark.GetPixel(x, y);
                bool changed = l.ToArgb() != d.ToArgb();
                if (changed) changedPixels++;
                if (!InsideInnerHexagon(x, y, 3)) continue;
                if (changed) interiorDifferences++;
                if (artwork.GetPixel(x, y).A == 0) {
                    cleanFieldPixels++;
                    if (l.ToArgb() != Red.ToArgb() || d.ToArgb() != Red.ToArgb())
                        throw new InvalidOperationException("Nonuniform red field at " + x + "," + y);
                }
            }
        }
        if (interiorDifferences != 0 || changedPixels == 0)
            throw new InvalidOperationException("Variants must differ only at the hexagon border.");
        foreach (Point p in new[] { new Point(0, 0), new Point(1199, 0),
                                    new Point(0, 1199), new Point(1199, 1199) }) {
            if (light.GetPixel(p.X, p.Y).A != 0 || dark.GetPixel(p.X, p.Y).A != 0)
                throw new InvalidOperationException("Corner transparency check failed.");
        }
        Console.WriteLine("Validated: {0} exact #B40036 field pixels; identical interiors; {1} border-only differences; transparent corners.", cleanFieldPixels, changedPixels);
    }

    public static void Build(string input, string outputDirectory)
    {
        using (var source = new Bitmap(input))
        using (var extracted = ExtractArtwork(source))
        using (var artwork = ResizeArtwork(extracted))
        using (var light = Compose(artwork, LightBorder))
        using (var dark = Compose(artwork, Color.White)) {
            Validate(light, dark, artwork);
            light.Save(Path.Combine(outputDirectory, "logo-light.png"), ImageFormat.Png);
            dark.Save(Path.Combine(outputDirectory, "logo-dark.png"), ImageFormat.Png);
        }
        File.Copy(Path.Combine(outputDirectory, "logo-light.png"),
                  Path.Combine(outputDirectory, "logo.png"), true);
    }
}
'@
}

[EatTechReportLogo]::Build($sourcePath, $outputDirectory)
Get-Item -LiteralPath (Join-Path $outputDirectory 'logo-light.png'),
    (Join-Path $outputDirectory 'logo-dark.png'),
    (Join-Path $outputDirectory 'logo.png') | Select-Object Name, Length
