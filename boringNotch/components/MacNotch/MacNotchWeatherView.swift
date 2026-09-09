//
//  MacNotchWeatherView.swift
//  boringNotch
//
//  Created by boringNotch on 08/09/2026.
//

import SwiftUI

struct HourlyForecast: Identifiable {
    let id = UUID()
    let time: String
    let icon: String
    let temp: String
}

struct MacNotchWeatherView: View {
    private let hourlyData: [HourlyForecast] = [
        HourlyForecast(time: "Now", icon: "sun.max.fill", temp: "17°"),
        HourlyForecast(time: "02", icon: "moon.stars.fill", temp: "16°"),
        HourlyForecast(time: "03", icon: "moon.fill", temp: "16°"),
        HourlyForecast(time: "04", icon: "moon.fill", temp: "15°"),
        HourlyForecast(time: "05", icon: "sun.haze.fill", temp: "15°"),
        HourlyForecast(time: "06", icon: "sunrise.fill", temp: "16°"),
        HourlyForecast(time: "07", icon: "sun.max.fill", temp: "19°"),
        HourlyForecast(time: "08", icon: "sun.max.fill", temp: "21°"),
        HourlyForecast(time: "09", icon: "sun.max.fill", temp: "23°"),
        HourlyForecast(time: "10", icon: "sun.max.fill", temp: "25°")
    ]

    var body: some View {
        HStack(spacing: 14) {
            // Left Card: Main Temp & Glanceable stats
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.yellow)
                        Text("17°C")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Text("Clear sky")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))

                    Text("H: 31°C  L: 15°C")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                }

                Divider().frame(height: 70).opacity(0.2)

                // Stats Grid
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 16) {
                        statItem(title: "Feels like", value: "17°C", icon: "thermometer.medium")
                        statItem(title: "Humidity", value: "59%", icon: "humidity")
                        statItem(title: "Wind", value: "5 km/h", icon: "wind")
                    }

                    HStack(spacing: 16) {
                        statItem(title: "UV Index", value: "0 Low", icon: "sun.min")
                        statItem(title: "Rain chance", value: "0%", icon: "cloud.rain")
                        statItem(title: "Pressure", value: "1012 hPa", icon: "gauge.medium")
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.08).opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                    )
            )

            // Right Card: Sun Times & Hourly Strip
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.yellow)
                        Text("06:06")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "sunset.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                        Text("20:58")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(hourlyData) { item in
                            VStack(spacing: 3) {
                                Text(item.time)
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.5))
                                Image(systemName: item.icon)
                                    .font(.system(size: 11))
                                    .foregroundColor(.yellow)
                                Text(item.temp)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 26)
                        }
                    }
                }
            }
            .frame(width: 220)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.08).opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                    )
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func statItem(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 7))
                    .foregroundColor(.cyan)
                Text(title)
                    .font(.system(size: 7))
                    .foregroundColor(.white.opacity(0.45))
            }
            Text(value)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}
