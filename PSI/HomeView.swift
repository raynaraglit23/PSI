//
//  HomeView.swift
//  PSI

import SwiftUI
import MapKit

// MARK: - Models

struct Experience: Identifiable, Codable {
    let id: UUID
    let title: String
    let imageName: String
    let imageURL: URL?
    let category: Category
    let distanceKm: Double
    let description: String
    let price: String
    let location: String
    let date: String?   // optional — not all events have a confirmed date
}

enum Category: String, CaseIterable, Identifiable, Codable {
    case criar    = "Criar"
    case mover    = "Mover"
    case aprender = "Aprender"
    case celebrar = "Celebrar"
    case explorar = "Explorar"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .criar:    return Color(hex: "FFB5C8")
        case .mover:    return Color(hex: "FFD97D")
        case .aprender: return Color(hex: "A8E6CF")
        case .celebrar: return Color(hex: "B5C8FF")
        case .explorar: return Color(hex: "FFB5A0")
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB,
                  red:     Double(r)/255,
                  green:   Double(g)/255,
                  blue:    Double(b)/255,
                  opacity: Double(a)/255)
    }
}

// MARK: - HomeView

struct HomeView: View {
    @State private var viewModel       = HomeViewModel()
    @State private var locationManager = LocationManager()
    @State private var selectedCategory: Category? = nil
    @State private var showLocationSheet = false
    @State private var showFilterSheet   = false
    @State private var selectedCity      = "Fortaleza, Ceará"
    @State private var selectedExperience: Experience? = nil
    @State private var maxDistance: Double = 100
    @State private var maxPrice: Double    = 200

    var filteredExperiences: [Experience] {
        viewModel.experiences.filter { exp in
            let categoryMatch = selectedCategory == nil || exp.category == selectedCategory
            let distanceMatch = exp.distanceKm <= maxDistance
            return categoryMatch && distanceMatch
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Lore")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .padding()

                    // Header — location + filter
                    HStack(alignment: .center) {
                        Button { showLocationSheet = true } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 13, weight: .medium))
                                Text(selectedCity)
                                    .font(.system(size: 14, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button { showFilterSheet = true } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .padding(.leading, 12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // Category chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            Button {
                                withAnimation(.spring(response: 0.3)) { selectedCategory = nil }
                            } label: {
                                Text("Todos")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .padding(.horizontal, 18).padding(.vertical, 10)
                                    .background(selectedCategory == nil ? Color.primary : Color(.gray))
                                    .foregroundColor(selectedCategory == nil ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            ForEach(Category.allCases) { cat in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedCategory = selectedCategory == cat ? nil : cat
                                    }
                                } label: {
                                    Text(cat.rawValue)
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .padding(.horizontal, 18).padding(.vertical, 10)
                                        .background(selectedCategory == cat
                                                    ? cat.color : cat.color.opacity(0.35))
                                        .foregroundColor(.primary)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(
                                            selectedCategory == cat ? cat.color : .clear,
                                            lineWidth: 2))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)

                    if viewModel.isLoading && viewModel.experiences.isEmpty {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Carregando eventos culturais...")
                                .font(.system(size: 14, weight: .medium)).foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20).padding(.bottom, 16)
                    }

                    if let err = viewModel.errorMessage, viewModel.experiences.isEmpty {
                        Text(err).font(.system(size: 14)).foregroundColor(.secondary)
                            .padding(.horizontal, 20).padding(.bottom, 16)
                    }

                    AsymmetricGrid(experiences: filteredExperiences) { selectedExperience = $0 }
                        .padding(.horizontal, 14).padding(.bottom, 100)
                }
            }
            .background(Color.white)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showLocationSheet) {
            LocationPickerSheet(selectedCity: $selectedCity)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(maxDistance: $maxDistance, maxPrice: $maxPrice)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedExperience) { experience in
            ExperienceDetailView(experience: experience)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .task {
            await viewModel.loadExperiences()
            locationManager.requestWhenInUseAuthorization()
            viewModel.updateUserCoordinate(locationManager.userCoordinate)
        }
        .onChange(of: locationManager.userCoordinate?.latitude) { _, _ in
            viewModel.updateUserCoordinate(locationManager.userCoordinate)
        }
    }
}

// MARK: - Location Picker Sheet

