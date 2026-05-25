//  JournalView.swift — PSI
//  iOS 26+  |  PaperKit.framework + PencilKit.framework required

import SwiftUI
import PaperKit
import PencilKit
import PhotosUI

struct JournalView: View {
    @State private var store           = EntriesStore()
    @State private var selectedEntry: JournalEntry? = nil
    @State private var entryToRename: JournalEntry? = nil
    @State private var renameText      = ""
    @State private var showRenameAlert = false
    
    // Cor de fundo inspirada no seu print (Bege pastel)
    let themeBackground = Color(red: 0.98, green: 0.97, blue: 0.92)
    
    var body: some View {
        NavigationStack {
            List {
                Group {
                    ProfileCardView()
                        .padding(.top, 16)
                    
                    SavedEventsCarousel()
                        .padding(.top, 24)
                    
                    CalendarDumpView(entries: store.entries) { clickedEntry in
                        selectedEntry = clickedEntry
                    }
                    .padding(.vertical, 24)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                
                if store.entries.isEmpty {
                    emptyState
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(store.entries) { entry in
                        Button { selectedEntry = entry } label: {
                            EntryRowView(entry: entry)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color(.clear))
                        // Suas actions nativas de volta!
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                entryToRename   = entry
                                renameText      = entry.title
                                showRenameAlert = true
                            } label: { Label("Renomear", systemImage: "pencil") }
                                .tint(.blue)
                        }
                    }
                    .onDelete { store.delete(at: $0) }
                }
            }
            .listStyle(.plain) // Estilo limpo para imitar o ScrollView
            .fullScreenCover(item: $selectedEntry) { entry in
                EntryEditorView(entry: storeBinding(for: entry), onSave: { store.save() })
            }
            .background(themeBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        let e = JournalEntry(title: "", date: Date())
                        store.add(e)
                        selectedEntry = e
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.primary)
                    }
                }
            }
            .alert("Renomear", isPresented: $showRenameAlert) {
                TextField("Título", text: $renameText)
                Button("Salvar") {
                    if let id = entryToRename?.id { store.rename(id: id, to: renameText) }
                }
                Button("Cancelar", role: .cancel) {}
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical").font(.system(size: 40))
                .foregroundColor(Color(.systemGray3))
            Text("Nenhuma entrada ainda")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
            Text("Toque no ✏️ acima para criar.")
                .font(.system(size: 14)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var entryList: some View {
        LazyVStack(spacing: 12) {
            ForEach(store.entries) { entry in
                Button { selectedEntry = entry } label: {
                    EntryRowView(entry: entry)
                }
                .buttonStyle(.plain)
                // Substituindo as funcionalidades do swipeActions do List por um Menu de contexto (Long press)
                .contextMenu {
                    Button {
                        entryToRename  = entry
                        renameText     = entry.title
                        showRenameAlert = true
                    } label: { Label("Renomear", systemImage: "pencil") }
                    
                    Button(role: .destructive) {
                        if let idx = store.entries.firstIndex(where: { $0.id == entry.id }) {
                            store.delete(at: IndexSet(integer: idx))
                        }
                    } label: { Label("Deletar", systemImage: "trash") }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func storeBinding(for entry: JournalEntry) -> Binding<JournalEntry> {
        guard let idx = store.entries.firstIndex(where: { $0.id == entry.id }) else {
            return .constant(entry)
        }
        return Binding(
            get: { self.store.entries[idx] },
            set: { self.store.entries[idx] = $0; self.store.save() }
        )
    }
}

// MARK: - Entry Row

struct EntryRowView: View {
    let entry: JournalEntry
    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(fmt(entry.date, "d")).font(.system(size: 22, weight: .bold, design: .rounded))
                Text(fmt(entry.date, "MMM", locale: "pt_BR"))
                    .font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            .frame(width: 44).padding(.vertical, 6).padding(.horizontal, 8)
            .background(Color(.white)).clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title.isEmpty ? "Sem título" : entry.title)
                    .font(.system(size: 16, weight: .semibold)).lineLimit(1)
                Text(fmt(entry.date, "HH:mm")).font(.system(size: 13)).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium)).foregroundColor(Color(.systemGray3))
        }
        .padding(.vertical, 4)
    }
    private func fmt(_ d: Date, _ f: String, locale: String? = nil) -> String {
        let df = DateFormatter(); df.dateFormat = f
        if let l = locale { df.locale = Locale(identifier: l) }
        return df.string(from: d)
    }
}

