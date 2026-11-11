import SwiftUI

struct LiveView: View {
    @EnvironmentObject var model: AppModel
    @AppStorage(SettingsKey.rpmStyle) private var rpmStyle = "Ring"
    @AppStorage(SettingsKey.units) private var unitsRaw = "Metric"

    private var fmt: ReadingFormat { ReadingFormat(units: UnitSystem(rawValue: unitsRaw) ?? .metric) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !model.codes.isEmpty { milBanner }
            switch DS.skin {
            case .racing: racingGauge
            case .power: powerGauge
            case .retro: retroGauge
            case .simple:
                switch rpmStyle {
                case "Bar": rpmBar
                case "Dial": rpmDial
                default: rpmRing
                }
            }
            Rule(color: DS.separator)
            if DS.p.cards { cards } else { cells }
            Text("Tap a reading to graph it.")
                .font(DS.body(12))
                .foregroundStyle(DS.neutral700)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }

    private var rpm: Double? { model.readings[.rpm] }
    private var rpmText: String { fmt.value(.rpm, rpm) }
    private var rpmColor: Color { (rpm ?? 0) > 6000 ? DS.accent : DS.text }
    private var peakText: String { fmt.value(.rpm, model.extremes[.rpm]?.hi ?? rpm) }

    private func graph(_ key: ChannelKey) {
        model.graphKey = key
        model.select(.graph)
    }

    private var gearText: String { model.readings.gear > 0 ? String(model.readings.gear) : "N" }

