//
//  MapaCulturalAPIService.swift
//  PSI
//
//  Created by OpenAI Codex on 14/05/26.
//

import Foundation
import CoreLocation

enum MapaCulturalAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unsuccessfulStatusCode(Int)
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Nao foi possivel montar a URL da API."
        case .invalidResponse:
            return "A API retornou uma resposta invalida."
        case .unsuccessfulStatusCode(let code):
            return "A API retornou status HTTP \(code)."
        case .invalidPayload:
            return "O JSON da API nao veio no formato esperado."
        }
    }
}

struct MapaCulturalAPIService: EventLocationProviding {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func fetchNearbyEvents() async throws -> [EventLocation] {
        let request = try makeRequest()
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MapaCulturalAPIError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw MapaCulturalAPIError.unsuccessfulStatusCode(httpResponse.statusCode)
        }

        let payload = try decoder.decode(MapaCulturalPayload.self, from: data)

        return payload
            .events
            .flatMap { event in
                event.occurrences.compactMap { occurrence in
                    guard let mapped = occurrence.toEventLocation(
                        eventName: event.name,
                        eventID: event.id,
                        shortDescription: event.shortDescription,
                        imageURL: event.imageURL
                    ) else {
                        return nil
                    }

                    return mapped.isFromFortaleza ? mapped.event : nil
                }
            }
            .uniqued()
    }

    private func makeRequest() throws -> URLRequest {
        guard var components = URLComponents(string: "https://mapacultural.secult.ce.gov.br/api/event/find") else {
            throw MapaCulturalAPIError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(
                name: "@select",
                value: "id,name,shortDescription,occurrences.{space.{id,name,endereco,En_Municipio,location}}"
            ),
            URLQueryItem(name: "@files", value: "(header.header,avatar.avatarBig):url"),
            URLQueryItem(name: "@limit", value: "200")
        ]

        guard let url = components.url else {
            throw MapaCulturalAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}

private struct MapaCulturalPayload: Decodable {
    let events: [MapaCulturalEventDTO]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let events = try? container.decode([MapaCulturalEventDTO].self) {
            self.events = events
            return
        }

        if let wrapped = try? container.decode(MapaCulturalWrappedEventsDTO.self) {
            self.events = wrapped.items
            return
        }

        throw MapaCulturalAPIError.invalidPayload
    }
}

private struct MapaCulturalWrappedEventsDTO: Decodable {
    let items: [MapaCulturalEventDTO]
}

private struct MapaCulturalEventDTO: Decodable {
    let id: IdentifierValue
    let name: String
    let shortDescription: String?
    let occurrences: [MapaCulturalOccurrenceDTO]
    let imageURL: URL?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)

        id = try container.decode(IdentifierValue.self, forKey: DynamicCodingKey("id"))
        name = try container.decode(String.self, forKey: DynamicCodingKey("name"))
        shortDescription = try container.decodeIfPresent(String.self, forKey: DynamicCodingKey("shortDescription"))
        occurrences = try container.decodeIfPresent([MapaCulturalOccurrenceDTO].self, forKey: DynamicCodingKey("occurrences")) ?? []
        imageURL = container.decodePreferredImageURL()
    }
}

private struct MapaCulturalOccurrenceDTO: Decodable {
    let space: MapaCulturalSpaceDTO?

    func toEventLocation(
        eventName: String,
        eventID: IdentifierValue,
        shortDescription: String?,
        imageURL: URL?
    ) -> (event: EventLocation, isFromFortaleza: Bool)? {
        guard
            let space,
            let coordinate = space.coordinate
        else {
            return nil
        }

        let identifierSeed = "\(eventID.stringValue)-\(space.id?.stringValue ?? space.name ?? eventName)-\(coordinate.latitude)-\(coordinate.longitude)"
        let event = EventLocation(
            id: UUID.stableIdentifier(from: identifierSeed),
            title: eventName,
            coordinate: coordinate,
            venueName: space.name ?? "Local a confirmar",
            address: space.endereco ?? "Fortaleza, Ceará",
            details: shortDescription,
            price: nil,
            imageURL: imageURL
        )

        return (event, space.isFromFortaleza)
    }
}

