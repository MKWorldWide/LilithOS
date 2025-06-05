import SwiftUI

public struct StarfieldView: View {
  @State private var phase = 0.0
  public init() {}
  public var body: some View {
    TimelineView(.animation) { _ in
      Canvas { context, size in
        let starCount = 100
        for _ in 0..<starCount {
          let x = Double.random(in: 0...size.width)
          let y = Double.random(in: 0...size.height)
          let opacity = Double.random(in: 0.3...0.8)
          let size = Double.random(in: 1...3)
          context.opacity = opacity
          context.fill(
            Path(ellipseIn: CGRect(x: x, y: y, width: size, height: size)),
            with: .color(.white)
          )
        }
      }
    }
  }
} 