    private var milBanner: some View {
        let shape = skinShape(DS.p.cornerRadius)
        return Button { model.select(.codes) } label: {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    HStack(spacing: 10) {
                        skinShape(DS.p.pills ? 4 : 0).fill(DS.accent).frame(width: 8, height: 8)
                        Text("Check engine · \(model.codes.count) code\(model.codes.count > 1 ? "s" : "")")
                            .font(DS.body(14))
                    }
                    Spacer()
                    Text("View →").font(DS.heading(14))
                }
                .foregroundStyle(DS.accent800)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                Rule(color: DS.separator)
            }
        }
        .buttonStyle(FlatButtonStyle(background: DS.accent100, pressed: DS.accent200))
        .clipShape(shape)
        // Simple: an inset rounded card (`--skin-mil-m: 12px 16px 0`)
        .padding(.horizontal, DS.p.cornerRadius > 0 ? 16 : 0)
        .padding(.top, DS.p.cornerRadius > 0 ? 12 : 0)
    }

    // Racing skin: Type R rev bar with the gear in the middle (replaces dial / bar).
    private var racingGauge: some View {
        Button { graph(.rpm) } label: {
            TypeRGauge(rpm: rpm ?? 0, rpmText: rpmText, peakText: peakText,
                       gear: gearText,
                       speedText: fmt.value(.speed, model.readings[.speed]), speedUnit: fmt.unit(.speed),
                       rpmColor: rpmColor)
        }
        .buttonStyle(FlatButtonStyle(pressed: DS.text.opacity(0.04)))
    }

    // Power skin: twin speed / rpm gauges with the gear in the right one.
    private var powerGauge: some View {
        Button { graph(.rpm) } label: {
            PowerGauge(rpm: rpm ?? 0, rpmText: rpmText, peakText: peakText, gear: gearText,
                       speed: fmt.convert(.speed, model.readings[.speed] ?? 0),
                       speedText: fmt.value(.speed, model.readings[.speed]), speedUnit: fmt.unit(.speed),
                       imperial: fmt.units == .imperial, rpmColor: rpmColor)
        }
        .buttonStyle(FlatButtonStyle(pressed: DS.text.opacity(0.04)))
    }

    // Retro skin: 80s digital dash with seven-segment speed / gear / rpm, a rev bar, two needle
    // gauges and warning lamps.
    private var retroGauge: some View {
        Button { graph(.rpm) } label: {
            RetroGauge(rpm: rpm, speed: model.readings[.speed].map { fmt.convert(.speed, $0) },
                       speedText: fmt.value(.speed, model.readings[.speed]), speedUnit: fmt.unit(.speed),
                       gear: model.readings.gear, rpmText: rpmText,
                       coolant: model.readings[.coolant],
                       coolantText: model.readings[.coolant] == nil ? "—" : fmt.value(.coolant, model.readings[.coolant]) + fmt.unit(.coolant),
                       volt: model.readings[.volt], milOn: !model.codes.isEmpty)
        }
        .buttonStyle(FlatButtonStyle(pressed: DS.text.opacity(0.04)))
    }

    // Simple skin default: speed in a 270° rpm ring on a rounded card, gear and peak rpm below.
    private var ringColor: Color { (rpm ?? 0) > 6000 ? Color(hex: 0xFF645F) : DS.accent }

    private var rpmRing: some View {
        Button { graph(.rpm) } label: {
            ZStack {
                RpmRing(fraction: min(max((rpm ?? 0) / 7000, 0), 1), color: ringColor)
                    .frame(width: 280, height: 280)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 10)
                VStack(spacing: 0) {
                    Text(fmt.unit(.speed).uppercased())
                        .font(DS.label(12, medium: true))
                        .tracking(0.96)
                        .foregroundStyle(DS.neutral700)
                    Text(fmt.value(.speed, model.readings[.speed]))
                        .font(DS.headingSemi(104))
                        .tracking(-3.12)
                        .monospacedDigit()
                        .frame(height: 99)
                    Text("\(rpmText) rpm")
                        .font(DS.label(15, medium: true))
                        .monospacedDigit()
                        .foregroundStyle(ringColor)
                }
                .offset(y: -6)
                HStack(alignment: .bottom) {
                    ringStat("Gear", gearText, alignment: .leading)
                    Spacer()
                    ringStat("Peak rpm", peakText, alignment: .trailing)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .contentShape(skinShape(20))
        }
        .buttonStyle(CardButtonStyle(radius: 20, background: DS.surface, pressed: DS.neutral200))
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .accessibilityElement(children: .combine)
    }

    private func ringStat(_ label: String, _ value: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(label.uppercased()).font(DS.label(11)).foregroundStyle(DS.neutral700)
            Text(value).font(DS.headingSemi(28)).monospacedDigit()
        }
    }

    // 2a: analog tachometer centred, the number under it, Peak and Gear below.
    private var rpmDial: some View {
        Button { graph(.rpm) } label: {
            VStack(spacing: 0) {
                VStack(spacing: 2) {
                    Tachometer(fraction: min(max((rpm ?? 0) / 7000, 0), 1))
                        .frame(width: 196, height: 196)
                    VStack(spacing: 2) {
                        Kicker(text: "Engine speed · 0x10C")
                        Text(rpmText)
                            .font(DS.heading(44))
                            .tracking(-1.32)
                            .monospacedDigit()
                            .foregroundStyle(rpmColor)
                        Text("rpm").font(DS.body(12)).foregroundStyle(DS.neutral700)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 12)
                Rule(weight: 1)
                HStack(spacing: 0) {
                    stat("Peak", peakText).padding(.leading, 16)
                    DS.divider.frame(width: 1)
                    stat("Gear", gearText).padding(.leading, 14)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .buttonStyle(FlatButtonStyle(pressed: DS.text.opacity(0.04)))
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Kicker(text: label)
            Text(value).font(DS.heading(18)).monospacedDigit()
        }
        .padding(.vertical, 10)
        .padding(.trailing, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // 1a: big number over a 35-segment bar.
    private var rpmBar: some View {
        Button { graph(.rpm) } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Kicker(text: "Engine speed · 0x10C", size: 11)
                    Spacer()
                    Kicker(text: "Peak \(peakText)", size: 11)
                }
                Text(rpmText)
                    .font(DS.heading(88))
                    .tracking(-3.52)
                    .monospacedDigit()
                    .foregroundStyle(rpmColor)
                    .frame(height: 80, alignment: .leading)
                SegmentBar(fraction: min(max((rpm ?? 0) / 7000, 0), 1))
                    .frame(height: 22)
                HStack(spacing: 0) {
                    ForEach(0..<8) { i in
                        Text("\(i)")
                        if i < 7 { Spacer(minLength: 0) }
                    }
                }
                .font(DS.body(10))
                .foregroundStyle(DS.neutral600)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 16)
        }
        .buttonStyle(FlatButtonStyle(pressed: DS.text.opacity(0.04)))
    }

    private var cells: some View {
        VStack(spacing: 0) {
            ForEach(0..<Channel.cells.count / 2, id: \.self) { row in
                HStack(spacing: 0) {
                    cell(Channel.cells[row * 2])
                    DS.divider.frame(width: 2)
                    cell(Channel.cells[row * 2 + 1])
                }
                .fixedSize(horizontal: false, vertical: true)
                Rule(weight: 1)
            }
        }
    }

    // Simple: each reading on its own rounded card with a range bar, 10pt apart.
    private var cards: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(Channel.cells, id: \.self) { card($0) }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func card(_ key: ChannelKey) -> some View {
        let raw = model.readings[key]
        let color = fmt.isWarning(key, raw) ? DS.accent : DS.text
        let c = key.info
        let fraction = raw.map { min(max(($0 - c.min) / (c.max - c.min), 0), 1) } ?? 0
        return Button { graph(key) } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(c.label.uppercased()).foregroundStyle(DS.neutral700)
                    Spacer(minLength: 4)
                    Text(c.pidLabel.uppercased()).foregroundStyle(DS.neutral500)
                }
                .font(DS.label(10))
                .tracking(0.8)
                .lineLimit(1)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(fmt.value(key, raw))
                        .font(DS.heading(30))
                        .tracking(-0.6)
                        .monospacedDigit()
                        .foregroundStyle(color)
                    Text(fmt.unit(key)).font(DS.body(13)).foregroundStyle(DS.neutral700)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(DS.neutral300)
                        Capsule().fill(color).frame(width: geo.size.width * fraction)
                    }
                }
                .frame(height: 4)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .contentShape(skinShape(DS.p.cornerRadius))
        }
        .buttonStyle(CardButtonStyle(radius: DS.p.cornerRadius, background: DS.surface, pressed: DS.text.opacity(0.1)))
    }

    private func cell(_ key: ChannelKey) -> some View {
        let raw = model.readings[key]
        return Button { graph(key) } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Kicker(text: key.info.label)
                    Spacer(minLength: 4)
                    Kicker(text: key.info.pidLabel, color: DS.neutral500)
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(fmt.value(key, raw))
                        .font(DS.heading(30))
                        .tracking(-0.6)
                        .monospacedDigit()
                        .foregroundStyle(fmt.isWarning(key, raw) ? DS.warn : DS.readout)
                        .skinGlow()
                    Text(fmt.unit(key)).font(DS.body(13)).foregroundStyle(DS.neutral700)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .buttonStyle(FlatButtonStyle(pressed: DS.text.opacity(0.1)))
    }
}

