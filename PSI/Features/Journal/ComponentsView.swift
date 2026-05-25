import SwiftUI
import PhotosUI
// MARK: - Profile Card

struct ProfileCardView: View {
    // Persistência automática no UserDefaults
    @AppStorage("profileName") private var name: String = "Kelly"
    @AppStorage("profileDescription") private var description: String = "cool girl and vibes"
    
    // Estados do Picker e da Imagem
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var profileImage: Image? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .topLeading) {
                // PhotosPicker transformado em botão
                PhotosPicker(selection: $photoItem, matching: .images) {
                    if let profileImage {
                        profileImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(Color(.systemGray4))
                            .clipShape(Circle())
                    }
                }
                
                Rectangle()
                    .fill(Color(red: 0.82, green: 0.74, blue: 0.67))
                    .frame(width: 45, height: 16)
                    .rotationEffect(.degrees(-20))
                    .offset(x: -5, y: -5)
                    .allowsHitTesting(false) // Deixa o clique passar para a imagem
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    TextField("Nome", text: $name)
                        .font(.system(size: 24, weight: .bold, design: .serif))
                    Image(systemName: "sparkles")
                }
                
                TextField("Descrição", text: $description)
                    .font(.system(size: 15))
                    .foregroundColor(.primary.opacity(0.7))
                
                Divider()
            }
            Spacer()
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
        // Lógica para carregar a imagem quando a tela abre
        .onAppear { loadProfileImage() }
        // Lógica para quando o usuário escolhe uma nova foto
        .onChange(of: photoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    saveProfileImage(data)
                    if let uiImage = UIImage(data: data) {
                        profileImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }
    
    // MARK: - Funções de Persistência da Imagem
    private var imageURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("profile_avatar.jpg")
    }
    
    private func saveProfileImage(_ data: Data) {
        try? data.write(to: imageURL, options: .atomic)
    }
    
    private func loadProfileImage() {
        if let data = try? Data(contentsOf: imageURL), let uiImage = UIImage(data: data) {
            profileImage = Image(uiImage: uiImage)
        }
    }
}

// MARK: - Saved Events
struct SavedEventsCarousel: View {
    @Environment(SavedEventsStore.self) private var savedEvents
    
    // 1. Estado para controlar qual evento foi clicado e deve abrir a sheet
    @State private var selectedExperience: Experience? = nil
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Eventos salvos")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.gray)
                Spacer()
                
                if !savedEvents.savedExperiences.isEmpty {
                    Text("\(savedEvents.savedExperiences.count)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.5))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            
            if savedEvents.savedExperiences.isEmpty {
                Text("Nenhum evento salvo ainda. Explore a home!")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(savedEvents.savedExperiences) { exp in
                            RemoteExperienceImage(
                                imageURL: exp.imageURL,
                                fallbackSystemName: exp.imageName,
                                accentColor: exp.category.color,
                                cornerRadius: 12,
                                style: .gridCard
                            )
                            .frame(width: 100, height: 140)
                            .overlay(alignment: .topTrailing) {
                                if let date = exp.date {
                                    Text(date.prefix(5))
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color(red: 0.82, green: 0.74, blue: 0.67))
                                        .cornerRadius(4)
                                        .offset(x: -4, y: 4)
                                }
                            }
                            // 2. Adiciona o gesto de toque para capturar o evento selecionado
                            .onTapGesture {
                                selectedExperience = exp
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        // 3. Modificador para apresentar a sheet do evento selecionado
        .sheet(item: $selectedExperience) { experience in
            ExperienceDetailView(experience: experience)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}
import SwiftUI

struct CalendarDumpView: View {
    let entries: [JournalEntry]
    let onEntryTap: (JournalEntry) -> Void
    
    @State private var currentDate: Date = Date()
    
    private let daysOfWeek = ["dom", "seg", "ter", "qua", "qui", "sex", "sáb"]
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("DUMP")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.gray)
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.gray)
                
                Spacer()
                
                // O truque do DatePicker invisível
                ZStack {
                    HStack(spacing: 4) {
                        Text(currentDateFormatter.string(from: currentDate))
                        Image(systemName: "chevron.down")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.82, green: 0.74, blue: 0.67).opacity(0.6))
                    .cornerRadius(6)
                    
                    // DatePicker nativo escondido, mas clicável
                    DatePicker("", selection: $currentDate, displayedComponents: [.date])
                        .labelsHidden()
                        .blendMode(.destinationOver) // Joga para trás
                        .opacity(0.011)              // Deixa quase invisível, mas interativo
                }
            }
            .padding(.horizontal, 20)
            
            // Grid do Calendário
            VStack(spacing: 0) {
                // Cabeçalho dos dias
                HStack(spacing: 0) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 8)
                    }
                }
                
                let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
                let days = generateDaysInMonth(for: currentDate)
                
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(0..<days.count, id: \.self) { index in
                        if let date = days[index] {
                            let entry = entryForDate(date)
                            CalendarCellView(date: date, entry: entry)
                                .onTapGesture {
                                    if let entry = entry {
                                        onEntryTap(entry)
                                    }
                                }
                        } else {
                            // Célula vazia para compensar o início do mês
                            CalendarCellView(date: nil, entry: nil)
                        }
                    }
                }
                .border(Color.gray.opacity(0.4), width: 1)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Helpers de Calendário
    
    private var currentDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM, yyyy"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter
    }
    
    // Gera o array de dias, inserindo 'nil' para os dias vazios no início do grid
    private func generateDaysInMonth(for date: Date) -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1)
        else { return [] }
        
        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        var days: [Date?] = []
        
        calendar.enumerateDates(startingAfter: dateInterval.start - 1, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime) { date, _, stop in
            if let date = date {
                if date < monthInterval.start {
                    days.append(nil) // Espaço em branco
                } else if date >= monthInterval.end {
                    stop = true
                } else {
                    days.append(date) // Dia real do mês
                }
            }
        }
        return days
    }
    
    // Verifica se existe alguma entrada (JournalEntry) para essa data exata
    private func entryForDate(_ date: Date) -> JournalEntry? {
        entries.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
}

// MARK: - Calendar Cell

struct CalendarCellView: View {
    let date: Date?
    let entry: JournalEntry?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Fundo e borda
            Rectangle()
                .fill(Color.clear)
                .border(Color.gray.opacity(0.4), width: 0.5)
                .aspectRatio(0.8, contentMode: .fit)
            
            // Número do dia
            if let date = date {
                let dayNumber = Calendar.current.component(.day, from: date)
                Text("\(dayNumber)")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .padding(4)
            }
            
            // Indicador de Entrada (A Estrela ou Thumbnail)
            if entry != nil {
                VStack {
                    Spacer()
                    
                    Text("⭐️")
                        .font(.system(size: 18))
                        // Pequena animação/shadow para destacar
                        .shadow(color: .yellow.opacity(0.5), radius: 2, x: 0, y: 0)
                    
                    /* Futuramente, para colocar o thumbnail da colagem:
                    if let thumbData = entry?.thumbnailData, let uiImage = UIImage(data: thumbData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                    */
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
