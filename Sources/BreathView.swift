import SwiftUI

struct BreathView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var engine: BreathEngine
    @ObservedObject var stats: UsageStats

    private var countdownColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.05, green: 0.15, blue: 0.29)
    }

    var circleScale: CGFloat {
        0.4 + 0.6 * engine.expansion
    }

    var circleOpacity: Double {
        0.4 + 0.5 * engine.expansion
    }

    static func cycleCountLabel(_ count: Int) -> LocalizedStringResource {
        count == 1 ? "1 cycle" : "\(count) cycles"
    }

    static func minutesLabel(_ count: Int) -> LocalizedStringResource {
        "\(count) min"
    }

    static func sessionsLabel(_ count: Int) -> LocalizedStringResource {
        count == 1 ? "1 session" : "\(count) sessions"
    }

    static func streakLabel(_ count: Int) -> LocalizedStringResource {
        count == 1 ? "1 day" : "\(count) days"
    }

    private func statColumn(_ value: LocalizedStringResource, _ caption: LocalizedStringResource) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Text(caption)
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var patternPicker: some View {
        HStack(spacing: 2) {
            ForEach(BreathEngine.Pattern.allCases) { pattern in
                let isSelected = engine.pattern == pattern
                Button {
                    engine.pattern = pattern
                } label: {
                    Text(pattern.rawValue)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(isSelected ? .secondary : .tertiary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.primary.opacity(isSelected ? 0.08 : 0)))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Breathing pattern")
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("breathe")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                if engine.isBreathing {
                    Text(Self.cycleCountLabel(engine.cycleCount))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 4)

            Spacer()

            Button {
                engine.toggle()
            } label: {
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
                            .foregroundStyle(countdownColor)
                            .monospacedDigit()
                    }
                }
                .frame(width: 200, height: 200)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
            .accessibilityLabel(engine.isBreathing ? "End Session" : "Start")

            Text(engine.phase.label)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(engine.isBreathing ? .primary : .secondary)

            Text(engine.pattern.summary)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(.tertiary)

            patternPicker
                .disabled(engine.isBreathing)

            Spacer()

            HStack(spacing: 0) {
                statColumn(Self.minutesLabel(stats.minutesToday), "today")
                statColumn(Self.sessionsLabel(stats.sessionsThisWeek), "this week")
                statColumn(Self.streakLabel(stats.streakDays), "streak")
            }

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
        .frame(width: 280)
    }
}
