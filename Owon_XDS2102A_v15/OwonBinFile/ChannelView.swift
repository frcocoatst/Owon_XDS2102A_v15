//
//  ChannelView.swift
//  OwonBinFile
//
//  Bounds-safe drawing for Swift 5 / Xcode 15.2
//

import Cocoa

class ChannelView: NSView {
    private var ch1Values: [UInt8] = []
    private var ch2Values: [UInt8] = []
    private var ch1Count = 0
    private var ch2Count = 0
    private var ch1ReferenceZero: CGFloat?
    private var ch2ReferenceZero: CGFloat?

    override func awakeFromNib() {
        super.awakeFromNib()

        // Der ChannelView ist nicht mehr größer als der sichtbare Bereich.
        // Er wächst und schrumpft immer gemeinsam mit dem ClipView der ScrollView.
        translatesAutoresizingMaskIntoConstraints = true
        autoresizingMask = [.width, .height]
    }

    func addChannels(_ channel1Count: Int, _ channel1Values: [UInt8],
                     _ channel2Count: Int, _ channel2Values: [UInt8],
                     ch1ReferenceZero: String? = nil,
                     ch2ReferenceZero: String? = nil) {
        ch1Values = channel1Values
        ch1Count = min(max(0, channel1Count), channel1Values.count)
        ch2Values = channel2Values
        ch2Count = min(max(0, channel2Count), channel2Values.count)
        self.ch1ReferenceZero = parseReferenceZero(ch1ReferenceZero)
        self.ch2ReferenceZero = parseReferenceZero(ch2ReferenceZero)
        needsDisplay = true
    }

