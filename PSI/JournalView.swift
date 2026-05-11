//
//  JornaulView.swift
//  PSI
//
//  Created by Raynara Coelho on 11/05/26.
//
import SwiftUI

struct JournalView: View {
    var body: some View {
        ZStack {
            Color(.gray).ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("Diário")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}
