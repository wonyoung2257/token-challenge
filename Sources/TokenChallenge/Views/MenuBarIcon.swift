import AppKit
import SwiftUI

enum MenuBarIcon {
    static func createImage(progress: Double, goalMet: Bool, percent: Int) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let ctx = NSGraphicsContext.current!.cgContext
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius: CGFloat = 7.5
            let lineWidth: CGFloat = 3.0

            // Background circle
            ctx.setStrokeColor(NSColor.systemGray.withAlphaComponent(0.3).cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
            ctx.strokePath()

            if goalMet {
                // Green checkmark
                ctx.setStrokeColor(NSColor.systemGreen.cgColor)
                ctx.setLineWidth(lineWidth)
                ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
                ctx.strokePath()

                ctx.setStrokeColor(NSColor.systemGreen.cgColor)
                ctx.setLineWidth(2.0)
                ctx.setLineCap(.round)
                ctx.setLineJoin(.round)
                ctx.move(to: CGPoint(x: 5, y: 9))
                ctx.addLine(to: CGPoint(x: 8, y: 6))
                ctx.addLine(to: CGPoint(x: 13, y: 12))
                ctx.strokePath()
            } else {
                // Progress arc
                let startAngle = CGFloat.pi / 2
                let endAngle = startAngle - CGFloat(progress) * 2 * .pi

                ctx.setStrokeColor(NSColor.white.cgColor)
                ctx.setLineWidth(lineWidth)
                ctx.setLineCap(.round)
                ctx.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                ctx.strokePath()
            }

            return true
        }

        image.isTemplate = false
        return image
    }
}
