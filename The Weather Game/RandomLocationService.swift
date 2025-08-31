//
//  LocationService.swift
//  The Weather Game
//
//  Created by Liam Ford on 8/30/25.
//

import Foundation
import CoreLocation
import MapKit

class LocationService {
    static let shared = LocationService()
    
    private init() {}
    
    /// Generates a random location with reverse geocoding to get a meaningful place name
    func getRandomLocation() async -> (coordinate: CLLocationCoordinate2D, name: String) {
        var attempts = 0
        let maxAttempts = 15 // Increased attempts for better results
        
        while attempts < maxAttempts {
            // Generate random coordinate, but bias towards populated areas
            let randomLat = generateWeightedLatitude()
            let randomLon = Double.random(in: -180...180)
            let coordinate = CLLocationCoordinate2D(latitude: randomLat, longitude: randomLon)
            
            // Try to get actual place name using reverse geocoding
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: randomLat, longitude: randomLon)
            
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let placemark = placemarks.first {
                    // Only proceed if we can get a real place name (not coordinates)
                    if let locationName = extractRealLocationName(from: placemark) {
                        // Skip if it's clearly in the middle of an ocean or uninhabited area
                        if !isLikelyUninhabited(placemark: placemark) {
                            return (coordinate, locationName)
                        }
                    }
                }
            } catch {
                print("Reverse geocoding failed: \(error)")
            }
            
            attempts += 1
        }
        
        // Fallback to a known city if all attempts failed
        return getFallbackLocation()
    }
    
    // MARK: - Private Helper Methods
    
    /// Extract a real location name, return nil if only coordinates available
    private func extractRealLocationName(from placemark: CLPlacemark) -> String? {
        // Priority order: city -> town -> administrative area -> country
        if let locality = placemark.locality {
            var name = locality
            if let country = placemark.country, country != "United States" {
                name += ", \(country)"
            } else if let state = placemark.administrativeArea {
                name += ", \(state)"
            }
            return name
        } else if let subLocality = placemark.subLocality {
            var name = subLocality
            if let country = placemark.country {
                name += ", \(country)"
            }
            return name
        } else if let administrativeArea = placemark.administrativeArea {
            var name = administrativeArea
            if let country = placemark.country {
                name += ", \(country)"
            }
            return name
        } else if let country = placemark.country {
            return country
        }
        
        // Return nil if we don't have a real place name (this will cause retry)
        return nil
    }
    
    /// Generate latitude with bias towards populated regions
    private func generateWeightedLatitude() -> Double {
        // Most populated areas are between -50 and 60 degrees latitude
        let random = Double.random(in: 0...1)
        
        if random < 0.8 {
            // 80% chance: populated temperate zones (-40 to 60)
            return Double.random(in: -40...60)
        } else if random < 0.95 {
            // 15% chance: tropical zones (-23.5 to 23.5)
            return Double.random(in: -23.5...23.5)
        } else {
            // 5% chance: anywhere else (-90 to 90)
            return Double.random(in: -90...90)
        }
    }
    
    /// Check if a location is likely uninhabited
    private func isLikelyUninhabited(placemark: CLPlacemark) -> Bool {
        // If there's no locality, sublocality, or administrative area, it's likely uninhabited
        if placemark.locality == nil &&
           placemark.subLocality == nil &&
           placemark.administrativeArea == nil {
            return true
        }
        
        // Check for ocean-related keywords
        let oceanKeywords = ["ocean", "sea", "pacific", "atlantic", "indian", "arctic", "southern"]
        let locationString = [
            placemark.locality,
            placemark.subLocality,
            placemark.administrativeArea,
            placemark.country
        ].compactMap { $0 }.joined(separator: " ").lowercased()
        
        for keyword in oceanKeywords {
            if locationString.contains(keyword) {
                return true
            }
        }
        
        return false
    }
    
    /// Fallback to known interesting cities
    private func getFallbackLocation() -> (coordinate: CLLocationCoordinate2D, name: String) {
        let fallbackCities = [
            ("London, UK", CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)),
            ("Tokyo, Japan", CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)),
            ("Sydney, Australia", CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)),
            ("New York, NY", CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)),
            ("Paris, France", CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)),
            ("Cairo, Egypt", CLLocationCoordinate2D(latitude: 30.0444, longitude: 31.2357))
        ]
        
        let randomCity = fallbackCities.randomElement()!
        return (randomCity.1, randomCity.0)
    }
}
