import SwiftUI
import WidgetKit

private enum WidgetKeys {
    static let appGroup = "group.de.golden-developer.EasyWallet"
    static let upcoming = "upcomingData"
    static let calendar = "calendarData"
}

/// Why there is nothing to show.
///
/// UserDefaults(suiteName:) hands back an object even when the App Group is
/// not shared, so an unreadable group is indistinguishable from an app that
/// never wrote. Both end up in `noData`; the app's settings say which it is.
enum EmptyReason {
    case noData
    case unreadable

    var message: String {
        switch self {
        case .noData:
            return "No data in the shared container.\nSee Settings › About."
        case .unreadable:
            return "Could not read the data.\nOpen EasyWallet once."
        }
    }
}

// MARK: - Data

/// A colour the app picked for a category, as "#RRGGBB". The widget falls back
/// to its own accent when a subscription has no category.
private func color(fromHex hex: String) -> Color? {
    var value = hex
    if value.hasPrefix("#") { value.removeFirst() }
    guard value.count == 6, let rgb = UInt32(value, radix: 16) else { return nil }
    return Color(
        red: Double((rgb >> 16) & 0xFF) / 255,
        green: Double((rgb >> 8) & 0xFF) / 255,
        blue: Double(rgb & 0xFF) / 255
    )
}

struct PaymentRow: Identifiable {
    let id = UUID()
    let days: Int
    let title: String
    let amount: String
    let iconPath: String
    let colorHex: String

    var accent: Color { color(fromHex: colorHex) ?? .accentColor }

    /// "Today" reads better than "0 d" on the day something is billed.
    var dayLabel: String { days == 0 ? "Today" : "\(days) d" }

    var icon: UIImage? {
        iconPath.isEmpty ? nil : UIImage(contentsOfFile: iconPath)
    }
}

struct UpcomingData {
    let rows: [PaymentRow]

    static func decode(_ json: [String: Any]) -> UpcomingData {
        let items = json["items"] as? [[String: Any]] ?? []
        return UpcomingData(rows: items.map { item in
            PaymentRow(
                days: item["days"] as? Int ?? 0,
                title: item["title"] as? String ?? "",
                amount: item["amount"] as? String ?? "",
                iconPath: item["icon"] as? String ?? "",
                colorHex: item["color"] as? String ?? ""
            )
        })
    }
}

struct CalendarData {
    let title: String
    let total: String
    let dayCount: Int
    let leadingBlanks: Int
    let today: Int
    let marks: [Int: [Color]]

    static func decode(_ json: [String: Any]) -> CalendarData {
        // JSONSerialization hands the nested arrays over as Any, so they are
        // unwrapped one at a time rather than cast in one go.
        var marks: [Int: [Color]] = [:]
        for (key, value) in json["marks"] as? [String: Any] ?? [:] {
            guard let day = Int(key), let hexes = value as? [Any] else { continue }
            marks[day] = hexes.map { color(fromHex: $0 as? String ?? "") ?? .accentColor }
        }
        return CalendarData(
            title: json["title"] as? String ?? "",
            total: json["total"] as? String ?? "",
            dayCount: json["dayCount"] as? Int ?? 0,
            leadingBlanks: json["leadingBlanks"] as? Int ?? 0,
            today: json["today"] as? Int ?? 0,
            marks: marks
        )
    }
}

// MARK: - Provider

struct DataEntry<Payload>: TimelineEntry {
    let date: Date
    let payload: Payload?
    let reason: EmptyReason?
}

struct JSONProvider<Payload>: TimelineProvider {
    let key: String
    let decode: ([String: Any]) -> Payload

    func placeholder(in context: Context) -> DataEntry<Payload> {
        DataEntry(date: Date(), payload: nil, reason: .noData)
    }

    func getSnapshot(in context: Context, completion: @escaping (DataEntry<Payload>) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DataEntry<Payload>>) -> Void) {
        // The app rewrites the data whenever something changes and asks for a
        // reload. Refreshing at midnight keeps the day counts honest when it
        // does not, because every one of them is a day out by then.
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        completion(Timeline(entries: [readEntry()], policy: .after(midnight)))
    }

    private func readEntry() -> DataEntry<Payload> {
        guard let defaults = UserDefaults(suiteName: WidgetKeys.appGroup),
              let raw = defaults.string(forKey: key), !raw.isEmpty else {
            return DataEntry(date: Date(), payload: nil, reason: .noData)
        }
        guard let data = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return DataEntry(date: Date(), payload: nil, reason: .unreadable)
        }
        return DataEntry(date: Date(), payload: decode(json), reason: nil)
    }
}

