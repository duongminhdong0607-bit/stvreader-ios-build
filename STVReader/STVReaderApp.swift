import SwiftUI
import UIKit
import UniformTypeIdentifiers
import AVFoundation

// STV Reader Native — một ứng dụng đọc văn bản iOS thực sự.
// Không sử dụng WebKit hay trình duyệt nhúng.

struct ReaderBook: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var author: String
    var content: String
    var progress: Double = 0
    var bookmarked: Bool = false
    var updatedAt: Date = Date()
}

@MainActor
final class ReaderLibrary: ObservableObject {
    @Published private(set) var books: [ReaderBook] = []
    private let fileURL: URL

    init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = directory.appendingPathComponent("reader-library.json")
        if let bytes = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([ReaderBook].self, from: bytes) {
            books = decoded
        } else {
            books = [ReaderBook(
                title: "Hướng dẫn sử dụng STV Reader",
                author: "STV Reader Native",
                content: """
                Chào mừng bạn đến với STV Reader Native!

                Đây là ứng dụng đọc truyện chạy trực tiếp trên iPhone, được xây dựng lại bằng SwiftUI. Ứng dụng này hoạt động độc lập và không phải bản STV MobileReader chính thức.

                MỤC 1 — THÊM TRUYỆN

                Trong màn hình Thư viện, chạm dấu cộng để nhập một tệp TXT hoặc Markdown từ ứng dụng Tệp trên iPhone. Bạn cũng có thể bấm nút Dán nội dung và nhập truyện của riêng mình.

                MỤC 2 — ĐỌC NGOẠI TUYẾN

                Nội dung truyện đã nhập sẽ được lưu trên iPhone. Bạn có thể đọc ngay cả khi không có Internet.

                MỤC 3 — TÙY CHỈNH

                Trong màn hình đọc, dùng nút A− và A+ để đổi cỡ chữ. Mở mục Cài đặt để chọn nền sáng, nền giấy hoặc nền tối.

                MỤC 4 — ĐỌC BẰNG GIỌNG NÓI

                Bấm nút loa để sử dụng giọng đọc tiếng Việt có sẵn trên iOS. Bấm lần nữa để dừng.

                MỤC 5 — LƯU VỊ TRÍ

                Mỗi khi bạn cuộn trong truyện, ứng dụng tự lưu tiến độ đọc để lần sau có thể tiếp tục từ vị trí gần nhất.

                Chúc bạn có thời gian đọc sách thật thú vị!
                """
            )]
            save()
        }
    }

    func book(_ id: UUID) -> ReaderBook? {
        books.first(where: { $0.id == id })
    }

    @discardableResult
    func add(title: String, author: String, content: String) -> Bool {
        let normalized = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return false }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
        books.insert(ReaderBook(
            title: cleanTitle.isEmpty ? "Truyện chưa đặt tên" : cleanTitle,
            author: cleanAuthor.isEmpty ? "Không rõ tác giả" : cleanAuthor,
            content: normalized
        ), at: 0)
        save()
        return true
    }

    func delete(_ id: UUID) {
        books.removeAll(where: { $0.id == id })
        save()
    }

    func toggleBookmark(_ id: UUID) {
        guard let index = books.firstIndex(where: { $0.id == id }) else { return }
        books[index].bookmarked.toggle()
        books[index].updatedAt = Date()
        save()
    }

    func setProgress(_ id: UUID, fraction: Double) {
        guard let index = books.firstIndex(where: { $0.id == id }) else { return }
        let value = min(1, max(0, fraction))
        guard abs(books[index].progress - value) >= 0.012 else { return }
        books[index].progress = value
        books[index].updatedAt = Date()
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(books) {
            try? data.write(to: fileURL, options: [.atomic])
        }
    }
}

@main
struct STVReaderNativeApp: App {
    @StateObject private var library = ReaderLibrary()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(library)
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            LibraryView()
                .tabItem {
                    Label("Thư viện", systemImage: "books.vertical.fill")
                }
            STVOnlineSearchView()
                .tabItem {
                    Label("Tìm STV", systemImage: "magnifyingglass")
                }
            ReaderSettingsView()
                .tabItem {
                    Label("Cài đặt", systemImage: "textformat.size")
                }
        }
        .accentColor(Color(red: 0.21, green: 0.40, blue: 0.76))
    }
}

