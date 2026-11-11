import SwiftUI

/// Header, the active tab's content and the bottom tab bar.
struct AppShellView: View {
    @EnvironmentObject var model: AppModel
    @AppStorage(SettingsKey.skin) private var skinRaw = Skin.simple.rawValue

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(DS.headerRule).frame(height: 2)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch model.tab {
                    case .live: LiveView()
                    case .graph: GraphView()
                    case .codes: CodesView()
                    case .can: CANView()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            tabBar
        }
        .overlay {
            if model.showClear { ClearCodesSheet() }
        }
    }

    private var title: String {
        switch model.tab {
        case .live: return "Live"
        case .graph: return "Graph"
        case .codes: return "Codes"
        case .can: return "CAN bus"
        }
    }

    private var linkLabel: String {
        if model.paused { return "Paused" }
        if model.source == .demo { return "Demo · 25 Hz" }
        if model.reconnecting { return "Reconnecting…" }
        if model.rateHz > 0 { return LiveDecode.rateLabel(model.rateHz) }
        return model.loggerAsleep ? "Standby" : "No ECU"
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Kicker(text: model.vehicleLabel, color: DS.accent700, tracking: 0.1)
                Kicker(text: model.vin.map { "VIN \($0)" } ?? "VIN not reported")
                    .monospacedDigit()
                    .textSelection(.enabled)
                Text(title)
                    .font(DS.heading(32))
                    .tracking(-0.48)
            }
            Spacer(minLength: 0)
            // skin switch, as in the design's header: Simple → Racing → Power → Retro
            Button { skinRaw = DS.skin.next.rawValue } label: {
                Text(DS.skin.rawValue)
                    .font(DS.body(11))
                    .foregroundStyle(DS.neutral800)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .overlay(chip.strokeBorder(DS.neutral300, lineWidth: 1))
            }
            .buttonStyle(TintButtonStyle(background: .clear, pressed: DS.neutral200, shape: chip))
            .accessibilityLabel("Skin: \(DS.skin.rawValue). Switch skin")
            .padding(.trailing, -6) // chips sit 6pt apart in the design
            Button(action: model.disconnect) {
                HStack(spacing: 6) {
                    skinShape(DS.p.pills ? 3 : 0)
                        .fill(model.paused || (model.source == .device && model.rateHz == 0) ? DS.neutral500 : DS.accent)
                        .frame(width: 6, height: 6)
                    Text(model.source == .demo ? linkLabel : "ONE+ · \(linkLabel)")
                        .font(DS.body(11))
                        .monospacedDigit()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .foregroundStyle(DS.neutral800)
            }
            .buttonStyle(TintButtonStyle(background: DS.neutral200, pressed: DS.neutral300, shape: chip))
            .accessibilityLabel("Disconnect")
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 12)
    }

    /// Header chips and tab bar pills: capsules on Simple, square elsewhere (`--skin-pill-r`).
    private var chip: RoundedRectangle { skinShape(DS.p.pills ? 999 : 0) }

    private var tabBar: some View {
        VStack(spacing: 0) {
            Rule(color: DS.separator)
            if DS.p.pillTabs {
                // Simple: a segmented pill, the selected tab filled in the text colour
                HStack(spacing: 4) {
                    ForEach(AppModel.Tab.allCases, id: \.self) { tab in tabButton(tab) }
                }
                .padding(5)
                .background(DS.p.tabBarFill ?? DS.neutral200, in: chip)
                .overlay(chip.strokeBorder(DS.p.tabBarBorder ?? DS.divider, lineWidth: 1))
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)
            } else {
                HStack(spacing: 0) {
                    ForEach(AppModel.Tab.allCases, id: \.self) { tab in tabButton(tab) }
                }
            }
        }
        .background(DS.bg.ignoresSafeArea(edges: .bottom))
    }

    private func tabButton(_ tab: AppModel.Tab) -> some View {
        let on = model.tab == tab
        let pill = DS.p.pillTabs
        return Button { model.select(tab) } label: {
            HStack(spacing: 6) {
                Text(tab == .can ? "CAN" : tab.rawValue.capitalized)
                    .font(pill ? DS.headingSemi(14) : DS.heading(14))
                if tab == .codes && !model.codes.isEmpty {
                    Text("\(model.codes.count)")
                        .font(DS.body(10))
                        .padding(.vertical, 1)
                        .padding(.horizontal, 5)
                        .background(DS.accent, in: chip)
                        .foregroundStyle(DS.ctaText)
                }
            }
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(on ? (DS.p.tabOnText ?? DS.accent) : DS.neutral700)
            // labels are flush left, so a short trailing inset leaves room for a two-digit badge
            .padding(.leading, pill ? 4 : 16)
            .padding(.trailing, 4)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: pill ? .center : .leading)
            .background(on ? (DS.p.tabOnFill ?? .clear) : .clear, in: chip)
            .overlay(alignment: .top) {
                (on && !pill ? DS.accent : Color.clear).frame(height: 3)
            }
            .contentShape(chip)
        }
        .buttonStyle(FlatButtonStyle(pressed: pill ? .clear : DS.text.opacity(0.05)))
    }
}

/// Filled chip button with a darker pressed fill.
struct TintButtonStyle: ButtonStyle {
    let background: Color
    let pressed: Color
    var shape = RoundedRectangle(cornerRadius: 0)
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.background(configuration.isPressed ? pressed : background, in: shape)
    }
}

/// "Clear all trouble codes?" bottom sheet.
struct ClearCodesSheet: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ZStack(alignment: .bottom) {
            DS.neutral900.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { model.showClear = false }
            VStack(alignment: .leading, spacing: 12) {
                Text("Clear all trouble codes?")
                    .font(DS.heading(22))
                Text("This sends Mode 04: the check-engine light goes off and freeze-frame data and readiness monitors are reset. A code returns if the fault is still present. Inspections can fail a car with incomplete monitors.")
                    .font(DS.body(14))
                    .lineSpacing(5)
                    .foregroundStyle(DS.neutral800)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 8) {
                    Button("Clear codes", action: model.clearCodes)
                        .buttonStyle(PrimaryButtonStyle(minHeight: 50, fontSize: 15, cta: false))
                    Button("Cancel") { model.showClear = false }
                        .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TopRoundedRectangle(radius: DS.p.sheetRadius).fill(DS.surface).ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) {
                // `border-top: 2px solid` following the rounded corners
                TopEdge(radius: DS.p.sheetRadius).stroke(DS.text, lineWidth: 2).padding(.top, 1)
            }
            .shadow(color: DS.neutral900.opacity(0.22), radius: 16, y: 12)
        }
        .transition(.opacity)
    }
}

/// Rectangle with only its top corners rounded (iOS 16 has no UnevenRoundedRectangle).
struct TopRoundedRectangle: Shape {
    var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        let r = min(radius, rect.width / 2, rect.height)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r, startAngle: .degrees(270), endAngle: .degrees(360), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// The top edge of a TopRoundedRectangle, for its border.
struct TopEdge: Shape {
    var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        let r = min(radius, rect.width / 2)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + r))
        if r > 0 {
            p.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        if r > 0 {
            p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r, startAngle: .degrees(270), endAngle: .degrees(360), clockwise: false)
        }
        return p
    }
}