// MARK: - Shared pieces

struct PlaceholderView: View {
    let reason: EmptyReason?

    var body: some View {
        VStack(spacing: 4) {
            Text("EasyWallet").font(.footnote.weight(.semibold))
            Text(reason?.message ?? "")
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// The favicon, or the first letter when there is none. Both keep the same
/// footprint so the rows stay aligned.
struct IconView: View {
    let row: PaymentRow
    var side: CGFloat = 20

    var body: some View {
        Group {
            if let icon = row.icon {
                Image(uiImage: icon).resizable().aspectRatio(contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(row.accent.opacity(0.25))
                    .overlay(
                        Text(row.title.prefix(1))
                            .font(.system(size: side * 0.55, weight: .semibold))
                            .foregroundStyle(row.accent)
                    )
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

// MARK: - Upcoming payments

struct UpcomingWidgetView: View {
    var entry: DataEntry<UpcomingData>
    @Environment(\.widgetFamily) private var family

    private var visibleRows: [PaymentRow] {
        let limit = family == .systemLarge ? 10 : 4
        return Array((entry.payload?.rows ?? []).prefix(limit))
    }

    var body: some View {
        if entry.payload == nil {
            PlaceholderView(reason: entry.reason)
        } else if visibleRows.isEmpty {
            VStack(spacing: 4) {
                Text("Upcoming").font(.caption.weight(.semibold))
                Text("Nothing due").font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("UPCOMING")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 6)

                ForEach(Array(visibleRows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 { Divider().opacity(0.4) }
                    HStack(spacing: 8) {
                        Text(row.dayLabel)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(row.days <= 2 ? .red : .secondary)
                            .frame(width: 42, alignment: .leading)

                        IconView(row: row)

                        Text(row.title)
                            .font(.system(size: 13))
                            .lineLimit(1)

                        Spacer(minLength: 4)

                        if !row.amount.isEmpty {
                            Text(row.amount)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 24)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Calendar

struct CalendarWidgetView: View {
    var entry: DataEntry<CalendarData>

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekdays = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        if let data = entry.payload {
            VStack(spacing: 4) {
                HStack {
                    Text(data.title).font(.system(size: 12, weight: .semibold))
                    Spacer()
                    Text(data.total)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(0..<7, id: \.self) { index in
                        Text(weekdays[index])
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    ForEach(0..<data.leadingBlanks, id: \.self) { _ in
                        Color.clear.frame(height: 18)
                    }
                    ForEach(1...max(data.dayCount, 1), id: \.self) { day in
                        DayCell(
                            day: day,
                            isToday: day == data.today,
                            marks: data.marks[day] ?? []
                        )
                    }
                }

                Spacer(minLength: 0)
            }
        } else {
            PlaceholderView(reason: entry.reason)
        }
    }
}

struct DayCell: View {
    let day: Int
    let isToday: Bool
    let marks: [Color]

    var body: some View {
        VStack(spacing: 1) {
            Text("\(day)")
                .font(.system(size: 10, weight: isToday ? .bold : .regular))
                .foregroundStyle(isToday ? Color.white : Color.primary)
                .frame(width: 16, height: 16)
                .background(
                    Circle().fill(isToday ? Color.accentColor : Color.clear)
                )

            HStack(spacing: 1) {
                // More than three billings on one day would not be legible at
                // this size, so the rest stay unmarked.
                ForEach(Array(marks.prefix(3).enumerated()), id: \.offset) { _, color in
                    Circle().fill(color).frame(width: 3, height: 3)
                }
            }
            .frame(height: 3)
        }
    }
}

// MARK: - Widgets

struct NextPaymentWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "NextPaymentWidget",
            provider: JSONProvider(key: WidgetKeys.upcoming, decode: UpcomingData.decode)
        ) { entry in
            if #available(iOS 17.0, *) {
                UpcomingWidgetView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
            } else {
                UpcomingWidgetView(entry: entry).padding()
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
            provider: JSONProvider(key: WidgetKeys.calendar, decode: CalendarData.decode)
        ) { entry in
            if #available(iOS 17.0, *) {
                CalendarWidgetView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
            } else {
                CalendarWidgetView(entry: entry).padding()
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
