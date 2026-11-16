#!/usr/bin/env python3
"""Add a small native Capacitor iOS shortcut menu; never handles credentials."""
from pathlib import Path

p=Path("ios/App/App/AppDelegate.swift")
s=p.read_text()
if "STVActions.shared.prepare()" in s:
    print("Already patched"); raise SystemExit(0)
start=s.find("didFinishLaunchingWithOptions")
where=s.find("return true",start)
if start<0 or where<0 or where-start>4000:
    raise SystemExit("AppDelegate launch method not recognized")
s="import WebKit\n"+s
start=s.find("didFinishLaunchingWithOptions")
where=s.find("return true",start)
s=s[:where]+"STVActions.shared.prepare()\n        "+s[where:]
s += r'''

// MARK: STV MobileReader shortcuts into the publisher's web app.
// The original STV search, account and history synchronization UI is reused.
// NO automatic overwriting, password collection or third-party API endpoint.
private final class STVActions: NSObject {
    static let shared = STVActions()
    private var observer: NSObjectProtocol?
    private var didOpenPublisherApp = false
    // Always use the current publisher page, not the truncated 1.3.2 index.html.
    // The remote page runs with its own HTTPS origin, retaining its own cookies
    // for authentication and account-based reading history.
    private func openCurrentSTVApplication(in web: WKWebView, force: Bool = false) {
        if didOpenPublisherApp && !force { return }
        didOpenPublisherApp = true
        guard let url = URL(string: "https://sangtacviet.com/app.v2.php") else { return }
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 40)
        // Allow standard first-party cookies and browser caching to persist.
        web.load(request)
    }
    func prepare() {
        observer = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in self?.installSoon() }
        installSoon()
    }
    private func currentWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }.first(where: { $0.isKeyWindow })
    }
    private func installSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { [weak self] in self?.install() }
    }
    private func install() {
        guard let container = currentWindow()?.rootViewController?.view else { return }
        if let web = findWebView(container) { openCurrentSTVApplication(in: web) }
        if container.viewWithTag(92461) != nil { return }
        let button = UIButton(type: .system)
        button.tag = 92461
        button.setTitle("STV", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 14)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.14, green: 0.36, blue: 0.75, alpha: 0.95)
        button.layer.cornerRadius = 23
        button.accessibilityLabel = "Tìm kiếm, đăng nhập và đồng bộ lịch sử STV"
        button.addTarget(self, action: #selector(openActions), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(button)
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: container.safeAreaLayoutGuide.trailingAnchor, constant: -9),
            button.bottomAnchor.constraint(equalTo: container.safeAreaLayoutGuide.bottomAnchor, constant: -82),
            button.widthAnchor.constraint(equalToConstant: 46),
            button.heightAnchor.constraint(equalToConstant: 46)
        ])
    }
    @objc private func openActions() {
        guard let root=currentWindow()?.rootViewController else { return }
        let presenter=root.presentedViewController ?? root
        let alert=UIAlertController(title: "STV MobileReader", message: "Tìm truyện và đồng bộ lịch sử bằng chức năng của Sáng Tác Việt.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "🔎 Tìm truyện", style: .default) { [weak self] _ in self?.execute("search") })
        alert.addAction(UIAlertAction(title: "👤 Đăng nhập / Tài khoản", style: .default) { [weak self] _ in self?.execute("account") })
        alert.addAction(UIAlertAction(title: "☁️ Đồng bộ lịch sử đọc", style: .default) { [weak self] _ in self?.execute("history") })
        alert.addAction(UIAlertAction(title: "↻ Làm mới trang", style: .default) { [weak self] _ in self?.execute("refresh") })
        alert.addAction(UIAlertAction(title: "Đóng", style: .cancel))
        if let pop=alert.popoverPresentationController {
            pop.sourceView=presenter.view
            pop.sourceRect=CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1)
            pop.permittedArrowDirections=[]
        }
        presenter.present(alert, animated: true)
    }
    private func findWebView(_ view: UIView) -> WKWebView? {
        if let web=view as? WKWebView { return web }
        for child in view.subviews { if let web=findWebView(child) { return web } }
        return nil
    }
    private func execute(_ command: String) {
        guard let root=currentWindow()?.rootViewController, let web=findWebView(root.view) else {
            inform("Không tìm thấy giao diện STV. Hãy mở lại ứng dụng.")
            return
        }
        if command == "refresh" { openCurrentSTVApplication(in: web, force: true); return }
        let script: String
        switch command {
        case "search":
            script = "(()=>{try{if(!window.app||!app.theme||!app.fun||typeof app.fun.showSearch!=='function')return 'notready';app.fun.showSearch();return 'ok'}catch(e){return 'error:'+e.message}})()"
        case "account":
            script = "(()=>{try{if(!window.app||!app.theme||!app.fun)return 'notready';if(app.user&&app.user.isLogin&&typeof app.fun.showSetting==='function'){app.fun.showSetting();return 'ok'}if(typeof app.fun.showLogin==='function'){app.fun.showLogin();return 'ok'}return 'notready'}catch(e){return 'error:'+e.message}})()"
        case "history":
            script = "(()=>{try{if(!window.app||!app.fun)return 'notready';if(!app.user||!app.user.isLogin){if(typeof app.fun.showLogin==='function')app.fun.showLogin();return 'login'}if(app.history&&typeof app.history.showSynchronizer==='function'){app.history.showSynchronizer();return 'ok'}return 'notready'}catch(e){return 'error:'+e.message}})()"
        default: return
        }
        web.evaluateJavaScript(script) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error=error { self?.inform("Lỗi STV: " + error.localizedDescription); return }
                guard let status=result as? String else { return }
                if status == "notready" { self?.inform("Giao diện STV chưa khởi tạo xong. Hãy đợi tải trang hoặc chọn Làm mới trang.") }
                else if status == "login" { self?.inform("Hãy đăng nhập rồi chọn Đồng bộ lịch sử đọc một lần nữa.") }
                else if status.hasPrefix("error:") { self?.inform(status) }
            }
        }
    }
    private func inform(_ message: String) {
        guard let root=currentWindow()?.rootViewController else { return }
        let presenter=root.presentedViewController ?? root
        let alert=UIAlertController(title: "STV Reader", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presenter.present(alert, animated: true)
    }
}
'''
# Install a minimal compatibility shim in the WebKit main content world before STV JS executes.
# This guards the publisher's missing CSS selector during iOS platform setup.
import json
compat=Path("stv-ios-compat.js").read_text(encoding="utf-8")
compat += "\n" + Path("stv-ios-tts.js").read_text(encoding="utf-8")
compat += "\n" + Path("stv-ios-http-bridge.js").read_text(encoding="utf-8")
compat += "\n" + Path("stv-com-session.js").read_text(encoding="utf-8")
compat += "\n" + Path("stv-ios-chapter-transport.js").read_text(encoding="utf-8")
js_literal=json.dumps(compat, ensure_ascii=False)
s=s.replace(
    "private var didOpenPublisherApp = false",
    "private var didOpenPublisherApp = false\n    private weak var shimmedWebView: WKWebView?",
    1
)
old="        web.load(request)"
if old not in s:
    raise SystemExit("Cannot locate navigation request for WebKit injection")
injection=(
    "        if shimmedWebView !== web {\n"
    + "            let compatibilityJS = " + js_literal + "\n"
    + "            web.configuration.userContentController.addUserScript(WKUserScript(source: compatibilityJS, injectionTime: .atDocumentStart, forMainFrameOnly: true))\n"
    + "            shimmedWebView = web\n"
    + "        }\n"
    + "        web.load(request)"
)
s=s.replace(old,injection,1)
p.write_text(s)
print("Patched STV iOS compatibility bridge and native action menu")

