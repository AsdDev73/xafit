import ActivityKit
import WidgetKit
import SwiftUI

private let appGroupId = "group.com.asddev73.xafit"

/// IMPORTANTE:
/// - Este archivo es una plantilla lista para pegar en la Widget Extension.
/// - No queda funcional por sí solo hasta crear la extensión en Xcode,
///   activar App Groups y añadir NSSupportsLiveActivities.
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState

    public struct ContentState: Codable, Hashable { }

    var id = UUID()

    func prefixedKey(_ key: String) -> String {
        "\(id)_\(key)"
    }
}

private extension ActivityViewContext where Attributes == LiveActivitiesAppAttributes {
    var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupId)!
    }

    func numberValue(_ key: String) -> NSNumber? {
        sharedDefaults.object(forKey: attributes.prefixedKey(key)) as? NSNumber
    }

    func stringValue(_ key: String, fallback: String = "") -> String {
        sharedDefaults.string(forKey: attributes.prefixedKey(key)) ?? fallback
    }

    func boolValue(_ key: String, fallback: Bool = false) -> Bool {
        (sharedDefaults.object(forKey: attributes.prefixedKey(key)) as? NSNumber)?.boolValue ?? fallback
    }

    func dateValue(_ key: String) -> Date? {
        guard let raw = numberValue(key) else { return nil }
        let milliseconds = raw.doubleValue
        guard milliseconds > 0 else { return nil }
        return Date(timeIntervalSince1970: milliseconds / 1000.0)
    }

    var workoutTitle: String {
        stringValue("title", fallback: "XaFit")
    }

    var currentExerciseName: String {
        stringValue("currentExerciseName", fallback: "Sin ejercicio")
    }

    var workoutStartedAt: Date? {
        dateValue("workoutStartedAtMs")
    }

    var restStartedAt: Date? {
        dateValue("restStartedAtMs")
    }

    var isResting: Bool {
        boolValue("isResting", fallback: false)
    }

    var exercisesCount: Int {
        numberValue("exercisesCount")?.intValue ?? 0
    }

    var setsCount: Int {
        numberValue("setsCount")?.intValue ?? 0
    }
}

private struct XaFitTimerText: View {
    let date: Date?
    let placeholder: String

    var body: some View {
        Group {
            if let date {
                Text(date, style: .timer)
                    .monospacedDigit()
            } else {
                Text(placeholder)
                    .monospacedDigit()
            }
        }
    }
}

private struct XaFitWorkoutLockScreenView: View {
    let context: ActivityViewContext<LiveActivitiesAppAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(context.workoutTitle)
                        .font(.headline)
                        .lineLimit(1)

                    Text(context.currentExerciseName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Entreno")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    XaFitTimerText(
                        date: context.workoutStartedAt,
                        placeholder: "00:00"
                    )
                    .font(.title2.bold())
                }
            }

            if context.isResting, let restStartedAt = context.restStartedAt {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                    Text("Descanso")
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Text(restStartedAt, style: .timer)
                        .monospacedDigit()
                        .font(.title3.bold())
                }
                .padding(10)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            HStack(spacing: 14) {
                Label("\(context.exercisesCount) ejercicios", systemImage: "list.bullet")
                Label("\(context.setsCount) series", systemImage: "number.square")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

@main
struct XaFitWorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            XaFitWorkoutLockScreenView(context: context)
                .activityBackgroundTint(Color.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Entreno")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        XaFitTimerText(
                            date: context.workoutStartedAt,
                            placeholder: "00:00"
                        )
                        .font(.title3.bold())
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    if context.isResting, let restStartedAt = context.restStartedAt {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Descanso")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text(restStartedAt, style: .timer)
                                .monospacedDigit()
                                .font(.title3.bold())
                        }
                    } else {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Series")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text("\(context.setsCount)")
                                .font(.title3.bold())
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(context.workoutTitle)
                                .font(.subheadline.bold())
                                .lineLimit(1)

                            Text(context.currentExerciseName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text("\(context.exercisesCount) ej.")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                XaFitTimerText(
                    date: context.workoutStartedAt,
                    placeholder: "00:00"
                )
                .font(.caption2.bold())
            } compactTrailing: {
                if context.isResting, let restStartedAt = context.restStartedAt {
                    Text(restStartedAt, style: .timer)
                        .monospacedDigit()
                        .font(.caption2.bold())
                } else {
                    Text("\(context.setsCount)S")
                        .font(.caption2.bold())
                }
            } minimal: {
                Image(systemName: context.isResting ? "timer" : "figure.strengthtraining.traditional")
            }
        }
    }
}
