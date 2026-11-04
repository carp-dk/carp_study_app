import SwiftUI

/// What the morph shows. Mirrors `CarpMorphMode` in the phone app.
enum CarpMorphMode {
    case collecting, syncing, sent, away
}

/// A sphere of CARP-red fragments that lights up with the sync's progress and
/// morphs into the CARP mark (assets/carp_logo.svg) once the data is sent.
struct CarpMorphView: View {
    var mode: CarpMorphMode
    var progress: Double

    @Environment(\.isLuminanceReduced) private var dimmed
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var clock = MorphClock()

    static let red = Color(red: 214 / 255, green: 29 / 255, blue: 65 / 255)

    var body: some View {
        // Always-on and Reduce Motion: no animation, just the still mark or sphere.
        TimelineView(.animation(paused: dimmed || reduceMotion)) { timeline in
            Canvas { context, size in
                clock.step(to: timeline.date, mode: mode, instant: dimmed || reduceMotion)
                MorphDrawing.draw(in: &context, size: size, clock: clock, mode: mode, progress: progress)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Animation state, advanced once per frame. A class so the Canvas can update it.
final class MorphClock {
    var time = 0.0, formed = 1.0, solid = 0.0
    private var last: Date?

    func step(to now: Date, mode: CarpMorphMode, instant: Bool) {
        let dt = min(0.05, last.map { now.timeIntervalSince($0) } ?? 0)
        last = now
        let formedTarget = (mode == .collecting || mode == .sent) ? 1.0 : 0.0
        let solidTarget = (mode == .sent && formed > 0.98) ? 1.0 : 0.0
        if instant {
            formed = formedTarget
            solid = mode == .sent ? 1 : 0
            return
        }
        time += dt * (mode == .away ? 0.2 : 1)
        formed += max(-dt / 1.7, min(dt / 1.7, formedTarget - formed))
        solid += (solidTarget - solid) * min(1, dt * 4)
    }
}

private struct Dot {
    let logo: CGPoint
    let white: Bool
    var sphere = (x: 0.0, y: 0.0, z: 0.0)
    var delay = 0.0
    var k = 0.0
}

private enum MorphDrawing {
    static let logoWidth = 37.925, logoMiddle = 15.64, grid = 0.78

    // The mark from assets/carp_logo.svg, in its SVG units.
    static let body: Path = {
        var p = Path()
        p.move(to: CGPoint(x: 28.4426, y: 6))
        p.addLine(to: CGPoint(x: 9.47791, y: 6))
        p.addLine(to: CGPoint(x: 9.47791, y: 15.6412))
        p.addCurve(to: CGPoint(x: 18.9603, y: 25.2825), control1: CGPoint(x: 9.47791, y: 20.9637), control2: CGPoint(x: 13.7211, y: 25.2825))
        p.addLine(to: CGPoint(x: 28.4426, y: 25.2825))
        p.addCurve(to: CGPoint(x: 37.925, y: 15.6412), control1: CGPoint(x: 33.6774, y: 25.2825), control2: CGPoint(x: 37.925, y: 20.9682))
        p.addCurve(to: CGPoint(x: 28.4426, y: 6), control1: CGPoint(x: 37.925, y: 10.3188), control2: CGPoint(x: 33.6818, y: 6))
        p.closeSubpath()
        return p
    }()

    static let tail: Path = {
        var p = Path()
        p.move(to: CGPoint(x: 9.48236, y: 15.6412))
        p.addCurve(to: CGPoint(x: 0, y: 6), control1: CGPoint(x: 9.48236, y: 10.3188), control2: CGPoint(x: 5.23473, y: 6))
        p.addLine(to: CGPoint(x: 0, y: 25.2825))
        p.addCurve(to: CGPoint(x: 9.48236, y: 15.6412), control1: CGPoint(x: 5.23473, y: 25.2825), control2: CGPoint(x: 9.48236, y: 20.9682))
        p.closeSubpath()
        return p
    }()

    static let plusCorners: [CGPoint] = [
        (32.5409, 14.2741), (29.0705, 14.2741), (29.0705, 10.75), (26.3861, 10.75),
        (26.3861, 14.2741), (22.9156, 14.2741), (22.9156, 17.0034), (26.3861, 17.0034),
        (26.3861, 20.532), (29.0705, 20.532), (29.0705, 17.0034), (32.5409, 17.0034),
    ].map { CGPoint(x: $0.0, y: $0.1) }

    static let plus: Path = {
        var p = Path()
        p.addLines(plusCorners)
        p.closeSubpath()
        return p
    }()

    /// Dots evenly spaced along each outline (so straight edges stay straight),
    /// then a regular grid inside, kept clear of the outlines.
    static let dots: [Dot] = {
        var dots: [Dot] = []
        for (path, white) in [(body, false), (tail, false), (plus, true)] {
            for point in outlinePoints(of: path) { dots.append(Dot(logo: point, white: white)) }
        }
        let outline = dots.map(\.logo)
        var y = 6 + grid
        while y < 25.3 {
            var x = grid / 2
            while x < logoWidth {
                let p = CGPoint(x: x, y: y)
                if !outline.contains(where: { hypot($0.x - x, $0.y - y) < grid * 0.75 }) {
                    if plus.contains(p) {
                        dots.append(Dot(logo: p, white: true))
                    } else if body.contains(p) || tail.contains(p) {
                        dots.append(Dot(logo: p, white: false))
                    }
                }
                x += grid
            }
            y += grid
        }
        var random = SeededRandom(seed: 1)
        dots.shuffle(using: &random)
        for i in dots.indices {
            // Golden-angle spiral: evenly spread points on a unit sphere.
            let sy = 1 - 2 * (Double(i) + 0.5) / Double(dots.count), r = (1 - sy * sy).squareRoot(), a = Double(i) * 2.39996
            dots[i].sphere = (cos(a) * r, sy, sin(a) * r)
            dots[i].delay = Double.random(in: 0..<0.45, using: &random)
            dots[i].k = Double.random(in: 0..<1, using: &random)
        }
        return dots
    }()

    /// Points every `grid` along a path's lines and curves, flattened into short segments.
    static func outlinePoints(of path: Path) -> [CGPoint] {
        var polyline: [CGPoint] = []
        var current = CGPoint.zero
        path.forEach { element in
            switch element {
            case .move(let p): current = p; polyline.append(p)
            case .line(let p): current = p; polyline.append(p)
            case .curve(let p, let c1, let c2):
                let p0 = current
                for i in 1...24 {
                    let t = Double(i) / 24, u = 1 - t
                    polyline.append(CGPoint(
                        x: u * u * u * p0.x + 3 * u * u * t * c1.x + 3 * u * t * t * c2.x + t * t * t * p.x,
                        y: u * u * u * p0.y + 3 * u * u * t * c1.y + 3 * u * t * t * c2.y + t * t * t * p.y))
                }
                current = p
            case .quadCurve(let p, _): current = p; polyline.append(p)
            case .closeSubpath: if let first = polyline.first { polyline.append(first) }
            }
        }
        let segments = zip(polyline, polyline.dropFirst()).map { ($0, $1, hypot($1.x - $0.x, $1.y - $0.y)) }
        let length = segments.reduce(0) { $0 + $1.2 }
        let n = Int((length / grid).rounded())
        var points: [CGPoint] = []
        var index = 0, walked = 0.0
        for i in 0..<n {
            let target = Double(i) * length / Double(n)
            while index < segments.count - 1 && walked + segments[index].2 < target {
                walked += segments[index].2
                index += 1
            }
            let (a, b, l) = segments[index], f = l > 0 ? (target - walked) / l : 0
            points.append(CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f))
        }
        return points
    }

    static func draw(in context: inout GraphicsContext, size: CGSize, clock: MorphClock, mode: CarpMorphMode, progress: Double) {
        let w = size.width, h = size.height, unit = w / 184
        let scale = 0.72 * w / logoWidth
        let origin = CGPoint(x: (w - logoWidth * scale) / 2, y: h / 2 - logoMiddle * scale)
        let radius = min(0.3 * w, 0.42 * h)
        let rot = clock.time * 0.75, cr = cos(rot), sr = sin(rot), ct = cos(0.35), st = sin(0.35)
        let fade = 1 - clock.solid
        let red = (214.0, 29.0, 65.0), white = (255.0, 255.0, 255.0), grey = (95.0, 95.0, 100.0), unlit = (80.0, 16.0, 30.0)

        if fade > 0.01 {
            for d in dots {
                var z = -d.sphere.x * sr + d.sphere.z * cr
                let x = d.sphere.x * cr + d.sphere.z * sr
                let y = d.sphere.y * ct - z * st
                z = d.sphere.y * st + z * ct
                let s = 1 / (1 + z * 0.35), depth = (1 - z) / 2
                let onLogo = CGPoint(x: origin.x + d.logo.x * scale, y: origin.y + d.logo.y * scale)
                var u = max(0, min(1, (clock.formed - d.delay) / 0.55))
                u = u * u * (3 - 2 * u)

                let from = mode == .away ? grey : (mode == .syncing && d.k >= progress) ? unlit : red
                let to = d.white ? white : red
                // Collecting: a wave of brightness runs across the still mark.
                let glow = (mode == .collecting && !d.white) ? 0.82 + 0.18 * sin(clock.time * 2 - onLogo.x / unit * 0.08) : 1
                let color = Color(
                    red: (from.0 + (to.0 - from.0) * u) * glow / 255,
                    green: (from.1 + (to.1 - from.1) * u) * glow / 255,
                    blue: (from.2 + (to.2 - from.2) * u) * glow / 255)
                let alpha = ((0.3 + 0.7 * depth) * (1 - u) + u) * fade
                let px = (w / 2 + x * radius * s) * (1 - u) + onLogo.x * u
                let py = (h / 2 + y * radius * s) * (1 - u) + onLogo.y * u
                let r = ((1 + depth * 1.3) * (1 - u) + 1.3 * u) * unit
                context.fill(Path(ellipseIn: CGRect(x: px - r, y: py - r, width: 2 * r, height: 2 * r)), with: .color(color.opacity(alpha)))
            }
        }

        if clock.solid > 0.01 {
            let transform = CGAffineTransform(translationX: origin.x, y: origin.y).scaledBy(x: scale, y: scale)
            context.fill(body.applying(transform), with: .color(CarpMorphView.red.opacity(clock.solid)))
            context.fill(tail.applying(transform), with: .color(CarpMorphView.red.opacity(clock.solid)))
            context.fill(plus.applying(transform), with: .color(.white.opacity(clock.solid)))
        }
    }
}

/// The same dot layout on every launch.
private struct SeededRandom: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
