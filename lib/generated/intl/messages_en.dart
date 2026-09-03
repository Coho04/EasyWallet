// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(count) => "${count} subscriptions";

  static String m1(count) => "${count} subscriptions imported";

  static String m2(title) => "Your subscription ${title} is due soon!";

  static String m3(title, price) =>
      "Your subscription ${title} (${price} €) is due soon!";

  static String m4(title) => "The trial of ${title} ends soon";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "D": MessageLookupByLibrary.simpleMessage("D"),
    "M": MessageLookupByLibrary.simpleMessage("M"),
    "OK": MessageLookupByLibrary.simpleMessage("OK"),
    "Y": MessageLookupByLibrary.simpleMessage("Y"),
    "about": MessageLookupByLibrary.simpleMessage("About"),
    "actions": MessageLookupByLibrary.simpleMessage("Actions"),
    "active": MessageLookupByLibrary.simpleMessage("Active"),
    "add": MessageLookupByLibrary.simpleMessage("Add"),
    "addNewCategory": MessageLookupByLibrary.simpleMessage("Add New Category"),
    "addNewSubscription": MessageLookupByLibrary.simpleMessage(
      "Add New Subscription",
    ),
    "addSubscription": MessageLookupByLibrary.simpleMessage("Add subscription"),
    "additionalInformation": MessageLookupByLibrary.simpleMessage(
      "Additional information",
    ),
    "all": MessageLookupByLibrary.simpleMessage("All"),
    "allCategories": MessageLookupByLibrary.simpleMessage("All"),
    "alphabeticalAscending": MessageLookupByLibrary.simpleMessage(
      "Alphabetical Ascending",
    ),
    "alphabeticalDescending": MessageLookupByLibrary.simpleMessage(
      "Alphabetical Descending",
    ),
    "appCurrency": MessageLookupByLibrary.simpleMessage("App currency"),
    "appStats": MessageLookupByLibrary.simpleMessage("App Statistics"),
    "apple_pay": MessageLookupByLibrary.simpleMessage("Apple Pay"),
    "byPaymentMethod": MessageLookupByLibrary.simpleMessage(
      "By payment method",
    ),
    "calendar": MessageLookupByLibrary.simpleMessage("Calendar"),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "categories": MessageLookupByLibrary.simpleMessage("Categories"),
    "categoryTitle": MessageLookupByLibrary.simpleMessage("Category Title"),
    "chooseAColor": MessageLookupByLibrary.simpleMessage("Choose a color"),
    "chooseColor": MessageLookupByLibrary.simpleMessage("Choose color"),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "contactDeveloper": MessageLookupByLibrary.simpleMessage(
      "Contact Developer",
    ),
    "continueSubscription": MessageLookupByLibrary.simpleMessage(
      "Continue this subscription",
    ),
    "convertedCosts": MessageLookupByLibrary.simpleMessage("Converted costs"),
    "costAscending": MessageLookupByLibrary.simpleMessage("Cost Ascending"),
    "costDescending": MessageLookupByLibrary.simpleMessage("Cost Descending"),
    "costDistribution": MessageLookupByLibrary.simpleMessage(
      "Cost distribution",
    ),
    "costShare": MessageLookupByLibrary.simpleMessage("Cost share"),
    "costs": MessageLookupByLibrary.simpleMessage("Costs"),
    "couldNotLaunch": MessageLookupByLibrary.simpleMessage("Could not launch"),
    "countSubscriptions": m0,
    "createdOn": MessageLookupByLibrary.simpleMessage("Created on"),
    "creditCard": MessageLookupByLibrary.simpleMessage("Creditcard"),
    "currency": MessageLookupByLibrary.simpleMessage("Currency"),
    "dataExportedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Data exported successfully.",
    ),
    "dataImportedFailed": MessageLookupByLibrary.simpleMessage(
      "Data imported failed.",
    ),
    "dataImportedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Data imported successfully.",
    ),
    "dataManagement": MessageLookupByLibrary.simpleMessage("Data Management"),
    "dayBefore": MessageLookupByLibrary.simpleMessage("One Day Before"),
    "days": MessageLookupByLibrary.simpleMessage("Days"),
    "daysRemainingAscending": MessageLookupByLibrary.simpleMessage(
      "Days Remaining Ascending",
    ),
    "daysRemainingDescending": MessageLookupByLibrary.simpleMessage(
      "Days Remaining Descending",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "deleteCategoryHint": MessageLookupByLibrary.simpleMessage(
      "This cannot be undone.",
    ),
    "deleteCategoryQuestion": MessageLookupByLibrary.simpleMessage(
      "Delete category?",
    ),
    "deleteSubscription": MessageLookupByLibrary.simpleMessage(
      "Delete this subscription",
    ),
    "deletionIsNotSupportedOnTheWeb": MessageLookupByLibrary.simpleMessage(
      "Deletion is not supported on the web",
    ),
    "displayCategories": MessageLookupByLibrary.simpleMessage(
      "Display categories",
    ),
    "done": MessageLookupByLibrary.simpleMessage("Done"),
    "edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "editCategory": MessageLookupByLibrary.simpleMessage("Edit Category"),
    "editSubscription": MessageLookupByLibrary.simpleMessage(
      "Edit subscription",
    ),
    "enableAuthProtection": MessageLookupByLibrary.simpleMessage(
      "Enable Biometric",
    ),
    "enableNotifications": MessageLookupByLibrary.simpleMessage(
      "Enable Notifications",
    ),
    "endDate": MessageLookupByLibrary.simpleMessage("End date"),
    "enterMonthlyLimit": MessageLookupByLibrary.simpleMessage(
      "Enter Monthly Limit",
    ),
    "error": MessageLookupByLibrary.simpleMessage("Error"),
    "expenditureThisYear": MessageLookupByLibrary.simpleMessage(
      "Expenditure this year",
    ),
    "expenditureUntilTheEndOfTheMonth": MessageLookupByLibrary.simpleMessage(
      "Expenses until the end of the month",
    ),
    "expenditureUntilTheEndOfTheYear": MessageLookupByLibrary.simpleMessage(
      "Expenditure until the end of the year",
    ),
    "expensesSinceAppInstallation": MessageLookupByLibrary.simpleMessage(
      "Expenditure since installing the app",
    ),
    "expensesThisMonth": MessageLookupByLibrary.simpleMessage(
      "Expenses this Month",
    ),
    "expensesThisYear": MessageLookupByLibrary.simpleMessage(
      "Expenses this Year",
    ),
    "expired": MessageLookupByLibrary.simpleMessage("Expired"),
    "export": MessageLookupByLibrary.simpleMessage("Export"),
    "exportData": MessageLookupByLibrary.simpleMessage("Export Data"),
    "exportFailed": MessageLookupByLibrary.simpleMessage("Export failed"),
    "feedback": MessageLookupByLibrary.simpleMessage("Feedback"),
    "firstDebit": MessageLookupByLibrary.simpleMessage("First Debit"),
    "general": MessageLookupByLibrary.simpleMessage("General"),
    "generalInformation": MessageLookupByLibrary.simpleMessage(
      "General information",
    ),
    "googleDriveLoginFailed": MessageLookupByLibrary.simpleMessage(
      "Google Drive login failed",
    ),
    "googleDriveLoginSuccess": MessageLookupByLibrary.simpleMessage(
      "Google Drive login successful",
    ),
    "googleDriveLogoutSuccess": MessageLookupByLibrary.simpleMessage(
      "Google Drive logout successful",
    ),
    "google_pay": MessageLookupByLibrary.simpleMessage("Google Pay"),
    "help": MessageLookupByLibrary.simpleMessage("Help"),
    "hint": MessageLookupByLibrary.simpleMessage("Hint"),
    "import": MessageLookupByLibrary.simpleMessage("Import"),
    "importData": MessageLookupByLibrary.simpleMessage("Import Data"),
    "importFailed": MessageLookupByLibrary.simpleMessage("Import failed"),
    "importedCount": m1,
    "imprint": MessageLookupByLibrary.simpleMessage("Imprint"),
    "inTrial": MessageLookupByLibrary.simpleMessage("Trial"),
    "includeCostInNotifications": MessageLookupByLibrary.simpleMessage(
      "Include cost in notifications",
    ),
    "invoice": MessageLookupByLibrary.simpleMessage("Invoice"),
    "invoiceInformation": MessageLookupByLibrary.simpleMessage(
      "Invoice information",
    ),
    "issuesOfAnnualSubscriptions": MessageLookupByLibrary.simpleMessage(
      "Issues of annual subscriptions",
    ),
    "issuesOfMonthlySubscriptions": MessageLookupByLibrary.simpleMessage(
      "Issues of monthly subscriptions",
    ),
    "loading": MessageLookupByLibrary.simpleMessage("Loading..."),
    "month": MessageLookupByLibrary.simpleMessage("month"),
    "monthTotal": MessageLookupByLibrary.simpleMessage("Month total"),
    "monthly": MessageLookupByLibrary.simpleMessage("Monthly"),
    "monthlyExpenses": MessageLookupByLibrary.simpleMessage("Monthly Expenses"),
    "monthlyLimit": MessageLookupByLibrary.simpleMessage("Monthly Limit"),
    "monthlyTrend": MessageLookupByLibrary.simpleMessage("Monthly trend"),
    "nextInvoice": MessageLookupByLibrary.simpleMessage("Next invoice"),
    "noActiveSubscriptions": MessageLookupByLibrary.simpleMessage(
      "No active subscriptions",
    ),
    "noBillingsThisDay": MessageLookupByLibrary.simpleMessage(
      "No billings on this day",
    ),
    "noCategoriesAvailable": MessageLookupByLibrary.simpleMessage(
      "No categories available",
    ),
    "noData": MessageLookupByLibrary.simpleMessage("No data"),
    "noDataYet": MessageLookupByLibrary.simpleMessage("No data yet"),
    "noEndDate": MessageLookupByLibrary.simpleMessage("No end date"),
    "noEntriesFound": MessageLookupByLibrary.simpleMessage("No entries found"),
    "noPriceChanges": MessageLookupByLibrary.simpleMessage(
      "No price changes yet",
    ),
    "noSubscriptions": MessageLookupByLibrary.simpleMessage("No subscriptions"),
    "noSubscriptionsAvailable": MessageLookupByLibrary.simpleMessage(
      "No subscriptions available",
    ),
    "noTrial": MessageLookupByLibrary.simpleMessage("No trial"),
    "notShared": MessageLookupByLibrary.simpleMessage("Not shared"),
    "notes": MessageLookupByLibrary.simpleMessage("Notes"),
    "notificationTime": MessageLookupByLibrary.simpleMessage(
      "Notification Time",
    ),
    "notifications": MessageLookupByLibrary.simpleMessage("Notifications"),
    "numberOfSubscriptions": MessageLookupByLibrary.simpleMessage(
      "Number of Subscriptions",
    ),
    "oneSubscription": MessageLookupByLibrary.simpleMessage("One subscription"),
    "openExpenditureYear": MessageLookupByLibrary.simpleMessage(
      "Open expenditure year",
    ),
    "outstandingExpenditureMonth": MessageLookupByLibrary.simpleMessage(
      "Outstanding expenditure month",
    ),
    "overview": MessageLookupByLibrary.simpleMessage("Overview"),
    "pauseSubscription": MessageLookupByLibrary.simpleMessage(
      "Pause this subscription",
    ),
    "paused": MessageLookupByLibrary.simpleMessage("Paused"),
    "pausedVsActive": MessageLookupByLibrary.simpleMessage("Paused vs Active"),
    "paymentMethode": MessageLookupByLibrary.simpleMessage("Payment Methode"),
    "paymentMethods": MessageLookupByLibrary.simpleMessage("Payment Methods"),
    "paymentRate": MessageLookupByLibrary.simpleMessage("Payment rate"),
    "paypal": MessageLookupByLibrary.simpleMessage("Paypal"),
    "pickAColor": MessageLookupByLibrary.simpleMessage("Pick a color"),
    "pinSubscription": MessageLookupByLibrary.simpleMessage(
      "Pin this subscription",
    ),
    "pinned": MessageLookupByLibrary.simpleMessage("Pinned"),
    "pinnedVsUnpinned": MessageLookupByLibrary.simpleMessage(
      "Pinned vs Unpinned",
    ),
    "pleaseAuthenticateYourselfToChangeThisSetting":
        MessageLookupByLibrary.simpleMessage(
          "Please authenticate yourself to change this setting",
        ),
    "pleaseAuthenticateYourselfToViewYourSubscriptions":
        MessageLookupByLibrary.simpleMessage(
          "Please authenticate yourself to view your subscriptions",
        ),
    "previousDebits": MessageLookupByLibrary.simpleMessage("Previous debits"),
    "previousInvoice": MessageLookupByLibrary.simpleMessage("Previous invoice"),
    "priceHistory": MessageLookupByLibrary.simpleMessage("Price history"),
    "privacyPolicy": MessageLookupByLibrary.simpleMessage("Privacy Policy"),
    "rateApp": MessageLookupByLibrary.simpleMessage("Rate the App"),
    "remainingCosts": MessageLookupByLibrary.simpleMessage("Remaining costs"),
    "remembering": MessageLookupByLibrary.simpleMessage("Remembering"),
    "repetitionRate": MessageLookupByLibrary.simpleMessage("Repetition rate"),
    "sameDay": MessageLookupByLibrary.simpleMessage("Same Day"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "search": MessageLookupByLibrary.simpleMessage("Search"),
    "security": MessageLookupByLibrary.simpleMessage("Security"),
    "select": MessageLookupByLibrary.simpleMessage("Select"),
    "selectCurrency": MessageLookupByLibrary.simpleMessage("Select Currency"),
    "sepa": MessageLookupByLibrary.simpleMessage("Sepa-Payment"),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "settingsAuthFailed": MessageLookupByLibrary.simpleMessage(
      "Authentication failed. Setting was not changed.",
    ),
    "sortOptions": MessageLookupByLibrary.simpleMessage("Sort Options"),
    "splitCount": MessageLookupByLibrary.simpleMessage("Shared by"),
    "startDate": MessageLookupByLibrary.simpleMessage("Start date"),
    "statistics": MessageLookupByLibrary.simpleMessage("Statistics"),
    "subscriptionCurrency": MessageLookupByLibrary.simpleMessage(
      "Subscription currency",
    ),
    "subscriptionIsDueSoon": m2,
    "subscriptionIsDueSoonWithPrice": m3,
    "subscriptionReminder": MessageLookupByLibrary.simpleMessage(
      "Subscription Reminder",
    ),
    "subscriptions": MessageLookupByLibrary.simpleMessage("Subscriptions"),
    "successfully": MessageLookupByLibrary.simpleMessage("Successfully"),
    "support": MessageLookupByLibrary.simpleMessage("Support"),
    "syncWithGoogleDrive": MessageLookupByLibrary.simpleMessage(
      "Sync with Google Drive",
    ),
    "syncWithICloud": MessageLookupByLibrary.simpleMessage("Sync with iCloud"),
    "tipJar": MessageLookupByLibrary.simpleMessage("Tip Jar"),
    "title": MessageLookupByLibrary.simpleMessage("Title"),
    "topSubscriptions": MessageLookupByLibrary.simpleMessage(
      "Top subscriptions",
    ),
    "total": MessageLookupByLibrary.simpleMessage("Total"),
    "totalCosts": MessageLookupByLibrary.simpleMessage("Total costs"),
    "totalExpenses": MessageLookupByLibrary.simpleMessage("Total Expenses"),
    "trialEndDate": MessageLookupByLibrary.simpleMessage("Trial end"),
    "trialEndsSoon": m4,
    "trialReminder": MessageLookupByLibrary.simpleMessage("Trial ending"),
    "twoDaysBefore": MessageLookupByLibrary.simpleMessage("Two Days Before"),
    "unknown": MessageLookupByLibrary.simpleMessage("unknown"),
    "unpinSubscription": MessageLookupByLibrary.simpleMessage(
      "Unpin this subscription",
    ),
    "unpinned": MessageLookupByLibrary.simpleMessage("Unpinned"),
    "untilEndOfMonth": MessageLookupByLibrary.simpleMessage(
      "Until end of month",
    ),
    "untilEndOfYear": MessageLookupByLibrary.simpleMessage("Until end of year"),
    "version": MessageLookupByLibrary.simpleMessage("Version"),
    "weekBefore": MessageLookupByLibrary.simpleMessage("One Week Before"),
    "year": MessageLookupByLibrary.simpleMessage("year"),
    "yearly": MessageLookupByLibrary.simpleMessage("Yearly"),
    "yearlyExpenses": MessageLookupByLibrary.simpleMessage("Yearly Expenses"),
    "yearlyVsMonthlyExpenses": MessageLookupByLibrary.simpleMessage(
      "Yearly vs Monthly Expenses",
    ),
    "yearlyVsMonthlyExpensesSubtitle": MessageLookupByLibrary.simpleMessage(
      "Monthly and annual expenditure relative to total expenditure",
    ),
    "yourShare": MessageLookupByLibrary.simpleMessage("Your share"),
  };
}
