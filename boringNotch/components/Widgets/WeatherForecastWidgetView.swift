//
//  WeatherForecastWidgetView.swift
//  boringNotch
//
//  LaunchMe-style weather widget for the NotchNest panel.
//  Uses Open-Meteo (free, no API key) for real weather data.
//

import SwiftUI
import CoreLocation
import Defaults

// MARK: - Weather Data Models

struct WeatherHourlyPoint: Identifiable {
    let id = UUID()
    let hour: String    // e.g. "10:00"
    let temp: Int       // e.g. 27
    let icon: String    // SF Symbol
}

// MARK: - Weather Manager (Open-Meteo, no API key required)

@MainActor
final class WeatherManager: ObservableObject {
    static let shared = WeatherManager()

    @Published var temperature: Int = 28
    @Published var feelsLike: Int = 29
    @Published var condition: String = "Mostly Clear"
    @Published var conditionIcon: String = "cloud.sun.fill"
    @Published var location: String = "New York"
    @Published var high: Int = 36
    @Published var low: Int = 25
    @Published var hourly: [WeatherHourlyPoint] = [
        WeatherHourlyPoint(hour: "10:00", temp: 27, icon: "sun.max.fill"),
        WeatherHourlyPoint(hour: "14:00", temp: 24, icon: "cloud.sun.fill"),
        WeatherHourlyPoint(hour: "18:00", temp: 25, icon: "cloud.fill")
    ]

    private let locationManager = CLLocationManager()
    private var locationDelegate: WeatherLocationDelegate?
    private var lastFetch: Date?

    private init() {
        locationDelegate = WeatherLocationDelegate { [weak self] location in
            Task { @MainActor in
                await self?.fetchWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
                self?.reverseGeocode(location)
            }
        }
        locationManager.delegate = locationDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        // Refresh every 30 minutes
        Task {
            while true {
                try? await Task.sleep(for: .seconds(1800))
                locationManager.startUpdatingLocation()
            }
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            Task { @MainActor in
                if let city = placemarks?.first?.locality {
                    self?.location = city
                }
            }
        }
    }

    private func fetchWeather(lat: Double, lon: Double) async {
        // Avoid rapid re-fetching
        if let last = lastFetch, Date().timeIntervalSince(last) < 300 { return }
        lastFetch = Date()

        let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,apparent_temperature,weather_code&hourly=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=1"

        guard let url = URL(string: urlStr) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Current
                if let current = json["current"] as? [String: Any] {
                    if let temp = current["temperature_2m"] as? Double {
                        self.temperature = Int(temp.rounded())
                    }
                    if let feels = current["apparent_temperature"] as? Double {
                        self.feelsLike = Int(feels.rounded())
                    }
                    if let code = current["weather_code"] as? Int {
                        let (cond, icon) = weatherCodeToDescription(code)
                        self.condition = cond
                        self.conditionIcon = icon
                    }
                }

                // Daily hi/lo
                if let daily = json["daily"] as? [String: Any] {
                    if let maxTemps = daily["temperature_2m_max"] as? [Double], let first = maxTemps.first {
                        self.high = Int(first.rounded())
                    }
                    if let minTemps = daily["temperature_2m_min"] as? [Double], let first = minTemps.first {
                        self.low = Int(first.rounded())
                    }
                }

                // Hourly (next 6 hours from now)
                if let hourlyData = json["hourly"] as? [String: Any],
                   let times = hourlyData["time"] as? [String],
                   let temps = hourlyData["temperature_2m"] as? [Double],
                   let codes = hourlyData["weather_code"] as? [Int] {

                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
                    let now = Date()
                    let displayFormatter = DateFormatter()
                    displayFormatter.dateFormat = "HH:mm"

                    var forecasts: [WeatherHourlyPoint] = []
                    for i in 0..<min(times.count, temps.count) {
                        guard let time = formatter.date(from: times[i]),
                              time > now,
                              forecasts.count < 4 else {
                            if forecasts.count >= 4 { break }
                            continue
                        }
                        let (_, icon) = weatherCodeToDescription(codes[i])
                        forecasts.append(WeatherHourlyPoint(
                            hour: displayFormatter.string(from: time),
                            temp: Int(temps[i].rounded()),
                            icon: icon
                        ))
                    }
                    self.hourly = forecasts
                }
            }
        } catch {
            // Silently fail — show placeholder
        }
    }

    private func weatherCodeToDescription(_ code: Int) -> (String, String) {
        switch code {
        case 0:         return ("Clear", "sun.max.fill")
        case 1:         return ("Mostly Clear", "sun.max.fill")
        case 2:         return ("Partly Cloudy", "cloud.sun.fill")
        case 3:         return ("Overcast", "cloud.fill")
        case 45, 48:    return ("Foggy", "cloud.fog.fill")
        case 51...55:   return ("Drizzle", "cloud.drizzle.fill")
        case 61...65:   return ("Rain", "cloud.rain.fill")
        case 66, 67:    return ("Freezing Rain", "cloud.sleet.fill")
        case 71...75:   return ("Snow", "cloud.snow.fill")
        case 77:        return ("Snow Grains", "cloud.snow.fill")
        case 80...82:   return ("Showers", "cloud.heavyrain.fill")
        case 85, 86:    return ("Snow Showers", "cloud.snow.fill")
        case 95:        return ("Thunderstorm", "cloud.bolt.fill")
        case 96, 99:    return ("Hail Storm", "cloud.bolt.rain.fill")
        default:        return ("Unknown", "cloud")
        }
    }
}

// MARK: - CLLocationManager Delegate

private class WeatherLocationDelegate: NSObject, CLLocationManagerDelegate {
    let onLocation: (CLLocation) -> Void

    init(onLocation: @escaping (CLLocation) -> Void) {
        self.onLocation = onLocation
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        manager.stopUpdatingLocation()
        onLocation(loc)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorized || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}

// MARK: - Compact Weather Widget (for NotchNest — matches LaunchMe screenshot)

struct WeatherNestWidgetView: View {
    @ObservedObject var weather = WeatherManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header: Weather condition icon + location
            HStack(spacing: 4) {
                Image(systemName: weather.conditionIcon)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 11, weight: .bold))
                Text(weather.location.isEmpty ? "Weather" : weather.location)
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                Spacer()
            }

            Spacer(minLength: 0)

            // Temperature + Condition
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(weather.temperature)°")
                    .font(.system(size: 23, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(weather.condition)
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                    Text("Feels \(weather.feelsLike)°")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                }
            }

            Spacer(minLength: 0)

            // High / Low
            HStack(spacing: 6) {
                Text("H: \(weather.high)°")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.white.opacity(0.65))
                Text("L: \(weather.low)°")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CGFloat(Defaults[.widgetCornerRadius]), style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: CGFloat(Defaults[.widgetCornerRadius]), style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                )
        )
    }
}

// MARK: - Full Weather Widget (with hourly forecast — matches LaunchMe expanded view)

struct WeatherForecastWidgetView: View {
    @ObservedObject var weather = WeatherManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("+\(weather.temperature)°")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    HStack(spacing: 2) {
                        Text("H: +\(weather.high)°")
                            .font(.system(size: 10, weight: .medium))
                        Text("L: +\(weather.low)°")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: weather.conditionIcon)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 28))
            }

            Divider().opacity(0.3)

            // Hourly forecast strip
            HStack(spacing: 0) {
                ForEach(weather.hourly) { forecast in
                    VStack(spacing: 3) {
                        Image(systemName: forecast.icon)
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 12))
                        Text(forecast.hour)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("+\(forecast.temp)°")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.12).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                )
        )
    }
}
