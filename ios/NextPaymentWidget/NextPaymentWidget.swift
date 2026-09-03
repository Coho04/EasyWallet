import SwiftUI
import WidgetKit

/// Values written by the Flutter side into the shared App Group. All
/// formatting happens there: the widget has no access to the database or to
/// the app's locale settings.
private enum WidgetKeys {
    static let appGroup = "group.de.golden-developer.EasyWallet"
    static let empty = "nextPaymentEmpty"
    static let title = "nextPaymentTitle"
    static let amount = "nextPaymentAmount"
    static let date = "nextPaymentDate"
}

struct NextPaymentEntry: TimelineEntry {
    let date: Date
    let isEmpty: Bool
    let title: String
    let amount: String
    let due: String
}

struct NextPaymentProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextPaymentEntry {
        NextPaymentEntry(date: Date(), isEmpty: false, title: "Netflix",
                         amount: "5,99 €", due: "Oct 2")
    }

    func getSnapshot(in context: Context,
                     completion: @escaping (NextPaymentEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<NextPaymentEntry>) -> Void) {
        // The app rewrites the values whenever something changes and asks for a
        // reload, so refreshing once an hour is only a safety net.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [readEntry()], policy: .after(next)))
    }

    private func readEntry() -> NextPaymentEntry {
        let defaults = UserDefaults(suiteName: WidgetKeys.appGroup)
        return NextPaymentEntry(
            date: Date(),
            isEmpty: defaults?.bool(forKey: WidgetKeys.empty) ?? true,
            title: defaults?.string(forKey: WidgetKeys.title) ?? "",
            amount: defaults?.string(forKey: WidgetKeys.amount) ?? "",
            due: defaults?.string(forKey: WidgetKeys.date) ?? ""
        )
    }
}

struct NextPaymentWidgetView: View {
    var entry: NextPaymentProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NEXT PAYMENT")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)

            if entry.isEmpty {
                Text("Nothing due")
                    .font(.system(size: 16, weight: .semibold))
            } else {
                Text(entry.title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                Text(entry.amount)
                    .font(.system(size: 20, weight: .bold))
                Text(entry.due)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@main
struct NextPaymentWidget: Widget {
    let kind: String = "NextPaymentWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextPaymentProvider()) { entry in
            if #available(iOS 17.0, *) {
                NextPaymentWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                NextPaymentWidgetView(entry: entry).padding()
            }
        }
        .configurationDisplayName("Next payment")
        .description("The next subscription that is billed.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