struct LibraryView: View {
    @EnvironmentObject private var library: ReaderLibrary
    @State private var showImporter = false
    @State private var showPaste = false
    @State private var searchText = ""
    @State private var importError = ""
    @State private var showImportError = false

    private var visibleBooks: [ReaderBook] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let results = keyword.isEmpty ? library.books : library.books.filter {
            $0.title.localizedCaseInsensitiveContains(keyword) ||
            $0.author.localizedCaseInsensitiveContains(keyword)
        }
        return results.sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "books.vertical.circle.fill")
                                .font(.system(size: 36))
                            Spacer()
                            Text("\(library.books.count) truyện")
                                .font(.footnote)
                        }
                        Text("Tủ sách của bạn")
                            .font(.title2.bold())
                        Text("Đọc ngoại tuyến • Lưu tiến độ • Giọng đọc iOS")
                            .font(.subheadline)
                    }
                    .foregroundColor(.white)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.15, green: 0.34, blue: 0.67),
                                Color(red: 0.31, green: 0.52, blue: 0.86)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }

                Section(header: Text("Đang đọc và đã lưu")) {
                    ForEach(visibleBooks) { book in
                        NavigationLink(destination: ReaderScreen(bookID: book.id)) {
                            LibraryBookRow(book: book)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                library.delete(book.id)
                            } label: {
                                Label("Xóa", systemImage: "trash")
                            }
                            Button {
                                library.toggleBookmark(book.id)
                            } label: {
                                Label("Đánh dấu", systemImage: "bookmark")
                            }
                            .tint(.orange)
                        }
                    }
                    if visibleBooks.isEmpty {
                        Text("Chưa tìm thấy truyện. Hãy nhập một tệp TXT hoặc dán nội dung.")
                            .foregroundColor(.secondary)
                            .padding(.vertical)
                    }
                }
                Section {
                    Button {
                        showImporter = true
                    } label: {
                        Label("Nhập truyện TXT từ Tệp", systemImage: "square.and.arrow.down")
                    }
                    Button {
                        showPaste = true
                    } label: {
                        Label("Dán nội dung truyện", systemImage: "doc.on.clipboard")
                    }
                } header: {
                    Text("Thêm truyện")
                }
            }
            .navigationTitle("STV Reader")
            .searchable(text: $searchText, prompt: "Tìm trong tủ sách")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showImporter = true
                        } label: {
                            Label("Nhập TXT", systemImage: "doc.text")
                        }
                        Button {
                            showPaste = true
                        } label: {
                            Label("Dán văn bản", systemImage: "doc.on.clipboard")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showPaste) {
                PasteBookView()
                    .environmentObject(library)
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.plainText, UTType(filenameExtension: "md") ?? .plainText],
                allowsMultipleSelection: false
            ) { result in
                do {
                    let urls = try result.get()
                    guard let url = urls.first else { return }
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    let data = try Data(contentsOf: url)
                    guard data.count <= 12_000_000 else {
                        throw ReaderImportError.tooLarge
                    }
                    let content = String(data: data, encoding: .utf8)
                        ?? String(data: data, encoding: .utf16)
                        ?? String(data: data, encoding: .windowsCP1252)
                    guard let content = content, !content.isEmpty else {
                        throw ReaderImportError.invalidText
                    }
                    let title = url.deletingPathExtension().lastPathComponent
                    DispatchQueue.main.async {
                        if !library.add(title: title, author: "Truyện đã nhập", content: content) {
                            showError("Tệp không có nội dung đọc được.")
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        showError(error.localizedDescription)
                    }
                }
            }
            .alert("Không thể nhập truyện", isPresented: $showImportError) {
                Button("Đóng", role: .cancel) {}
            } message: {
                Text(importError)
            }
        }
        .navigationViewStyle(.stack)
    }

    private func showError(_ message: String) {
        importError = message
        showImportError = true
    }
}

enum ReaderImportError: LocalizedError {
    case tooLarge
    case invalidText
    var errorDescription: String? {
        switch self {
        case .tooLarge: return "Tệp lớn hơn 12 MB. Hãy chia thành các phần nhỏ hơn."
        case .invalidText: return "Không thể đọc tệp. Vui lòng chọn TXT mã hóa UTF-8."
        }
    }
}

