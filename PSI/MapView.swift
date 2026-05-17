//
//  MapView.swift
//  PSI
//
//  Created by Raynara Coelho on 11/05/26.
//

import MapKit
import SwiftUI

struct MapView: View {
    @State private var locationManager = LocationManager()
    @State private var viewModel = MapViewModel()
    @State private var selectedEventID: EventLocation.ID?
    @State private var selectedExperience: Experience?
    @State private var cameraPosition: MapCameraPosition = .region(EventMapDefaults.region)
    @State private var hasCenteredOnUser = false

    private let experienceMapper = ExperienceMapper()

    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()

            ForEach(viewModel.events) { event in
                Annotation(event.title, coordinate: event.coordinate) {
                    MapEventAnnotationView(
                        isSelected: selectedEventID == event.id,
                        accentColor: color(for: event)
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            selectedEventID = event.id
                        }
                        selectedExperience = experienceMapper.map(
                            event: event,
                            userCoordinate: locationManager.userCoordinate
                        )
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .overlay(alignment: .top) {
            if locationManager.authorizationStatus == CLAuthorizationStatus.denied
                || locationManager.authorizationStatus == CLAuthorizationStatus.restricted {
                LocationPermissionBanner {
                    locationManager.requestWhenInUseAuthorization()
                }
            }
        }
        .task {
            await viewModel.loadEvents()
            locationManager.requestWhenInUseAuthorization()
        }
        .onChange(of: locationManager.userCoordinate?.latitude) { _, _ in
            guard let newCoordinate = locationManager.userCoordinate, hasCenteredOnUser == false else { return }

            hasCenteredOnUser = true
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: newCoordinate,
                    span: EventMapDefaults.span
                )
            )
        }
        .sheet(item: $selectedExperience, onDismiss: {
            withAnimation(.easeOut(duration: 0.2)) {
                selectedEventID = nil
            }
        }) { experience in
            ExperienceDetailView(experience: experience)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func color(for event: EventLocation) -> Color {
        experienceMapper.map(event: event, userCoordinate: locationManager.userCoordinate).category.color
    }
}

private struct MapEventAnnotationView: View {
    let isSelected: Bool
    let accentColor: Color

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: isSelected ? 34 : 28, weight: .semibold))
                .foregroundStyle(.white, accentColor)
                .shadow(color: .black.opacity(0.18), radius: isSelected ? 10 : 6, y: 3)
                .scaleEffect(isSelected ? 1.06 : 1)
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: isSelected)
    }
}

private struct LocationPermissionBanner: View {
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ative sua localização para ver eventos por perto.")
                .font(.subheadline.weight(.semibold))

            Button("Permitir localização", action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

#Preview {
    MapView()
}