/// The 2a dial, drawn in the design's 240-unit viewBox: 270° sweep, redline from 6000 rpm.
struct Tachometer: View {
    let fraction: Double

    static func point(_ f: Double, _ r: Double) -> CGPoint {
        let a = (225 - 270 * f) * .pi / 180
        return CGPoint(x: 120 + r * cos(a), y: 120 - r * sin(a))
    }

    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width / 240
            ZStack(alignment: .topLeading) {
                Canvas { ctx, _ in
                    ctx.scaleBy(x: s, y: s)
                    func arc(from f0: Double, to f1: Double) -> Path {
                        var p = Path()
                        p.addArc(center: CGPoint(x: 120, y: 120), radius: 100,
                                 startAngle: .degrees(-(225 - 270 * f0)), endAngle: .degrees(-(225 - 270 * f1)), clockwise: false)
                        return p
                    }
                    ctx.stroke(arc(from: 0, to: 1), with: .color(DS.neutral300), lineWidth: 2)
                    ctx.stroke(arc(from: 6.0 / 7.0, to: 1), with: .color(DS.accent), lineWidth: 8)
                    for i in 0...28 {
                        let major = i % 4 == 0
                        var p = Path()
                        p.move(to: Tachometer.point(Double(i) / 28, 100))
                        p.addLine(to: Tachometer.point(Double(i) / 28, major ? 84 : 93))
                        ctx.stroke(p, with: .color(i >= 24 ? DS.accent : DS.text), lineWidth: major ? 3 : 1.5)
                    }
                    var needle = Path()
                    needle.move(to: CGPoint(x: 120, y: 120))
                    needle.addLine(to: Tachometer.point(fraction, 90))
                    ctx.stroke(needle, with: .color(DS.accent), lineWidth: 4)
                    ctx.fill(Path(CGRect(x: 111, y: 111, width: 18, height: 18)), with: .color(DS.text))
                }
                Text("×1000 RPM")
                    .font(DS.body(11 * s))
                    .tracking(1 * s)
                    .foregroundStyle(DS.neutral700)
                    .fixedSize()
                    .position(x: 120 * s, y: 174 * s)
                ForEach(0..<8) { i in
                    let p = Tachometer.point(Double(i) / 7, 70)
                    Text("\(i)")
                        .font(DS.heading(14))
                        .foregroundStyle(i >= 6 ? DS.accent700 : DS.text)
                        .position(x: p.x * s, y: p.y * s)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// The Ring gauge (`ringStyle` in OBD Prototype.dc.html), in its 280-unit viewBox: a 14pt track over
/// 270° from the lower left, the 6000–7000 rpm zone tinted red, and the value arc with round caps.
struct RpmRing: View {
    let fraction: Double
    let color: Color

    var body: some View {
        Canvas { ctx, size in
            let s = size.width / 280
            ctx.scaleBy(x: s, y: s)
            var arc = Path()
            arc.addArc(center: CGPoint(x: 140, y: 140), radius: 120, startAngle: .degrees(135), endAngle: .degrees(405), clockwise: false)
            let round = StrokeStyle(lineWidth: 14, lineCap: .round)
            ctx.stroke(arc, with: .color(DS.neutral300), style: round)
            ctx.stroke(arc.trimmedPath(from: 6.0 / 7.0, to: 1), with: .color(Color(hex: 0xF75D59).opacity(0.45)), lineWidth: 14)
            if fraction > 0 {
                ctx.stroke(arc.trimmedPath(from: 0, to: fraction), with: .color(color), style: round)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Rounded, filled button background with a pressed fill (Live cards and the Ring gauge).
struct CardButtonStyle: ButtonStyle {
    let radius: CGFloat
    let background: Color
    let pressed: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                ZStack {
                    skinShape(radius).fill(background)
                    skinShape(radius).fill(configuration.isPressed ? pressed : .clear)
                }
            }
    }
}

/// The 1a segmented bar: 35 segments, the last five are the redline.
struct SegmentBar: View {
    let fraction: Double

    var body: some View {
        let lit = Int((fraction * 35).rounded())
        HStack(spacing: 2) {
            ForEach(0..<35) { i in
                let red = i >= 30
                (i < lit ? (red ? DS.accent : DS.text) : (red ? DS.accent200 : DS.neutral300))
            }
        }
    }
}
