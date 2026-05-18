// JournalView.swift
// Requires: iOS 26+, Xcode 26+, PaperKit + PencilKit frameworks

import SwiftUI
import PaperKit
import PencilKit
import PhotosUI

// MARK: - Journal List View

struct JournalView: View {
    @State private var entries: [JournalEntry] = []
    @State private var selectedEntry: JournalEntry? = nil
    @State private var entryToRename: JournalEntry? = nil
    @State private var renameText = ""
    @State private var showRenameAlert = false
    
    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    entryList
                }
            }
            .navigationTitle("Diário")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        let entry = JournalEntry(
                            title: "",
                            date: Date()
                        )
                        entries.insert(entry, at: 0)
                        selectedEntry = entry
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 17, weight: .medium))
                    }
                }
            }
            .sheet(item: $selectedEntry) { entry in
                EntryEditorView(entry: binding(for: entry))
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .alert("Renomear entrada", isPresented: $showRenameAlert) {
                TextField("Título", text: $renameText)
                Button("Salvar") {
                    if let id = entryToRename?.id,
                       let idx = entries.firstIndex(where: { $0.id == id }) {
                        entries[idx].title = renameText
                    }
                }
                Button("Cancelar", role: .cancel) {}
            }
        }
    }
    
    // MARK: Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 52))
                .foregroundColor(Color(.systemGray3))
            
            Text("Nenhuma entrada ainda")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Toque em  para criar seu primeiro registro de experiência.")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: Entry List
    
    private var entryList: some View {
        List {
            ForEach(entries) { entry in
                Button {
                    selectedEntry = entry
                } label: {
                    EntryRowView(entry: entry)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color(.secondarySystemGroupedBackground))
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        entryToRename = entry
                        renameText = entry.title
                        showRenameAlert = true
                    } label: {
                        Label("Renomear", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
            .onDelete { indexSet in
                entries.remove(atOffsets: indexSet)
            }
        }
        .listStyle(.insetGrouped)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: Helpers
    
    private func binding(for entry: JournalEntry) -> Binding<JournalEntry> {
        guard let idx = entries.firstIndex(where: { $0.id == entry.id }) else {
            return .constant(entry)
        }
        return $entries[idx]
    }
}

// MARK: - Entry Row

struct EntryRowView: View {
    let entry: JournalEntry
    
    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(dayString(entry.date))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(monthString(entry.date))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            .frame(width: 44)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title.isEmpty ? "Sem título" : entry.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(timeString(entry.date))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(.systemGray3))
        }
        .padding(.vertical, 4)
    }
    
    private func dayString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d"; return f.string(from: date)
    }
    private func monthString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        f.locale = Locale(identifier: "pt_BR")
        return f.string(from: date)
    }
    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

struct EntryEditorView: View {
    @Binding var entry: JournalEntry
    @Environment(\.dismiss) var dismiss
    
    @State private var coordinator = PaperMarkupCoordinator()
    @State private var isPencilActive = false
    @State private var showClearConfirm = false
    
    // Controles de Foto e Câmera
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showCamera = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    //O Canvas
                    PaperMarkupView(
                        canvasSize: geometry.size,
                        isEditable: true,
                        markupDataURL: entry.markupDataURL,
                        coordinator: coordinator
                    )
                    
