import SwiftUI

/// Co-parent JOIN side. Three word inputs (two text words + a 2-digit suffix).
/// Once all three are filled and the shape validates, the link preview
/// appears; the CTA changes to a partner-blue "Confirm — link with Sam".
///
/// Local-only — confirming creates a `LinkedParent` named "Sam" with the
/// partner-blue hue. Production would resolve the code against the other
/// device.
///
/// Mirrors `v5-share.jsx::V5EnterCode`.
struct EnterCodeView: View {
    @Environment(ActivityStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var word1: String = ""
    @State private var word2: String = ""
    @State private var num: String = ""
    @State private var partnerName: String = "Sam"
    @FocusState private var focused: Field?

    enum Field: Hashable { case w1, w2, num }

    private var assembled: String {
        let parts = [word1, word2, num].map { $0.lowercased() }
        return parts.joined(separator: "-")
    }
    private var isFilled: Bool {
        !word1.isEmpty && !word2.isEmpty && num.count == 2
    }
    private var isValid: Bool { isFilled && InviteCode.isValid(assembled) }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.warmCanvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    wordInputs
                    pasteRow
                    if isValid { linkPreview }
                    Color.clear.frame(height: 180)
                }
            }
            .scrollIndicators(.hidden)

            stickyCTA
        }
        .navigationTitle("Link a co-parent")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.warmCanvas, for: .navigationBar)
        .onAppear { focused = .w1 }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(Color.partnerBlue).frame(width: 6, height: 6)
                Text("GOT A CODE?")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(Color.partnerBlueInk)
            }
            Text("Type the code your\npartner shared.")
                .font(.system(size: 24, weight: .bold))
                .kerning(-0.5)
                .foregroundStyle(.warmTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Three short words and a number. They'll see your kids and saves the moment you confirm.")
                .font(.system(size: 13))
                .foregroundStyle(.warmTextTertiary)
                .lineSpacing(2)
                .padding(.top, 4)
        }
        .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 16)
    }

    // MARK: - Word inputs

    private var wordInputs: some View {
        HStack(spacing: 8) {
            wordField(text: $word1, placeholder: "word", field: .w1, flex: 1.4, isNumeric: false)
            Text("–").font(.system(size: 18)).foregroundStyle(.warmTextFaint)
            wordField(text: $word2, placeholder: "word", field: .w2, flex: 1.4, isNumeric: false)
            Text("–").font(.system(size: 18)).foregroundStyle(.warmTextFaint)
            wordField(text: $num, placeholder: "##", field: .num, flex: 0.7, isNumeric: true)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }

    private func wordField(
        text: Binding<String>, placeholder: String, field: Field,
        flex: CGFloat, isNumeric: Bool
    ) -> some View {
        let isFocused = focused == field
        let hasValue = !text.wrappedValue.isEmpty
        return TextField(placeholder, text: text)
            .font(.system(
                size: isNumeric ? 18 : 16,
                weight: .semibold,
                design: isNumeric ? .monospaced : .default
            ))
            .keyboardType(isNumeric ? .numberPad : .default)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .multilineTextAlignment(.center)
            .focused($focused, equals: field)
            .foregroundStyle(hasValue ? .warmTextPrimary : .warmTextFaint)
            .padding(.vertical, 14).padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .background(Color.warmCard, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isFocused ? Color.partnerBlue
                            : hasValue ? Color(brown: 0.12)
                            : Color(brown: 0.08),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: isFocused ? Color.partnerBlue.opacity(0.15) : .clear,
                radius: 6
            )
            .layoutPriority(Double(flex))
            .frame(minWidth: isNumeric ? 56 : 80)
            .onSubmit { advanceFocus(from: field) }
            .onChange(of: text.wrappedValue) { _, new in
                if isNumeric {
                    let digits = String(new.filter(\.isNumber).prefix(2))
                    if digits != new { text.wrappedValue = digits }
                    if digits.count == 2 { focused = nil }
                } else {
                    let letters = String(new.filter(\.isLetter).lowercased())
                    if letters != new { text.wrappedValue = letters }
                }
            }
    }

    private func advanceFocus(from field: Field) {
        switch field {
        case .w1: focused = .w2
        case .w2: focused = .num
        case .num: focused = nil
        }
    }

    private var pasteRow: some View {
        Button {
            if let pasted = UIPasteboard.general.string {
                splitInto(pasted)
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 11, weight: .semibold))
                Text("Paste full code instead")
                    .font(.system(size: 11.5))
            }
            .foregroundStyle(.warmTextTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .padding(.bottom, 14)
    }

    private func splitInto(_ raw: String) {
        let parts = raw.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "-").map(String.init)
        guard parts.count == 3 else { return }
        word1 = parts[0]
        word2 = parts[1]
        num = String(parts[2].prefix(2))
    }

    // MARK: - Link preview

    private var linkPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YOU'LL BE LINKING WITH")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.warmTextFaint)

            HStack(spacing: 12) {
                Text(String(partnerName.prefix(1)))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.partnerBlue, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    TextField("Sam", text: $partnerName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.warmTextPrimary)
                        .textInputAutocapitalization(.words)
                    Text("Tap to rename · iPhone")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.warmTextTertiary)
                }
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 6) {
                previewLine(n: store.kids.count, label: "kids combined", detail: kidsDetail)
                previewLine(n: store.savedActivityIds.count, label: "saved activities", detail: "(yours + theirs after merge)")
                previewLine(n: 0, label: "overlap", detail: "(any matches will dedupe)")
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.partnerBlueSoft, in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .warmCard(radius: 14)
        .padding(.horizontal, 16)
    }

    private var kidsDetail: String {
        let names = store.kids.map(\.name).filter { !$0.isEmpty }
        return names.isEmpty ? "(your kids show here)" : "(\(names.joined(separator: ", ")))"
    }

    private func previewLine(n: Int, label: String, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(n)")
                .font(.system(size: 13, weight: .bold).monospacedDigit())
                .foregroundStyle(.partnerBlue)
                .frame(minWidth: 14, alignment: .trailing)
            VStack(alignment: .leading, spacing: 0) {
                Text(label).font(.system(size: 12.5))
                    .foregroundStyle(.warmTextPrimary)
                Text(detail).font(.system(size: 11.5))
                    .foregroundStyle(.warmTextTertiary)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Sticky CTA

    private var stickyCTA: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.warmCanvas.opacity(0), Color.warmCanvas],
                startPoint: .top, endPoint: .bottom
            ).frame(height: 24).allowsHitTesting(false)

            VStack(spacing: 10) {
                Button { confirm() } label: {
                    Text(isValid ? "Confirm — link with \(partnerName)" : "Enter code")
                        .font(.system(size: 15, weight: .bold))
                        .kerning(-0.1)
                        .foregroundStyle(isValid ? .white : .warmTextFaint)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isValid ? Color.partnerBlue : Color(brown: 0.12))
                        )
                        .shadow(color: isValid ? Color.partnerBlue.opacity(0.25) : .clear,
                                radius: 12, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(!isValid)

                NavigationLink {
                    ShareCodeView()
                } label: {
                    Text("Don't have a code? Generate one instead")
                        .font(.system(size: 12))
                        .foregroundStyle(.partnerBlue)
                        .padding(.bottom, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
            .background(Color.warmCanvas)
        }
    }

    private func confirm() {
        guard isValid else { return }
        let trimmed = partnerName.trimmingCharacters(in: .whitespaces)
        let partner = Parent(
            id: UUID(), name: trimmed.isEmpty ? "Sam" : trimmed,
            hue: 250, role: .partner
        )
        store.linkPartner(partner, code: assembled)
        dismiss()
    }
}
