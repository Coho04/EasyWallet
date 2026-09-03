# EasyWallet

Keep track of what you subscribe to, what it costs, and when the next payment is due.

[![Flutter CI](https://github.com/Coho04/EasyWallet/actions/workflows/build.yml/badge.svg)](https://github.com/Coho04/EasyWallet/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![App Store](https://img.shields.io/badge/App_Store-Download-0D96F6?logo=apple&logoColor=white)](https://apps.apple.com/app/6478509715)
[![Google Play](https://img.shields.io/badge/Google_Play-Download-414141?logo=googleplay&logoColor=white)](https://play.google.com/store/apps/details?id=io.github.coho04.easy_wallet)

EasyWallet collects your recurring payments in one place. Everything is stored
on the device, reminders arrive before money leaves your account, and the app
shows what your subscriptions add up to over a month or a year. Sync via iCloud
or Google Drive is optional and off by default.

## Features

### Subscriptions

A subscription holds a title, an amount, a start date, a billing rate (monthly
or yearly), a payment method, a reminder cycle, optional notes, and a website.
The website provides the service's icon, which is why entries appear with their
real logo.

- **End date** — optional. A cancelled subscription runs until that day and is
  not billed afterwards; the day itself still counts.
- **Pause** — keeps the entry but stops billing and reminders.
- **Pin** — keeps important entries at the top.
- **Search and sort** — by name, price, or days remaining.

### Categories

Free-form categories with a colour of your choice. A subscription can belong to
several. Categories colour-code the calendar and can be hidden entirely.

### Calendar

A month grid showing which subscriptions are billed on which day, drawn with
their icons and ringed in their category colour. The selected day is listed in
full below the grid, the month's total above it.

Billing dates are derived from the subscriptions themselves, so nothing is
maintained twice. Month ends are handled without drift: a subscription starting
on the 31st falls on the 28th in February and returns to the 31st in March.

### Statistics

Remaining costs until the end of the month and of the year, the most expensive
subscriptions, cost distribution, monthly trend, and totals since installation.
Paused and expired subscriptions are left out of these figures.

### Reminders

Local notifications before a payment is due — on the day, one day, two days, or
a week ahead, configurable per subscription. The reminders are handed to the
operating system in advance, so they arrive at the configured time even if the
app never runs. Optionally the amount is included.

### Privacy

Data lives in a local SQLite database on the device. The app can be locked so
that subscriptions are only shown after a successful face scan; devices offering
only a fingerprint, and the device passcode, are not accepted as a fallback.

## Platforms

| Platform | Status |
| --- | --- |
| iOS | Published on the [App Store](https://apps.apple.com/app/6478509715) |
| Android | Published on [Google Play](https://play.google.com/store/apps/details?id=io.github.coho04.easy_wallet) |
| macOS, Windows, Linux, Web | Build targets exist in the repository; they are not published |

The interface follows the system language and is available in German and
English.

## Getting started

```bash
git clone https://github.com/Coho04/EasyWallet.git
cd EasyWallet
flutter pub get
flutter run
```

Use Flutter **3.47.1**. Other versions may fail to resolve dependencies. The
version is pinned in `.github/workflows/build.yml` and in
`ios/ci_scripts/ci_post_clone.sh`; change both together.

```bash
flutter test        # unit and widget tests
flutter analyze     # static analysis
```

Translations are generated, not written by hand. After editing
`lib/l10n/intl_de.arb` or `lib/l10n/intl_en.arb`:

```bash
dart pub global run intl_utils:generate
```

## How it is built

| | |
| --- | --- |
| Framework | Flutter with Cupertino widgets throughout; the only Material widget left in the running app is a transparent wrapper the third-party chip display requires |
| Storage | sqflite, schema version 5, migrated with `ALTER TABLE` on upgrade |
| State | `provider` |
| Localisation | `intl` with `intl_utils` |
| Notifications | `flutter_local_notifications`, scheduled ahead via `zonedSchedule` |
| Charts | `fl_chart` and `syncfusion_flutter_charts` |
| Error reporting | Sentry |

### Project layout

| Path | Contents |
| --- | --- |
| `lib/model/` | `Subscription`, `Category`, and their SQL |
| `lib/provider/` | Application state |
| `lib/class/` | Logic without I/O: billing dates, reminder planning, amount formatting |
| `lib/views/main/` | The five tabs: subscriptions, categories, calendar, statistics, settings |
| `lib/views/components/` | Reusable widgets |
| `lib/managers/` | Background work and notification scheduling |
| `lib/l10n/` | Translation sources |
| `test/` | Unit and widget tests |

## Contributing

Issues and pull requests are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md)
and the [Code of Conduct](CODE_OF_CONDUCT.md), and report security findings the
way [SECURITY.md](SECURITY.md) describes.

## License

MIT — see [LICENSE](LICENSE).
