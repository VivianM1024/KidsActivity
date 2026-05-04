import SwiftUI
import SafariServices

// SFSafariViewController wrapper used wherever we want to keep the user
// inside the app while showing a web flow (registration links, Google
// Calendar template URLs, etc).

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
