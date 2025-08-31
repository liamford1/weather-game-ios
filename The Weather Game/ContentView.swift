//
//  ContentView.swift
//  The Weather Game
//
//  Created by Liam Ford on 8/30/25.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State private var currentPlayer = "Player 1"
    @State private var targetLocation = "New York"
    @State private var targetCoordinate: CLLocationCoordinate2D?
    @State private var userGuess = ""
    @State private var actualTemp = 72
    @State private var showResult = false
    @State private var resultMessage = ""
    @State private var score = 0
    @State private var showingMapPicker = false
    
    var body: some View {
        VStack(spacing: 30) {
            VStack {
                Image(systemName: "cloud.sun")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
                Text("The Weather Game")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .padding(.top)
            
            VStack(spacing: 15) {
                Text("Current Player: \(currentPlayer)")
                    .font(.headline)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                
                Text("Guess the temperature in:")
                    .font(.title3)
                
                Text(targetLocation)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            
            VStack(spacing: 20) {
                TextField("Enter temperature (°F)", text: $userGuess)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                
                Button("Submit Guess") {
                    Task {
                        await submitGuess()
                    }
                }
                .buttonStyle(.borderedProminent)
                .font(.headline)
                .disabled(userGuess.isEmpty)
            }
            .padding(.horizontal)
            
            Text("Score: \(score)")
                .font(.title3)
                .fontWeight(.medium)
            
            Spacer()
            
            VStack(spacing: 15) {
                HStack(spacing: 20) {
                    Button("Choose on Map") {
                        showingMapPicker = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Random Location") {
                        newRandomLocation()
                    }
                    .buttonStyle(.bordered)
                }
                
                Button("Reset Game") {
                    resetGame()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .alert("Result", isPresented: $showResult) {
            Button("Next Turn") {
                nextTurn()
            }
        } message: {
            Text(resultMessage)
        }
        .sheet(isPresented: $showingMapPicker) {
            WeatherMapPickerView { coordinate, locationName in
                // Only update if a valid location was selected (not cancelled)
                if coordinate.latitude != 0 || coordinate.longitude != 0 {
                    targetCoordinate = coordinate
                    targetLocation = locationName
                }
                showingMapPicker = false
            }
        }
    }
    
    // MARK: - Core Logic Functions
    
    func submitGuess() async {
        guard let guess = Int(userGuess) else { return }
        let weatherService = WeatherService()
        
        do {
            // Use coordinates if available, otherwise fall back to city name
            if let coordinate = targetCoordinate {
                actualTemp = try await weatherService.getTemp(lat: coordinate.latitude, lon: coordinate.longitude)
            } else {
                actualTemp = try await weatherService.getTemp(for: targetLocation)
            }
        } catch {
            actualTemp = 70
            print("Weather API failed: \(error)")
        }
        
        let diff = abs(guess - actualTemp)
        
        if diff == 0 {
            resultMessage = "🎉 Exact! The temperature was \(actualTemp)°F. +10 points!"
            score += 10
        } else if diff <= 5 {
            resultMessage = "🔥 Close! The temperature was \(actualTemp)°F. You were off by \(diff)°. +5 points!"
            score += 5
        } else {
            resultMessage = "❄️ The temperature was \(actualTemp)°F. You were off by \(diff)°. -\(diff) points!"
            score -= diff
        }
        showResult = true
    }
    
    func nextTurn() {
        userGuess = ""
        // Keep the current location for the next player, or generate a new one
    }
    
    func newRandomLocation() {
        let locations = [
            "New York",
            "Los Angeles",
            "Chicago",
            "Miami",
            "Seattle",
            "Denver",
            "Phoenix",
            "Boston"
        ]
        targetLocation = locations.randomElement() ?? "New York"
        targetCoordinate = nil // Clear coordinate when using random location
    }
    
    func resetGame() {
        score = 0
        userGuess = ""
        currentPlayer = "Player 1"
        targetCoordinate = nil
        newRandomLocation()
    }
}

#Preview {
    ContentView()
}