    private func parseReferenceZero(_ text: String?) -> CGFloat? {
        guard let text = text else { return nil }
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized) else { return nil }
        return CGFloat(value)
    }

    private func drawGrid() {
        let path = NSBezierPath()
        path.lineWidth = 1.0

        // Das Raster füllt den ChannelView in beiden Richtungen vollständig aus.
        // Horizontal: 14 Rastereinheiten (Randfelder je 1/2 Einheit)
        // Vertikal:   10 Rastereinheiten
        let xStep = bounds.width / 14.0
        let yStep = bounds.height / 10.0
        let originX = bounds.minX
        let originY = bounds.minY

        // 10 vertikale Kästchen = 11 horizontale Linien.
        for i in 0...10 {
            let y = originY + CGFloat(i) * yStep
            path.move(to: NSPoint(x: originX, y: y))
            path.line(to: NSPoint(x: bounds.maxX, y: y))
        }

        // Vertikale Linien: erstes und letztes Feld je halb so breit.
        var x = originX
        path.move(to: NSPoint(x: x, y: originY))
        path.line(to: NSPoint(x: x, y: bounds.maxY))

        x += 0.5 * xStep
        path.move(to: NSPoint(x: x, y: originY))
        path.line(to: NSPoint(x: x, y: bounds.maxY))

        for _ in 0..<13 {
            x += xStep
            path.move(to: NSPoint(x: x, y: originY))
            path.line(to: NSPoint(x: x, y: bounds.maxY))
        }

        x += 0.5 * xStep
        path.move(to: NSPoint(x: x, y: originY))
        path.line(to: NSPoint(x: x, y: bounds.maxY))

        NSColor.gridColor.setStroke()
        path.stroke()

        // Horizontale Mittellinie (Reference_Zero = 0) deutlich hervorheben.
        let centerPath = NSBezierPath()
        centerPath.lineWidth = 2.5
        centerPath.move(to: NSPoint(x: bounds.minX, y: bounds.midY))
        centerPath.line(to: NSPoint(x: bounds.maxX, y: bounds.midY))
        NSColor.gridColor.setStroke()
        centerPath.stroke()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor(red: 28.0 / 255.0,
                green: 60.0 / 255.0,
                blue: 121.0 / 255.0,
                alpha: 1.0).setFill()
        bounds.fill()

        drawGrid()
        drawChannel(ch1Values, byteCount: ch1Count, color: NSColor.white.withAlphaComponent(0.6))
        drawChannel(ch2Values, byteCount: ch2Count, color: NSColor.yellow.withAlphaComponent(0.6))

        // Reference_Zero wird relativ zur horizontalen Mittellinie dargestellt.
        // Die Reference_Zero-Skala benötigt gegenüber dem gezeichneten 10er-Raster den Faktor 2.
        drawReferenceZeroArrow(ch1ReferenceZero, color: NSColor.white, label: "CH1")
        drawReferenceZeroArrow(ch2ReferenceZero, color: NSColor.yellow, label: "CH2")
    }

    private func drawReferenceZeroArrow(_ referenceZero: CGFloat?, color: NSColor, label: String) {
        guard let referenceZero = referenceZero else { return }

        // Reference_Zero: 100 soll zwei gezeichneten 1/10-Schritten entsprechen.
        // Daher wird für den Marker eine Skaleneinheit von 1/5 der Gesamthöhe verwendet.
        // +100 -> 2 Grid-Schritte nach oben, -200 -> 4 Grid-Schritte nach unten.
        let referenceZeroStep = bounds.height / 5.0
        let y = bounds.midY + (referenceZero / 100.0) * referenceZeroStep

        // Außerhalb des sichtbaren Grids keinen irreführenden Marker zeichnen.
        guard y >= bounds.minY && y <= bounds.maxY else { return }

        let xTip = bounds.minX + 12.0
        let arrowLength: CGFloat = 22.0
        let halfHeight: CGFloat = 6.0

        let arrow = NSBezierPath()
        arrow.lineWidth = 2.0
        arrow.move(to: NSPoint(x: xTip + arrowLength, y: y))
        arrow.line(to: NSPoint(x: xTip, y: y))
        arrow.move(to: NSPoint(x: xTip, y: y))
        arrow.line(to: NSPoint(x: xTip + 8.0, y: y + halfHeight))
        arrow.move(to: NSPoint(x: xTip, y: y))
        arrow.line(to: NSPoint(x: xTip + 8.0, y: y - halfHeight))
        color.setStroke()
        arrow.stroke()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10.0, weight: .semibold),
            .foregroundColor: color
        ]
        let text = "\(label) 0"
        let textSize = text.size(withAttributes: attributes)
        text.draw(at: NSPoint(x: xTip + arrowLength + 4.0,
                              y: y - textSize.height / 2.0),
                  withAttributes: attributes)
    }

    private func drawChannel(_ bytes: [UInt8], byteCount requestedByteCount: Int, color: NSColor) {
        let byteCount = min(max(0, requestedByteCount), bytes.count)
        let evenByteCount = byteCount - (byteCount % 2)
        guard evenByteCount >= 2 else { return }

        color.setStroke()
        let path = NSBezierPath()
        path.lineWidth = 1.0

        let sampleCount = evenByteCount / 2
        var byteOffset = 0
        var sampleIndex = 0

        while byteOffset + 1 < evenByteCount {
            let raw = UInt16(bytes[byteOffset]) | (UInt16(bytes[byteOffset + 1]) << 8)
            let value = Int16(bitPattern: raw)

            // Die Zeitachse belegt unabhängig von der Fenstergröße immer
            // exakt die gesamte Breite des Bordered Scroll View.
            let x: CGFloat
            if sampleCount > 1 {
                x = bounds.minX + CGFloat(sampleIndex) * bounds.width / CGFloat(sampleCount - 1)
            } else {
                x = bounds.midX
            }

            // Die BIN-Rohwerte besitzen für die vertikale Lage den Faktor 8:
            // rawValue / 8 entspricht der Reference_Zero-Skala.
            // Dadurch liegt der Mittelwert der Kurve auf demselben Y-Niveau
            // wie der zugehörige Reference_Zero-Marker.
            let referenceHeight: CGFloat = 500.0
            let yScale = bounds.height / referenceHeight
            let y = bounds.midY + (CGFloat(value) / 8.0) * yScale

            let point = NSPoint(x: x, y: y)
            if sampleIndex == 0 {
                path.move(to: point)
            } else {
                path.line(to: point)
            }

            byteOffset += 2
            sampleIndex += 1
        }

        path.stroke()
    }
}
