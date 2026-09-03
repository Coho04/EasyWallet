# iOS widget setup

The Swift source next to this file is complete. What it needs is an Xcode
target, and that cannot be scripted safely: `project.pbxproj` is generated and
a bad edit breaks the whole iOS build. These steps take a couple of minutes in
Xcode and only have to be done once.

1. Open `ios/Runner.xcworkspace` in Xcode.
2. **File → New → Target… → Widget Extension**. Name it `NextPaymentWidget`.
   Uncheck *Include Live Activity* and *Include Configuration App Intent*.
   When Xcode offers to activate the new scheme, accept.
3. Xcode creates a folder with template Swift files. Delete the generated
   `NextPaymentWidget.swift` and drag `ios/NextPaymentWidget/NextPaymentWidget.swift`
   from this repository into the target instead ("Copy items if needed" off).
4. Select the **Runner** target → *Signing & Capabilities* → **+ Capability** →
   **App Groups**, and add `group.de.golden-developer.EasyWallet`.
5. Repeat step 4 for the **NextPaymentWidget** target. Both need the same group,
   otherwise the widget cannot read what the app writes.
6. Set the widget target's *Minimum Deployment* to the same iOS version the
   Runner target uses.

The group id also appears in `lib/managers/home_widget_bridge.dart` as
`HomeWidgetBridge.appGroupId`. Change it in all three places or nowhere.

Xcode Cloud picks the new target up automatically once it is committed, but the
provisioning profile has to carry the App Group, so the first cloud build after
this change is worth watching.