                    //Gestos (Zoom, Arrastar, Apagar e Duplicar)
                    ForEach($entry.attachedPhotos) { $photo in
                        if let uiImage = loadImage(fileName: photo.fileName) {
                            DraggablePhotoView(
                                photo: $photo,
                                uiImage: uiImage,
                                onDelete: {
                                    deletePhoto(photo)
                                },
                                onDuplicate: {
                                    duplicatePhoto(photo, originalImage: uiImage)
                                }
                            )
                            .zIndex(photo.scale)
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                        .fontWeight(.medium)
                }
                
                //Plus pencil
                ToolbarItemGroup(placement: .primaryAction) {
                    //Undo
                    Button {
                        coordinator.undo()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .fontWeight(.semibold)
                    }
                    //popover
                    Button {
                        if isPencilActive {
                            isPencilActive = false
                            coordinator.deactivatePencil()
                        }
                        coordinator.showAddMenu()
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    
                    //pencil
                    Button {
                        isPencilActive.toggle()
                        if isPencilActive {
                            coordinator.activatePencil()
                        } else {
                            coordinator.deactivatePencil()
                        }
                    } label: {
                        Image(systemName: isPencilActive ? "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle")
                            .foregroundColor(isPencilActive ? .blue : .primary)
                    }
                }
                
                //Barra inferior
                ToolbarItemGroup(placement: .bottomBar) {
                    //Câmera
                    Button { showCamera = true } label: {
                        Image(systemName: "camera")
                    }
                    //Galeria
                    Button { showPhotoPicker = true } label: {
                        Image(systemName: "photo")
                    }
                    //Lixo
                    Button { showClearConfirm = true } label: {
                        Image(systemName: "trash").foregroundColor(.red)
                    }
                }
            }
            // foto da galeria
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        // Usa a nova função direta!
                        coordinator.insertImage(uiImage)
                        selectedPhotoItem = nil
                    }
                }
            }
            // ── PROCESSA A FOTO DA CÂMERA ──
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker(image: Binding(
                    get: { nil },
                    set: { newImage in
                        if let img = newImage {
                            coordinator.insertImage(img)
                        }
                    }
                ))
                .ignoresSafeArea()
            }
        }
    }
    
    // MARK: - Helpers de Imagem
    
    private func saveAndInjectImage(_ uiImage: UIImage) {
        let fileName = UUID().uuidString + ".jpg"
        let supportDir = JournalEntry.storageURL(for: entry.id).deletingLastPathComponent()
        let fileURL = supportDir.appendingPathComponent(fileName)
        
        if let data = uiImage.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
            let newPhoto = CanvasPhoto(
                position: CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY),
                fileName: fileName,
                scale: 1.0 // Tamanho inicial
            )
            entry.attachedPhotos.append(newPhoto)
        }
    }
    
    private func loadImage(fileName: String) -> UIImage? {
        let supportDir = JournalEntry.storageURL(for: entry.id).deletingLastPathComponent()
        let fileURL = supportDir.appendingPathComponent(fileName)
        if let data = try? Data(contentsOf: fileURL) { return UIImage(data: data) }
        return nil
    }
    
    private func deletePhoto(_ photo: CanvasPhoto) {
        entry.attachedPhotos.removeAll { $0.id == photo.id }
        let supportDir = JournalEntry.storageURL(for: entry.id).deletingLastPathComponent()
        let fileURL = supportDir.appendingPathComponent(photo.fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
    private func duplicatePhoto(_ photo: CanvasPhoto, originalImage: UIImage) {
        let newFileName = UUID().uuidString + ".jpg"
        let supportDir = JournalEntry.storageURL(for: entry.id).deletingLastPathComponent()
        let fileURL = supportDir.appendingPathComponent(newFileName)

        if let data = originalImage.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
            
            let newPhoto = CanvasPhoto(
                position: CGPoint(x: photo.position.x + 30, y: photo.position.y + 30),
                fileName: newFileName,
                scale: photo.scale
            )
            
            // Adiciona no final da lista
            entry.attachedPhotos.append(newPhoto)
        }
    }
}

// MARK: - View Secundária para Controlar os Gestos da Foto
struct DraggablePhotoView: View {
    @Binding var photo: CanvasPhoto
    let uiImage: UIImage
    let onDelete: () -> Void
    let onDuplicate: () -> Void // Nova ação
    
    @State private var currentMagnify: CGFloat = 1.0
    
