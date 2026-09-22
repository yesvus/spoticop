// Generates plain generic AppIcon.icns and preview PNG for SpotiCop.
import AppKit
import CoreGraphics

func createPlainIcon(size: Int) -> CGImage {
    let s = CGFloat(size)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
    
    let scale = s / 1024.0
    ctx.scaleBy(x: scale, y: scale)
    
    // 1. Standard macOS Squircle (824x824 inside 1024x1024)
    let squircleRect = CGRect(x: 100, y: 100, width: 824, height: 824)
    let squirclePath = CGPath(roundedRect: squircleRect, cornerWidth: 185, cornerHeight: 185, transform: nil)
    
    // Subtle drop shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 24, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.35))
    ctx.addPath(squirclePath)
    ctx.setFillColor(CGColor(red: 0.1, green: 0.75, blue: 0.35, alpha: 1.0))
    ctx.fillPath()
    ctx.restoreGState()
    
    // Clip to squircle
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()
    
    // Background: Spotify Green with subtle Apple-style gradient
    let bgColors = [
        CGColor(red: 0.13, green: 0.78, blue: 0.37, alpha: 1.0), // #21C75E
        CGColor(red: 0.08, green: 0.64, blue: 0.29, alpha: 1.0)  // #15A44A
    ] as CFArray
    let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
    
    // Subtle inner rim highlight
    ctx.setLineWidth(3)
    ctx.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.18))
    ctx.addPath(squirclePath)
    ctx.strokePath()
    
    // 2. Shield: Solid crisp white silhouette
    let shieldPath = CGMutablePath()
    shieldPath.move(to: CGPoint(x: 512, y: 790))
    shieldPath.addLine(to: CGPoint(x: 740, y: 730))
    shieldPath.addQuadCurve(to: CGPoint(x: 710, y: 430), control: CGPoint(x: 740, y: 550))
    shieldPath.addQuadCurve(to: CGPoint(x: 512, y: 230), control: CGPoint(x: 650, y: 310))
    shieldPath.addQuadCurve(to: CGPoint(x: 314, y: 430), control: CGPoint(x: 374, y: 310))
    shieldPath.addQuadCurve(to: CGPoint(x: 284, y: 730), control: CGPoint(x: 284, y: 550))
    shieldPath.closeSubpath()
    
    // Subtle shadow under shield
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 16, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.18))
    ctx.addPath(shieldPath)
    ctx.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
    ctx.fillPath()
    ctx.restoreGState()
    
    // 3. Three clean Spotify Sound Arcs in Dark Green (flat vector)
    let waveCenter = CGPoint(x: 512, y: 370)
    let waveColor = CGColor(red: 0.07, green: 0.38, blue: 0.18, alpha: 1.0)
    
    func drawFlatArc(radius: CGFloat, width: CGFloat, angleSpan: CGFloat) {
        let startAngle = (CGFloat.pi / 2.0) - (angleSpan / 2.0)
        let endAngle = (CGFloat.pi / 2.0) + (angleSpan / 2.0)
        
        let path = CGMutablePath()
        path.addArc(center: waveCenter, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        
        ctx.setLineWidth(width)
        ctx.setLineCap(.round)
        ctx.setStrokeColor(waveColor)
        ctx.addPath(path)
        ctx.strokePath()
    }
    
    drawFlatArc(radius: 230, width: 34, angleSpan: 1.10)
    drawFlatArc(radius: 160, width: 30, angleSpan: 1.15)
    drawFlatArc(radius: 95,  width: 26, angleSpan: 1.25)
    
    ctx.restoreGState()
    
    return ctx.makeImage()!
}

let fm = FileManager.default
let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().path
let resourcesDir = "\(scriptDir)/Resources"
let iconsetDir = "\(resourcesDir)/AppIcon.iconset"

try? fm.removeItem(atPath: iconsetDir)
try fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let specs: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in specs {
    let cg = createPlainIcon(size: size)
    let rep = NSBitmapImageRep(cgImage: cg)
    let png = rep.representation(using: .png, properties: [:])!
    try png.write(to: URL(fileURLWithPath: "\(iconsetDir)/\(name)"))
}

let appIconCg = createPlainIcon(size: 1024)
let appIconRep = NSBitmapImageRep(cgImage: appIconCg)
let appIconPng = appIconRep.representation(using: .png, properties: [:])!
try appIconPng.write(to: URL(fileURLWithPath: "\(resourcesDir)/AppIcon.png"))

print("Generated iconset at \(iconsetDir)")
