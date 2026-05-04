import SwiftUI

// V5 "Warm Hybrid" palette + helpers. Mirrors the OKLCH-driven design system
// from design_handoff_v5_hybrid.

extension Color {
    // Surfaces
    static let warmCanvas       = Color(hex: 0xFBF7F1)
    static let warmCard         = Color.white
    static let warmSubtleFill   = Color(brown: 0.05)

    // Text
    static let warmTextPrimary  = Color(hex: 0x26201A)
    static let warmTextSecondary = Color(hex: 0x5B4F3F)
    static let warmTextTertiary = Color(hex: 0x7A6D5C)
    static let warmTextMuted    = Color(hex: 0x8B7E6E)
    static let warmTextFaint    = Color(hex: 0xA89B86)

    // Lines
    static let warmHairline     = Color(brown: 0.06)
    static let warmDivider      = Color(brown: 0.08)
    static let warmBorder       = Color(brown: 0.12)
    static let warmDotSeparator = Color(hex: 0xC5B9A7)

    // Brand
    static let terracotta       = Color.oklch(0.55, 0.13, 22)
    static let terracottaDeep   = Color.oklch(0.32, 0.13, 22)
    static let terracottaSoft   = Color.oklch(0.92, 0.07, 22)

    // Status: registered / open
    static let registeredGreen  = Color.oklch(0.55, 0.15, 145)
    static let registeredBg     = Color.oklch(0.94, 0.07, 145)
    static let registeredText   = Color.oklch(0.40, 0.15, 145)

    // Status: opens soon (gold)
    static let opensSoonBg      = Color.oklch(0.95, 0.06, 60)
    static let opensSoonText    = Color.oklch(0.45, 0.13, 60)

    // Series badge (lavender)
    static let seriesBg         = Color.oklch(0.95, 0.04, 280)
    static let seriesText       = Color.oklch(0.40, 0.13, 280)

    // One-time badge (teal)
    static let oneTimeBg        = Color.oklch(0.95, 0.06, 200)
    static let oneTimeText     = Color.oklch(0.40, 0.13, 200)

    // Conflict / warning (amber). Used by Calendar conflict ring + Resolve sheet
    // and by Why-this transparency.
    static let amberWarn        = Color.oklch(0.62, 0.14, 70)
    static let amberWarnSoft    = Color.oklch(0.96, 0.05, 70)
    static let amberWarnInk     = Color.oklch(0.42, 0.14, 70)

    // Partner (linked co-parent). Cool blue keeps the partner visually distinct
    // from the user's terracotta. Used by Share / Linked Settings + Calendar
    // parent chips + Detail "+ Add Sam" row.
    static let partnerBlue      = Color.oklch(0.55, 0.14, 250)
    static let partnerBlueSoft  = Color.oklch(0.94, 0.05, 250)
    static let partnerBlueInk   = Color.oklch(0.40, 0.14, 250)

    // Destructive (Disconnect partner, Cancel one).
    static let dangerRed        = Color.oklch(0.50, 0.18, 25)
    static let dangerRedSoft    = Color.oklch(0.95, 0.05, 25)
}

