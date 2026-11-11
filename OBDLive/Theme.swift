import SwiftUI

/// The app's four looks, the skins in OBD Prototype.dc.html. All four are dark.
/// Simple is the Modernist skin (graphite ground, amber accent, Barlow type, rounded cards and a pill
/// tab bar); Racing is "Type R" (carbon ground, red accent, Saira type, Type R style rev bar); Power is
/// a navy ground with a blue-to-red accent and twin speed / rpm gauges; Retro is an 80s digital dash
/// (black scanline ground, glowing red seven-segment readouts, Share Tech Mono type, warning lamps).
enum Skin: String, CaseIterable {
    case simple = "Simple", racing = "Racing", power = "Power", retro = "Retro"

    var palette: Palette {
        switch self {
        case .simple: return .simple
        case .racing: return .racing
        case .power: return .power
        case .retro: return .retro
        }
    }

    /// The next skin for the header's skin switch.
    var next: Skin { Skin.allCases[(Skin.allCases.firstIndex(of: self)! + 1) % Skin.allCases.count] }
}

/// Ground texture over the background (`--skin-texture`).
enum Texture { case none, carbon, power, scanlines }

/// Colour, type and shape tokens for one skin (the design's CSS custom properties).
struct Palette {
    let bg, surface, text, accent, divider: Color
    let neutral200, neutral300, neutral500, neutral600, neutral700, neutral800, neutral900: Color
    let accent100, accent200, accent600, accent700, accent800: Color
    /// The 2px rule under the app header (`--skin-rule`); a gradient on Power, invisible on Simple,
    /// and on Retro a red line that fades out at both ends.
    let headerRule: [Color]
    var headerRuleFades = false
    /// Rules between Live sections and cells (`--skin-sep`); nil means the divider colour.
    var separator: Color? = nil
    /// Primary action fill, pressed fill and label (`--skin-cta*`); nil means the accent.
    var cta: Color? = nil
    var ctaPressed: Color? = nil
    var ctaText: Color? = nil
    /// Live reading values (`--skin-readout`) and out-of-range values (`--skin-warn`); nil means text / accent.
    var readout: Color? = nil
    var warn: Color? = nil
    /// Glow around Live reading values (`--skin-glow`); nil means none.
    var glow: Color? = nil
    let headingFont, headingBoldFont, headingSemiFont, bodyFont, bodyMediumFont: String
    /// Small labels on Live (`--skin-mono`); nil means the body font.
    var monoFont: String? = nil
    var monoMediumFont: String? = nil
    var texture: Texture = .none
    /// `--skin-r`: Live cards and the check-engine banner.
    var cornerRadius: CGFloat = 0
    /// `--skin-r-btn`: Clear codes buttons.
    var buttonRadius: CGFloat = 0
    /// `--skin-pill-r` / `--skin-dot-r`: header chips, tab bar and badges are pills, status dots round.
    var pills = false
    /// `--skin-sheet-r`: top corners of the Clear codes sheet.
    var sheetRadius: CGFloat = 0
    /// Live reading cells as separate cards with a range bar (`--skin-card`, `--skin-bars`).
    var cards = false
    /// Tab bar as a segmented pill with a filled selection (`--skin-tabs-*`, `--skin-tab-on-*`).
    var pillTabs = false
    var tabBarFill: Color? = nil
    var tabBarBorder: Color? = nil
    var tabOnFill: Color? = nil
    var tabOnText: Color? = nil

    /// SKINS.Modernist in OBD Prototype.dc.html (oklch values converted to sRGB).
    static let simple = Palette(
        bg: Color(hex: 0x0A0B0D), surface: Color(hex: 0x121416), text: Color(hex: 0xF0F2F4), accent: Color(hex: 0xFCB442),
        divider: Color(hex: 0x1F2224),
        neutral200: Color(hex: 0x181B1E), neutral300: Color(hex: 0x212428), neutral500: Color(hex: 0x51565B), neutral600: Color(hex: 0x65696F),
        neutral700: Color(hex: 0x82878C), neutral800: Color(hex: 0xB9BEC4), neutral900: Color(hex: 0x000000),
        accent100: Color(hex: 0x372100), accent200: Color(hex: 0x4F3000), accent600: Color(hex: 0xFFC76C), accent700: Color(hex: 0xFCB442),
        accent800: Color(hex: 0xFFEBD2), headerRule: [.clear], separator: .clear,
        ctaText: Color(hex: 0x171008),
        headingFont: "BarlowSemiCondensed-ExtraBold", headingBoldFont: "BarlowSemiCondensed-ExtraBold",
        headingSemiFont: "BarlowSemiCondensed-SemiBold", bodyFont: "Barlow-Regular", bodyMediumFont: "Barlow-Medium",
        monoFont: "JetBrainsMono-Regular", monoMediumFont: "JetBrainsMono-Medium",
        cornerRadius: 16, buttonRadius: 14, pills: true, sheetRadius: 28, cards: true, pillTabs: true,
        tabBarFill: Color(hex: 0x181B1E), tabBarBorder: Color(hex: 0x26292D), tabOnFill: Color(hex: 0xF0F2F4), tabOnText: Color(hex: 0x101214))