    var body: some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
            .frame(width: 250)
            .padding(12)
        // Aplica a escala salva multiplicada pelo zoom atual
            .scaleEffect(photo.scale * currentMagnify)
            .position(photo.position)
        
        // ── MENU DE CONTEXTO (Segurar para abrir) ──
            .contextMenu {
                Button {
                    onDuplicate()
                } label: {
                    Label("Duplicar", systemImage: "plus.square.on.square")
                }
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Excluir", systemImage: "trash")
                }
            }
        
        //arrastar
            .gesture(
                DragGesture()
                    .onChanged { value in
                        photo.position = value.location
                    }
            )
        
        //zoom
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        currentMagnify = value
                    }
                    .onEnded { value in
                        photo.scale *= value
                        currentMagnify = 1.0
                    }
            )
    }
}

// MARK: - Camera Wrapper
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        // Importante: Checa se a câmera está disponível (previne crash no Simulador)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - PaperMarkupView (UIViewControllerRepresentable)

struct PaperMarkupView: UIViewControllerRepresentable {
    let canvasSize: CGSize
    let isEditable: Bool
    let markupDataURL: URL
    let coordinator: PaperMarkupCoordinator
    
    func makeCoordinator() -> PaperMarkupCoordinator { coordinator }
    
    func makeUIViewController(context: Context) -> PaperMarkupWrapperViewController {
        let vc = PaperMarkupWrapperViewController(
            canvasSize: canvasSize,
            isEditable: isEditable,
            markupDataURL: markupDataURL
        )
        context.coordinator.setWrapperViewController(vc)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: PaperMarkupWrapperViewController,
                                context: Context) {
        uiViewController.setCanvasEditable(isEditable)
    }
}

// MARK: - PaperMarkupWrapperViewController

