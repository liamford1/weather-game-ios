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
    @State private var targetLocation = "Pyongyang, North Korea"
    @State private var targetCoordinate: CLLocationCoordinate2D?
    @State private var userGuess = ""
    @State private var actualTemp = 72
    @State private var showResult = false
    @State private var resultMessage = ""
    @State private var score = 0
    @State private var showingMapPicker = false
    @State private var showTimer = false
    @State private var drinkingSeconds = 0
    
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
            
            if showTimer {
                DrinkingTimerView(
                    duration: drinkingSeconds,
                    onComplete: {
                        nextTurn()
                    },
                    onSkip: {
                        nextTurn()
                    }
                )
            } else {
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
            }
            
            Text("Score: \(score)")
                .font(.title3)
                .fontWeight(.medium)
            
            Spacer()
            
            if !showTimer {
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
        }
        .padding()
        .alert("Result", isPresented: $showResult) {
            Button("Start Drinking Timer") {
                if drinkingSeconds > 0 {
                    startTimer()
                } else {
                    nextTurn()
                }
            }
            Button("Skip Drinking") {
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
        drinkingSeconds = diff // Set drinking duration based on difference
        
        if diff == 0 {
            resultMessage = "🎉 Exact! The temperature was \(actualTemp)°F. No drinking required! +10 points!"
            score += 10
        } else if diff <= 5 {
            resultMessage = "🔥 Close! The temperature was \(actualTemp)°F. You were off by \(diff)° - drink for \(diff) seconds! +5 points!"
            score += 5
        } else {
            resultMessage = "❄️ The temperature was \(actualTemp)°F. You were off by \(diff)° - drink for \(diff) seconds! -\(diff) points!"
            score -= diff
        }
        showResult = true
    }
    
    func startTimer() {
        showResult = false
        showTimer = true
    }
    
    func nextTurn() {
        showTimer = false
        userGuess = ""
        drinkingSeconds = 0
        // Keep the current location for the next player, or generate a new one
    }
    
    func newRandomLocation() {
        Task {
            let randomLocation = await LocationService.shared.getRandomLocation()
            await MainActor.run {
                targetLocation = randomLocation.name
                targetCoordinate = randomLocation.coordinate
            }
        }
    }
    
    func resetGame() {
        showTimer = false
        score = 0
        userGuess = ""
        currentPlayer = "Player 1"
        drinkingSeconds = 0
        
        // Set to a known city initially, then get random location
        targetLocation = "Pyongyang, North Korea"
        targetCoordinate = nil
        
        newRandomLocation()
    }
}

#Preview {
    ContentView()
}
