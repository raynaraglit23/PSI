//
//  RemoteExperienceImage.swift
//  PSI
//
//  Created by OpenAI Codex on 15/05/26.
//

import SwiftUI

struct RemoteExperienceImage: View {
    enum ContentStyle {
        case gridCard
        case detailHero

        var contentMode: ContentMode {
            switch self {
            case .gridCard:
                return .fill
            case .detailHero:
                return .fit
            }
        }

        var fallbackFontSize: CGFloat {
            switch self {
            case .gridCard:
                return 44
            case .detailHero:
                return 72
            }
        }
    }

    let imageURL: URL?
    let fallbackSystemName: String
    let accentColor: Color
    let cornerRadius: CGFloat
    let style: ContentStyle

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundShape

                imageLayer(in: proxy.size)
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
                    .clipped()
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }

    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(accentColor.opacity(0.20))
    }

    @ViewBuilder
    private func imageLayer(in size: CGSize) -> some View {
        if let imageURL {
            AsyncImage(url: imageURL, transaction: Transaction(animation: .easeInOut(duration: 0.2))) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .tint(accentColor)
                        .frame(width: size.width, height: size.height)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height, alignment: .center)
                        .clipped()
                case .failure:
                    fallbackContent
                        .frame(width: size.width, height: size.height)
                @unknown default:
                    fallbackContent
                        .frame(width: size.width, height: size.height)
                }
            }
        } else {
            fallbackContent
                .frame(width: size.width, height: size.height)
        }
    }

    private var fallbackContent: some View {
        Image(systemName: fallbackSystemName)
            .font(.system(size: style.fallbackFontSize, weight: .regular))
            .foregroundColor(accentColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