struct LibraryBookRow: View {
    let book: ReaderBook
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.24, green: 0.38, blue: 0.68),
                                Color(red: 0.37, green: 0.55, blue: 0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "book.closed.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(width: 54, height: 72)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(2)
                    if book.bookmarked {
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(.orange)
                    }
                }
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                ProgressView(value: book.progress)
                    .tint(Color(red: 0.22, green: 0.44, blue: 0.78))
                Text("Đã đọc \(Int(book.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PasteBookView: View {
    @EnvironmentObject private var library: ReaderLibrary
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var author = ""
    @State private var content = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Thông tin")) {
                    TextField("Tên truyện", text: $title)
                    TextField("Tác giả", text: $author)
                }
                Section(header: Text("Nội dung truyện")) {
                    TextEditor(text: $content)
                        .frame(minHeight: 280)
                }
            }
            .navigationTitle("Thêm truyện")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu") {
                        if library.add(title: title, author: author, content: content) {
                            dismiss()
                        }
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct ReaderSettingsView: View {
    @AppStorage("stv.native.fontSize") private var fontSize = 19.0
    @AppStorage("stv.native.theme") private var theme = "paper"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Hiển thị khi đọc")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Cỡ chữ")
                            Spacer()
                            Text("\(Int(fontSize))")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $fontSize, in: 14...32, step: 1)
                    }
                    Picker("Giao diện", selection: $theme) {
                        Text("Giấy ấm").tag("paper")
                        Text("Sáng").tag("light")
                        Text("Tối").tag("dark")
                    }
                }
                Section(header: Text("Chức năng")) {
                    Label("Đọc offline nội dung đã nhập", systemImage: "checkmark.circle")
                    Label("Tự động lưu tiến độ", systemImage: "bookmark")
                    Label("Đọc tiếng Việt bằng giọng iOS", systemImage: "speaker.wave.2")
                    Label("Nhập TXT và Markdown từ Tệp", systemImage: "doc.text")
                }
                Section(header: Text("Về ứng dụng")) {
                    Text("STV Reader Native — phiên bản thử nghiệm độc lập. Không kết nối tài khoản hoặc kho truyện của STV MobileReader gốc.")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
            }
            .navigationTitle("Cài đặt")
        }
        .navigationViewStyle(.stack)
    }
}

struct ReaderScreen: View {
    @EnvironmentObject private var library: ReaderLibrary
    @AppStorage("stv.native.fontSize") private var fontSize = 19.0
    @AppStorage("stv.native.theme") private var theme = "paper"
    @StateObject private var speech = NativeSpeechReader()
    let bookID: UUID

    var body: some View {
        Group {
            if let book = library.book(bookID) {
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "text.book.closed.fill")
                            .foregroundColor(.secondary)
                        Text(book.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Spacer()
                        Text("\(Int(book.progress * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    ProgressView(value: book.progress)
                        .tint(.blue)
                        .padding(.horizontal, 16)

                    NativeReadingText(
                        text: book.content,
                        initialProgress: book.progress,
                        fontSize: fontSize,
                        theme: theme
                    ) { fraction in
                        library.setProgress(bookID, fraction: fraction)
                    }
                    .background(readerBackground)

                    HStack(spacing: 20) {
                        Button {
                            fontSize = max(14, fontSize - 1)
                        } label: {
                            Label("Nhỏ", systemImage: "textformat.size.smaller")
                                .labelStyle(.iconOnly)
                        }
                        Spacer()
                        Button {
                            speech.toggle(book.content)
                        } label: {
                            Label(speech.speaking ? "Dừng" : "Nghe", systemImage: speech.speaking ? "stop.fill" : "speaker.wave.2.fill")
                        }
                        Spacer()
                        Button {
                            library.toggleBookmark(bookID)
                        } label: {
                            Label("Đánh dấu", systemImage: book.bookmarked ? "bookmark.fill" : "bookmark")
                        }
                        Spacer()
                        Button {
                            theme = (theme == "dark") ? "paper" : "dark"
                        } label: {
                            Label("Giao diện", systemImage: theme == "dark" ? "sun.max" : "moon")
                        }
                        Spacer()
                        Button {
                            fontSize = min(32, fontSize + 1)
                        } label: {
                            Label("Lớn", systemImage: "textformat.size.larger")
                                .labelStyle(.iconOnly)
                        }
                    }
                    .font(.title3)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(Color(uiColor: .secondarySystemBackground))
                }
                .navigationBarTitleDisplayMode(.inline)
                .onDisappear {
                    speech.stop()
                }
            } else {
                Text("Truyện đã bị xóa khỏi thư viện.")
            }
        }
    }