    /// SKINS['Type R'] in OBD Prototype.dc.html
    static let racing = Palette(
        bg: Color(hex: 0x0D0D0F), surface: Color(hex: 0x18181C), text: Color(hex: 0xF5F5F6), accent: Color(hex: 0xE8001F),
        divider: Color(hex: 0x38383F),
        neutral200: Color(hex: 0x24242A), neutral300: Color(hex: 0x33333A), neutral500: Color(hex: 0x6C6C75), neutral600: Color(hex: 0x8B8B94),
        neutral700: Color(hex: 0xA9A9B1), neutral800: Color(hex: 0xD2D2D7), neutral900: Color(hex: 0x000000),
        accent100: Color(hex: 0x3B0910), accent200: Color(hex: 0x5E0E19), accent600: Color(hex: 0xFF2B44), accent700: Color(hex: 0xFF5468),
        accent800: Color(hex: 0xFFB8C1), headerRule: [Color(hex: 0xE8001F)],
        headingFont: "SairaCondensed-ExtraBold", headingBoldFont: "SairaCondensed-Bold", headingSemiFont: "SairaCondensed-Bold",
        bodyFont: "Saira-Regular", bodyMediumFont: "Saira-Regular", texture: .carbon)

    /// SKINS.Power in OBD Prototype.dc.html
    static let power = Palette(
        bg: Color(hex: 0x06080F), surface: Color(hex: 0x0E1220), text: Color(hex: 0xF2F5FA), accent: Color(hex: 0xE22718),
        divider: Color(hex: 0x232A3D),
        neutral200: Color(hex: 0x161B2A), neutral300: Color(hex: 0x232A3D), neutral500: Color(hex: 0x5A6480), neutral600: Color(hex: 0x7F89A4),
        neutral700: Color(hex: 0xA3ACC2), neutral800: Color(hex: 0xD0D6E4), neutral900: Color(hex: 0x000000),
        accent100: Color(hex: 0x141A3F), accent200: Color(hex: 0x1F2C6B), accent600: Color(hex: 0xFF3D2B), accent700: Color(hex: 0x5CB4FF),
        accent800: Color(hex: 0xCFE5FF),
        headerRule: [Color(hex: 0x4FB3FF), Color(hex: 0x0066B1), Color(hex: 0x3B2D8F), Color(hex: 0xE22718)],
        cta: Color(hex: 0x0066B1), ctaPressed: Color(hex: 0x0F4D92), ctaText: .white,
        headingFont: "SairaCondensed-ExtraBold", headingBoldFont: "SairaCondensed-Bold", headingSemiFont: "SairaCondensed-Bold",
        bodyFont: "Saira-Regular", bodyMediumFont: "Saira-Regular", texture: .power)

    /// SKINS.Retro in OBD Prototype.dc.html
    static let retro = Palette(
        bg: Color(hex: 0x050505), surface: Color(hex: 0x0E0E0E), text: Color(hex: 0xF3E9E4), accent: Color(hex: 0xFF2414),
        divider: Color(hex: 0x2A1210),
        neutral200: Color(hex: 0x161616), neutral300: Color(hex: 0x242424), neutral500: Color(hex: 0x5C5C5C), neutral600: Color(hex: 0x7D7672),
        neutral700: Color(hex: 0xA39A95), neutral800: Color(hex: 0xD4CBC6), neutral900: Color(hex: 0x000000),
        accent100: Color(hex: 0x2A0705), accent200: Color(hex: 0x4A0C08), accent600: Color(hex: 0xFF4A3A), accent700: Color(hex: 0xFF5A48),
        accent800: Color(hex: 0xFFB3A8), headerRule: [Color(hex: 0xFF2414)], headerRuleFades: true,
        cta: Color(hex: 0xFF2414), ctaPressed: Color(hex: 0xC81A0E), ctaText: Color(hex: 0x050505),
        readout: Color(hex: 0xFF3B2A), warn: Color(hex: 0xFFB000), glow: Color(hex: 0xFF2414),
        headingFont: "ShareTechMono-Regular", headingBoldFont: "ShareTechMono-Regular", headingSemiFont: "ShareTechMono-Regular",
        bodyFont: "ShareTechMono-Regular", bodyMediumFont: "ShareTechMono-Regular", texture: .scanlines)
}