class PaperMarkupWrapperViewController: UIViewController,
                                        PaperMarkupViewController.Delegate, UIPopoverPresentationControllerDelegate{
    
    // MARK: - Properties
    private var paperVC: PaperMarkupViewController!
    private var markupModel: PaperMarkup!
    private var toolPicker: PKToolPicker!
    private var isEditable: Bool
    private let canvasSize: CGSize
    private let markupDataURL: URL
    
    weak var coordinator: PaperMarkupCoordinator?
    
    // MARK: - Init
    init(canvasSize: CGSize, isEditable: Bool, markupDataURL: URL) {
        self.canvasSize = canvasSize
        self.isEditable = isEditable
        self.markupDataURL = markupDataURL
        super.init(nibName: nil, bundle: nil)
        setupMarkupModel()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPaperVC()
        setupToolPicker()
    }
    
    override var canBecomeFirstResponder: Bool { isEditable }
    
    // MARK: - Setup
    private func setupMarkupModel() {
        markupModel = PaperMarkup(bounds: CGRect(origin: .zero, size: canvasSize))
    }
    
    private func setupPaperVC() {
        paperVC = PaperMarkupViewController(
            markup: markupModel,
            supportedFeatureSet: .latest   // drawing, shapes, images, text, audio
        )
        
        // Embed as child VC
        view.addSubview(paperVC.view)
        addChild(paperVC)
        paperVC.didMove(toParent: self)
        
        paperVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            paperVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            paperVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            paperVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            paperVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        paperVC.zoomRange = 0.25...4.0
        paperVC.delegate = self
        
        loadMarkup()
    }
    
    private func setupToolPicker() {
        toolPicker = PKToolPicker()
        toolPicker.addObserver(paperVC)
        toolPicker.selectedTool = PKInkingTool(.pen, color: .black, width: 3)
    }
    
    // MARK: - Public API
    func setCanvasEditable(_ editable: Bool) {
        isEditable = editable
        paperVC.view.isUserInteractionEnabled = editable
    }
    
    func activatePencil() {
        pencilKitResponderState.activeToolPicker = toolPicker
        pencilKitResponderState.toolPickerVisibility = .visible
        becomeFirstResponder()
    }
    
    func deactivatePencil() {
        pencilKitResponderState.toolPickerVisibility = .hidden
        resignFirstResponder()
    }
    // MARK: - Inserção Direta Nativa (API do PaperKit)
    
    func insertImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let maxDimension: CGFloat = 300.0
        let imageSize = image.size

        let scale = min(maxDimension / imageSize.width, maxDimension / imageSize.height)
        let newWidth = imageSize.width * scale
        let newHeight = imageSize.height * scale
        
        let centerX = canvasSize.width / 2
        let centerY = canvasSize.height / 2
        
        let frame = CGRect(
            x: centerX - (newWidth / 2),
            y: centerY - (newHeight / 2),
            width: newWidth,
            height: newHeight
        )
        
        markupModel.insertNewImage(cgImage, frame: frame)
        
        paperVC.markup = markupModel
        
        saveMarkup(markupModel)
    }
    
    func presentAddMenu() {
        let editVC = MarkupEditViewController(supportedFeatureSet: .latest)
        editVC.delegate = paperVC as? any MarkupEditViewController.Delegate
        
        editVC.modalPresentationStyle = .popover // Define como popover
        
        if let popover = editVC.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.width - 40, y: 10, width: 1, height: 1)
            popover.permittedArrowDirections = [.up]
            
            // ISSO FAZ A MÁGICA DE NÃO VIRAR SHEET NO IPHONE
            popover.delegate = self
        }
        
        present(editVC, animated: true)
    }
    // MARK: - UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func clearCanvas() {
        setupMarkupModel()

        paperVC.markup = markupModel
        
        saveMarkup(markupModel)
    }
    
    func undoLastAction() {
        paperVC.undoManager?.undo()
    }
    
    // MARK: - PaperMarkupViewController.Delegate
    func paperMarkupViewControllerDidChangeMarkup(_ vc: PaperMarkupViewController) {
        guard let markup = vc.markup else { return }
        saveMarkup(markup)
    }
    
    func paperMarkupViewControllerDidChangeSelection(_ vc: PaperMarkupViewController) {}
    
    func paperMarkupViewControllerDidBeginDrawing(_ vc: PaperMarkupViewController) {}
    
    func paperMarkupViewControllerDidChangeContentVisibleFrame(_ vc: PaperMarkupViewController) {}
    
    // MARK: - Persistence
    private func loadMarkup() {
        guard FileManager.default.fileExists(atPath: markupDataURL.path) else { return }
        Task {
            do {
                let data = try Data(contentsOf: markupDataURL)
                let loaded = try PaperMarkup(dataRepresentation: data)
                await MainActor.run {
                    self.paperVC.markup = loaded
                    self.markupModel = loaded
                }
            } catch {
                print("PaperKit load error: \(error)")
            }
        }
    }
    
    private func saveMarkup(_ markup: PaperMarkup) {
        Task {
            do {
                let data = try await markup.dataRepresentation()
                try data.write(to: markupDataURL, options: .atomic)
            } catch {
                print("PaperKit save error: \(error)")
            }
        }
    }
}

// MARK: - Coordinator

@Observable
class PaperMarkupCoordinator {
    private weak var wrapperVC: PaperMarkupWrapperViewController?
    
    func setWrapperViewController(_ vc: PaperMarkupWrapperViewController) {
        wrapperVC = vc
        vc.coordinator = self
    }
    
    func activatePencil()   { wrapperVC?.activatePencil() }
    func deactivatePencil() { wrapperVC?.deactivatePencil() }
    func showAddMenu()      { wrapperVC?.presentAddMenu() }
    func insertImage(_ image: UIImage) {
        wrapperVC?.insertImage(image)
    }
    func clear()            { wrapperVC?.clearCanvas() }
    func undo()             { wrapperVC?.undoLastAction() }
}


#Preview {
    JournalView()
}
