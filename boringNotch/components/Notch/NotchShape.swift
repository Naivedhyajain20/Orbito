//
//  NotchShape.swift
//  boringNotch
//
// Created by Kai Azim on 2023-08-24.
// Original source: https://github.com/MrKai77/DynamicNotchKit
// Modified by Alexander on 2025-05-18.

import SwiftUI

struct NotchShape: Shape {
    private var topCornerRadius: CGFloat
    private var bottomCornerRadius: CGFloat

    init(
        topCornerRadius: CGFloat? = nil,
        bottomCornerRadius: CGFloat? = nil
    ) {
        self.topCornerRadius = topCornerRadius ?? 6
        self.bottomCornerRadius = bottomCornerRadius ?? 14
    }

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get {
            .init(
                topCornerRadius,
                bottomCornerRadius
            )
        }
        set {
            topCornerRadius = newValue.first
            bottomCornerRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topR = topCornerRadius
        let botR = bottomCornerRadius
        // Smoothing factor for cubic bezier (higher = rounder, Apple-like)
        let smooth: CGFloat = 0.55

        // Start at top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))

        // Top-left corner (outer ear curve) — cubic for smoother transition
        path.addCurve(
            to: CGPoint(x: rect.minX + topR, y: rect.minY + topR),
            control1: CGPoint(x: rect.minX + topR * smooth, y: rect.minY),
            control2: CGPoint(x: rect.minX + topR, y: rect.minY + topR * (1 - smooth))
        )

        // Left edge down to bottom-left corner
        path.addLine(to: CGPoint(x: rect.minX + topR, y: rect.maxY - botR))

        // Bottom-left corner — smooth cubic
        path.addCurve(
            to: CGPoint(x: rect.minX + topR + botR, y: rect.maxY),
            control1: CGPoint(x: rect.minX + topR, y: rect.maxY - botR * (1 - smooth)),
            control2: CGPoint(x: rect.minX + topR + botR * (1 - smooth), y: rect.maxY)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.maxX - topR - botR, y: rect.maxY))

        // Bottom-right corner — smooth cubic
        path.addCurve(
            to: CGPoint(x: rect.maxX - topR, y: rect.maxY - botR),
            control1: CGPoint(x: rect.maxX - topR - botR * (1 - smooth), y: rect.maxY),
            control2: CGPoint(x: rect.maxX - topR, y: rect.maxY - botR * (1 - smooth))
        )

        // Right edge up to top-right corner
        path.addLine(to: CGPoint(x: rect.maxX - topR, y: rect.minY + topR))

        // Top-right corner — smooth cubic
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control1: CGPoint(x: rect.maxX - topR, y: rect.minY + topR * (1 - smooth)),
            control2: CGPoint(x: rect.maxX - topR * smooth, y: rect.minY)
        )

        // Close to top-left
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))

        return path
    }
}

#Preview {
    NotchShape(topCornerRadius: 6, bottomCornerRadius: 14)
        .frame(width: 200, height: 32)
        .padding(10)
}
