//
//  HomeView.swift
//  PSI
//
//  Created by Raynara Coelho on 11/05/26.
//

import SwiftUI
import MapKit

// MARK: - Models

struct Experience: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let category: Category
    let distanceKm: Double
    let description: String
    let price: String
    let location: String
}

enum Category: String, CaseIterable, Identifiable {
    case criar = "Criar"
    case mover = "Mover"
    case aprender = "Aprender"
    case celebrar = "Celebrar"
    case explorar = "Explorar"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .criar:    return Color(hex: "FFB5C8") // rosa
        case .mover:    return Color(hex: "FFD97D") // amarelo
        case .aprender: return Color(hex: "A8E6CF") // verde menta
        case .celebrar: return Color(hex: "B5C8FF") // azul lavanda
        case .explorar: return Color(hex: "FFB5A0") // pêssego
        }
    }
}

// MARK: - Sample Data

let sampleExperiences: [Experience] = [
    Experience(title: "Music Show", imageName: "music_show", category: .celebrar, distanceKm: 2.0,
               description: "Um show de música ao vivo com artistas locais incríveis no Rimberio Stadium.", price: "R$ 40", location: "Rimberio Stadium, Fortaleza"),
    Experience(title: "Workshop", imageName: "workshop", category: .aprender, distanceKm: 10.0,
               description: "Workshop de marketing digital para iniciantes e profissionais.", price: "R$ 80", location: "Digital Start, Fortaleza"),
    Experience(title: "Reading Club", imageName: "reading_club", category: .criar, distanceKm: 0.4,
               description: "Clube do livro semanal com discussões ricas e café.", price: "Gratuito", location: "Café Literário, Fortaleza"),
    Experience(title: "Marché", imageName: "marche", category: .explorar, distanceKm: 50.0,
               description: "Feira de criadores com cerâmica, flores, velas e objetos de decoração.", price: "Gratuito", location: "Centro, Fortaleza"),
    Experience(title: "Art Classes", imageName: "art_classes", category: .criar, distanceKm: 3.2,
               description: "Aulas de arte para todas as idades com foco em expressão livre.", price: "R$ 60", location: "Ateliê Cores, Fortaleza"),
    Experience(title: "Speak Now", imageName: "speak_now", category: .aprender, distanceKm: 1.5,
               description: "Noite de inglês conversacional em ambiente descontraído.", price: "R$ 25", location: "The Hub, Fortaleza"),
]

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct HomeView: View {
    @State private var selectedCategory: Category? = nil
    @State private var showLocationSheet = false
    @State private var showFilterSheet = false
    @State private var selectedCity = "Fortaleza, Ceará"
    @State private var selectedExperience: Experience? = nil
    @State private var maxDistance: Double = 100
    @State private var maxPrice: Double = 200
    
    var filteredExperiences: [Experience] {
        sampleExperiences.filter { exp in
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
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding()
                    
                    // MARK: Header
                    HStack(alignment: .center) {
                        // Location Button
                        Button {
                            showLocationSheet = true
                        } label: {
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
                        // Filter Button
                        Button {
                            showFilterSheet = true
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .padding(.leading, 12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    
                    // MARK: Category Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            // All
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedCategory = nil
                                }
                            } label: {
                                Text("Todos")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedCategory == nil
                                        ? Color.primary
                                        : Color(.gray)
                                    )
                                    .foregroundColor(
                                        selectedCategory == nil
                                        ? Color(.white)
                                        : .primary
                                    )
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
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 10)
                                        .background(
                                            selectedCategory == cat
                                            ? cat.color
                                            : cat.color.opacity(0.35)
                                        )
                                        .foregroundColor(.primary)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(
                                                    selectedCategory == cat ? cat.color : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                    
                    // MARK: Asymmetric Grid
                    AsymmetricGrid(experiences: filteredExperiences) { experience in
                        selectedExperience = experience
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 100)
                }
            }
            .background(Color(.white))
            .navigationBarHidden(true)
        }
        
        // MARK: Location Sheet
        .sheet(isPresented: $showLocationSheet) {
            LocationPickerSheet(selectedCity: $selectedCity)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        
        // MARK: Filter Sheet
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(maxDistance: $maxDistance, maxPrice: $maxPrice)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        
        // MARK: Detail Sheet
        .sheet(item: $selectedExperience) { experience in
            ExperienceDetailView(experience: experience)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

struct FilterSheet: View {
    @Binding var maxDistance: Double
    @Binding var maxPrice: Double
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Distância máxima")
                                .font(.system(size: 15, weight: .medium))
                            Spacer()
                            Text(maxDistance < 100 ? "\(Int(maxDistance)) km" : "Qualquer")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $maxDistance, in: 1...100, step: 1)
                            .accentColor(.primary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Distância")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Preço máximo")
                                .font(.system(size: 15, weight: .medium))
                            Spacer()
                            Text(maxPrice < 200 ? "R$ \(Int(maxPrice))" : "Qualquer")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $maxPrice, in: 0...200, step: 10)
                            .accentColor(.primary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Preço")
                }
                
                Section {
                    Button {
                        maxDistance = 100
                        maxPrice = 200
                    } label: {
                        Text("Limpar filtros")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Aplicar") { dismiss() }
                        .fontWeight(.semibold)
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
        let leftColumn = stride(from: 0, to: experiences.count, by: 2).map { experiences[$0] }
        let rightColumn = stride(from: 1, to: experiences.count, by: 2).map { experiences[$0] }
        
        HStack(alignment: .top, spacing: 10) {
            // Left column — cards maiores
            LazyVStack(spacing: 10) {
                ForEach(leftColumn) { exp in
                    ExperienceCard(experience: exp, isLarge: true)
                        .onTapGesture { onTap(exp) }
                }
            }
            
            // Right column — cards menores
            LazyVStack(spacing: 10) {
                ForEach(rightColumn) { exp in
                    ExperienceCard(experience: exp, isLarge: false)
                        .onTapGesture { onTap(exp) }
                }
            }
        }
    }
}

// MARK: - Experience Card

struct ExperienceCard: View {
    let experience: Experience
    let isLarge: Bool
    
    var cardHeight: CGFloat {
        isLarge ? 280 : 220
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Image placeholder (usa SF Symbol como placeholder)
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(experience.category.color.opacity(0.25))
                    .frame(height: cardHeight)
                
                VStack(spacing: 8) {
                    Image(systemName: categoryIcon(experience.category))
                        .font(.system(size: isLarge ? 48 : 36))
                        .foregroundColor(experience.category.color)
                    Text(experience.title)
                        .font(.system(size: isLarge ? 18 : 15, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Info row
            HStack(spacing: 6) {
                Circle()
                    .fill(experience.category.color)
                    .frame(width: 10, height: 10)
                
                Text(experience.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                Text(distanceLabel(experience.distanceKm))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
    }
    
    func distanceLabel(_ km: Double) -> String {
        if km < 1 {
            return "~\(Int(km * 1000))m"
        } else {
            return "~\(km < 10 ? String(format: "%.0f", km) : String(Int(km)))km"
        }
    }
    
    func categoryIcon(_ category: Category) -> String {
        switch category {
        case .criar:    return "paintbrush.pointed.fill"
        case .mover:    return "figure.run"
        case .aprender: return "book.fill"
        case .celebrar: return "music.note"
        case .explorar: return "binoculars.fill"
        }
    }
}

// MARK: - Experience Detail View

struct ExperienceDetailView: View {
    let experience: Experience
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                
                // Hero
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(experience.category.color.opacity(0.3))
                        .frame(height: 300)
                        .overlay(
                            Image(systemName: categoryIcon(experience.category))
                                .font(.system(size: 80))
                                .foregroundColor(experience.category.color)
                        )
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white, Color(.systemGray3))
                            .padding()
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Category tag
                    HStack {
                        Text(experience.category.rawValue.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.5)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(experience.category.color)
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        // Distance badge
                        Label(distanceLabel(experience.distanceKm), systemImage: "location.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    // Title
                    Text(experience.title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    // Location
                    Label(experience.location, systemImage: "mappin")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    // Description
                    Text(experience.description)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                    
                    Divider()
                    
                    // Price
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Investimento")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(experience.price)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        
                        // CTA
                        Button {
                            // action
                        } label: {
                            Text("Quero ir")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
                                .background(Color.primary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(24)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
    
    func distanceLabel(_ km: Double) -> String {
        km < 1 ? "~\(Int(km * 1000))m" : "~\(Int(km))km"
    }
    
    func categoryIcon(_ category: Category) -> String {
        switch category {
        case .criar:    return "paintbrush.pointed.fill"
        case .mover:    return "figure.run"
        case .aprender: return "book.fill"
        case .celebrar: return "music.note"
        case .explorar: return "binoculars.fill"
        }
    }
}

// MARK: - Location Picker Sheet

struct LocationPickerSheet: View {
    @Binding var selectedCity: String
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var searchResults: [MKLocalSearchCompletion] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
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
}
