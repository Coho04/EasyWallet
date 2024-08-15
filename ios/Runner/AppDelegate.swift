import Flutter
import UIKit
import CoreData

@main
@objc class AppDelegate: FlutterAppDelegate {
  lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "EasyWallet")
    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
    return container
  }()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let migrationChannel = FlutterMethodChannel(name: "com.example.easywallet/migration",
                                                binaryMessenger: controller.binaryMessenger)
    if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    migrationChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "exportCoreDataToJSON" {
        self.exportCoreDataToJSON(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func exportCoreDataToJSON(result: FlutterResult) {
    let context = persistentContainer.viewContext
    let fetchRequest: NSFetchRequest<Subscription> = Subscription.fetchRequest()

    do {
      let subscriptions = try context.fetch(fetchRequest)
      let jsonSubscriptions = try subscriptions.map { try $0.toDictionary() }
      let jsonData = try JSONSerialization.data(withJSONObject: jsonSubscriptions, options: .prettyPrinted)
      if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let jsonFilePath = documentDirectory.appendingPathComponent("subscriptions.json")
        try jsonData.write(to: jsonFilePath)
        print("Daten erfolgreich exportiert nach: \(jsonFilePath)")
        result(jsonFilePath.path)
      }
    } catch {
      print("Fehler beim Exportieren der Daten: \(error)")
      result(FlutterError(code: "EXPORT_ERROR", message: "Fehler beim Exportieren der Daten", details: nil))
    }
  }
}

extension Subscription {
  func toDictionary() throws -> [String: Any] {
    var dict: [String: Any] = [:]
    dict["amount"] = self.amount
    dict["date"] = self.date?.iso8601String() ?? NSNull()
    dict["isPaused"] = self.isPaused
    dict["isPinned"] = self.isPinned
    dict["notes"] = self.notes ?? NSNull()
    dict["remembercycle"] = self.remembercycle ?? NSNull()
    dict["repeating"] = self.repeating
    dict["repeatPattern"] = self.repeatPattern ?? NSNull()
    dict["timestamp"] = self.timestamp?.iso8601String() ?? NSNull()
    dict["title"] = self.title ?? NSNull()
    dict["url"] = self.url ?? NSNull()
    return dict
  }
}

extension Date {
  func iso8601String() -> String {
    let formatter = ISO8601DateFormatter()
    return formatter.string(from: self)
  }
}