// Dot-shorthand support for custom colors in `foregroundStyle`, `tint`,
// `fill`, etc. (SwiftUI's ShapeStyle resolution doesn't pick up plain
// `Color` extensions — they need to be exposed on `ShapeStyle where Self == Color`.)
extension ShapeStyle where Self == Color {
    static var warmCanvas: Color        { .warmCanvas }
    static var warmCard: Color          { .warmCard }
    static var warmTextPrimary: Color   { .warmTextPrimary }
    static var warmTextSecondary: Color { .warmTextSecondary }
    static var warmTextTertiary: Color  { .warmTextTertiary }
    static var warmTextMuted: Color     { .warmTextMuted }
    static var warmTextFaint: Color     { .warmTextFaint }
    static var warmHairline: Color      { .warmHairline }
    static var warmDivider: Color       { .warmDivider }
    static var warmBorder: Color        { .warmBorder }
    static var warmDotSeparator: Color  { .warmDotSeparator }
    static var terracotta: Color        { .terracotta }
    static var terracottaDeep: Color    { .terracottaDeep }
    static var terracottaSoft: Color    { .terracottaSoft }
    static var registeredGreen: Color   { .registeredGreen }
    static var registeredBg: Color      { .registeredBg }
    static var registeredText: Color    { .registeredText }
    static var opensSoonBg: Color       { .opensSoonBg }
    static var opensSoonText: Color     { .opensSoonText }
    static var seriesBg: Color          { .seriesBg }
    static var seriesText: Color        { .seriesText }
    static var oneTimeBg: Color         { .oneTimeBg }
    static var oneTimeText: Color       { .oneTimeText }
    static var amberWarn: Color         { .amberWarn }
    static var amberWarnSoft: Color     { .amberWarnSoft }
    static var amberWarnInk: Color      { .amberWarnInk }
    static var partnerBlue: Color       { .partnerBlue }
    static var partnerBlueSoft: Color   { .partnerBlueSoft }
    static var partnerBlueInk: Color    { .partnerBlueInk }
    static var dangerRed: Color         { .dangerRed }
    static var dangerRedSoft: Color     { .dangerRedSoft }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xff) / 255
        let g = Double((hex >> 8)  & 0xff) / 255
        let b = Double( hex        & 0xff) / 255
        self = Color(red: r, green: g, blue: b)
    }

    /// Translucent warm-brown — matches the rgba(60,40,20,α) pattern used
    /// for hairlines, dividers, and pressed states throughout the prototype.
    init(brown opacity: Double) {
        self = Color(red: 60/255, green: 40/255, blue: 20/255).opacity(opacity)
    }

    /// OKLCH → sRGB for design tokens. Implements the CSS Color 4 OKLab
    /// conversion (https://bottosson.github.io/posts/oklab/).
    static func oklch(_ l: Double, _ c: Double, _ h: Double) -> Color {
        let hRad = h * .pi / 180
        let a = c * cos(hRad)
        let b = c * sin(hRad)

        let lp = l + 0.3963377774 * a + 0.2158037573 * b
        let mp = l - 0.1055613458 * a - 0.0638541728 * b
        let sp = l - 0.0894841775 * a - 1.2914855480 * b
        let lc = lp * lp * lp
        let mc = mp * mp * mp
        let sc = sp * sp * sp

        let lr =  4.0767416621 * lc - 3.3077115913 * mc + 0.2309699292 * sc
        let lg = -1.2684380046 * lc + 2.6097574011 * mc - 0.3413193965 * sc
        let lb = -0.0041960863 * lc - 0.7034186147 * mc + 1.7076147010 * sc

        return Color(red: gammaEncode(lr), green: gammaEncode(lg), blue: gammaEncode(lb))
    }
}

private func gammaEncode(_ v: Double) -> Double {
    let clamped = max(0, min(1, v))
    return clamped <= 0.0031308
        ? 12.92 * clamped
        : 1.055 * pow(clamped, 1/2.4) - 0.055
}

// MARK: - Category styling

struct CategoryStyle {
    let hue: Double
    var swatchBG: Color  { .oklch(0.88, 0.07, hue) }
    var swatchFG: Color  { .oklch(0.32, 0.13, hue) }
    var chipBG:  Color   { .oklch(0.92, 0.07, hue) }
    var chipFG:  Color   { .oklch(0.32, 0.13, hue) }
    var dot:     Color   { .oklch(0.55, 0.15, hue) }
    var border:  Color   { .oklch(0.60, 0.13, hue) }
}

extension ActivityCategory {
    var style: CategoryStyle { CategoryStyle(hue: hue) }
}

// MARK: - Kid styling

extension Kid {
    var avatarColor: Color { .oklch(0.60, 0.14, hue) }
    var pillBG: Color      { .oklch(0.95, 0.06, hue) }
    var pillBorder: Color  { .oklch(0.60, 0.14, hue) }
    var pillFG: Color      { .oklch(0.32, 0.13, hue) }
    var deepText: Color    { .oklch(0.40, 0.14, hue) }

    var avatarColor3pxAccent: Color { .oklch(0.60, 0.15, hue) }
}

// MARK: - Venue type letter (corner mark on category swatch)

extension VenueType {
    var letter: String {
        switch self {
        case .parkDistrict:    return "P"
        case .library:         return "L"
        case .museum:          return "M"
        case .communityCenter: return "C"
        }
    }
}

// MARK: - Card surface modifier

struct WarmCardModifier: ViewModifier {
    var radius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background(Color.warmCard, in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Color(brown: 0.05), lineWidth: 0.5)
            )
            .shadow(color: Color(brown: 0.03), radius: 1, y: 1)
    }
}

extension View {
    /// White card with warm hairline outline and a feather-light shadow.
    func warmCard(radius: CGFloat = 12) -> some View {
        modifier(WarmCardModifier(radius: radius))
    }
}

// MARK: - Typography

extension Font {
    static let v5Display     = Font.system(size: 28, weight: .bold).leading(.tight)
    static let v5Eyebrow     = Font.system(size: 11, weight: .semibold)
    static let v5Headline    = Font.system(size: 14, weight: .semibold)
    static let v5Body        = Font.system(size: 13, weight: .regular)
    static let v5Meta        = Font.system(size: 11, weight: .regular)
    static let v5MetaBold    = Font.system(size: 11, weight: .semibold)
    static let v5Caption     = Font.system(size: 10, weight: .bold)
    static let v5Tabular     = Font.system(size: 13, weight: .bold).monospacedDigit()
}