    private var readerBackground: Color {
        switch theme {
        case "dark": return Color(red: 0.10, green: 0.11, blue: 0.15)
        case "light": return Color.white
        default: return Color(red: 0.98, green: 0.95, blue: 0.87)
        }
    }
}

// UITextView là thành phần đọc văn bản native của UIKit, không phải WebView.
struct NativeReadingText: UIViewRepresentable {
    let text: String
    let initialProgress: Double
    let fontSize: Double
    let theme: String
    let onProgress: (Double) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onProgress: onProgress)
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView(frame: .zero)
        view.delegate = context.coordinator
        view.isEditable = false
        view.isSelectable = true
        view.alwaysBounceVertical = true
        view.textContainerInset = UIEdgeInsets(top: 22, left: 18, bottom: 28, right: 18)
        view.textContainer.lineFragmentPadding = 0
        view.showsVerticalScrollIndicator = true
        view.adjustsFontForContentSizeCategory = false
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onProgress = onProgress
        let styleKey = "\(text.hashValue)-\(fontSize)-\(theme)"
        guard coordinator.lastStyleKey != styleKey else { return }

        let fraction = coordinator.didRestore ? coordinator.fraction(of: view) : initialProgress
        coordinator.lastStyleKey = styleKey
        coordinator.isRestoring = true

        let foreground: UIColor
        let background: UIColor
        switch theme {
        case "dark":
            foreground = UIColor(red: 0.89, green: 0.90, blue: 0.92, alpha: 1)
            background = UIColor(red: 0.10, green: 0.11, blue: 0.15, alpha: 1)
        case "light":
            foreground = .black
            background = .white
        default:
            foreground = UIColor(red: 0.25, green: 0.21, blue: 0.17, alpha: 1)
            background = UIColor(red: 0.98, green: 0.95, blue: 0.87, alpha: 1)
        }

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = fontSize * 0.32
        paragraph.paragraphSpacing = fontSize * 0.72
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .regular),
            .foregroundColor: foreground,
            .paragraphStyle: paragraph
        ]
        view.attributedText = NSAttributedString(string: text, attributes: attributes)
        view.backgroundColor = background
        view.tintColor = theme == "dark" ? UIColor.white : UIColor.systemBlue
        view.setNeedsLayout()
        DispatchQueue.main.async {
            view.layoutIfNeeded()
            coordinator.restore(view, fraction: fraction)
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var onProgress: (Double) -> Void
        var lastStyleKey = ""
        var didRestore = false
        var isRestoring = false
        private var lastReported = -1.0

        init(onProgress: @escaping (Double) -> Void) {
            self.onProgress = onProgress
        }

        func fraction(of view: UITextView) -> Double {
            let maxY = max(0, view.contentSize.height - view.bounds.height + view.adjustedContentInset.bottom)
            guard maxY > 0 else { return 0 }
            return max(0, min(1, (view.contentOffset.y + view.adjustedContentInset.top) / maxY))
        }

        func restore(_ view: UITextView, fraction: Double) {
            let maxY = max(0, view.contentSize.height - view.bounds.height + view.adjustedContentInset.bottom)
            view.setContentOffset(
                CGPoint(x: 0, y: max(-view.adjustedContentInset.top, fraction * maxY - view.adjustedContentInset.top)),
                animated: false
            )
            didRestore = true
            isRestoring = false
            lastReported = fraction
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard !isRestoring, let view = scrollView as? UITextView, didRestore else { return }
            let value = fraction(of: view)
            if abs(value - lastReported) > 0.013 {
                lastReported = value
                onProgress(value)
            }
        }
    }
}

