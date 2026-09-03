# iOS widget

The target `NextPaymentWidget` is part of `Runner.xcodeproj`, it is embedded
into `Runner.app/PlugIns/` and it builds. Nothing has to be created in Xcode.

What is left is signing, which cannot be done from a repository.

## Once, in the Apple Developer portal

The widget is its own App ID and both it and the app must share an App Group.

1. Certificates, Identifiers & Profiles → **Identifiers** → **App Groups**:
   create `group.de.golden-developer.EasyWallet` if it does not exist.
2. **Identifiers → App IDs**: make sure
   `de.golden-developer.EasyWallet.NextPaymentWidget` exists, and enable the
   *App Groups* capability on it and on `de.golden-developer.EasyWallet`,
   each pointing at the group above.
3. Regenerate the provisioning profiles, or let Xcode do it: with automatic
   signing, opening the project with your account and building to a device
   creates the App ID and updates the profiles for you.

The same group id appears in three places and they have to agree:

- `ios/Runner/Runner.entitlements`
- `ios/NextPaymentWidget/NextPaymentWidget.entitlements`
- `HomeWidgetBridge.appGroupId` in `lib/managers/home_widget_bridge.dart`

## To see it on a device

1. Build a **signed** build onto the iPhone: open `ios/Runner.xcworkspace`,
   pick the *Runner* scheme and your device, and run. `--no-codesign` builds
   cannot be installed.
2. Start the app once. The widget shows what the app writes; before the first
   launch there is nothing to read.
3. On the iPhone, long press the home screen → **+** → search for *EasyWallet*
   → pick a size → *Add widget*.

Without an upcoming payment the widget reads "Nothing due" - that is the empty
state, not a failure.