private struct MapaCulturalSpaceDTO: Decodable {
    let id: IdentifierValue?
    let name: String?
    let endereco: String?
    let city: String?
    let location: MapaCulturalLocationDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case endereco
        case city = "En_Municipio"
        case location
    }

    var coordinate: CLLocationCoordinate2D? {
        guard
            let latitude = location?.latitude?.doubleValue,
            let longitude = location?.longitude?.doubleValue
        else {
            return nil
        }

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var isFromFortaleza: Bool {
        let candidates = [city, endereco, name]
            .compactMap { $0?.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current) }

        return candidates.contains { $0.contains("fortaleza") }
    }
}

private struct MapaCulturalLocationDTO: Decodable {
    let latitude: FlexibleValue?
    let longitude: FlexibleValue?

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
}

private struct IdentifierValue: Decodable {
    let stringValue: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            stringValue = String(intValue)
            return
        }

        if let stringValue = try? container.decode(String.self) {
            self.stringValue = stringValue
            return
        }

        throw DecodingError.typeMismatch(
            String.self,
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Identifier should be Int or String.")
        )
    }
}

private struct FlexibleValue: Decodable {
    let doubleValue: Double?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let doubleValue = try? container.decode(Double.self) {
            self.doubleValue = doubleValue
            return
        }

        if let intValue = try? container.decode(Int.self) {
            self.doubleValue = Double(intValue)
            return
        }

        if let stringValue = try? container.decode(String.self) {
            self.doubleValue = Double(stringValue.replacingOccurrences(of: ",", with: "."))
            return
        }

        self.doubleValue = nil
    }
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(_ stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

private struct FlexibleImageReference: Decodable {
    let preferredURL: URL?

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer() {
            if let stringValue = try? container.decode(String.self) {
                preferredURL = URL(string: stringValue)
                return
            }
        }

        if var container = try? decoder.unkeyedContainer() {
            while container.isAtEnd == false {
                if let reference = try? container.decode(FlexibleImageReference.self), let url = reference.preferredURL {
                    preferredURL = url
                    return
                }
            }

            preferredURL = nil
            return
        }

        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        let preferredKeys = [
            "url",
            "originalUrl",
            "downloadUrl",
            "header",
            "avatar",
            "header.header",
            "avatar.avatarBig"
        ]

        for keyName in preferredKeys {
            let key = DynamicCodingKey(keyName)
            if let reference = try? container.decode(FlexibleImageReference.self, forKey: key), let url = reference.preferredURL {
                preferredURL = url
                return
            }
        }

        for key in container.allKeys {
            if let reference = try? container.decode(FlexibleImageReference.self, forKey: key), let url = reference.preferredURL {
                preferredURL = url
                return
            }
        }

        preferredURL = nil
    }
}

private extension KeyedDecodingContainer where K == DynamicCodingKey {
    func decodePreferredImageURL() -> URL? {
        let prioritizedKeys = ["files", "header", "avatar", "header.header", "avatar.avatarBig"]

        for keyName in prioritizedKeys {
            let key = DynamicCodingKey(keyName)
            if let reference = try? decode(FlexibleImageReference.self, forKey: key), let url = reference.preferredURL {
                return url
            }
        }

        for key in allKeys where key.stringValue.localizedCaseInsensitiveContains("header") || key.stringValue.localizedCaseInsensitiveContains("avatar") {
            if let reference = try? decode(FlexibleImageReference.self, forKey: key), let url = reference.preferredURL {
                return url
            }
        }

        return nil
    }
}

private extension Sequence where Element == EventLocation {
    func uniqued() -> [EventLocation] {
        var seen = Set<UUID>()
        return filter { seen.insert($0.id).inserted }
    }
}
