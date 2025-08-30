//
//  WeatherService.swift
//  The Weather Game
//
//  Created by Liam Ford on 8/30/25.
//

import Foundation

struct WeatherResponse: Codable {
    let main: MainWeather
    let name: String
}

struct MainWeather: Codable {
    let temp: Double
}

class WeatherService {
    private let apiKey = APIKeys.weatherAPI
    
    func getTemp(for city: String) async throws -> Int {
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(encodedCity)&appid=\(apiKey)&units=imperial"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
        return Int(weatherResponse.main.temp.rounded())
    }
}