final class NativeSpeechReader: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var speaking = false
    private let synth = AVSpeechSynthesizer()
    private var chunks: [String] = []
    private var currentIndex = 0

    override init() {
        super.init()
        synth.delegate = self
    }

    func toggle(_ content: String) {
        if speaking {
            stop()
            return
        }
        let paragraphs = content.components(separatedBy: .newlines)
        chunks = []
        var buffer = ""
        for paragraph in paragraphs {
            let clean = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty else { continue }
            if !buffer.isEmpty && buffer.count + clean.count > 650 {
                chunks.append(buffer)
                buffer = ""
            }
            if clean.count > 1200 {
                let letters = Array(clean)
                for offset in stride(from: 0, to: letters.count, by: 650) {
                    chunks.append(String(letters[offset..<min(offset + 650, letters.count)]))
                }
            } else {
                buffer += (buffer.isEmpty ? "" : "\n") + clean
            }
        }
        if !buffer.isEmpty { chunks.append(buffer) }
        currentIndex = 0
        speaking = !chunks.isEmpty
        speakNext()
    }

    func stop() {
        chunks = []
        currentIndex = 0
        speaking = false
        synth.stopSpeaking(at: .immediate)
    }

    private func speakNext() {
        guard speaking, currentIndex < chunks.count else {
            speaking = false
            return
        }
        let utterance = AVSpeechUtterance(string: chunks[currentIndex])
        utterance.voice = AVSpeechSynthesisVoice(language: "vi-VN")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.90
        currentIndex += 1
        synth.speak(utterance)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.speakNext() }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.speaking = false }
    }
}


// MARK: Native STV public catalog — SwiftUI + Foundation URLSession only.
// This is an independent client, NOT an official STV iOS app. No WKWebView.
// STV's unauthenticated catalog search and chapter index are public endpoints.
// Account login and complete chapter bodies require publisher-supported APIs.

struct STVOnlineBook: Identifiable {
    let host: String
    let sourceID: String
    let title: String
    let author: String
    let summary: String
    let chapterCount: Int
    var id: String { host + ":" + sourceID }
}

struct STVOnlineChapter: Identifiable {
    let id: String
    let title: String
    let host: String
    let sourceID: String
}

enum STVOnlineError: LocalizedError {
    case invalidResponse
    case unsupportedPlatform(String)
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Dữ liệu trả về từ Sáng Tác Việt không đúng định dạng mong đợi."
        case .unsupportedPlatform(let message):
            return message
        }
    }
}

enum STVPublicAPI {
    static let root = "https://sangtacviet.com"

    static func fetch(url: URL) async throws -> Data {
        guard url.scheme == "https", url.host == "sangtacviet.com" else {
            throw STVOnlineError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 22
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw STVOnlineError.invalidResponse
        }
        return data
    }

    static func endpoint(_ path: String, items: [URLQueryItem]) throws -> URL {
        guard var c = URLComponents(string: root + path) else {
            throw STVOnlineError.invalidResponse
        }
        c.queryItems = items
        guard let url = c.url else { throw STVOnlineError.invalidResponse }
        return url
    }

    static func field(_ value: Any?) -> String {
        if let text = value as? String { return text.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let number = value as? NSNumber { return number.stringValue }
        return ""
    }

    static func search(_ keyword: String) async throws -> [STVOnlineBook] {
        let url = try endpoint("/io/searchtp/searchBooks", items: [
            URLQueryItem(name: "method", value: "search"),
            URLQueryItem(name: "minc", value: "0"),
            URLQueryItem(name: "category", value: ""),
            URLQueryItem(name: "findinname", value: keyword),
            URLQueryItem(name: "find", value: ""),
            URLQueryItem(name: "sort", value: ""),
            URLQueryItem(name: "host", value: ""),
            URLQueryItem(name: "tag", value: ""),
            URLQueryItem(name: "step", value: ""),
            URLQueryItem(name: "p", value: "0")
        ])
        let data = try await fetch(url: url)
        // STV responds with JSON in its app, but a direct native HTTP client
        // often receives HTML result cards from the very same public endpoint.
        // Parse the returned data into native SwiftUI models; never render HTML.
        let bytes = String(data: data, encoding: .utf8) ?? ""
        if !bytes.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") {
            let parsed = parseSearchHTML(bytes)
            guard !parsed.isEmpty else { throw STVOnlineError.invalidResponse }
            return parsed
        }
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rows = root["list"] as? [[String: Any]] else {
            throw STVOnlineError.invalidResponse
        }
        return rows.compactMap { item in
            let host = field(item["host"])
            let sourceID = field(item["id"])
            guard !host.isEmpty, !sourceID.isEmpty else { return nil }
            return STVOnlineBook(
                host: host, sourceID: sourceID,
                title: field(item["tname"]).isEmpty ? field(item["name"]) : field(item["tname"]),
                author: field(item["hauthor"]).isEmpty ? field(item["author"]) : field(item["hauthor"]),
                summary: field(item["info"]),
                chapterCount: Int(field(item["chaptercount"])) ?? 0
            )
        }
    }

