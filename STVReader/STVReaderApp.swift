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