// MARK: - Entry Editor

struct EntryEditorView: View {
    @Binding var entry: JournalEntry
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var coordinator      = PaperMarkupCoordinator()
    @State private var isPencilActive   = false
    @State private var showClearConfirm = false
    @State private var showPhotoPicker  = false
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var exportImage: UIImage?        = nil
    @State private var showShareSheet               = false
    @State private var canvasSize: CGSize           = .zero
    
    var body: some View {
        NavigationStack {
            // ── Scrollable canvas area ──────────────────────────────────
            GeometryReader { geo in
                let size = geo.size
                ZStack {
                    Color.white.ignoresSafeArea()
                    
                    if size != .zero {
                        PaperMarkupView(
                            canvasSize: size,
                            isEditable: true,
                            markupDataURL: entry.markupDataURL,
                            coordinator: coordinator
                        )
                        .frame(width: size.width, height: size.height)
                        .clipped()
                    }
                }
                .onAppear {
                    if canvasSize == .zero {
                        canvasSize = size
                        coordinator.canvasSize = size
                    }
                }
                .onChange(of: geo.size) { _, newSize in
                    canvasSize = newSize
                    coordinator.canvasSize = newSize
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .images)
            .onChange(of: photoItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let img  = UIImage(data: data) {
                        coordinator.insertImage(img)
                        photoItem = nil
                    }
                }
            }
            .confirmationDialog("Limpar canvas?", isPresented: $showClearConfirm,
                                titleVisibility: .visible) {
                Button("Limpar tudo", role: .destructive) { coordinator.clear() }
                Button("Cancelar", role: .cancel) {}
            } message: { Text("Essa ação não pode ser desfeita.") }
                .sheet(isPresented: $showShareSheet) {
                    if let img = exportImage { ShareSheet(items: [img]) }
                }
        }
    }
    