    private static func capture(_ pattern: String, in source: String, group: Int = 1) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else { return nil }
        let text = source as NSString
        guard let match = regex.firstMatch(in: source, range: NSRange(location: 0, length: text.length)),
              match.numberOfRanges > group,
              match.range(at: group).location != NSNotFound else { return nil }
        return text.substring(with: match.range(at: group))
    }

    private static func cleanHTML(_ html: String) -> String {
        let stripped = html.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        return stripped
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parseSearchHTML(_ html: String) -> [STVOnlineBook] {
        let pattern = #"<a\b(?=[^>]*\bbooksearch\b)[^>]*href="/truyen/([^/]+)/[^/]+/([^/]+)/"[^>]*>(.*?)</a>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else {
            return []
        }
        let text = html as NSString
        return regex.matches(in: html, range: NSRange(location: 0, length: text.length)).compactMap { match in
            guard match.numberOfRanges >= 4 else { return nil }
            let host = text.substring(with: match.range(at: 1))
            let sourceID = text.substring(with: match.range(at: 2))
            let innerHTML = text.substring(with: match.range(at: 3))
            guard let title = capture(#"<b[^>]*class="searchbooktitle"[^>]*>(.*?)</b>"#, in: innerHTML),
                  !title.isEmpty else { return nil }
            let author = capture(#"<span[^>]*class="searchbookauthor"[^>]*>(.*?)</span>"#, in: innerHTML) ?? ""
            let summary = capture(#"<span[^>]*class="lhr"[^>]*>(.*?)</span>"#, in: innerHTML) ?? ""
            return STVOnlineBook(host: host, sourceID: sourceID,
                                 title: cleanHTML(title), author: cleanHTML(author),
                                 summary: cleanHTML(summary), chapterCount: 0)
        }
    }

    static func chapters(for book: STVOnlineBook) async throws -> [STVOnlineChapter] {
        let url = try endpoint("/index.php", items: [
            URLQueryItem(name: "ngmar", value: "chapterlist"),
            URLQueryItem(name: "h", value: book.host),
            URLQueryItem(name: "bookid", value: book.sourceID),
            URLQueryItem(name: "sajax", value: "getchapterlist")
        ])
        let data = try await fetch(url: url)
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let raw = object["data"] as? String else {
            throw STVOnlineError.invalidResponse
        }
        // Original STV serializes public chapter metadata with -//- rows
        // and -/- columns; chapter text is deliberately NOT synthesized.
        return raw.components(separatedBy: "-//-").compactMap { line -> STVOnlineChapter? in
            let parts = line.components(separatedBy: "-/-")
            guard parts.count >= 3 else { return nil }
            let chapterID = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let name = parts.dropFirst(2).joined(separator: "-/-").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !chapterID.isEmpty, !name.isEmpty else { return nil }
            return STVOnlineChapter(id: chapterID, title: name, host: book.host, sourceID: book.sourceID)
        }
    }

    static func chapterBody(_ chapter: STVOnlineChapter) async throws -> String {
        // Public guest call only. Some STV hosts reject third-party clients
        // with "Platform unknown". Never try to fabricate auth/platform tokens.
        let url = try endpoint("/index.php", items: [
            URLQueryItem(name: "sajax", value: "readchapter"),
            URLQueryItem(name: "h", value: chapter.host),
            URLQueryItem(name: "bookid", value: chapter.sourceID),
            URLQueryItem(name: "c", value: chapter.id)
        ])
        let data = try await fetch(url: url)
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw STVOnlineError.invalidResponse
        }
        if let errorText = object["err"] as? String, !errorText.isEmpty {
            throw STVOnlineError.unsupportedPlatform("Máy chủ STV từ chối yêu cầu đọc chương: " + errorText)
        }
        if let chapterText = object["data"] as? String, !chapterText.isEmpty {
            return chapterText.replacingOccurrences(of: "<[^>]*>", with: "\n", options: .regularExpression)
        }
        throw STVOnlineError.unsupportedPlatform("Chưa thể lấy nội dung chương qua API công khai của STV. Cần giao thức iOS được nhà phát triển hỗ trợ.")
    }
}

@MainActor
final class STVOnlineSearchModel: ObservableObject {
    @Published var results: [STVOnlineBook] = []
    @Published var loading = false
    @Published var message: String?
    func search(_ query: String) async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { message = "Nhập tên truyện để tìm."; return }
        loading = true
        message = nil
        defer { loading = false }
        do {
            results = try await STVPublicAPI.search(term)
            if results.isEmpty { message = "Không tìm thấy truyện phù hợp." }
        } catch {
            results = []
            message = error.localizedDescription
        }
    }
}