struct LocationPickerSheet: View {
    @Binding var selectedCity: String
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    var completer = CitySearchCompleter()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Buscar cidade...", text: $searchText)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onChange(of: searchText) { _, new in
                            completer.search(query: new)
                        }
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            completer.results = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if completer.results.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView(
                        "Nenhum resultado",
                        systemImage: "mappin.slash",
                        description: Text("Tente outro nome de cidade ou estado.")
                    )
                    .padding(.top, 40)
                    Spacer()
                } else {
                    List(completer.results, id: \.self) { result in
                        Button {
                            let full = [result.title, result.subtitle]
                                .filter { !$0.isEmpty }
                                .joined(separator: ", ")
                            selectedCity = full
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(result.title)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                if !result.subtitle.isEmpty {
                                    Text(result.subtitle)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Escolher cidade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}

// MARK: - City Search Completer
@Observable
final class CitySearchCompleter: NSObject, MKLocalSearchCompleterDelegate {
    var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate  = self
        // .address gives city-level results; avoids noisy POI names
        completer.resultTypes = .address
    }

    func search(query: String) {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { results = []; return }
        completer.queryFragment = q
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            // Keep only results that have a subtitle (state/country) — city-like entries
            self.results = completer.results.filter { !$0.subtitle.isEmpty }
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("LocationCompleter error:", error.localizedDescription)
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Binding var maxDistance: Double
    @Binding var maxPrice: Double
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Distância") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Distância máxima").font(.system(size: 15, weight: .medium))
                            Spacer()
                            Text(maxDistance < 100 ? "\(Int(maxDistance)) km" : "Qualquer")
                                .font(.system(size: 14, weight: .semibold)).foregroundColor(.secondary)
                        }
                        Slider(value: $maxDistance, in: 1...100, step: 1).accentColor(.primary)
                    }
                    .padding(.vertical, 4)
                }
                Section("Preço") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Preço máximo").font(.system(size: 15, weight: .medium))
                            Spacer()
                            Text(maxPrice < 200 ? "R$ \(Int(maxPrice))" : "Qualquer")
                                .font(.system(size: 14, weight: .semibold)).foregroundColor(.secondary)
                        }
                        Slider(value: $maxPrice, in: 0...200, step: 10).accentColor(.primary)
                    }
                    .padding(.vertical, 4)
                }
                Section {
                    Button { maxDistance = 100; maxPrice = 200 } label: {
                        Text("Limpar filtros").foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Aplicar") { dismiss() }.fontWeight(.semibold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Asymmetric Grid

struct AsymmetricGrid: View {
    let experiences: [Experience]
    let onTap: (Experience) -> Void

    var body: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 10
            let columnWidth = max((proxy.size.width - spacing) / 2, 0)
            let columns = MasonryLayout.makeColumns(from: experiences)

            HStack(alignment: .top, spacing: spacing) {
                ForEach(columns) { column in
                    LazyVStack(spacing: spacing) {
                        ForEach(column.items) { item in
                            ExperienceCard(experience: item.experience, style: item.style)
                                .frame(width: columnWidth)
                                .onTapGesture { onTap(item.experience) }
                        }
                    }
                    .frame(width: columnWidth, alignment: .top)
                }
            }
            .frame(width: proxy.size.width, alignment: .top)
        }
        .frame(height: MasonryLayout.totalHeight(for: experiences))
    }
}

private struct MasonryLayout {
    static func makeColumns(from experiences: [Experience]) -> [MasonryColumn] {
        var columns = [
            MasonryColumn(id: 0, items: [], totalHeight: 0),
            MasonryColumn(id: 1, items: [], totalHeight: 0)
        ]
        for (index, experience) in experiences.enumerated() {
            let style = ExperienceCardStyle.style(for: experience, index: index)
            let item  = MasonryItem(experience: experience, style: style)
            let dest  = columns[0].totalHeight <= columns[1].totalHeight ? 0 : 1
            columns[dest].items.append(item)
            columns[dest].totalHeight += style.totalHeight + 10
        }
        return columns
    }

    static func totalHeight(for experiences: [Experience]) -> CGFloat {
        makeColumns(from: experiences).map(\.totalHeight).max() ?? 0
    }
}