/// Design tokens of the active skin. RootView sets `skin` and rebuilds the view tree when it changes,
/// so views read these directly.
enum DS {
    private(set) static var skin: Skin = .simple
    static var p: Palette { skin.palette }

    static func use(_ skin: Skin) { self.skin = skin }

    static var bg: Color { p.bg }
    static var surface: Color { p.surface }
    static var text: Color { p.text }
    static var accent: Color { p.accent }
    static var divider: Color { p.divider }
    static var separator: Color { p.separator ?? p.divider }

    static var neutral200: Color { p.neutral200 }
    static var neutral300: Color { p.neutral300 }
    static var neutral500: Color { p.neutral500 }
    static var neutral600: Color { p.neutral600 }
    static var neutral700: Color { p.neutral700 }
    static var neutral800: Color { p.neutral800 }
    static var neutral900: Color { p.neutral900 }

    static var accent100: Color { p.accent100 }
    static var accent200: Color { p.accent200 }
    static var accent600: Color { p.accent600 }
    static var accent700: Color { p.accent700 }
    static var accent800: Color { p.accent800 }

    static var cta: Color { p.cta ?? p.accent }
    static var ctaPressed: Color { p.ctaPressed ?? p.accent700 }
    static var ctaText: Color { p.ctaText ?? p.bg }
    static var readout: Color { p.readout ?? p.text }
    static var warn: Color { p.warn ?? p.accent }

    /// The header rule: one colour, the Power skin's left-to-right gradient (stops at 0, 30, 58, 88 %),
    /// or Retro's red line faded out over the outer 18 % at each end.
    static var headerRule: AnyShapeStyle {
        let c = p.headerRule
        if p.headerRuleFades, let red = c.first {
            return AnyShapeStyle(LinearGradient(stops: [
                .init(color: red.opacity(0), location: 0), .init(color: red, location: 0.18),
                .init(color: red, location: 0.82), .init(color: red.opacity(0), location: 1),
            ], startPoint: .leading, endPoint: .trailing))
        }
        if c.count == 4 {
            return AnyShapeStyle(LinearGradient(stops: [
                .init(color: c[0], location: 0), .init(color: c[1], location: 0.3),
                .init(color: c[2], location: 0.58), .init(color: c[3], location: 0.88),
            ], startPoint: .leading, endPoint: .trailing))
        }
        return AnyShapeStyle(c.first ?? p.divider)
    }

    /// Headings, numbers and button labels (Barlow Semi Condensed / Saira Condensed ExtraBold).
    static func heading(_ size: CGFloat) -> Font { .custom(p.headingFont, fixedSize: size) }
    /// The 700 weight the Racing and Power gauges use for their scale, speed and rpm figures.
    static func headingBold(_ size: CGFloat) -> Font { .custom(p.headingBoldFont, fixedSize: size) }
    /// The 600 weight of the Ring gauge figures and the pill tab bar.
    static func headingSemi(_ size: CGFloat) -> Font { .custom(p.headingSemiFont, fixedSize: size) }
    static func body(_ size: CGFloat) -> Font { .custom(p.bodyFont, fixedSize: size) }
    static func bodyMedium(_ size: CGFloat) -> Font { .custom(p.bodyMediumFont, fixedSize: size) }
    /// `--skin-mono`: JetBrains Mono on Simple, the body font elsewhere.
    static func label(_ size: CGFloat, medium: Bool = false) -> Font {
        let name = medium ? (p.monoMediumFont ?? p.bodyMediumFont) : (p.monoFont ?? p.bodyFont)
        return .custom(name, fixedSize: size)
    }
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight, design: .monospaced) }
}

/// Rounded rectangle with a radius of 0 drawn as a plain rectangle, so square skins stay crisp.
func skinShape(_ radius: CGFloat) -> RoundedRectangle { RoundedRectangle(cornerRadius: radius, style: .continuous) }

/// The Power skin's ground: a blue glow from above the top edge
/// (`radial-gradient(140% 45% at 50% -8%, rgba(0,102,177,.24), transparent 62%)`)
/// over 1px vertical hairlines every 3px in 1.8% white.
struct PowerTexture: View {
    var body: some View {
        Canvas { ctx, size in
            var lines = Path()
            var x: CGFloat = 0
            while x < size.width {
                lines.addRect(CGRect(x: x, y: 0, width: 1, height: size.height))
                x += 3
            }
            ctx.fill(lines, with: .color(.white.opacity(0.018)))
            var glow = ctx
            let rx = size.width * 1.4, ry = size.height * 0.45
            glow.translateBy(x: size.width / 2, y: -size.height * 0.08)
            glow.scaleBy(x: 1, y: ry / rx)
            glow.fill(Path(ellipseIn: CGRect(x: -rx, y: -rx, width: rx * 2, height: rx * 2)),
                      with: .radialGradient(Gradient(colors: [Color(hex: 0x0066B1).opacity(0.24), Color(hex: 0x0066B1).opacity(0)]),
                                            center: .zero, startRadius: 0, endRadius: rx * 0.62))
        }
        .allowsHitTesting(false)
    }
}