struct STVOnlineSearchView: View {
    @StateObject private var model = STVOnlineSearchModel()
    @State private var keyword = ""
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    TextField("Nhập tên truyện trên STV", text: $keyword)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .submitLabel(.search)
                        .onSubmit { Task { await model.search(keyword) } }
                    Button("Tìm") { Task { await model.search(keyword) } }
                        .disabled(model.loading || keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                if model.loading { ProgressView("Đang tìm truyện…").padding(.bottom, 10) }
                if let message = model.message {
                    Text(message).font(.footnote).foregroundColor(.secondary).padding(12)
                }
                List(model.results) { book in
                    NavigationLink(destination: STVOnlineBookDetail(book: book)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(book.title).font(.headline)
                            Text(book.author).font(.subheadline).foregroundColor(.secondary)
                            Text("Nguồn: \(book.host) • \(book.chapterCount) chương")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.vertical, 5)
                    }
                }
                .listStyle(.plain)
                Text("Ứng dụng SwiftUI native. Không sử dụng WebView. Đăng nhập STV chưa có giao thức API iOS được xác minh.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            .navigationTitle("Tìm truyện STV")
        }
        .navigationViewStyle(.stack)
    }
}

@MainActor
final class STVChapterIndexModel: ObservableObject {
    @Published var chapters: [STVOnlineChapter] = []
    @Published var loading = false
    @Published var message: String?
    func load(_ book: STVOnlineBook) async {
        loading = true
        defer { loading = false }
        do {
            chapters = try await STVPublicAPI.chapters(for: book)
            if chapters.isEmpty { message = "Máy chủ không cung cấp danh sách chương từ nguồn này." }
            else { message = nil }
        } catch {
            message = error.localizedDescription
        }
    }
}

struct STVOnlineBookDetail: View {
    let book: STVOnlineBook
    @StateObject private var model = STVChapterIndexModel()

    var body: some View {
        List {
            Section(header: Text("Thông tin truyện")) {
                Text(book.title).font(.title3.bold())
                Text(book.author).foregroundColor(.secondary)
                if !book.summary.isEmpty {
                    Text(book.summary).font(.callout).lineLimit(9)
                }
                Text("Nguồn: \(book.host)")
                    .font(.caption).foregroundColor(.secondary)
            }
            Section(header: Text("Danh sách chương")) {
                if model.loading { ProgressView("Đang tải danh sách…") }
                if let message = model.message { Text(message).foregroundColor(.secondary) }
                ForEach(model.chapters) { chapter in
                    NavigationLink(destination: STVOnlineChapterView(chapter: chapter)) {
                        Text(chapter.title).font(.body).lineLimit(2)
                    }
                }
            }
        }
        .navigationTitle("Truyện")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load(book) }
    }
}

struct STVOnlineChapterView: View {
    let chapter: STVOnlineChapter
    @State private var text = ""
    @State private var errorMessage: String?
    @State private var loading = true
    @AppStorage("stv.native.fontSize") private var fontSize = 19.0
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(chapter.title).font(.title3.bold())
                if loading { ProgressView("Đang tải chương…") }
                if let errorMessage = errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                if !text.isEmpty {
                    Text(text)
                        .font(.system(size: fontSize))
                        .lineSpacing(fontSize * 0.35)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
        }
        .background(Color(red: 0.98, green: 0.96, blue: 0.90))
        .navigationTitle("Đọc chương")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loading = true
            defer { loading = false }
            do { text = try await STVPublicAPI.chapterBody(chapter) }
            catch { errorMessage = error.localizedDescription }
        }
    }
}
