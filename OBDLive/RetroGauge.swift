import SwiftUI

/// The Retro skin's engine-speed display (`rtStyle` in OBD Prototype.dc.html), an 80s digital dash:
/// a chrome-rimmed black panel with seven-segment speed, gear and rpm in glowing red, a 32-segment
/// rev bar to 8000 rpm (orange from 6750), coolant and battery needle gauges, and three warning lamps
/// (check engine, low voltage, shift). Drawn in the design's 402×262 coordinates, scaled to the width.
struct RetroGauge: View {
    let rpm: Double?
    /// Speed in display units (km/h or mph).
    let speed: Double?
    let speedText: String
    let speedUnit: String
    let gear: Int
    let rpmText: String
    /// Coolant in °C, for the needle; `coolantText` is in display units.
    let coolant: Double?
    let coolantText: String
    let volt: Double?
    let milOn: Bool

    static let maxRPM = 8000.0
    static let shiftRPM = 6000.0
    static let lowVolt = 12.2

    private static let red = Color(hex: 0xFF2414)
    private static let unlit = Color(hex: 0x220604)
    private static let label = Color(hex: 0x7A2A22)
    private static let caption = Color(hex: 0xA33A2E)
    private static let amber = Color(hex: 0xFFB000)
    private static let font = "ShareTechMono-Regular"

    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width / 402
            Canvas { ctx, _ in
                ctx.scaleBy(x: s, y: s)
                draw(&ctx)
            }
        }
        .aspectRatio(402.0 / 262.0, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Engine speed \(rpmText) rpm, gear \(gear > 0 ? String(gear) : "neutral"), speed \(speedText) \(speedUnit)"
                            + (milOn ? ", check engine" : ""))
    }

    // MARK: drawing

    private func draw(_ ctx: inout GraphicsContext) {
        // bezel: chrome rim, black glass, scanlines
        let rim = Path(roundedRect: CGRect(x: 10, y: 8, width: 382, height: 246), cornerRadius: 12)
        ctx.fill(rim, with: .color(Color(hex: 0x0B0B0B)))
        ctx.stroke(rim, with: .linearGradient(Gradient(stops: [
            .init(color: Color(hex: 0x8A8A8A), location: 0), .init(color: Color(hex: 0x3A3A3A), location: 0.45),
            .init(color: Color(hex: 0x161616), location: 1),
        ]), startPoint: CGPoint(x: 0, y: 8), endPoint: CGPoint(x: 0, y: 254)), lineWidth: 2)
        let glass = Path(roundedRect: CGRect(x: 20, y: 18, width: 362, height: 226), cornerRadius: 6)
        ctx.fill(glass, with: .color(Color(hex: 0x030303)))
        ctx.stroke(glass, with: .color(Color(hex: 0x1C1C1C)), lineWidth: 1)
        var scan = Path()
        var y: CGFloat = 18
        while y < 244 { scan.addRect(CGRect(x: 20, y: y, width: 362, height: 1)); y += 3 }
        var clip = ctx
        clip.clip(to: glass)
        clip.fill(scan, with: .color(.white.opacity(0.025)))

        text(&ctx, "SPEED", x: 34, y: 38, size: 10, tracking: 2, color: Self.label, anchor: .leading)
        text(&ctx, "GEAR", x: 201, y: 38, size: 10, tracking: 2, color: Self.label, anchor: .center)
        text(&ctx, "RPM", x: 368, y: 38, size: 10, tracking: 2, color: Self.label, anchor: .trailing)
        text(&ctx, speedUnit, x: 146, y: 96, size: 11, color: Self.caption, anchor: .leading)

        // seven-segment readouts, slanted like the design's skewX(-6)
        var seg = ctx
        seg.concatenate(CGAffineTransform(a: 1, b: 0, c: -tan(6 * .pi / 180), d: 1, tx: 0, ty: 0))
        let speedDigits = speed.map { String(Int($0.rounded())) } ?? "--"
        let rpmDigits = rpm.map { String(Int(($0 / 10).rounded()) * 10) } ?? "--"
        sevenSegment(&seg, padded(speedDigits, 3), x: 47)
        sevenSegment(&seg, gear > 0 ? String(gear) : "n", x: 195)
        sevenSegment(&seg, padded(rpmDigits, 4), x: 241)

        // rev bar: 32 segments to 8000 rpm, the last five orange
        let lit = Int((min(max((rpm ?? 0) / Self.maxRPM, 0), 1) * 32).rounded())
        let bw = (334.0 - 31 * 2) / 32
        for i in 0..<32 {
            let on = i < lit, hot = i >= 27
            let r = Path(roundedRect: CGRect(x: 34 + Double(i) * (bw + 2), y: 114, width: bw, height: 24), cornerRadius: 1)
            if on {
                let c = (hot ? Color(hex: 0xFF6A1A) : Self.red).opacity(0.55 + 0.45 * Double(i) / 31)
                glowing(&ctx, c) { $0.fill(r, with: .color(c)) }
            } else {
                ctx.fill(r, with: .color(hot ? Color(hex: 0x2A0D04) : Color(hex: 0x1E0604)))
            }
        }
        for k in 0...8 {
            text(&ctx, String(k), x: 34 + 334 * Double(k) / 8, y: 152, size: 10, color: Self.label, anchor: .center)
        }

        // coolant and battery needle gauges
        dial(&ctx, cx: 78, fraction: coolant.map { ($0 - 60) / 55 }, caption: "TEMP \(coolantText)")
        dial(&ctx, cx: 324, fraction: volt.map { ($0 - 11.5) / 3.5 },
             caption: "BATT " + (volt.map { String(format: "%.1f V", $0) } ?? "—"))

        // warning lamps
        lamp(&ctx, y: 166, "CHECK ENGINE", on: milOn, color: Self.amber)
        lamp(&ctx, y: 190, "LOW VOLTAGE", on: (volt ?? 99) < Self.lowVolt, color: Self.amber)
        lamp(&ctx, y: 214, "SHIFT", on: (rpm ?? 0) > Self.shiftRPM, color: Self.red)
    }

    private func padded(_ s: String, _ n: Int) -> String {
        String((String(repeating: " ", count: max(0, n - s.count)) + s).suffix(n))
    }

    /// Draws `body` with a red bloom like the design's `rtGlow` filter (blur 2.2 merged under the shape).
    private func glowing(_ ctx: inout GraphicsContext, _ color: Color, _ body: (inout GraphicsContext) -> Void) {
        ctx.drawLayer { layer in
            layer.addFilter(.shadow(color: color, radius: 2.2))
            body(&layer)
        }
    }

    private func text(_ ctx: inout GraphicsContext, _ s: String, x: CGFloat, y: CGFloat, size: CGFloat,
                      tracking: CGFloat = 0, color: Color, anchor: UnitPoint) {
        // y is the SVG baseline; Canvas anchors on the text box, so lift by about a third of the size
        ctx.draw(Text(s).font(.custom(Self.font, fixedSize: size)).tracking(tracking).foregroundColor(color),
                 at: CGPoint(x: x, y: y - size * 0.35), anchor: anchor)
    }

    private static let segments: [Character: String] = [
        "0": "abcdef", "1": "bc", "2": "abdeg", "3": "abcdg", "4": "bcfg", "5": "acdfg", "6": "acdefg",
        "7": "abc", "8": "abcdefg", "9": "abcdfg", "n": "ceg", "-": "g",
    ]

    /// Seven-segment digits 26×48, 34 apart, from `x` at y = 48 (the design's `seg7`).
    private func sevenSegment(_ ctx: inout GraphicsContext, _ str: String, x x0: CGFloat) {
        let w: CGFloat = 26, h: CGFloat = 48, step: CGFloat = 34, top: CGFloat = 48, t: CGFloat = 5, h2 = t / 2
        for (i, ch) in str.enumerated() {
            let X = x0 + CGFloat(i) * step, m = top + h / 2
            let on = Self.segments[ch] ?? ""
            func horizontal(_ yc: CGFloat) -> Path {
                let x1 = X + h2 + 1, x2 = X + w - h2 - 1
                return poly([(x1, yc), (x1 + h2, yc - h2), (x2 - h2, yc - h2), (x2, yc), (x2 - h2, yc + h2), (x1 + h2, yc + h2)])
            }
            func vertical(_ xc: CGFloat, _ y1: CGFloat, _ y2: CGFloat) -> Path {
                poly([(xc, y1), (xc + h2, y1 + h2), (xc + h2, y2 - h2), (xc, y2), (xc - h2, y2 - h2), (xc - h2, y1 + h2)])
            }
            let parts: [Character: Path] = [
                "a": horizontal(top + h2), "g": horizontal(m), "d": horizontal(top + h - h2),
                "f": vertical(X + h2, top + h2 + 1, m - 1), "b": vertical(X + w - h2, top + h2 + 1, m - 1),
                "e": vertical(X + h2, m + 1, top + h - h2 - 1), "c": vertical(X + w - h2, m + 1, top + h - h2 - 1),
            ]
            var dark = Path(), lit = Path()
            for k in "abcdefg" { if on.contains(k) { lit.addPath(parts[k]!) } else { dark.addPath(parts[k]!) } }
            ctx.fill(dark, with: .color(Self.unlit))
            if !lit.isEmpty { glowing(&ctx, Self.red) { $0.fill(lit, with: .color(Self.red)) } }
        }
    }

    private func poly(_ pts: [(CGFloat, CGFloat)]) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: pts[0].0, y: pts[0].1))
        for q in pts.dropFirst() { p.addLine(to: CGPoint(x: q.0, y: q.1)) }
        p.closeSubpath()
        return p
    }

    /// A 240° needle gauge of radius 28 centred at (cx, 198): from lower left over the top to lower right.
    private func dial(_ ctx: inout GraphicsContext, cx: CGFloat, fraction: Double?, caption: String) {
        let cy: CGFloat = 198, r: CGFloat = 28
        func point(_ deg: Double, _ rr: CGFloat) -> CGPoint {
            CGPoint(x: cx + rr * CGFloat(cos(deg * .pi / 180)), y: cy - rr * CGFloat(sin(deg * .pi / 180)))
        }
        var arc = Path()
        arc.move(to: point(210, r))
        for i in 1...48 { arc.addLine(to: point(210 - 240 * Double(i) / 48, r)) }
        ctx.stroke(arc, with: .color(Color(hex: 0x2A0D0A)), lineWidth: 3)
        for i in 0..<7 {
            var tick = Path()
            tick.move(to: point(210 - 40 * Double(i), r))
            tick.addLine(to: point(210 - 40 * Double(i), r - 5))
            ctx.stroke(tick, with: .color(Self.label), lineWidth: 1.5)
        }
        if let fraction {
            var needle = Path()
            needle.move(to: CGPoint(x: cx, y: cy))
            needle.addLine(to: point(210 - 240 * min(max(fraction, 0), 1), 24))
            glowing(&ctx, Self.red) { $0.stroke(needle, with: .color(Self.red), style: StrokeStyle(lineWidth: 2.5, lineCap: .round)) }
        }
        let hub = Path(ellipseIn: CGRect(x: cx - 3.5, y: cy - 3.5, width: 7, height: 7))
        ctx.fill(hub, with: .color(Color(hex: 0x3A3A3A)))
        ctx.stroke(hub, with: .color(Color(hex: 0x6A6A6A)), lineWidth: 1)
        text(&ctx, caption, x: cx, y: 232, size: 10, color: Self.caption, anchor: .center)
    }

    private func lamp(_ ctx: inout GraphicsContext, y: CGFloat, _ label: String, on: Bool, color: Color) {
        let r = Path(roundedRect: CGRect(x: 146, y: y, width: 110, height: 18), cornerRadius: 2)
        if on {
            glowing(&ctx, color) { $0.fill(r, with: .color(color)) }
        } else {
            ctx.fill(r, with: .color(Color(hex: 0x140C06)))
        }
        ctx.stroke(r, with: .color(Color(hex: 0x2A2016)), lineWidth: 1)
        text(&ctx, label, x: 201, y: y + 13, size: 10, tracking: 1.5, color: on ? Color(hex: 0x140800) : Color(hex: 0x4A3A26), anchor: .center)
    }
}
