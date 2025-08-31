//
//  DrinkingTimerView.swift
//  The Weather Game
//
//  Created by Liam Ford on 8/30/25.
//

import SwiftUI

struct DrinkingTimerView: View {
    let duration: Int
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    @State private var timeRemaining: Int
    @State private var timer: Timer?
    
    init(duration: Int, onComplete: @escaping () -> Void, onSkip: @escaping () -> Void) {
        self.duration = duration
        self.onComplete = onComplete
        self.onSkip = onSkip
        self._timeRemaining = State(initialValue: duration)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🍺 Time to Drink!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(duration))
                    .stroke(
                        LinearGradient(
                            colors: timeRemaining > 10 ? [.orange, .red] : [.red, .red.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeRemaining)
                
                VStack {
                    Text("\(timeRemaining)")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(timeRemaining <= 5 ? .red : .primary)
                        .scaleEffect(timeRemaining <= 5 ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: timeRemaining)
                    
                    Text(timeRemaining == 1 ? "second" : "seconds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if duration > 0 {
                Text("Drink for \(duration) seconds!")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Button("Skip/Done") {
                stopTimer()
                onSkip()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(15)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - Timer Functions
    
    private func startTimer() {
        guard duration > 0 else {
            onComplete()
            return
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                onComplete()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
