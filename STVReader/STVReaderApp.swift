import SwiftUI
import WebKit
import UIKit

@main
struct STVReaderApp: App {
    var body: some Scene {
        WindowGroup { ReaderView() }
    }
}

struct ReaderView: View {
    @State private var pageTitle = "STV Reader"
    @State private var canGoBack = false
    @State private var webView: WKWebView?
    @State private var loadError: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(pageTitle).font(.headline).lineLimit(1)
                Spacer()
                Button("Safari") {
                    UIApplication.shared.open(URL(string: "https://sangtacviet.com/")!)
                }
            }.padding(.horizontal).frame(height: 50)
            ReaderWebView(webView: $webView, title: $pageTitle, canGoBack: $canGoBack, loadError: $loadError)
            if let error = loadError {
                Text(error).font(.caption).foregroundColor(.red).padding(8)
            }
            HStack {
                Button("Quay lại") { webView?.goBack() }.disabled(!canGoBack)
                Spacer()
                Button("Trang chủ") { webView?.load(URLRequest(url: URL(string: "https://sangtacviet.com/")!)) }
                Spacer()
                Button("Tải lại") { webView?.reload() }
            }.padding()
        }
    }
}
struct ReaderWebView: UIViewRepresentable {
    @Binding var webView: WKWebView?
    @Binding var title: String
    @Binding var canGoBack: Bool
    @Binding var loadError: String?

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        DispatchQueue.main.async { self.webView = view }
        view.load(URLRequest(url: URL(string: "https://sangtacviet.com/")!))
        return view
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: ReaderWebView
        init(_ parent: ReaderWebView) { self.parent = parent }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.title = webView.title ?? "STV Reader"
                self.parent.canGoBack = webView.canGoBack
                self.parent.loadError = nil
            }
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            if (error as NSError).code == NSURLErrorCancelled { return }
            DispatchQueue.main.async { self.parent.loadError = error.localizedDescription }
        }
    }
}