    // MARK: Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                coordinator.forceSave()
                onSave()
                dismiss()
            } label: {
                Image(systemName: "chevron.left").fontWeight(.semibold)
            }
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
            Button { coordinator.undo() } label: {
                Image(systemName: "arrow.uturn.backward").fontWeight(.semibold)
            }
            Button { exportCanvas() } label: {
                Image(systemName: "square.and.arrow.up")
            }
            Button {
                if isPencilActive { isPencilActive = false; coordinator.deactivatePencil() }
                coordinator.showAddMenu()
            } label: { Image(systemName: "plus").fontWeight(.semibold) }
            
            Button {
                isPencilActive.toggle()
                isPencilActive ? coordinator.activatePencil() : coordinator.deactivatePencil()
            } label: {
                Image(systemName: isPencilActive
                      ? "pencil.tip.crop.circle.fill"
                      : "pencil.tip.crop.circle")
                .foregroundColor(isPencilActive ? .blue : .primary)
            }
        }
        
        ToolbarItemGroup(placement: .bottomBar) {
            Button { showPhotoPicker = true } label: { Image(systemName: "photo") }
            Spacer()
            Button { showClearConfirm = true } label: {
                Image(systemName: "trash").foregroundColor(.red)
            }
        }
    }
    
    // MARK: Export — renders only the usable canvas area
    private func exportCanvas() {
        let img      = coordinator.exportAsImage()
        exportImage  = img
        showShareSheet = img != nil
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - PaperMarkupView (representable)

struct PaperMarkupView: UIViewControllerRepresentable {
    let canvasSize: CGSize
    let isEditable: Bool
    let markupDataURL: URL
    let coordinator: PaperMarkupCoordinator
    
    func makeCoordinator() -> PaperMarkupCoordinator { coordinator }
    
    func makeUIViewController(context: Context) -> PaperMarkupWrapperVC {
        let vc = PaperMarkupWrapperVC(
            canvasSize: canvasSize,
            isEditable: isEditable,
            markupDataURL: markupDataURL
        )
        context.coordinator.setWrapper(vc)
        return vc
    }
    
    func updateUIViewController(_ vc: PaperMarkupWrapperVC, context: Context) {
        vc.setEditable(isEditable)
    }
}

// MARK: - PaperMarkupWrapperVC

final class PaperMarkupWrapperVC: UIViewController,
                                  PaperMarkupViewController.Delegate,
                                  UIPopoverPresentationControllerDelegate {
    
    private var paperVC: PaperMarkupViewController!
    private var markupModel: PaperMarkup!
    private var toolPicker: PKToolPicker!
    private var isEditable: Bool
    private let canvasSize: CGSize
    private let markupDataURL: URL
    weak var coordinator: PaperMarkupCoordinator?
    
    init(canvasSize: CGSize, isEditable: Bool, markupDataURL: URL) {
        self.canvasSize    = canvasSize
        self.isEditable    = isEditable
        self.markupDataURL = markupDataURL
        super.init(nibName: nil, bundle: nil)
        markupModel = PaperMarkup(bounds: CGRect(origin: .zero, size: canvasSize))
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Transparent background — white comes from the SwiftUI layer below
        view.backgroundColor = .clear
        
        paperVC = PaperMarkupViewController(markup: markupModel, supportedFeatureSet: .latest)
        paperVC.view.backgroundColor = .clear
        view.addSubview(paperVC.view)
        addChild(paperVC); paperVC.didMove(toParent: self)
        
        paperVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            paperVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            paperVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            paperVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            paperVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        paperVC.zoomRange = 1.0...1.0   // zoom handled by outer ScrollView
        paperVC.delegate  = self
        
        toolPicker = PKToolPicker()
        toolPicker.addObserver(paperVC)
        toolPicker.selectedTool = PKInkingTool(.pen, color: .black, width: 3)
        
        loadMarkup()
    }
    
    override var canBecomeFirstResponder: Bool { isEditable }
    
    // MARK: Public API
    
    func setEditable(_ v: Bool) {
        isEditable = v
        paperVC.view.isUserInteractionEnabled = v
    }
    
    func activatePencil() {
        becomeFirstResponder()
        pencilKitResponderState.activeToolPicker = toolPicker
        pencilKitResponderState.toolPickerVisibility = .visible
    }
    
    func deactivatePencil() {
        pencilKitResponderState.toolPickerVisibility = .hidden
        resignFirstResponder()
        // Save immediately when pencil is put down — drawings don't trigger the delegate
        if let m = paperVC.markup { saveMarkup(m) }
    }
    
    /// Insert image directly into PaperMarkup so PaperKit owns layer order
    func insertImage(_ image: UIImage) {
        guard let cg = image.cgImage else { return }
        
        // Scale to fit inside canvas with max 320 pt on longest side
        let maxSide: CGFloat = 320
        let s = image.size
        let scale = min(maxSide / s.width, maxSide / s.height, 1.0)
        let w = s.width * scale, h = s.height * scale
        
        // Centre of canvas
        let frame = CGRect(
            x: canvasSize.width  / 2 - w / 2,
            y: canvasSize.height / 2 - h / 2,
            width: w, height: h
        )
        
        markupModel.insertNewImage(cg, frame: frame)
        paperVC.markup = markupModel
        saveMarkup(markupModel)
    }
    
    func presentAddMenu() {
        let editVC = MarkupEditViewController(supportedFeatureSet: .latest)
        editVC.delegate = paperVC as? any MarkupEditViewController.Delegate
        editVC.modalPresentationStyle = .popover
        if let pop = editVC.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.width - 40, y: 10, width: 1, height: 1)
            pop.permittedArrowDirections = [.up]
            pop.delegate = self
        }
        present(editVC, animated: true)
    }
    
    // Keep popover as popover on iPhone
    func adaptivePresentationStyle(for controller: UIPresentationController,
                                   traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        .none
    }
    
    func clearCanvas() {
        markupModel = PaperMarkup(bounds: CGRect(origin: .zero, size: canvasSize))
        paperVC.markup = markupModel
        saveMarkup(markupModel)
    }
    
    func undoLastAction() { paperVC.undoManager?.undo() }
    
    /// Export: uses drawHierarchy which flushes Metal/async rendering before capture
    func exportAsImage() -> UIImage {
        // Force a layout pass so everything is positioned correctly
        paperVC.view.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { _ in
            // White background
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: canvasSize))
            // drawHierarchy waits for screen updates — works with PaperKit's Metal renderer
            paperVC.view.drawHierarchy(
                in: CGRect(origin: .zero, size: canvasSize),
                afterScreenUpdates: true
            )
        }
    }
    
    /// Called by EntryEditorView when the user taps back — saves any unsaved drawings
    func forceSave() {
        if let m = paperVC?.markup { saveMarkup(m) }
    }
    
    // MARK: Delegate
    func paperMarkupViewControllerDidChangeMarkup(_ vc: PaperMarkupViewController) {
        guard let m = vc.markup else { return }
        markupModel = m; saveMarkup(m)
    }
    func paperMarkupViewControllerDidChangeSelection(_ vc: PaperMarkupViewController) {}
    func paperMarkupViewControllerDidBeginDrawing(_ vc: PaperMarkupViewController) {}
    func paperMarkupViewControllerDidChangeContentVisibleFrame(_ vc: PaperMarkupViewController) {}
    
    // PKToolPickerObserver — called when a stroke finishes
    // PaperKit forwards PKCanvasView delegate events; save after each stroke
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if let m = paperVC?.markup { saveMarkup(m) }
    }
    
    // MARK: Persistence
    private func loadMarkup() {
        guard FileManager.default.fileExists(atPath: markupDataURL.path) else { return }
        Task {
            do {
                let data   = try Data(contentsOf: markupDataURL)
                let loaded = try PaperMarkup(dataRepresentation: data)
                await MainActor.run {
                    self.markupModel = loaded
                    self.paperVC.markup = loaded
                }
            } catch { print("PaperKit load error:", error) }
        }
    }
    
    private func saveMarkup(_ markup: PaperMarkup) {
        Task {
            do {
                let data = try await markup.dataRepresentation()
                try data.write(to: markupDataURL, options: .atomic)
            } catch { print("PaperKit save error:", error) }
        }
    }
}

// MARK: - Coordinator

@Observable
final class PaperMarkupCoordinator {
    private weak var wrapperVC: PaperMarkupWrapperVC?
    var canvasSize: CGSize = .zero   // set by EntryEditorView via GeometryReader
    
    func setWrapper(_ vc: PaperMarkupWrapperVC) { wrapperVC = vc; vc.coordinator = self }
    
    func activatePencil()            { wrapperVC?.activatePencil() }
    func deactivatePencil()          { wrapperVC?.deactivatePencil() }
    func showAddMenu()               { wrapperVC?.presentAddMenu() }
    func insertImage(_ img: UIImage) { wrapperVC?.insertImage(img) }
    func clear()                     { wrapperVC?.clearCanvas() }
    func undo()                      { wrapperVC?.undoLastAction() }
    func forceSave()                 { wrapperVC?.forceSave() }
    func exportAsImage() -> UIImage? { wrapperVC?.exportAsImage() }
}

// MARK: - Preview
#Preview { JournalView() }
