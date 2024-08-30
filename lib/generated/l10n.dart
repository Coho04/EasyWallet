// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Subscriptions`
  String get subscriptions {
    return Intl.message(
      'Subscriptions',
      name: 'subscriptions',
      desc: 'Label for the subscriptions tab',
      args: [],
    );
  }

  /// `Statistics`
  String get statistics {
    return Intl.message(
      'Statistics',
      name: 'statistics',
      desc: 'Label for the statistics tab',
      args: [],
    );
  }

  /// `Notifications`
  String get notifications {
    return Intl.message(
      'Notifications',
      name: 'notifications',
      desc: '',
      args: [],
    );
  }

  /// `Enable Notifications`
  String get enableNotifications {
    return Intl.message(
      'Enable Notifications',
      name: 'enableNotifications',
      desc: '',
      args: [],
    );
  }

  /// `Include cost in notifications`
  String get includeCostInNotifications {
    return Intl.message(
      'Include cost in notifications',
      name: 'includeCostInNotifications',
      desc: '',
      args: [],
    );
  }

  /// `Notification Time`
  String get notificationTime {
    return Intl.message(
      'Notification Time',
      name: 'notificationTime',
      desc: '',
      args: [],
    );
  }

  /// `Currency`
  String get currency {
    return Intl.message(
      'Currency',
      name: 'currency',
      desc: '',
      args: [],
    );
  }

  /// `Monthly Limit`
  String get monthlyLimit {
    return Intl.message(
      'Monthly Limit',
      name: 'monthlyLimit',
      desc: '',
      args: [],
    );
  }

  /// `Support`
  String get support {
    return Intl.message(
      'Support',
      name: 'support',
      desc: '',
      args: [],
    );
  }

  /// `Imprint`
  String get imprint {
    return Intl.message(
      'Imprint',
      name: 'imprint',
      desc: '',
      args: [],
    );
  }

  /// `Privacy Policy`
  String get privacyPolicy {
    return Intl.message(
      'Privacy Policy',
      name: 'privacyPolicy',
      desc: '',
      args: [],
    );
  }

  /// `Help`
  String get help {
    return Intl.message(
      'Help',
      name: 'help',
      desc: '',
      args: [],
    );
  }

  /// `Feedback`
  String get feedback {
    return Intl.message(
      'Feedback',
      name: 'feedback',
      desc: '',
      args: [],
    );
  }

  /// `Contact Developer`
  String get contactDeveloper {
    return Intl.message(
      'Contact Developer',
      name: 'contactDeveloper',
      desc: '',
      args: [],
    );
  }

  /// `Tip Jar`
  String get tipJar {
    return Intl.message(
      'Tip Jar',
      name: 'tipJar',
      desc: '',
      args: [],
    );
  }

  /// `Rate the App`
  String get rateApp {
    return Intl.message(
      'Rate the App',
      name: 'rateApp',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get search {
    return Intl.message(
      'Search',
      name: 'search',
      desc: '',
      args: [],
    );
  }

  /// `Expenses this Month`
  String get expensesThisMonth {
    return Intl.message(
      'Expenses this Month',
      name: 'expensesThisMonth',
      desc: '',
      args: [],
    );
  }

  /// `Expenses this Year`
  String get expensesThisYear {
    return Intl.message(
      'Expenses this Year',
      name: 'expensesThisYear',
      desc: '',
      args: [],
    );
  }

  /// `No subscriptions available`
  String get noSubscriptionsAvailable {
    return Intl.message(
      'No subscriptions available',
      name: 'noSubscriptionsAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Add New Subscription`
  String get addNewSubscription {
    return Intl.message(
      'Add New Subscription',
      name: 'addNewSubscription',
      desc: '',
      args: [],
    );
  }

  /// `Sort Options`
  String get sortOptions {
    return Intl.message(
      'Sort Options',
      name: 'sortOptions',
      desc: '',
      args: [],
    );
  }

  /// `Alphabetical Ascending`
  String get alphabeticalAscending {
    return Intl.message(
      'Alphabetical Ascending',
      name: 'alphabeticalAscending',
      desc: '',
      args: [],
    );
  }

  /// `Alphabetical Descending`
  String get alphabeticalDescending {
    return Intl.message(
      'Alphabetical Descending',
      name: 'alphabeticalDescending',
      desc: '',
      args: [],
    );
  }

  /// `Cost Ascending`
  String get costAscending {
    return Intl.message(
      'Cost Ascending',
      name: 'costAscending',
      desc: '',
      args: [],
    );
  }

  /// `Cost Descending`
  String get costDescending {
    return Intl.message(
      'Cost Descending',
      name: 'costDescending',
      desc: '',
      args: [],
    );
  }

  /// `Days Remaining Ascending`
  String get daysRemainingAscending {
    return Intl.message(
      'Days Remaining Ascending',
      name: 'daysRemainingAscending',
      desc: '',
      args: [],
    );
  }

  /// `Days Remaining Descending`
  String get daysRemainingDescending {
    return Intl.message(
      'Days Remaining Descending',
      name: 'daysRemainingDescending',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Could not launch`
  String get couldNotLaunch {
    return Intl.message(
      'Could not launch',
      name: 'couldNotLaunch',
      desc: '',
      args: [],
    );
  }

  /// `Error`
  String get error {
    return Intl.message(
      'Error',
      name: 'error',
      desc: '',
      args: [],
    );
  }

  /// `Done`
  String get done {
    return Intl.message(
      'Done',
      name: 'done',
      desc: '',
      args: [],
    );
  }

  /// `Select Currency`
  String get selectCurrency {
    return Intl.message(
      'Select Currency',
      name: 'selectCurrency',
      desc: '',
      args: [],
    );
  }

  /// `Enter Monthly Limit`
  String get enterMonthlyLimit {
    return Intl.message(
      'Enter Monthly Limit',
      name: 'enterMonthlyLimit',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: 'Label for the settings tab',
      args: [],
    );
  }

  /// `Total Expenses`
  String get totalExpenses {
    return Intl.message(
      'Total Expenses',
      name: 'totalExpenses',
      desc: '',
      args: [],
    );
  }

  /// `Monthly Expenses`
  String get monthlyExpenses {
    return Intl.message(
      'Monthly Expenses',
      name: 'monthlyExpenses',
      desc: '',
      args: [],
    );
  }

  /// `Yearly Expenses`
  String get yearlyExpenses {
    return Intl.message(
      'Yearly Expenses',
      name: 'yearlyExpenses',
      desc: '',
      args: [],
    );
  }

  /// `Yearly vs Monthly Expenses`
  String get yearlyVsMonthlyExpenses {
    return Intl.message(
      'Yearly vs Monthly Expenses',
      name: 'yearlyVsMonthlyExpenses',
      desc: '',
      args: [],
    );
  }

  /// `Pinned vs Unpinned`
  String get pinnedVsUnpinned {
    return Intl.message(
      'Pinned vs Unpinned',
      name: 'pinnedVsUnpinned',
      desc: '',
      args: [],
    );
  }

  /// `Paused vs Active`
  String get pausedVsActive {
    return Intl.message(
      'Paused vs Active',
      name: 'pausedVsActive',
      desc: '',
      args: [],
    );
  }

  /// `Monthly`
  String get monthly {
    return Intl.message(
      'Monthly',
      name: 'monthly',
      desc: '',
      args: [],
    );
  }

  /// `Yearly`
  String get yearly {
    return Intl.message(
      'Yearly',
      name: 'yearly',
      desc: '',
      args: [],
    );
  }

  /// `Pinned`
  String get pinned {
    return Intl.message(
      'Pinned',
      name: 'pinned',
      desc: '',
      args: [],
    );
  }

  /// `Unpinned`
  String get unpinned {
    return Intl.message(
      'Unpinned',
      name: 'unpinned',
      desc: '',
      args: [],
    );
  }

  /// `Active`
  String get active {
    return Intl.message(
      'Active',
      name: 'active',
      desc: '',
      args: [],
    );
  }

  /// `Paused`
  String get paused {
    return Intl.message(
      'Paused',
      name: 'paused',
      desc: '',
      args: [],
    );
  }

  /// `unknown`
  String get unknown {
    return Intl.message(
      'unknown',
      name: 'unknown',
      desc: '',
      args: [],
    );
  }

  /// `month`
  String get month {
    return Intl.message(
      'month',
      name: 'month',
      desc: '',
      args: [],
    );
  }

  /// `year`
  String get year {
    return Intl.message(
      'year',
      name: 'year',
      desc: '',
      args: [],
    );
  }

  /// `Costs`
  String get costs {
    return Intl.message(
      'Costs',
      name: 'costs',
      desc: '',
      args: [],
    );
  }

  /// `Add subscription`
  String get addSubscription {
    return Intl.message(
      'Add subscription',
      name: 'addSubscription',
      desc: '',
      args: [],
    );
  }

  /// `Start date`
  String get startDate {
    return Intl.message(
      'Start date',
      name: 'startDate',
      desc: '',
      args: [],
    );
  }

  /// `Payment rate`
  String get paymentRate {
    return Intl.message(
      'Payment rate',
      name: 'paymentRate',
      desc: '',
      args: [],
    );
  }

  /// `Remembering`
  String get remembering {
    return Intl.message(
      'Remembering',
      name: 'remembering',
      desc: '',
      args: [],
    );
  }

  /// `Title`
  String get title {
    return Intl.message(
      'Title',
      name: 'title',
      desc: '',
      args: [],
    );
  }

  /// `Delete this subscription`
  String get deleteSubscription {
    return Intl.message(
      'Delete this subscription',
      name: 'deleteSubscription',
      desc: '',
      args: [],
    );
  }

  /// `Continue this subscription`
  String get continueSubscription {
    return Intl.message(
      'Continue this subscription',
      name: 'continueSubscription',
      desc: '',
      args: [],
    );
  }

  /// `Pause this subscription`
  String get pauseSubscription {
    return Intl.message(
      'Pause this subscription',
      name: 'pauseSubscription',
      desc: '',
      args: [],
    );
  }

  /// `Unpin this subscription`
  String get unpinSubscription {
    return Intl.message(
      'Unpin this subscription',
      name: 'unpinSubscription',
      desc: '',
      args: [],
    );
  }

  /// `Pin this subscription`
  String get pinSubscription {
    return Intl.message(
      'Pin this subscription',
      name: 'pinSubscription',
      desc: '',
      args: [],
    );
  }

  /// `Actions`
  String get actions {
    return Intl.message(
      'Actions',
      name: 'actions',
      desc: '',
      args: [],
    );
  }

  /// `Notes`
  String get notes {
    return Intl.message(
      'Notes',
      name: 'notes',
      desc: '',
      args: [],
    );
  }

  /// `Total costs`
  String get totalCosts {
    return Intl.message(
      'Total costs',
      name: 'totalCosts',
      desc: '',
      args: [],
    );
  }

  /// `Previous debits`
  String get previousDebits {
    return Intl.message(
      'Previous debits',
      name: 'previousDebits',
      desc: '',
      args: [],
    );
  }

  /// `Additional information`
  String get additionalInformation {
    return Intl.message(
      'Additional information',
      name: 'additionalInformation',
      desc: '',
      args: [],
    );
  }

  /// `Created on`
  String get createdOn {
    return Intl.message(
      'Created on',
      name: 'createdOn',
      desc: '',
      args: [],
    );
  }

  /// `First Debit`
  String get firstDebit {
    return Intl.message(
      'First Debit',
      name: 'firstDebit',
      desc: '',
      args: [],
    );
  }

  /// `Previous invoice`
  String get previousInvoice {
    return Intl.message(
      'Previous invoice',
      name: 'previousInvoice',
      desc: '',
      args: [],
    );
  }

  /// `Next invoice`
  String get nextInvoice {
    return Intl.message(
      'Next invoice',
      name: 'nextInvoice',
      desc: '',
      args: [],
    );
  }

  /// `Invoice information`
  String get invoiceInformation {
    return Intl.message(
      'Invoice information',
      name: 'invoiceInformation',
      desc: '',
      args: [],
    );
  }

  /// `Repetition rate`
  String get repetitionRate {
    return Intl.message(
      'Repetition rate',
      name: 'repetitionRate',
      desc: '',
      args: [],
    );
  }

  /// `General information`
  String get generalInformation {
    return Intl.message(
      'General information',
      name: 'generalInformation',
      desc: '',
      args: [],
    );
  }

  /// `Days`
  String get days {
    return Intl.message(
      'Days',
      name: 'days',
      desc: '',
      args: [],
    );
  }

  /// `Edit subscription`
  String get editSubscription {
    return Intl.message(
      'Edit subscription',
      name: 'editSubscription',
      desc: '',
      args: [],
    );
  }

  /// `Outstanding expenditure month`
  String get outstandingExpenditureMonth {
    return Intl.message(
      'Outstanding expenditure month',
      name: 'outstandingExpenditureMonth',
      desc: '',
      args: [],
    );
  }

  /// `Open expenditure year`
  String get openExpenditureYear {
    return Intl.message(
      'Open expenditure year',
      name: 'openExpenditureYear',
      desc: '',
      args: [],
    );
  }

  /// `Same Day`
  String get sameDay {
    return Intl.message(
      'Same Day',
      name: 'sameDay',
      desc: '',
      args: [],
    );
  }

  /// `One Day Before`
  String get dayBefore {
    return Intl.message(
      'One Day Before',
      name: 'dayBefore',
      desc: '',
      args: [],
    );
  }

  /// `Two Days Before`
  String get twoDaysBefore {
    return Intl.message(
      'Two Days Before',
      name: 'twoDaysBefore',
      desc: '',
      args: [],
    );
  }

  /// `One Week Before`
  String get weekBefore {
    return Intl.message(
      'One Week Before',
      name: 'weekBefore',
      desc: '',
      args: [],
    );
  }

  /// `Subscription Reminder`
  String get subscriptionReminder {
    return Intl.message(
      'Subscription Reminder',
      name: 'subscriptionReminder',
      desc: '',
      args: [],
    );
  }

  /// `Your subscription {title} is due soon!`
  String subscriptionIsDueSoon(String title) {
    return Intl.message(
      'Your subscription $title is due soon!',
      name: 'subscriptionIsDueSoon',
      desc: 'A message that indicates a subscription is due soon.',
      args: [title],
    );
  }

  /// `Your subscription {title} ({price} €) is due soon!`
  String subscriptionIsDueSoonWithPrice(String title, double price) {
    return Intl.message(
      'Your subscription $title ($price €) is due soon!',
      name: 'subscriptionIsDueSoonWithPrice',
      desc: 'A message that indicates a subscription is due soon.',
      args: [title, price],
    );
  }

  /// `Number of Subscriptions`
  String get numberOfSubscriptions {
    return Intl.message(
      'Number of Subscriptions',
      name: 'numberOfSubscriptions',
      desc: '',
      args: [],
    );
  }

  /// `Expenditure since installing the app`
  String get expensesSinceAppInstallation {
    return Intl.message(
      'Expenditure since installing the app',
      name: 'expensesSinceAppInstallation',
      desc: '',
      args: [],
    );
  }

  /// `Expenditure this year`
  String get expenditureThisYear {
    return Intl.message(
      'Expenditure this year',
      name: 'expenditureThisYear',
      desc: '',
      args: [],
    );
  }

  /// `Expenditure until the end of the year`
  String get expenditureUntilTheEndOfTheYear {
    return Intl.message(
      'Expenditure until the end of the year',
      name: 'expenditureUntilTheEndOfTheYear',
      desc: '',
      args: [],
    );
  }

  /// `Expenses until the end of the month`
  String get expenditureUntilTheEndOfTheMonth {
    return Intl.message(
      'Expenses until the end of the month',
      name: 'expenditureUntilTheEndOfTheMonth',
      desc: '',
      args: [],
    );
  }

  /// `Issues of monthly subscriptions`
  String get issuesOfMonthlySubscriptions {
    return Intl.message(
      'Issues of monthly subscriptions',
      name: 'issuesOfMonthlySubscriptions',
      desc: '',
      args: [],
    );
  }

  /// `Issues of annual subscriptions`
  String get issuesOfAnnualSubscriptions {
    return Intl.message(
      'Issues of annual subscriptions',
      name: 'issuesOfAnnualSubscriptions',
      desc: '',
      args: [],
    );
  }

  /// `Loading...`
  String get loading {
    return Intl.message(
      'Loading...',
      name: 'loading',
      desc: '',
      args: [],
    );
  }

  /// `Overview`
  String get overview {
    return Intl.message(
      'Overview',
      name: 'overview',
      desc: '',
      args: [],
    );
  }

  /// `Hint`
  String get hint {
    return Intl.message(
      'Hint',
      name: 'hint',
      desc: '',
      args: [],
    );
  }

  /// `No data`
  String get noData {
    return Intl.message(
      'No data',
      name: 'noData',
      desc: '',
      args: [],
    );
  }

  /// `App Statistics`
  String get appStats {
    return Intl.message(
      'App Statistics',
      name: 'appStats',
      desc: '',
      args: [],
    );
  }

  /// `Remaining costs`
  String get remainingCosts {
    return Intl.message(
      'Remaining costs',
      name: 'remainingCosts',
      desc: '',
      args: [],
    );
  }

  /// `Cost share`
  String get costShare {
    return Intl.message(
      'Cost share',
      name: 'costShare',
      desc: '',
      args: [],
    );
  }

  /// `Deletion is not supported on the web`
  String get deletionIsNotSupportedOnTheWeb {
    return Intl.message(
      'Deletion is not supported on the web',
      name: 'deletionIsNotSupportedOnTheWeb',
      desc: '',
      args: [],
    );
  }

  /// `Monthly and annual expenditure relative to total expenditure`
  String get yearlyVsMonthlyExpensesSubtitle {
    return Intl.message(
      'Monthly and annual expenditure relative to total expenditure',
      name: 'yearlyVsMonthlyExpensesSubtitle',
      desc: '',
      args: [],
    );
  }

  /// `Please authenticate yourself to view your subscriptions`
  String get pleaseAuthenticateYourselfToViewYourSubscriptions {
    return Intl.message(
      'Please authenticate yourself to view your subscriptions',
      name: 'pleaseAuthenticateYourselfToViewYourSubscriptions',
      desc: '',
      args: [],
    );
  }

  /// `Security`
  String get security {
    return Intl.message(
      'Security',
      name: 'security',
      desc: '',
      args: [],
    );
  }

  /// `Enable Biometric`
  String get enableAuthProtection {
    return Intl.message(
      'Enable Biometric',
      name: 'enableAuthProtection',
      desc: '',
      args: [],
    );
  }

  /// `Please authenticate yourself to change this setting`
  String get pleaseAuthenticateYourselfToChangeThisSetting {
    return Intl.message(
      'Please authenticate yourself to change this setting',
      name: 'pleaseAuthenticateYourselfToChangeThisSetting',
      desc: '',
      args: [],
    );
  }

  /// `Data Management`
  String get dataManagement {
    return Intl.message(
      'Data Management',
      name: 'dataManagement',
      desc: '',
      args: [],
    );
  }

  /// `Export Data`
  String get exportData {
    return Intl.message(
      'Export Data',
      name: 'exportData',
      desc: '',
      args: [],
    );
  }

  /// `Import Data`
  String get importData {
    return Intl.message(
      'Import Data',
      name: 'importData',
      desc: '',
      args: [],
    );
  }

  /// `Data exported successfully.`
  String get dataExportedSuccessfully {
    return Intl.message(
      'Data exported successfully.',
      name: 'dataExportedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Data imported successfully.`
  String get dataImportedSuccessfully {
    return Intl.message(
      'Data imported successfully.',
      name: 'dataImportedSuccessfully',
      desc: '',
      args: [],
    );
  }

  /// `Data imported failed.`
  String get dataImportedFailed {
    return Intl.message(
      'Data imported failed.',
      name: 'dataImportedFailed',
      desc: '',
      args: [],
    );
  }

  /// `Authentication failed. Setting was not changed.`
  String get settingsAuthFailed {
    return Intl.message(
      'Authentication failed. Setting was not changed.',
      name: 'settingsAuthFailed',
      desc: '',
      args: [],
    );
  }

  /// `Export`
  String get export {
    return Intl.message(
      'Export',
      name: 'export',
      desc: '',
      args: [],
    );
  }

  /// `Import`
  String get import {
    return Intl.message(
      'Import',
      name: 'import',
      desc: '',
      args: [],
    );
  }

  /// `OK`
  String get OK {
    return Intl.message(
      'OK',
      name: 'OK',
      desc: '',
      args: [],
    );
  }

  /// `Sync with iCloud`
  String get syncWithICloud {
    return Intl.message(
      'Sync with iCloud',
      name: 'syncWithICloud',
      desc: '',
      args: [],
    );
  }

  /// `Converted costs`
  String get convertedCosts {
    return Intl.message(
      'Converted costs',
      name: 'convertedCosts',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'de'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
