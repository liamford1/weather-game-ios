//
//  WeatherMapView.swift
//  The Weather Game
//
//  Created by Liam Ford on 8/30/25.
//

import SwiftUI
import MapKit

// MARK: - Main Map Picker View
struct WeatherMapPickerView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795), // Center of US
        span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
    )
    
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var selectedLocationName: String = ""
    @State private var showingSearch = false
    @State private var isLoadingLocation = false
    
    let onLocationSelected: (CLLocationCoordinate2D, String) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                // Map View
                Map(coordinateRegion: $region, annotationItems: annotations) { location in
                    MapAnnotation(coordinate: location.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                            .font(.title)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                }
                .onTapGesture { location in
                    addPin(at: location)
                }
                .frame(height: 400)
                
                // Instructions
                Text("Tap anywhere on the map to select a location")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                // Selected Location Info
                if let selectedLocation = selectedLocation {
                    LocationInfoCard(
                        selectedLocation: selectedLocation,
                        selectedLocationName: selectedLocationName,
                        isLoadingLocation: isLoadingLocation,
                        onUseLocation: {
                            onLocationSelected(selectedLocation, selectedLocationName.isEmpty ? "Custom Location" : selectedLocationName)
                        }
                    )
                }
                
                Spacer()
            }
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onLocationSelected(CLLocationCoordinate2D(), "")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Search") {
                        showingSearch = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingSearch) {
            LocationSearchView { coordinate, name in
                selectedLocation = coordinate
                selectedLocationName = name
                region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
                )
                showingSearch = false
            }
        }
    }
    
    private var annotations: [MapLocation] {
        guard let selectedLocation = selectedLocation else { return [] }
        return [MapLocation(coordinate: selectedLocation)]
    }
    
    private func addPin(at screenLocation: CGPoint) {
        // Convert screen tap to map coordinate
        let mapWidth = UIScreen.main.bounds.width
        let mapHeight: CGFloat = 400
        
        let xPercent = screenLocation.x / mapWidth
        let yPercent = screenLocation.y / mapHeight
        
        let longitudeSpan = region.span.longitudeDelta
        let latitudeSpan = region.span.latitudeDelta
        
        let newLongitude = region.center.longitude - (longitudeSpan / 2) + (Double(xPercent) * longitudeSpan)
        let newLatitude = region.center.latitude + (latitudeSpan / 2) - (Double(yPercent) * latitudeSpan)
        
        selectedLocation = CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)
        isLoadingLocation = true
        selectedLocationName = ""
        
        // Reverse geocode to get location name
        reverseGeocodeLocation(coordinate: CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude))
    }
    
    private func reverseGeocodeLocation(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                isLoadingLocation = false
                if let placemark = placemarks?.first {
                    selectedLocationName = LocationNameFormatter.formatLocationName(from: placemark)
                } else {
                    selectedLocationName = "Unknown Location"
                }
            }
        }
    }
}

// MARK: - Location Info Card Component
struct LocationInfoCard: View {
    let selectedLocation: CLLocationCoordinate2D
    let selectedLocationName: String
    let isLoadingLocation: Bool
    let onUseLocation: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoadingLocation {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Finding location...")
                        .font(.subheadline)
                }
            } else {
                Text("Selected Location")
                    .font(.headline)
                
                Text(selectedLocationName.isEmpty ?
                    "Lat: \(selectedLocation.latitude.formatted(.number.precision(.fractionLength(4)))), Lng: \(selectedLocation.longitude.formatted(.number.precision(.fractionLength(4))))" :
                    selectedLocationName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Use This Location") {
                onUseLocation()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoadingLocation)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Location Search View
struct LocationSearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    let onLocationSelected: (CLLocationCoordinate2D, String) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText, onSearchButtonClicked: performSearch)
                
                if isSearching {
                    HStack {
                        ProgressView()
                        Text("Searching...")
                    }
                    .padding()
                }
                
                List(searchResults, id: \.self) { item in
                    LocationSearchRow(item: item) {
                        onLocationSelected(
                            item.placemark.coordinate,
                            item.name ?? "Selected Location"
                        )
                    }
                }
            }
            .navigationTitle("Search Locations")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                self.isSearching = false
                
                guard let response = response else {
                    print("Search error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self.searchResults = response.mapItems
            }
        }
    }
}

// MARK: - Search Row Component
struct LocationSearchRow: View {
    let item: MKMapItem
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.name ?? "Unknown")
                .font(.headline)
            if let address = item.placemark.title {
                Text(address)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Custom Search Bar
struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var onSearchButtonClicked: () -> Void
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "Search for a city or place..."
        searchBar.searchBarStyle = .minimal
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UISearchBarDelegate {
        let parent: SearchBar
        
        init(_ parent: SearchBar) {
            self.parent = parent
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            parent.text = searchText
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            parent.onSearchButtonClicked()
            searchBar.resignFirstResponder()
        }
    }
}

// MARK: - Supporting Models and Utilities
struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct LocationNameFormatter {
    static func formatLocationName(from placemark: CLPlacemark) -> String {
        var nameComponents: [String] = []
        
        if let locality = placemark.locality {
            nameComponents.append(locality)
        }
        if let administrativeArea = placemark.administrativeArea {
            nameComponents.append(administrativeArea)
        }
        if let country = placemark.country {
            nameComponents.append(country)
        }
        
        let formattedName = nameComponents.joined(separator: ", ")
        
        if formattedName.isEmpty {
            return placemark.name ?? "Unknown Location"
        }
        
        return formattedName
    }
}