private struct MasonryColumn: Identifiable {
    let id: Int
    var items: [MasonryItem]
    var totalHeight: CGFloat
}

private struct MasonryItem: Identifiable {
    let experience: Experience
    let style: ExperienceCardStyle
    var id: UUID { experience.id }
}

enum ExperienceCardStyle {
    case tall, medium, compact

    static let interItemSpacing: CGFloat = 6
    static let infoRowHeight: CGFloat    = 22

    var mediaHeight: CGFloat {
        switch self { case .tall: return 280; case .medium: return 240; case .compact: return 205 }
    }
    var totalHeight: CGFloat { mediaHeight + Self.interItemSpacing + Self.infoRowHeight }

    static func style(for experience: Experience, index: Int) -> ExperienceCardStyle {
        switch (abs(experience.title.hashValue) + index) % 3 {
        case 0: return .tall; case 1: return .medium; default: return .compact
        }
    }
}

// MARK: - Experience Card

struct ExperienceCard: View {
    let experience: Experience
    let style: ExperienceCardStyle

    var body: some View {
        VStack(alignment: .leading, spacing: ExperienceCardStyle.interItemSpacing) {
            // Image + date badge overlay
            ZStack(alignment: .topTrailing) {
                RemoteExperienceImage(
                    imageURL: experience.imageURL,
                    fallbackSystemName: experience.imageName,
                    accentColor: experience.category.color,
                    cornerRadius: 16,
                    style: .gridCard
                )
                .frame(height: style.mediaHeight)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .clipped()

                // Date badge — only shown when date is available
                if let date = experience.date, !date.isEmpty {
                    Text(date)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(8)
                }
            }

            HStack(spacing: 6) {
                Circle().fill(experience.category.color).frame(width: 10, height: 10)
                Text(experience.title)
                    .font(.system(size: 13, weight: .semibold)).lineLimit(1)
                Spacer()
                Text(distanceLabel(experience.distanceKm))
                    .font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
            }
            .frame(height: ExperienceCardStyle.infoRowHeight, alignment: .center)
            .padding(.horizontal, 4)
        }
        .frame(height: style.totalHeight, alignment: .top)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .clipped()
    }

    private func distanceLabel(_ km: Double) -> String {
        km < 1 ? "~\(Int(km * 1000))m" : "~\(km < 10 ? String(format: "%.0f", km) : String(Int(km)))km"
    }
}

// MARK: - Experience Detail View

struct ExperienceDetailView: View {
    let experience: Experience
    @Environment(\.dismiss) var dismiss
    @Environment(SavedEventsStore.self) private var savedEvents

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    RemoteExperienceImage(
                        imageURL: experience.imageURL,
                        fallbackSystemName: experience.imageName,
                        accentColor: experience.category.color,
                        cornerRadius: 0,
                        style: .detailHero
                    )
                    .frame(height: 300)

                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white, Color(.systemGray3))
                            .padding()
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(experience.category.rawValue.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.5).padding(.horizontal, 12).padding(.vertical, 5)
                            .background(experience.category.color).clipShape(Capsule())
                        Spacer()
                        Label(distanceLabel(experience.distanceKm), systemImage: "location.fill")
                            .font(.system(size: 13, weight: .medium)).foregroundColor(.secondary)
                    }

                    Text(experience.title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))

                    Label(experience.location, systemImage: "mappin")
                        .font(.system(size: 14)).foregroundColor(.secondary)
                    if let date = experience.date, !date.isEmpty {
                        Label(date, systemImage: "calendar")
                            .font(.system(size: 14)).foregroundColor(.secondary)
                    }

                    Divider()

                    Text(experience.description)
                        .font(.system(size: 16)).lineSpacing(4)

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Investimento")
                                .font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                            Text(experience.price)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                        }
                        Spacer()
                        let isSaved = savedEvents.isSaved(experience)
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                savedEvents.toggleSave(for: experience)
                            }
                        } label: {
                            Text(isSaved ? "Salvo" : "Quero ir")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(isSaved ? .primary : .white)
                                .padding(.horizontal, 32).padding(.vertical, 14)
                                .background(isSaved ? Color(.systemGray5) : Color.primary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(24)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    private func distanceLabel(_ km: Double) -> String {
        km < 1 ? "~\(Int(km * 1000))m" : "~\(Int(km))km"
    }
}
