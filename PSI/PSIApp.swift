//
//  PSIApp.swift
//  PSI
//
//  Created by Raynara Coelho on 11/05/26.
//

import SwiftUI
import SwiftData

@main
struct PSIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("", systemImage: "house.fill"){
                HomeView()
            }
            Tab("", systemImage: "book.fill"){
                JournalView()
            }
            Tab("", systemImage: "map.fill"){
                MapView()
            }
            Tab(role: .search){
                SearchView()
            } 
        }
    }
}

#Preview {
    ContentView()
}