/// The Retro skin's CRT scanlines: a 1px horizontal line every 3px in 2.8% white.
struct ScanlineTexture: View {
    var body: some View {
        Canvas { ctx, size in
            var lines = Path()
            var y: CGFloat = 0
            while y < size.height {
                lines.addRect(CGRect(x: 0, y: y, width: size.width, height: 1))
                y += 3
            }
            ctx.fill(lines, with: .color(.white.opacity(0.028)))
        }
        .allowsHitTesting(false)
    }
}

/// The Racing skin's carbon weave: 2px stripes at ±45°, every 4px, in 2.5% white.
struct CarbonTexture: View {
    var body: some View {
        Canvas { ctx, size in
            let span = size.width + size.height
            for angle in [45.0, -45.0] {
                var c = ctx
                c.translateBy(x: size.width / 2, y: size.height / 2)
                c.rotate(by: .degrees(angle))
                var x = -span
                var stripes = Path()
                while x < span {
                    stripes.addRect(CGRect(x: x, y: -span, width: 2, height: span * 2))
                    x += 4
                }
                c.fill(stripes, with: .color(.white.opacity(0.025)))
            }
        }
        .allowsHitTesting(false)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

/// Small uppercase label used above values (10px, 0.08em tracking).
struct Kicker: View {
    let text: String
    var color: Color = DS.neutral700
    var size: CGFloat = 10
    var tracking: CGFloat = 0.08

    var body: some View {
        Text(text.uppercased())
            .font(DS.body(size))
            .tracking(size * tracking)
            .foregroundStyle(color)
            .lineLimit(1)
    }
}

/// Full-width rule: 2px between major sections, 1px between rows.
struct Rule: View {
    var weight: CGFloat = 2
    var color: Color = DS.divider
    var body: some View { color.frame(height: weight) }
}

/// Flat, flush-left button with the design system's pressed tint.
struct FlatButtonStyle: ButtonStyle {
    var background: Color = .clear
    var pressed: Color = DS.text.opacity(0.1)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(configuration.isPressed ? pressed : background)
            .contentShape(Rectangle())
    }
}

/// Solid accent action ("Scan for loggers", "Clear codes").
struct PrimaryButtonStyle: ButtonStyle {
    var minHeight: CGFloat = 52
    var fontSize: CGFloat = 16
    var radius: CGFloat = DS.p.buttonRadius
    /// The skin's call-to-action colours (`--skin-cta`, connect screen) or the plain accent (Clear codes sheet).
    var cta = true

    func makeBody(configuration: Configuration) -> some View {
        let fill = cta ? (configuration.isPressed ? DS.ctaPressed : DS.cta) : (configuration.isPressed ? DS.accent700 : DS.accent)
        return configuration.label
            .font(DS.heading(fontSize))
            .foregroundStyle(cta ? DS.ctaText : DS.bg)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .background(fill, in: skinShape(radius))
            .contentShape(skinShape(radius))
    }
}

/// Outlined action ("Use demo data", "Cancel").
struct SecondaryButtonStyle: ButtonStyle {
    var minHeight: CGFloat = 48
    var fontSize: CGFloat = 15
    var radius: CGFloat = DS.p.buttonRadius

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.heading(fontSize))
            .foregroundStyle(DS.text)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .background(configuration.isPressed ? DS.text.opacity(0.14) : .clear, in: skinShape(radius))
            .overlay(skinShape(radius).strokeBorder(DS.divider, lineWidth: 1))
            .contentShape(skinShape(radius))
    }
}

/// Small tinted status tag (11px, 3/10 padding).
struct Tag: View {
    let text: String
    let background: Color
    let foreground: Color
    var body: some View {
        Text(text)
            .font(DS.body(11))
            .tracking(0.44)
            .padding(.vertical, 3)
            .padding(.horizontal, 10)
            .background(background)
            .foregroundStyle(foreground)
    }
}

extension View {
    /// `--skin-glow`: on Retro, readouts glow like a lit display (`0 0 6px` at 75 % and `0 0 14px` at 35 %).
    @ViewBuilder func skinGlow() -> some View {
        if let glow = DS.p.glow {
            shadow(color: glow.opacity(0.75), radius: 3).shadow(color: glow.opacity(0.35), radius: 7)
        } else {
            self
        }
    }
}
