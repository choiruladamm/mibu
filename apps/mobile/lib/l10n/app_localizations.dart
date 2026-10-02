import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('id')];

  /// No description provided for @appTitle.
  ///
  /// In id, this message translates to:
  /// **'mibu'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In id, this message translates to:
  /// **'beranda'**
  String get tabHome;

  /// No description provided for @tabPockets.
  ///
  /// In id, this message translates to:
  /// **'kantong'**
  String get tabPockets;

  /// No description provided for @tabStats.
  ///
  /// In id, this message translates to:
  /// **'statistik'**
  String get tabStats;

  /// No description provided for @tabSettings.
  ///
  /// In id, this message translates to:
  /// **'pengaturan'**
  String get tabSettings;

  /// No description provided for @balanceLabel.
  ///
  /// In id, this message translates to:
  /// **'saldo kamu'**
  String get balanceLabel;

  /// No description provided for @safeToSpendToday.
  ///
  /// In id, this message translates to:
  /// **'aman jajan hari ini'**
  String get safeToSpendToday;

  /// No description provided for @overspentToday.
  ///
  /// In id, this message translates to:
  /// **'kebablasan hari ini'**
  String get overspentToday;

  /// No description provided for @uncategorized.
  ///
  /// In id, this message translates to:
  /// **'tanpa kategori'**
  String get uncategorized;

  /// No description provided for @onboardingSkip.
  ///
  /// In id, this message translates to:
  /// **'lewati'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In id, this message translates to:
  /// **'lanjut'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In id, this message translates to:
  /// **'mulai sekarang'**
  String get onboardingStart;

  /// No description provided for @onboardingFooter.
  ///
  /// In id, this message translates to:
  /// **'masuk pakai google / apple · tanpa password'**
  String get onboardingFooter;

  /// No description provided for @onboardingCounter.
  ///
  /// In id, this message translates to:
  /// **'0{step} / 03'**
  String onboardingCounter(int step);

  /// No description provided for @onboardingStepLabel.
  ///
  /// In id, this message translates to:
  /// **'langkah {step}'**
  String onboardingStepLabel(int step);

  /// No description provided for @onboarding1Title.
  ///
  /// In id, this message translates to:
  /// **'duit kamu, ada kantongnya.'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Body.
  ///
  /// In id, this message translates to:
  /// **'bagi gaji ke kantong-kantong kecil. makan, ngopi, liburan — semuanya jelas jatahnya.'**
  String get onboarding1Body;

  /// No description provided for @onboarding2Title.
  ///
  /// In id, this message translates to:
  /// **'tau jatah jajan hari ini.'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Body.
  ///
  /// In id, this message translates to:
  /// **'mibu ngitungin berapa yang aman dipake hari ini, biar tanggal tua nggak makan mie terus.'**
  String get onboarding2Body;

  /// No description provided for @onboarding3Title.
  ///
  /// In id, this message translates to:
  /// **'catat 3 detik, beres.'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Body.
  ///
  /// In id, this message translates to:
  /// **'ketik nominal, pilih kategori, simpan. nggak perlu spreadsheet, nggak perlu ribet.'**
  String get onboarding3Body;

  /// No description provided for @onboardingSalaryIn.
  ///
  /// In id, this message translates to:
  /// **'gajian masuk'**
  String get onboardingSalaryIn;

  /// No description provided for @pocketFood.
  ///
  /// In id, this message translates to:
  /// **'makan'**
  String get pocketFood;

  /// No description provided for @pocketCoffee.
  ///
  /// In id, this message translates to:
  /// **'ngopi'**
  String get pocketCoffee;

  /// No description provided for @pocketHoliday.
  ///
  /// In id, this message translates to:
  /// **'liburan'**
  String get pocketHoliday;

  /// No description provided for @addEntry.
  ///
  /// In id, this message translates to:
  /// **'catat'**
  String get addEntry;

  /// No description provided for @search.
  ///
  /// In id, this message translates to:
  /// **'cari'**
  String get search;

  /// No description provided for @seeAll.
  ///
  /// In id, this message translates to:
  /// **'lihat semua'**
  String get seeAll;

  /// No description provided for @today.
  ///
  /// In id, this message translates to:
  /// **'hari ini'**
  String get today;

  /// No description provided for @prediction.
  ///
  /// In id, this message translates to:
  /// **'prediksi'**
  String get prediction;

  /// No description provided for @monthPickerLabel.
  ///
  /// In id, this message translates to:
  /// **'ganti bulan, sekarang {month}'**
  String monthPickerLabel(String month);

  /// No description provided for @homeMonthlyBalance.
  ///
  /// In id, this message translates to:
  /// **'saldo per bulan'**
  String get homeMonthlyBalance;

  /// No description provided for @homeTapMonthHint.
  ///
  /// In id, this message translates to:
  /// **'tap bulannya buat intip'**
  String get homeTapMonthHint;

  /// No description provided for @homeRecent.
  ///
  /// In id, this message translates to:
  /// **'baru aja'**
  String get homeRecent;

  /// No description provided for @close.
  ///
  /// In id, this message translates to:
  /// **'tutup'**
  String get close;

  /// No description provided for @expense.
  ///
  /// In id, this message translates to:
  /// **'pengeluaran'**
  String get expense;

  /// No description provided for @income.
  ///
  /// In id, this message translates to:
  /// **'pemasukan'**
  String get income;

  /// No description provided for @saveEntry.
  ///
  /// In id, this message translates to:
  /// **'simpan {kind}'**
  String saveEntry(String kind);

  /// No description provided for @pickOtherDate.
  ///
  /// In id, this message translates to:
  /// **'pilih tanggal lain'**
  String get pickOtherDate;

  /// No description provided for @pickCategory.
  ///
  /// In id, this message translates to:
  /// **'pilih kategori'**
  String get pickCategory;

  /// No description provided for @noteButton.
  ///
  /// In id, this message translates to:
  /// **'catatan'**
  String get noteButton;

  /// No description provided for @editNote.
  ///
  /// In id, this message translates to:
  /// **'edit catatan: {note}'**
  String editNote(String note);

  /// No description provided for @clearNote.
  ///
  /// In id, this message translates to:
  /// **'hapus catatan'**
  String get clearNote;

  /// No description provided for @pocketAfter.
  ///
  /// In id, this message translates to:
  /// **'{emoji} kantong {name} abis ini'**
  String pocketAfter(String emoji, String name);

  /// No description provided for @balanceAfter.
  ///
  /// In id, this message translates to:
  /// **'saldo abis ini'**
  String get balanceAfter;

  /// No description provided for @leftAmount.
  ///
  /// In id, this message translates to:
  /// **'sisa {amount}'**
  String leftAmount(String amount);

  /// No description provided for @overAmount.
  ///
  /// In id, this message translates to:
  /// **'kelebihan {amount}'**
  String overAmount(String amount);

  /// No description provided for @keyThreeZeros.
  ///
  /// In id, this message translates to:
  /// **'tambah tiga nol'**
  String get keyThreeZeros;

  /// No description provided for @keyBackspace.
  ///
  /// In id, this message translates to:
  /// **'hapus satu angka'**
  String get keyBackspace;

  /// No description provided for @pickerTitle.
  ///
  /// In id, this message translates to:
  /// **'ini buat apa?'**
  String get pickerTitle;

  /// No description provided for @pickerSearch.
  ///
  /// In id, this message translates to:
  /// **'cari kategori'**
  String get pickerSearch;

  /// No description provided for @pickerRecent.
  ///
  /// In id, this message translates to:
  /// **'terakhir · sekali tap langsung keisi'**
  String get pickerRecent;

  /// No description provided for @pickerWhere.
  ///
  /// In id, this message translates to:
  /// **'di mana'**
  String get pickerWhere;

  /// No description provided for @pickerUse.
  ///
  /// In id, this message translates to:
  /// **'pakai {emoji} {name}'**
  String pickerUse(String emoji, String name);

  /// No description provided for @pickerNoMatch.
  ///
  /// In id, this message translates to:
  /// **'nggak ada kategori yang cocok'**
  String get pickerNoMatch;

  /// No description provided for @yesterday.
  ///
  /// In id, this message translates to:
  /// **'kemarin'**
  String get yesterday;

  /// No description provided for @twoDaysAgo.
  ///
  /// In id, this message translates to:
  /// **'kemarin lusa'**
  String get twoDaysAgo;

  /// No description provided for @daysAgo.
  ///
  /// In id, this message translates to:
  /// **'{n} hari lalu'**
  String daysAgo(int n);

  /// No description provided for @thisWeek.
  ///
  /// In id, this message translates to:
  /// **'minggu ini'**
  String get thisWeek;

  /// No description provided for @lastWeek.
  ///
  /// In id, this message translates to:
  /// **'minggu lalu'**
  String get lastWeek;

  /// No description provided for @weeksAgo.
  ///
  /// In id, this message translates to:
  /// **'{n} minggu lalu'**
  String weeksAgo(int n);

  /// No description provided for @backTo.
  ///
  /// In id, this message translates to:
  /// **'balik ke {day}'**
  String backTo(String day);

  /// No description provided for @prevWeek.
  ///
  /// In id, this message translates to:
  /// **'minggu sebelumnya'**
  String get prevWeek;

  /// No description provided for @nextWeek.
  ///
  /// In id, this message translates to:
  /// **'minggu berikutnya'**
  String get nextWeek;

  /// No description provided for @notYet.
  ///
  /// In id, this message translates to:
  /// **'belum kejadian'**
  String get notYet;

  /// No description provided for @pickDayIn.
  ///
  /// In id, this message translates to:
  /// **'pilih hari, {range}'**
  String pickDayIn(String range);

  /// No description provided for @dateSheetTitle.
  ///
  /// In id, this message translates to:
  /// **'kapan kejadiannya?'**
  String get dateSheetTitle;

  /// No description provided for @startOfMonth.
  ///
  /// In id, this message translates to:
  /// **'awal bulan'**
  String get startOfMonth;

  /// No description provided for @prevMonth.
  ///
  /// In id, this message translates to:
  /// **'bulan sebelumnya'**
  String get prevMonth;

  /// No description provided for @nextMonth.
  ///
  /// In id, this message translates to:
  /// **'bulan berikutnya'**
  String get nextMonth;

  /// No description provided for @entriesThatDay.
  ///
  /// In id, this message translates to:
  /// **'udah ada {n} catatan — jangan dobel ya'**
  String entriesThatDay(int n);

  /// No description provided for @noEntriesThatDay.
  ///
  /// In id, this message translates to:
  /// **'belum ada catatan di hari ini'**
  String get noEntriesThatDay;

  /// No description provided for @useDate.
  ///
  /// In id, this message translates to:
  /// **'pakai {date}'**
  String useDate(String date);

  /// No description provided for @noteFor.
  ///
  /// In id, this message translates to:
  /// **'buat'**
  String get noteFor;

  /// No description provided for @notePlaceholder.
  ///
  /// In id, this message translates to:
  /// **'buat apa, sama siapa, kenapa…'**
  String get notePlaceholder;

  /// No description provided for @noteQuickTags.
  ///
  /// In id, this message translates to:
  /// **'tag cepet · maks 3'**
  String get noteQuickTags;

  /// No description provided for @noteWroteBefore.
  ///
  /// In id, this message translates to:
  /// **'pernah kamu tulis'**
  String get noteWroteBefore;

  /// No description provided for @noteSave.
  ///
  /// In id, this message translates to:
  /// **'simpan catatan'**
  String get noteSave;

  /// No description provided for @noteLeaveEmpty.
  ///
  /// In id, this message translates to:
  /// **'nggak jadi, kosongin'**
  String get noteLeaveEmpty;

  /// No description provided for @pocketsNew.
  ///
  /// In id, this message translates to:
  /// **'baru'**
  String get pocketsNew;

  /// No description provided for @pocketsLeftTitle.
  ///
  /// In id, this message translates to:
  /// **'sisa jajan {month}'**
  String pocketsLeftTitle(String month);

  /// No description provided for @pocketsSpentOf.
  ///
  /// In id, this message translates to:
  /// **'{spent} dari {limit} kepake · {days} hari lagi'**
  String pocketsSpentOf(String spent, String limit, int days);

  /// No description provided for @pocketsEmpty.
  ///
  /// In id, this message translates to:
  /// **'belum ada kantong. bikin satu biar jajan ada batasnya.'**
  String get pocketsEmpty;

  /// No description provided for @pocketJarLabel.
  ///
  /// In id, this message translates to:
  /// **'{name}, {pct}% kepake'**
  String pocketJarLabel(String name, int pct);

  /// No description provided for @pocketSelected.
  ///
  /// In id, this message translates to:
  /// **'kantong yang dipilih'**
  String get pocketSelected;

  /// No description provided for @pocketStatusSafe.
  ///
  /// In id, this message translates to:
  /// **'aman'**
  String get pocketStatusSafe;

  /// No description provided for @pocketStatusAlmostOut.
  ///
  /// In id, this message translates to:
  /// **'hampir abis'**
  String get pocketStatusAlmostOut;

  /// No description provided for @pocketStatusUnused.
  ///
  /// In id, this message translates to:
  /// **'belum kepake'**
  String get pocketStatusUnused;

  /// No description provided for @pocketLeftOf.
  ///
  /// In id, this message translates to:
  /// **'sisa dari {limit}'**
  String pocketLeftOf(String limit);

  /// No description provided for @pocketDaily.
  ///
  /// In id, this message translates to:
  /// **'kira-kira {amount} sehari buat {days} hari ke depan'**
  String pocketDaily(String amount, int days);

  /// No description provided for @pocketOver.
  ///
  /// In id, this message translates to:
  /// **'kelebihan {amount} bulan ini'**
  String pocketOver(String amount);

  /// No description provided for @pocketManage.
  ///
  /// In id, this message translates to:
  /// **'atur kantong'**
  String get pocketManage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
