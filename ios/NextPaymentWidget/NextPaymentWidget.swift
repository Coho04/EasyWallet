import SwiftUI
import WidgetKit

private enum WidgetKeys {
    static let appGroup = "group.de.golden-developer.EasyWallet"
    static let upcomingImage = "upcomingImage"
    static let calendarImage = "calendarImage"
}

/// Both widgets show a picture the Flutter side renders. That keeps one
/// drawing for iOS and Android, lets the calendar reuse the grid from the app,
/// and puts the subscription icons on the widget without loading them here.
/// Why there is nothing to show.
///
/// UserDefaults(suiteName:) hands back an object even when the App Group is
/// not shared, so an unreadable group is indistinguishable from an app that
/// never wrote. Both end up in `noData`; the app's settings say which it is.
enum EmptyReason {
    case noData
    case fileMissing

    var message: String {
        switch self {
        case .noData:
            return "No data in the shared container.\nSee Settings › About."
        case .fileMissing:
            return "Data outdated.\nOpen EasyWallet once."
        }
    }
}

struct ImageEntry: TimelineEntry {
    let date: Date
    let image: UIImage?
    let reason: EmptyReason?
}

struct ImageProvider: TimelineProvider {
    let key: String

    func placeholder(in context: Context) -> ImageEntry {
        ImageEntry(date: Date(), image: nil, reason: .noData)
    }

    func getSnapshot(in context: Context, completion: @escaping (ImageEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ImageEntry>) -> Void) {
        // The app rewrites the picture whenever something changes and asks for
        // a reload; refreshing hourly is only a safety net.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [readEntry()], policy: .after(next)))
    }

    private func readEntry() -> ImageEntry {
        // Without the App Group entitlement in the profile this is nil, which
        // is the usual reason a widget stays empty on a real device.
        guard let defaults = UserDefaults(suiteName: WidgetKeys.appGroup),
              let path = defaults.string(forKey: key) else {
            return ImageEntry(date: Date(), image: nil, reason: .noData)
        }
        // The path carries the container id, which changes when the app is
        // reinstalled; the file is then gone until the app writes again.
        guard let image = UIImage(contentsOfFile: path) else {
            return ImageEntry(date: Date(), image: nil, reason: .fileMissing)
        }
        return ImageEntry(date: Date(), image: image, reason: nil)
    }
}

struct ImageWidgetView: View {
    var entry: ImageEntry

    var body: some View {
        if let image = entry.image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            VStack(spacing: 4) {
                Text("EasyWallet")
                    .font(.system(size: 13, weight: .semibold))
                Text(entry.reason?.message ?? "")
                    .font(.system(size: 11))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct NextPaymentWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "NextPaymentWidget",
            provider: ImageProvider(key: WidgetKeys.upcomingImage)
        ) { entry in
            if #available(iOS 17.0, *) {
                ImageWidgetView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
            } else {
                ImageWidgetView(entry: entry).padding()
            }
        }
        .configurationDisplayName("Upcoming payments")
        .description("The next subscriptions that are billed.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct CalendarWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "CalendarWidget",
            provider: ImageProvider(key: WidgetKeys.calendarImage)
        ) { entry in
            if #available(iOS 17.0, *) {
                ImageWidgetView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
            } else {
                ImageWidgetView(entry: entry).padding()
            }
        }
        .configurationDisplayName("Billing calendar")
        .description("This month, with a dot on every day something is billed.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

@main
struct EasyWalletWidgets: WidgetBundle {
    var body: some Widget {
        NextPaymentWidget()
        CalendarWidget()
    }
}
