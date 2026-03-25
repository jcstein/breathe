import SwiftUI

struct BreathView: View {
    @ObservedObject var engine: BreathEngine

    var circleScale: CGFloat {
        0.4 + 0.6 * engine.expansion
    }

    var circleOpacity: Double {
        0.4 + 0.5 * engine.expansion
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("breathe")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                if engine.isBreathing {
                    Text("\(engine.cycleCount) cycles")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 4)

            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.accentColor.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .scaleEffect(circleScale * 1.3)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.accentColor.opacity(0.9), .accentColor.opacity(0.5)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 150, height: 150)
                    .scaleEffect(circleScale)
                    .opacity(circleOpacity)

                if engine.isBreathing {
                    Text(String(format: "%.1f", engine.remaining))
                        .font(.system(size: 28, weight: .light, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
            }
            .frame(width: 200, height: 200)
            .onTapGesture {
                engine.toggle()
            }

            Text(engine.phase.rawValue)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(engine.isBreathing ? .primary : .secondary)

            Text("5.5s in \u{00B7} 5.5s out")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(.tertiary)

            Spacer()

            HStack {
                Spacer()
                Button("quit") { NSApp.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 4)
        }
        .padding(20)
        .frame(width: 280, height: 340)
    }
}
