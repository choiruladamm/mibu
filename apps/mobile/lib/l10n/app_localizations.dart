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
  /// **'lain-lain'**
  String get uncategorized;

  /// No description provided for @onboardingSkip.
  ///
  /// In id, this message translates to:
  /// **'skip'**
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
  /// **'masuk pakai google / apple'**
  String get onboardingFooter;

  /// No description provided for @onboardingNoPassword.
  ///
  /// In id, this message translates to:
  /// **'tanpa password'**
  String get onboardingNoPassword;

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
  /// **'ketik nominal, pilih buat apa, simpan. nggak perlu spreadsheet, nggak perlu ribet.'**
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
  /// **'liat semua'**
  String get seeAll;

  /// No description provided for @today.
  ///
  /// In id, this message translates to:
  /// **'hari ini'**
  String get today;

  /// No description provided for @monthPickerLabel.
  ///
  /// In id, this message translates to:
  /// **'ganti bulan, sekarang {month}'**
  String monthPickerLabel(String month);

  /// No description provided for @homeMonthlyBalance.
  ///
  /// In id, this message translates to:
  /// **'kepake per periode'**
  String get homeMonthlyBalance;

  /// No description provided for @homeTapMonthHint.
  ///
  /// In id, this message translates to:
  /// **'tap periode buat intip'**
  String get homeTapMonthHint;

  /// No description provided for @chartNow.
  ///
  /// In id, this message translates to:
  /// **'berjalan'**
  String get chartNow;

  /// No description provided for @chartOverBudget.
  ///
  /// In id, this message translates to:
  /// **'lewat budget'**
  String get chartOverBudget;

  /// No description provided for @chartBudget.
  ///
  /// In id, this message translates to:
  /// **'budget {amount}'**
  String chartBudget(String amount);

  /// No description provided for @homeRecent.
  ///
  /// In id, this message translates to:
  /// **'baru aja'**
  String get homeRecent;

  /// No description provided for @homePockets.
  ///
  /// In id, this message translates to:
  /// **'kantong'**
  String get homePockets;

  /// No description provided for @homeTodayTotal.
  ///
  /// In id, this message translates to:
  /// **'{total} hari ini'**
  String homeTodayTotal(String total);

  /// No description provided for @homeRecentIn.
  ///
  /// In id, this message translates to:
  /// **'terakhir di {month}'**
  String homeRecentIn(String month);

  /// No description provided for @homeAllCount.
  ///
  /// In id, this message translates to:
  /// **'semua transaksi ({n})'**
  String homeAllCount(int n);

  /// No description provided for @homeAllIn.
  ///
  /// In id, this message translates to:
  /// **'liat semua di {month} ({n})'**
  String homeAllIn(String month, int n);

  /// No description provided for @homeTodayEmpty.
  ///
  /// In id, this message translates to:
  /// **'belum ada catatan hari ini'**
  String get homeTodayEmpty;

  /// No description provided for @homeNoEntriesTitle.
  ///
  /// In id, this message translates to:
  /// **'belum ada catatan'**
  String get homeNoEntriesTitle;

  /// No description provided for @homeNoEntriesBody.
  ///
  /// In id, this message translates to:
  /// **'catat jajan pertama kamu, cuma 3 detik.'**
  String get homeNoEntriesBody;

  /// No description provided for @homeMonthEmpty.
  ///
  /// In id, this message translates to:
  /// **'belum ada catatan di {month}'**
  String homeMonthEmpty(String month);

  /// No description provided for @infoWhere.
  ///
  /// In id, this message translates to:
  /// **'dari mana angkanya?'**
  String get infoWhere;

  /// No description provided for @infoOk.
  ///
  /// In id, this message translates to:
  /// **'oke, ngerti'**
  String get infoOk;

  /// No description provided for @infoBudgetTitle.
  ///
  /// In id, this message translates to:
  /// **'sisa budget'**
  String get infoBudgetTitle;

  /// No description provided for @infoBudgetCalc.
  ///
  /// In id, this message translates to:
  /// **'budget {budget} − kepake {spent}'**
  String infoBudgetCalc(String budget, String spent);

  /// No description provided for @infoSafeCalc.
  ///
  /// In id, this message translates to:
  /// **'sisa budget {left} ÷ {days} hari sampai gajian'**
  String infoSafeCalc(String left, int days);

  /// No description provided for @infoSafeToday.
  ///
  /// In id, this message translates to:
  /// **'udah kepake {spent} hari ini, jadi aman jajan hari ini tinggal {left}.'**
  String infoSafeToday(String spent, String left);

  /// No description provided for @infoJarCalc.
  ///
  /// In id, this message translates to:
  /// **'total limit {limit} − kepake di kantong {spent}'**
  String infoJarCalc(String limit, String spent);

  /// No description provided for @infoJarOutside.
  ///
  /// In id, this message translates to:
  /// **'bisa beda dari sisa budget, soalnya {amount} kepake di luar kantong.'**
  String infoJarOutside(String amount);

  /// No description provided for @infoBudgetNone.
  ///
  /// In id, this message translates to:
  /// **'belum ada budget. pasang dulu biar aman jajan bisa dihitung.'**
  String get infoBudgetNone;

  /// No description provided for @infoSafeTitle.
  ///
  /// In id, this message translates to:
  /// **'aman jajan per hari'**
  String get infoSafeTitle;

  /// No description provided for @infoJarTitle.
  ///
  /// In id, this message translates to:
  /// **'sisa jajan (kantong)'**
  String get infoJarTitle;

  /// No description provided for @heroBudgetLeft.
  ///
  /// In id, this message translates to:
  /// **'sisa budget'**
  String get heroBudgetLeft;

  /// No description provided for @heroBudgetOver.
  ///
  /// In id, this message translates to:
  /// **'kelewat budget'**
  String get heroBudgetOver;

  /// No description provided for @heroSpent.
  ///
  /// In id, this message translates to:
  /// **'kepake bulan ini'**
  String get heroSpent;

  /// No description provided for @heroSpentEnd.
  ///
  /// In id, this message translates to:
  /// **'kepake {month}'**
  String heroSpentEnd(String month);

  /// No description provided for @heroBudgetLeftEnd.
  ///
  /// In id, this message translates to:
  /// **'sisa budget {month}'**
  String heroBudgetLeftEnd(String month);

  /// No description provided for @heroBudgetOverEnd.
  ///
  /// In id, this message translates to:
  /// **'kelewat budget {month}'**
  String heroBudgetOverEnd(String month);

  /// No description provided for @heroFromBudget.
  ///
  /// In id, this message translates to:
  /// **'dari budget {amount}'**
  String heroFromBudget(String amount);

  /// No description provided for @heroSetBudgetChip.
  ///
  /// In id, this message translates to:
  /// **'isi budget biar dapet aman jajan'**
  String get heroSetBudgetChip;

  /// No description provided for @heroEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'atur budget periode ini'**
  String get heroEmptyTitle;

  /// No description provided for @heroEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'biar keliatan sisa budget & aman jajan per hari. kepake periode ini {spent}.'**
  String heroEmptyBody(String spent);

  /// No description provided for @heroEmptyButton.
  ///
  /// In id, this message translates to:
  /// **'atur budget'**
  String get heroEmptyButton;

  /// No description provided for @heroCatatGajian.
  ///
  /// In id, this message translates to:
  /// **'udah gajian? catat'**
  String get heroCatatGajian;

  /// No description provided for @heroCatatGajianLate.
  ///
  /// In id, this message translates to:
  /// **'gajian belum masuk? catat'**
  String get heroCatatGajianLate;

  /// No description provided for @heroRemDulu.
  ///
  /// In id, this message translates to:
  /// **'rem dulu ya'**
  String get heroRemDulu;

  /// No description provided for @heroDaysLeft.
  ///
  /// In id, this message translates to:
  /// **'{n} hari lagi'**
  String heroDaysLeft(int n);

  /// No description provided for @heroAvgDay.
  ///
  /// In id, this message translates to:
  /// **'rata²/hari'**
  String get heroAvgDay;

  /// No description provided for @homePocketPill.
  ///
  /// In id, this message translates to:
  /// **'buka kantong {name}, {pct}% kepake'**
  String homePocketPill(String name, int pct);

  /// No description provided for @monthMenuTitle.
  ///
  /// In id, this message translates to:
  /// **'pilih bulan'**
  String get monthMenuTitle;

  /// No description provided for @monthMenuPrevYear.
  ///
  /// In id, this message translates to:
  /// **'tahun sebelumnya'**
  String get monthMenuPrevYear;

  /// No description provided for @monthMenuNextYear.
  ///
  /// In id, this message translates to:
  /// **'tahun berikutnya'**
  String get monthMenuNextYear;

  /// No description provided for @monthMenuLegend.
  ///
  /// In id, this message translates to:
  /// **'total pengeluaran'**
  String get monthMenuLegend;

  /// No description provided for @monthMenuNow.
  ///
  /// In id, this message translates to:
  /// **'bulan ini'**
  String get monthMenuNow;

  /// No description provided for @monthMenuCell.
  ///
  /// In id, this message translates to:
  /// **'{month} {year}'**
  String monthMenuCell(String month, int year);

  /// No description provided for @monthMenuFuture.
  ///
  /// In id, this message translates to:
  /// **'belum kejadian'**
  String get monthMenuFuture;

  /// No description provided for @monthMenuEarly.
  ///
  /// In id, this message translates to:
  /// **'belum ada catatan'**
  String get monthMenuEarly;

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
  /// **'buat apa?'**
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
  /// **'{emoji} jatah {name} abis ini'**
  String pocketAfter(String emoji, String name);

  /// No description provided for @balanceAfter.
  ///
  /// In id, this message translates to:
  /// **'sisa budget abis ini'**
  String get balanceAfter;

  /// No description provided for @incomeAfter.
  ///
  /// In id, this message translates to:
  /// **'pemasukan periode ini jadi'**
  String get incomeAfter;

  /// No description provided for @leftAmount.
  ///
  /// In id, this message translates to:
  /// **'sisa {amount}'**
  String leftAmount(String amount);

  /// No description provided for @overAmount.
  ///
  /// In id, this message translates to:
  /// **'lewat {amount}'**
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
  /// **'buat apa?'**
  String get pickerTitle;

  /// No description provided for @pickerSearch.
  ///
  /// In id, this message translates to:
  /// **'cari atau bikin…'**
  String get pickerSearch;

  /// No description provided for @pickerRecent.
  ///
  /// In id, this message translates to:
  /// **'terakhir dipakai'**
  String get pickerRecent;

  /// No description provided for @pickerWhere.
  ///
  /// In id, this message translates to:
  /// **'di mana'**
  String get pickerWhere;

  /// No description provided for @placeHint.
  ///
  /// In id, this message translates to:
  /// **'mis. warteg, indomaret, gofood'**
  String get placeHint;

  /// No description provided for @placeHintFor.
  ///
  /// In id, this message translates to:
  /// **'mis. {places}'**
  String placeHintFor(String places);

  /// No description provided for @pickerUse.
  ///
  /// In id, this message translates to:
  /// **'pakai {emoji} {name}'**
  String pickerUse(String emoji, String name);

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
  /// **'tanggal berapa?'**
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

  /// No description provided for @notePlaceholder.
  ///
  /// In id, this message translates to:
  /// **'sama siapa, kenapa, detailnya…'**
  String get notePlaceholder;

  /// No description provided for @noteQuickTags.
  ///
  /// In id, this message translates to:
  /// **'tag cepet'**
  String get noteQuickTags;

  /// No description provided for @noteTagsMax.
  ///
  /// In id, this message translates to:
  /// **'maks {n}'**
  String noteTagsMax(int n);

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

  /// No description provided for @pocketsSetLimit.
  ///
  /// In id, this message translates to:
  /// **'pasang limit'**
  String get pocketsSetLimit;

  /// No description provided for @pocketsJarNew.
  ///
  /// In id, this message translates to:
  /// **'limit'**
  String get pocketsJarNew;

  /// No description provided for @pocketsLeftTitle.
  ///
  /// In id, this message translates to:
  /// **'sisa jajan {month}'**
  String pocketsLeftTitle(String month);

  /// No description provided for @pocketsSpentOf.
  ///
  /// In id, this message translates to:
  /// **'{spent} dari {limit} kepake'**
  String pocketsSpentOf(String spent, String limit);

  /// No description provided for @pocketsCount.
  ///
  /// In id, this message translates to:
  /// **'{n} pakai limit'**
  String pocketsCount(int n);

  /// No description provided for @pocketsSwipe.
  ///
  /// In id, this message translates to:
  /// **'geser'**
  String get pocketsSwipe;

  /// No description provided for @pocketsIntroTitle.
  ///
  /// In id, this message translates to:
  /// **'kantong = budget kamu, dipecah per toples'**
  String get pocketsIntroTitle;

  /// No description provided for @pocketsIntroBody.
  ///
  /// In id, this message translates to:
  /// **'kayak amplop: makan Rp3jt, ngopi Rp600K, dst. biar ketauan bocornya di mana.'**
  String get pocketsIntroBody;

  /// No description provided for @pocketsIntroCount.
  ///
  /// In id, this message translates to:
  /// **'{n} kantong {total}'**
  String pocketsIntroCount(int n, String total);

  /// No description provided for @pocketsIntroFree.
  ///
  /// In id, this message translates to:
  /// **'{amount} belum dijatah'**
  String pocketsIntroFree(String amount);

  /// No description provided for @pocketsIntroOver.
  ///
  /// In id, this message translates to:
  /// **'lebih {amount} dari budget'**
  String pocketsIntroOver(String amount);

  /// No description provided for @pocketsIntroNoBudget.
  ///
  /// In id, this message translates to:
  /// **'belum pasang budget'**
  String get pocketsIntroNoBudget;

  /// No description provided for @pocketsIntroOk.
  ///
  /// In id, this message translates to:
  /// **'oke'**
  String get pocketsIntroOk;

  /// No description provided for @infoPocketsLead.
  ///
  /// In id, this message translates to:
  /// **'kantong = budget kamu, dipecah per toples.'**
  String get infoPocketsLead;

  /// No description provided for @infoPocketsBody.
  ///
  /// In id, this message translates to:
  /// **'pasang limit ke makan, ngopi, ojol, mibu ngitung sisanya sampai gajian.'**
  String get infoPocketsBody;

  /// No description provided for @pocketsNewJar.
  ///
  /// In id, this message translates to:
  /// **'pasang limit ke yang lain'**
  String get pocketsNewJar;

  /// No description provided for @pocketsFirstBody.
  ///
  /// In id, this message translates to:
  /// **'kayak amplop: makan, ngopi, ojol. mibu ngabarin pas mau abis.'**
  String get pocketsFirstBody;

  /// No description provided for @pocketsFirstButton.
  ///
  /// In id, this message translates to:
  /// **'+ pasang limit'**
  String get pocketsFirstButton;

  /// No description provided for @pocketsFreeTitle.
  ///
  /// In id, this message translates to:
  /// **'belum ada limit'**
  String get pocketsFreeTitle;

  /// No description provided for @pocketsNoLimit.
  ///
  /// In id, this message translates to:
  /// **'belum ada limit'**
  String get pocketsNoLimit;

  /// No description provided for @pocketsFreeSuffix.
  ///
  /// In id, this message translates to:
  /// **' bulan ini'**
  String get pocketsFreeSuffix;

  /// No description provided for @pocketsFreeChip.
  ///
  /// In id, this message translates to:
  /// **'pasang limit buat {name}'**
  String pocketsFreeChip(String name);

  /// No description provided for @pocketsFreeMore.
  ///
  /// In id, this message translates to:
  /// **'liat yang lain belum ada limit'**
  String get pocketsFreeMore;

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

  /// No description provided for @pocketStatusOver.
  ///
  /// In id, this message translates to:
  /// **'! lewat limit'**
  String get pocketStatusOver;

  /// No description provided for @pocketLeftLabel.
  ///
  /// In id, this message translates to:
  /// **'jatah sisa'**
  String get pocketLeftLabel;

  /// No description provided for @pocketOverLabel.
  ///
  /// In id, this message translates to:
  /// **'kelewat'**
  String get pocketOverLabel;

  /// No description provided for @pocketLimitOf.
  ///
  /// In id, this message translates to:
  /// **'limit {limit}'**
  String pocketLimitOf(String limit);

  /// No description provided for @pocketOverDays.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, =1{hari terakhir, rem dulu ya} other{masih {n} hari lagi, rem dulu ya}}'**
  String pocketOverDays(int n);

  /// No description provided for @pocketRaise.
  ///
  /// In id, this message translates to:
  /// **'naikin limit'**
  String get pocketRaise;

  /// No description provided for @pocketUsedPct.
  ///
  /// In id, this message translates to:
  /// **'{pct}% kepake'**
  String pocketUsedPct(int pct);

  /// No description provided for @pocketDaily.
  ///
  /// In id, this message translates to:
  /// **'≈ {amount}/hari sampai gajian'**
  String pocketDaily(String amount);

  /// No description provided for @pocketManage.
  ///
  /// In id, this message translates to:
  /// **'atur limit'**
  String get pocketManage;

  /// No description provided for @pocketRelease.
  ///
  /// In id, this message translates to:
  /// **'copot limit'**
  String get pocketRelease;

  /// No description provided for @limitSetTitle.
  ///
  /// In id, this message translates to:
  /// **'limit {name} {amount} kepasang'**
  String limitSetTitle(String name, String amount);

  /// No description provided for @limitSetSub.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, =0{toplesnya udah nongol} other{{n} catatan langsung keitung}}'**
  String limitSetSub(int n);

  /// No description provided for @limitReleasedTitle.
  ///
  /// In id, this message translates to:
  /// **'limit {name} dicopot'**
  String limitReleasedTitle(String name);

  /// No description provided for @limitReleasedSub.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, =0{{name} tetap ada, cuma nggak dibatesin} other{{name} & {n} catatannya tetap ada}}'**
  String limitReleasedSub(int n, String name);

  /// No description provided for @limitOffTitle.
  ///
  /// In id, this message translates to:
  /// **'copot limit {name}?'**
  String limitOffTitle(String name);

  /// No description provided for @limitOffSub.
  ///
  /// In id, this message translates to:
  /// **'toplesnya ilang, {name} jadi “belum ada limit”.'**
  String limitOffSub(String name);

  /// No description provided for @limitOffBusyTitle.
  ///
  /// In id, this message translates to:
  /// **'kamu udah {n}× catat {name} bulan ini'**
  String limitOffBusyTitle(String name, int n);

  /// No description provided for @limitOffBusySub.
  ///
  /// In id, this message translates to:
  /// **'termasuk yang paling sering. tanpa limit, mibu nggak bakal ngingetin kalau {name} mulai kebablasan.'**
  String limitOffBusySub(String name);

  /// No description provided for @limitOffNoWarn.
  ///
  /// In id, this message translates to:
  /// **'nggak ada peringatan “hampir abis” lagi'**
  String get limitOffNoWarn;

  /// No description provided for @limitOffFreed.
  ///
  /// In id, this message translates to:
  /// **'{amount} balik jadi belum dijatah di budget'**
  String limitOffFreed(String amount);

  /// No description provided for @limitOffKept.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, =0{catatan lama tetap aman, nggak kehapus} other{{n} catatan ({amount}) tetap aman, nggak kehapus}}'**
  String limitOffKept(int n, String amount);

  /// No description provided for @setLimitTitle.
  ///
  /// In id, this message translates to:
  /// **'pasang limit ke…'**
  String get setLimitTitle;

  /// No description provided for @setLimitHintOrder.
  ///
  /// In id, this message translates to:
  /// **'urut paling kepake'**
  String get setLimitHintOrder;

  /// No description provided for @setLimitHintCounts.
  ///
  /// In id, this message translates to:
  /// **'catatan lama langsung keitung'**
  String get setLimitHintCounts;

  /// No description provided for @setLimitCount.
  ///
  /// In id, this message translates to:
  /// **'{n, plural, =0{belum kepake} other{{n} catatan}}'**
  String setLimitCount(int n);

  /// No description provided for @setLimitSpent.
  ///
  /// In id, this message translates to:
  /// **'{amount} udah kepake bulan ini'**
  String setLimitSpent(String amount);

  /// No description provided for @setLimitUnused.
  ///
  /// In id, this message translates to:
  /// **'belum kepake bulan ini'**
  String get setLimitUnused;

  /// No description provided for @setLimitFilled.
  ///
  /// In id, this message translates to:
  /// **'keisi {pct}%'**
  String setLimitFilled(int pct);

  /// No description provided for @setLimitLeft.
  ///
  /// In id, this message translates to:
  /// **'sisa jatah {amount}'**
  String setLimitLeft(String amount);

  /// No description provided for @setLimitEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'semua udah pakai limit'**
  String get setLimitEmptyTitle;

  /// No description provided for @setLimitEmptyBody.
  ///
  /// In id, this message translates to:
  /// **'mau yang lain? bikin baru'**
  String get setLimitEmptyBody;

  /// No description provided for @setLimitNewCategory.
  ///
  /// In id, this message translates to:
  /// **'bikin baru'**
  String get setLimitNewCategory;

  /// No description provided for @setLimitIncomeNote.
  ///
  /// In id, this message translates to:
  /// **'pemasukan nggak pakai limit'**
  String get setLimitIncomeNote;

  /// No description provided for @setLimitBack.
  ///
  /// In id, this message translates to:
  /// **'ganti'**
  String get setLimitBack;

  /// No description provided for @setLimitSave.
  ///
  /// In id, this message translates to:
  /// **'pasang limit {amount}'**
  String setLimitSave(String amount);

  /// No description provided for @keyPlus.
  ///
  /// In id, this message translates to:
  /// **'tambah nominal lain'**
  String get keyPlus;

  /// No description provided for @keyTwoZeros.
  ///
  /// In id, this message translates to:
  /// **'tambah dua nol'**
  String get keyTwoZeros;

  /// No description provided for @keyClear.
  ///
  /// In id, this message translates to:
  /// **'kosongin semua'**
  String get keyClear;

  /// No description provided for @keyClearShort.
  ///
  /// In id, this message translates to:
  /// **'kosongin'**
  String get keyClearShort;

  /// No description provided for @keySave.
  ///
  /// In id, this message translates to:
  /// **'simpan'**
  String get keySave;

  /// No description provided for @amountSuggested.
  ///
  /// In id, this message translates to:
  /// **'kayak gaji terakhir, ketik buat ganti'**
  String get amountSuggested;

  /// No description provided for @amountTypeHint.
  ///
  /// In id, this message translates to:
  /// **'ketik nominal'**
  String get amountTypeHint;

  /// No description provided for @amountInWords.
  ///
  /// In id, this message translates to:
  /// **'{words} rupiah'**
  String amountInWords(String words);

  /// No description provided for @undo.
  ///
  /// In id, this message translates to:
  /// **'batalin'**
  String get undo;

  /// No description provided for @budgetTitle.
  ///
  /// In id, this message translates to:
  /// **'budget per periode'**
  String get budgetTitle;

  /// No description provided for @budgetSub.
  ///
  /// In id, this message translates to:
  /// **'berapa yang boleh kepake sampai gajian?'**
  String get budgetSub;

  /// No description provided for @budgetLastSpent.
  ///
  /// In id, this message translates to:
  /// **'periode lalu kepake {amount}'**
  String budgetLastSpent(String amount);

  /// No description provided for @budgetLabelNow.
  ///
  /// In id, this message translates to:
  /// **'budget sekarang'**
  String get budgetLabelNow;

  /// No description provided for @budgetLabelSuggest.
  ///
  /// In id, this message translates to:
  /// **'saran dari total limit'**
  String get budgetLabelSuggest;

  /// No description provided for @budgetAutoFilled.
  ///
  /// In id, this message translates to:
  /// **'diisi otomatis'**
  String get budgetAutoFilled;

  /// No description provided for @budgetInfoType.
  ///
  /// In id, this message translates to:
  /// **'ketik budget kamu'**
  String get budgetInfoType;

  /// No description provided for @budgetInfoTotal.
  ///
  /// In id, this message translates to:
  /// **'total limit {total}'**
  String budgetInfoTotal(String total);

  /// No description provided for @budgetInfoShort.
  ///
  /// In id, this message translates to:
  /// **'kurang {amount}'**
  String budgetInfoShort(String amount);

  /// No description provided for @budgetFillFirst.
  ///
  /// In id, this message translates to:
  /// **'isi dulu'**
  String get budgetFillFirst;

  /// No description provided for @budgetPerMonth.
  ///
  /// In id, this message translates to:
  /// **'{amount} / periode'**
  String budgetPerMonth(String amount);

  /// No description provided for @budgetDelete.
  ///
  /// In id, this message translates to:
  /// **'hapus budget'**
  String get budgetDelete;

  /// No description provided for @budgetSavedTitle.
  ///
  /// In id, this message translates to:
  /// **'budget {amount} kesimpen'**
  String budgetSavedTitle(String amount);

  /// No description provided for @budgetSavedSub.
  ///
  /// In id, this message translates to:
  /// **'budget di-track ulang'**
  String get budgetSavedSub;

  /// No description provided for @budgetDeletedTitle.
  ///
  /// In id, this message translates to:
  /// **'budget dihapus'**
  String get budgetDeletedTitle;

  /// No description provided for @budgetDeletedSub.
  ///
  /// In id, this message translates to:
  /// **'tracking budget off dulu'**
  String get budgetDeletedSub;

  /// No description provided for @pocketsBudget.
  ///
  /// In id, this message translates to:
  /// **'budget {amount}'**
  String pocketsBudget(String amount);

  /// No description provided for @pocketsSetBudget.
  ///
  /// In id, this message translates to:
  /// **'pasang budget'**
  String get pocketsSetBudget;

  /// No description provided for @pocketsDaysLeft.
  ///
  /// In id, this message translates to:
  /// **'{days} hari lagi'**
  String pocketsDaysLeft(int days);

  /// No description provided for @pickerManage.
  ///
  /// In id, this message translates to:
  /// **'atur'**
  String get pickerManage;

  /// No description provided for @categoryNew.
  ///
  /// In id, this message translates to:
  /// **'baru'**
  String get categoryNew;

  /// No description provided for @categoryCreateNamed.
  ///
  /// In id, this message translates to:
  /// **'bikin “{name}”'**
  String categoryCreateNamed(String name);

  /// No description provided for @categoryNewTitle.
  ///
  /// In id, this message translates to:
  /// **'bikin baru'**
  String get categoryNewTitle;

  /// No description provided for @categoryEditTitle.
  ///
  /// In id, this message translates to:
  /// **'edit'**
  String get categoryEditTitle;

  /// No description provided for @cancel.
  ///
  /// In id, this message translates to:
  /// **'batal'**
  String get cancel;

  /// No description provided for @categoryNameHint.
  ///
  /// In id, this message translates to:
  /// **'kasih nama'**
  String get categoryNameHint;

  /// No description provided for @categoryNameLabel.
  ///
  /// In id, this message translates to:
  /// **'buat apa?'**
  String get categoryNameLabel;

  /// No description provided for @categorySuggest.
  ///
  /// In id, this message translates to:
  /// **'saran ikon'**
  String get categorySuggest;

  /// No description provided for @categorySuggestFor.
  ///
  /// In id, this message translates to:
  /// **'saran buat “{name}”'**
  String categorySuggestFor(String name);

  /// No description provided for @categoryUseEmoji.
  ///
  /// In id, this message translates to:
  /// **'pakai {emoji}'**
  String categoryUseEmoji(String emoji);

  /// No description provided for @categorySuggestSource.
  ///
  /// In id, this message translates to:
  /// **'dari nama'**
  String get categorySuggestSource;

  /// No description provided for @categoryAllIcons.
  ///
  /// In id, this message translates to:
  /// **'semua ikon'**
  String get categoryAllIcons;

  /// No description provided for @categoryChangeIcon.
  ///
  /// In id, this message translates to:
  /// **'ganti ikon'**
  String get categoryChangeIcon;

  /// No description provided for @categoryKindLabel.
  ///
  /// In id, this message translates to:
  /// **'jenis'**
  String get categoryKindLabel;

  /// No description provided for @kindOut.
  ///
  /// In id, this message translates to:
  /// **'duit keluar'**
  String get kindOut;

  /// No description provided for @kindIn.
  ///
  /// In id, this message translates to:
  /// **'duit masuk'**
  String get kindIn;

  /// No description provided for @categoryPocket.
  ///
  /// In id, this message translates to:
  /// **'limit bulanan'**
  String get categoryPocket;

  /// No description provided for @categoryPocketOn.
  ///
  /// In id, this message translates to:
  /// **'muncul di kantong + diingetin'**
  String get categoryPocketOn;

  /// No description provided for @categoryPocketOff.
  ///
  /// In id, this message translates to:
  /// **'opsional, bisa nanti'**
  String get categoryPocketOff;

  /// No description provided for @categoryCreate.
  ///
  /// In id, this message translates to:
  /// **'bikin {emoji} {name}'**
  String categoryCreate(String emoji, String name);

  /// No description provided for @categoryCreateUse.
  ///
  /// In id, this message translates to:
  /// **'bikin & pakai {emoji} {name}'**
  String categoryCreateUse(String emoji, String name);

  /// No description provided for @categorySave.
  ///
  /// In id, this message translates to:
  /// **'simpan {emoji} {name}'**
  String categorySave(String emoji, String name);

  /// No description provided for @categoryFallbackName.
  ///
  /// In id, this message translates to:
  /// **'baru'**
  String get categoryFallbackName;

  /// No description provided for @categoryUsageYear.
  ///
  /// In id, this message translates to:
  /// **'{amount} tahun ini'**
  String categoryUsageYear(String amount);

  /// No description provided for @categoryUnused.
  ///
  /// In id, this message translates to:
  /// **'belum kepake'**
  String get categoryUnused;

  /// No description provided for @limitPerMonth.
  ///
  /// In id, this message translates to:
  /// **'/ bulan'**
  String get limitPerMonth;

  /// No description provided for @limitFieldLabel.
  ///
  /// In id, this message translates to:
  /// **'limit per bulan'**
  String get limitFieldLabel;

  /// No description provided for @limitSliderLabel.
  ///
  /// In id, this message translates to:
  /// **'geser limit'**
  String get limitSliderLabel;

  /// No description provided for @limitMax.
  ///
  /// In id, this message translates to:
  /// **'maks Rp100jt per limit'**
  String get limitMax;

  /// No description provided for @limitPerDay.
  ///
  /// In id, this message translates to:
  /// **'≈ {amount}/hari'**
  String limitPerDay(String amount);

  /// No description provided for @limitEmpty.
  ///
  /// In id, this message translates to:
  /// **'geser atau ketik'**
  String get limitEmpty;

  /// No description provided for @limitOver.
  ///
  /// In id, this message translates to:
  /// **'lewat {amount}'**
  String limitOver(String amount);

  /// No description provided for @limitFree.
  ///
  /// In id, this message translates to:
  /// **'belum dijatah {amount}'**
  String limitFree(String amount);

  /// No description provided for @limitSetBudget.
  ///
  /// In id, this message translates to:
  /// **'＋ pasang budget bulanan'**
  String get limitSetBudget;

  /// No description provided for @manageTitle.
  ///
  /// In id, this message translates to:
  /// **'buat apa aja'**
  String get manageTitle;

  /// No description provided for @manageDone.
  ///
  /// In id, this message translates to:
  /// **'beres'**
  String get manageDone;

  /// No description provided for @manageHintIcon.
  ///
  /// In id, this message translates to:
  /// **'tap ikon = ganti ikon'**
  String get manageHintIcon;

  /// No description provided for @manageHintIconBold.
  ///
  /// In id, this message translates to:
  /// **'tap ikon'**
  String get manageHintIconBold;

  /// No description provided for @manageHintName.
  ///
  /// In id, this message translates to:
  /// **'tap nama = edit'**
  String get manageHintName;

  /// No description provided for @manageHintNameBold.
  ///
  /// In id, this message translates to:
  /// **'tap nama'**
  String get manageHintNameBold;

  /// No description provided for @manageHintMove.
  ///
  /// In id, this message translates to:
  /// **'tahan = geser'**
  String get manageHintMove;

  /// No description provided for @manageUses.
  ///
  /// In id, this message translates to:
  /// **'{count} catatan'**
  String manageUses(int count);

  /// No description provided for @manageEdit.
  ///
  /// In id, this message translates to:
  /// **'edit {name}'**
  String manageEdit(String name);

  /// No description provided for @manageTitleDelete.
  ///
  /// In id, this message translates to:
  /// **'hapus yang mana?'**
  String get manageTitleDelete;

  /// No description provided for @manageDeleteMode.
  ///
  /// In id, this message translates to:
  /// **'hapus buat apa'**
  String get manageDeleteMode;

  /// No description provided for @manageDeleteDone.
  ///
  /// In id, this message translates to:
  /// **'selesai'**
  String get manageDeleteDone;

  /// No description provided for @manageHintMinus.
  ///
  /// In id, this message translates to:
  /// **'tap − buat hapus'**
  String get manageHintMinus;

  /// No description provided for @manageHintMinusBold.
  ///
  /// In id, this message translates to:
  /// **'tap −'**
  String get manageHintMinusBold;

  /// No description provided for @manageHintMoved.
  ///
  /// In id, this message translates to:
  /// **'catatannya dipindahin dulu, nggak ilang'**
  String get manageHintMoved;

  /// No description provided for @manageLocked.
  ///
  /// In id, this message translates to:
  /// **'dikunci'**
  String get manageLocked;

  /// No description provided for @manageDelete.
  ///
  /// In id, this message translates to:
  /// **'hapus {name}'**
  String manageDelete(String name);

  /// No description provided for @manageLockedNote.
  ///
  /// In id, this message translates to:
  /// **'lain-lain & gajian nggak bisa dihapus. lain-lain jadi tempat pindahan catatan, gajian dipakai buat ngitung hari gajian.'**
  String get manageLockedNote;

  /// No description provided for @manageIcon.
  ///
  /// In id, this message translates to:
  /// **'ganti ikon {name}'**
  String manageIcon(String name);

  /// No description provided for @manageIconSwapped.
  ///
  /// In id, this message translates to:
  /// **'ikon {name} diganti'**
  String manageIconSwapped(String name);

  /// No description provided for @manageIconSwappedSub.
  ///
  /// In id, this message translates to:
  /// **'toples, catatan & statistik ikut berubah'**
  String get manageIconSwappedSub;

  /// No description provided for @manageIncomeNote.
  ///
  /// In id, this message translates to:
  /// **'{name} itu pemasukan, nggak pernah dikasih limit.'**
  String manageIncomeNote(String name);

  /// No description provided for @manageJarNote.
  ///
  /// In id, this message translates to:
  /// **'yang ada {limit} jadi toples di tab kantong.'**
  String manageJarNote(String limit);

  /// No description provided for @manageJarNoteLimit.
  ///
  /// In id, this message translates to:
  /// **'limit'**
  String get manageJarNoteLimit;

  /// No description provided for @manageLimit.
  ///
  /// In id, this message translates to:
  /// **'limit {amount}'**
  String manageLimit(String amount);

  /// No description provided for @deleteTitle.
  ///
  /// In id, this message translates to:
  /// **'hapus {name}?'**
  String deleteTitle(String name);

  /// No description provided for @deleteUsageIn.
  ///
  /// In id, this message translates to:
  /// **'{amount} di {name}'**
  String deleteUsageIn(String amount, String name);

  /// No description provided for @deleteUnused.
  ///
  /// In id, this message translates to:
  /// **'belum ada catatan'**
  String get deleteUnused;

  /// No description provided for @deleteMoveTo.
  ///
  /// In id, this message translates to:
  /// **'{count} catatan pindah ke'**
  String deleteMoveTo(int count);

  /// No description provided for @deleteCount.
  ///
  /// In id, this message translates to:
  /// **'{count} catatan'**
  String deleteCount(int count);

  /// No description provided for @deleteHold.
  ///
  /// In id, this message translates to:
  /// **'tahan buat hapus'**
  String get deleteHold;

  /// No description provided for @deleteHolding.
  ///
  /// In id, this message translates to:
  /// **'tahan terus…'**
  String get deleteHolding;

  /// No description provided for @deleteHoldLabel.
  ///
  /// In id, this message translates to:
  /// **'tahan buat hapus {name}'**
  String deleteHoldLabel(String name);

  /// No description provided for @deleteCancel.
  ///
  /// In id, this message translates to:
  /// **'nggak jadi'**
  String get deleteCancel;

  /// No description provided for @deleteDoneTitle.
  ///
  /// In id, this message translates to:
  /// **'{name} udah dihapus'**
  String deleteDoneTitle(String name);

  /// No description provided for @deleteDoneMoved.
  ///
  /// In id, this message translates to:
  /// **'{count} catatan udah pindah ke {emoji} {name}.'**
  String deleteDoneMoved(int count, String emoji, String name);

  /// No description provided for @deleteDoneEmpty.
  ///
  /// In id, this message translates to:
  /// **'nggak ada catatan yang ikut pindah.'**
  String get deleteDoneEmpty;

  /// No description provided for @deleteCategory.
  ///
  /// In id, this message translates to:
  /// **'hapus'**
  String get deleteCategory;

  /// No description provided for @limitLabel.
  ///
  /// In id, this message translates to:
  /// **'limit per bulan'**
  String get limitLabel;

  /// No description provided for @txTitle.
  ///
  /// In id, this message translates to:
  /// **'transaksi'**
  String get txTitle;

  /// No description provided for @home.
  ///
  /// In id, this message translates to:
  /// **'beranda'**
  String get home;

  /// No description provided for @txCount.
  ///
  /// In id, this message translates to:
  /// **'{count} catatan'**
  String txCount(int count);

  /// No description provided for @txAll.
  ///
  /// In id, this message translates to:
  /// **'semua'**
  String get txAll;

  /// No description provided for @txNet.
  ///
  /// In id, this message translates to:
  /// **'selisih'**
  String get txNet;

  /// No description provided for @txLeftover.
  ///
  /// In id, this message translates to:
  /// **'sisa pemasukan'**
  String get txLeftover;

  /// No description provided for @txFirstPeriod.
  ///
  /// In id, this message translates to:
  /// **'periode pertama kamu'**
  String get txFirstPeriod;

  /// No description provided for @txSameAs.
  ///
  /// In id, this message translates to:
  /// **'sama kayak {month}'**
  String txSameAs(String month);

  /// No description provided for @txUpFrom.
  ///
  /// In id, this message translates to:
  /// **'naik {amount} dari {month}'**
  String txUpFrom(String amount, String month);

  /// No description provided for @txDownFrom.
  ///
  /// In id, this message translates to:
  /// **'turun {amount} dari {month}'**
  String txDownFrom(String amount, String month);

  /// No description provided for @txNoneYet.
  ///
  /// In id, this message translates to:
  /// **'belum ada'**
  String get txNoneYet;

  /// No description provided for @txLogSalary.
  ///
  /// In id, this message translates to:
  /// **'catat gajian dulu'**
  String get txLogSalary;

  /// No description provided for @txNoCarry.
  ///
  /// In id, this message translates to:
  /// **'dihitung per periode, sisa {month} nggak kebawa'**
  String txNoCarry(String month);

  /// No description provided for @txNoCarryFirst.
  ///
  /// In id, this message translates to:
  /// **'dihitung per periode, sisa periode lalu nggak kebawa'**
  String get txNoCarryFirst;

  /// No description provided for @txEmpty.
  ///
  /// In id, this message translates to:
  /// **'belum ada catatan di {month}'**
  String txEmpty(String month);

  /// No description provided for @txAllShown.
  ///
  /// In id, this message translates to:
  /// **'udah semua di {month}'**
  String txAllShown(String month);

  /// No description provided for @txSeeMonth.
  ///
  /// In id, this message translates to:
  /// **'liat {month}'**
  String txSeeMonth(String month);

  /// No description provided for @txNoPrev.
  ///
  /// In id, this message translates to:
  /// **'nggak ada bulan sebelumnya'**
  String get txNoPrev;

  /// No description provided for @txNotYet.
  ///
  /// In id, this message translates to:
  /// **'bulan depan belum kejadian'**
  String get txNotYet;

  /// No description provided for @txBackToNow.
  ///
  /// In id, this message translates to:
  /// **'balik ke {month} {year}'**
  String txBackToNow(String month, int year);

  /// No description provided for @txPickMonth.
  ///
  /// In id, this message translates to:
  /// **'{month} {year}, ganti bulan'**
  String txPickMonth(String month, int year);

  /// No description provided for @receiptTitle.
  ///
  /// In id, this message translates to:
  /// **'struk'**
  String get receiptTitle;

  /// No description provided for @receiptKind.
  ///
  /// In id, this message translates to:
  /// **'jenis'**
  String get receiptKind;

  /// No description provided for @receiptNote.
  ///
  /// In id, this message translates to:
  /// **'catatan'**
  String get receiptNote;

  /// No description provided for @receiptAddNote.
  ///
  /// In id, this message translates to:
  /// **'+ catatan'**
  String get receiptAddNote;

  /// No description provided for @receiptPocket.
  ///
  /// In id, this message translates to:
  /// **'{emoji} {name}'**
  String receiptPocket(String emoji, String name);

  /// No description provided for @receiptLeftOf.
  ///
  /// In id, this message translates to:
  /// **'jatah sisa {left} dari limit {limit}'**
  String receiptLeftOf(String left, String limit);

  /// No description provided for @receiptOverOf.
  ///
  /// In id, this message translates to:
  /// **'kelebihan {over} dari limit {limit}'**
  String receiptOverOf(String over, String limit);

  /// No description provided for @receiptShare.
  ///
  /// In id, this message translates to:
  /// **'ini aja makan {pct}% jatah {name}'**
  String receiptShare(int pct, String name);

  /// No description provided for @receiptAgain.
  ///
  /// In id, this message translates to:
  /// **'catat lagi'**
  String get receiptAgain;

  /// No description provided for @receiptEdit.
  ///
  /// In id, this message translates to:
  /// **'edit catatan'**
  String get receiptEdit;

  /// No description provided for @entryDelete.
  ///
  /// In id, this message translates to:
  /// **'hapus catatan'**
  String get entryDelete;

  /// No description provided for @receiptDeleted.
  ///
  /// In id, this message translates to:
  /// **'dihapus'**
  String get receiptDeleted;

  /// No description provided for @receiptBack.
  ///
  /// In id, this message translates to:
  /// **'balik ke transaksi'**
  String get receiptBack;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In id, this message translates to:
  /// **'hapus catatan ini?'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteBody.
  ///
  /// In id, this message translates to:
  /// **'{amount} di {place}, {date}. tenang, masih bisa dibatalin.'**
  String confirmDeleteBody(String amount, String place, String date);

  /// No description provided for @confirmPocket.
  ///
  /// In id, this message translates to:
  /// **'{emoji} jatah {name}'**
  String confirmPocket(String emoji, String name);

  /// No description provided for @confirmPocketAfter.
  ///
  /// In id, this message translates to:
  /// **'balik jadi sisa {amount}'**
  String confirmPocketAfter(String amount);

  /// No description provided for @confirmNow.
  ///
  /// In id, this message translates to:
  /// **'sekarang {pct}% kepake'**
  String confirmNow(int pct);

  /// No description provided for @confirmAfter.
  ///
  /// In id, this message translates to:
  /// **'abis dihapus {pct}%'**
  String confirmAfter(int pct);

  /// No description provided for @confirmDelete.
  ///
  /// In id, this message translates to:
  /// **'hapus'**
  String get confirmDelete;

  /// No description provided for @confirmCancel.
  ///
  /// In id, this message translates to:
  /// **'nggak jadi'**
  String get confirmCancel;

  /// No description provided for @entryDeletedToast.
  ///
  /// In id, this message translates to:
  /// **'catatan dihapus'**
  String get entryDeletedToast;

  /// No description provided for @entryDeletedPocket.
  ///
  /// In id, this message translates to:
  /// **'jatah {name} balik jadi sisa {amount}'**
  String entryDeletedPocket(String name, String amount);

  /// No description provided for @editAmount.
  ///
  /// In id, this message translates to:
  /// **'nominal'**
  String get editAmount;

  /// No description provided for @editCategory.
  ///
  /// In id, this message translates to:
  /// **'buat apa?'**
  String get editCategory;

  /// No description provided for @editPlace.
  ///
  /// In id, this message translates to:
  /// **'di mana'**
  String get editPlace;

  /// No description provided for @editDay.
  ///
  /// In id, this message translates to:
  /// **'kapan'**
  String get editDay;

  /// No description provided for @editChanged.
  ///
  /// In id, this message translates to:
  /// **'diubah'**
  String get editChanged;

  /// No description provided for @editNoChanges.
  ///
  /// In id, this message translates to:
  /// **'belum ada perubahan'**
  String get editNoChanges;

  /// No description provided for @editChanges.
  ///
  /// In id, this message translates to:
  /// **'batalin {count} perubahan'**
  String editChanges(int count);

  /// No description provided for @editSave.
  ///
  /// In id, this message translates to:
  /// **'simpan'**
  String get editSave;

  /// No description provided for @editDelete.
  ///
  /// In id, this message translates to:
  /// **'hapus catatan ini'**
  String get editDelete;

  /// No description provided for @setupCounter.
  ///
  /// In id, this message translates to:
  /// **'setup {step}/2'**
  String setupCounter(String step);

  /// No description provided for @setupBack.
  ///
  /// In id, this message translates to:
  /// **'balik ke tanggal gajian'**
  String get setupBack;

  /// No description provided for @setupLater.
  ///
  /// In id, this message translates to:
  /// **'nanti aja'**
  String get setupLater;

  /// No description provided for @setupBudgetBody.
  ///
  /// In id, this message translates to:
  /// **'batas yang kamu pasang sendiri, bukan gaji. boleh kosong dulu.'**
  String get setupBudgetBody;

  /// No description provided for @setupBudgetTitle.
  ///
  /// In id, this message translates to:
  /// **'budget per periode'**
  String get setupBudgetTitle;

  /// No description provided for @setupOptional.
  ///
  /// In id, this message translates to:
  /// **'opsional'**
  String get setupOptional;

  /// No description provided for @setupPeriodNow.
  ///
  /// In id, this message translates to:
  /// **'periode sekarang'**
  String get setupPeriodNow;

  /// No description provided for @setupNextPayday.
  ///
  /// In id, this message translates to:
  /// **'gajian {date}'**
  String setupNextPayday(String date);

  /// No description provided for @setupBalanceLabel.
  ///
  /// In id, this message translates to:
  /// **'budget per periode'**
  String get setupBalanceLabel;

  /// No description provided for @setupPaydayTitle.
  ///
  /// In id, this message translates to:
  /// **'gajian tiap tanggal berapa?'**
  String get setupPaydayTitle;

  /// No description provided for @setupPaydayBody.
  ///
  /// In id, this message translates to:
  /// **'mibu nyatet semuanya per periode gajian.'**
  String get setupPaydayBody;

  /// No description provided for @paydayCommon.
  ///
  /// In id, this message translates to:
  /// **'umum'**
  String get paydayCommon;

  /// No description provided for @setupPaydayEnd.
  ///
  /// In id, this message translates to:
  /// **'akhir'**
  String get setupPaydayEnd;

  /// No description provided for @setupPaydayEndLabel.
  ///
  /// In id, this message translates to:
  /// **'akhir bulan'**
  String get setupPaydayEndLabel;

  /// No description provided for @setupPaydayLabel.
  ///
  /// In id, this message translates to:
  /// **'tanggal {day}'**
  String setupPaydayLabel(int day);

  /// No description provided for @setupDaily.
  ///
  /// In id, this message translates to:
  /// **'aman jajan per hari'**
  String get setupDaily;

  /// No description provided for @setupUntil.
  ///
  /// In id, this message translates to:
  /// **'sampai gajian'**
  String get setupUntil;

  /// No description provided for @setupNext.
  ///
  /// In id, this message translates to:
  /// **'lanjut'**
  String get setupNext;

  /// No description provided for @setupPocketsTitle.
  ///
  /// In id, this message translates to:
  /// **'mau mulai pasang limit ke apa?'**
  String get setupPocketsTitle;

  /// No description provided for @setupPocketsBody.
  ///
  /// In id, this message translates to:
  /// **'pilih dulu, nominal bisa diubah nanti.'**
  String get setupPocketsBody;

  /// No description provided for @setupPerMonth.
  ///
  /// In id, this message translates to:
  /// **'{amount}/periode'**
  String setupPerMonth(String amount);

  /// No description provided for @setupPocketCount.
  ///
  /// In id, this message translates to:
  /// **'{count} dikasih limit'**
  String setupPocketCount(int count);

  /// No description provided for @setupNoPockets.
  ///
  /// In id, this message translates to:
  /// **'belum ada limit'**
  String get setupNoPockets;

  /// No description provided for @setupSummary.
  ///
  /// In id, this message translates to:
  /// **'ringkasan limit'**
  String get setupSummary;

  /// No description provided for @setupFree.
  ///
  /// In id, this message translates to:
  /// **'belum dijatah {free} dari budget {balance}'**
  String setupFree(String free, String balance);

  /// No description provided for @setupOver.
  ///
  /// In id, this message translates to:
  /// **'lebih {over} dari budget'**
  String setupOver(String over);

  /// No description provided for @setupLimitTotal.
  ///
  /// In id, this message translates to:
  /// **'total limit per periode'**
  String get setupLimitTotal;

  /// No description provided for @setupTapHint.
  ///
  /// In id, this message translates to:
  /// **'tap di atas buat mulai'**
  String get setupTapHint;

  /// No description provided for @setupDone.
  ///
  /// In id, this message translates to:
  /// **'beres, ke beranda'**
  String get setupDone;

  /// No description provided for @settingsBudget.
  ///
  /// In id, this message translates to:
  /// **'budget bulanan'**
  String get settingsBudget;

  /// No description provided for @settingsBudgetUnit.
  ///
  /// In id, this message translates to:
  /// **'/ bulan'**
  String get settingsBudgetUnit;

  /// No description provided for @settingsBudgetEmpty.
  ///
  /// In id, this message translates to:
  /// **'belum diisi'**
  String get settingsBudgetEmpty;

  /// No description provided for @settingsBudgetEdit.
  ///
  /// In id, this message translates to:
  /// **'atur budget'**
  String get settingsBudgetEdit;

  /// No description provided for @settingsBudgetSet.
  ///
  /// In id, this message translates to:
  /// **'pasang budget bulanan'**
  String get settingsBudgetSet;

  /// No description provided for @settingsLimits.
  ///
  /// In id, this message translates to:
  /// **'{n} limit'**
  String settingsLimits(int n);

  /// No description provided for @settingsMoney.
  ///
  /// In id, this message translates to:
  /// **'duit'**
  String get settingsMoney;

  /// No description provided for @settingsCategories.
  ///
  /// In id, this message translates to:
  /// **'buat apa aja'**
  String get settingsCategories;

  /// No description provided for @settingsCategoriesHint.
  ///
  /// In id, this message translates to:
  /// **'nama, ikon & limit'**
  String get settingsCategoriesHint;

  /// No description provided for @settingsCategoriesMore.
  ///
  /// In id, this message translates to:
  /// **'+{n}'**
  String settingsCategoriesMore(int n);

  /// No description provided for @settingsPayday.
  ///
  /// In id, this message translates to:
  /// **'tanggal gajian'**
  String get settingsPayday;

  /// No description provided for @settingsPaydayEvery.
  ///
  /// In id, this message translates to:
  /// **'tiap tgl {day}'**
  String settingsPaydayEvery(int day);

  /// No description provided for @settingsPaydayEnd.
  ///
  /// In id, this message translates to:
  /// **'akhir bulan'**
  String get settingsPaydayEnd;

  /// No description provided for @paydayIn.
  ///
  /// In id, this message translates to:
  /// **'gajian lagi {n} hari'**
  String paydayIn(int n);

  /// No description provided for @paydayToday.
  ///
  /// In id, this message translates to:
  /// **'gajian hari ini'**
  String get paydayToday;

  /// No description provided for @paydayLate.
  ///
  /// In id, this message translates to:
  /// **'gajian telat {n} hari'**
  String paydayLate(int n);

  /// No description provided for @paydaySheetTitle.
  ///
  /// In id, this message translates to:
  /// **'gajian tiap tanggal berapa?'**
  String get paydaySheetTitle;

  /// No description provided for @paydaySheetBody.
  ///
  /// In id, this message translates to:
  /// **'semua angka di mibu dihitung dari gajian ke gajian.'**
  String get paydaySheetBody;

  /// No description provided for @paydayShiftNote.
  ///
  /// In id, this message translates to:
  /// **'{day} jatuh hari {weekday} → dihitung jumat'**
  String paydayShiftNote(String day, String weekday);

  /// No description provided for @paydaySaturday.
  ///
  /// In id, this message translates to:
  /// **'sabtu'**
  String get paydaySaturday;

  /// No description provided for @paydaySunday.
  ///
  /// In id, this message translates to:
  /// **'minggu'**
  String get paydaySunday;

  /// No description provided for @paydayOther.
  ///
  /// In id, this message translates to:
  /// **'lain…'**
  String get paydayOther;

  /// No description provided for @paydayOtherLabel.
  ///
  /// In id, this message translates to:
  /// **'tanggal lain'**
  String get paydayOtherLabel;

  /// No description provided for @paydayOtherDay.
  ///
  /// In id, this message translates to:
  /// **'tgl {day}'**
  String paydayOtherDay(int day);

  /// No description provided for @paydayDayLabel.
  ///
  /// In id, this message translates to:
  /// **'tanggal {n}'**
  String paydayDayLabel(int n);

  /// No description provided for @paydayNext.
  ///
  /// In id, this message translates to:
  /// **'gajian berikutnya'**
  String get paydayNext;

  /// No description provided for @paydayNextToday.
  ///
  /// In id, this message translates to:
  /// **'hari ini'**
  String get paydayNextToday;

  /// No description provided for @paydayNextIn.
  ///
  /// In id, this message translates to:
  /// **'{n} hari lagi'**
  String paydayNextIn(int n);

  /// No description provided for @paydayBudgetNote.
  ///
  /// In id, this message translates to:
  /// **'budget & limit ngikut gajian. ganti tanggal berlaku mulai periode berikutnya.'**
  String get paydayBudgetNote;

  /// No description provided for @paydaySave.
  ///
  /// In id, this message translates to:
  /// **'simpan {label}'**
  String paydaySave(String label);

  /// No description provided for @paydayOk.
  ///
  /// In id, this message translates to:
  /// **'oke'**
  String get paydayOk;

  /// No description provided for @paydaySavedTitle.
  ///
  /// In id, this message translates to:
  /// **'gajian jadi {label}'**
  String paydaySavedTitle(String label);

  /// No description provided for @paydaySavedSubLater.
  ///
  /// In id, this message translates to:
  /// **'berlaku mulai {date}, periode ini selesai dulu'**
  String paydaySavedSubLater(String date);

  /// No description provided for @paydaySavedSubToday.
  ///
  /// In id, this message translates to:
  /// **'gajian hari ini, aman jajan dihitung ulang'**
  String get paydaySavedSubToday;

  /// No description provided for @paydaySavedSub.
  ///
  /// In id, this message translates to:
  /// **'aman jajan dihitung sampai {n} hari lagi'**
  String paydaySavedSub(int n);

  /// No description provided for @settingsLimitMonthly.
  ///
  /// In id, this message translates to:
  /// **'limit bulanan'**
  String get settingsLimitMonthly;

  /// No description provided for @settingsPrivacy.
  ///
  /// In id, this message translates to:
  /// **'privasi'**
  String get settingsPrivacy;

  /// No description provided for @settingsHide.
  ///
  /// In id, this message translates to:
  /// **'sembunyiin nominal'**
  String get settingsHide;

  /// No description provided for @settingsHideHint.
  ///
  /// In id, this message translates to:
  /// **'tampil ••• sampai kamu tap'**
  String get settingsHideHint;

  /// No description provided for @settingsData.
  ///
  /// In id, this message translates to:
  /// **'data'**
  String get settingsData;

  /// No description provided for @settingsExport.
  ///
  /// In id, this message translates to:
  /// **'ekspor ke csv'**
  String get settingsExport;

  /// No description provided for @settingsExportHint.
  ///
  /// In id, this message translates to:
  /// **'semua catatan, satu file'**
  String get settingsExportHint;

  /// No description provided for @settingsLicenses.
  ///
  /// In id, this message translates to:
  /// **'lisensi'**
  String get settingsLicenses;

  /// No description provided for @settingsVersion.
  ///
  /// In id, this message translates to:
  /// **'versi {v}'**
  String settingsVersion(String v);

  /// No description provided for @searchSub.
  ///
  /// In id, this message translates to:
  /// **'di {month}'**
  String searchSub(String month);

  /// No description provided for @txSearchSub.
  ///
  /// In id, this message translates to:
  /// **'“{q}”'**
  String txSearchSub(String q);

  /// No description provided for @searchClear.
  ///
  /// In id, this message translates to:
  /// **'hapus pencarian'**
  String get searchClear;

  /// No description provided for @searchHint.
  ///
  /// In id, this message translates to:
  /// **'cari apa aja…'**
  String get searchHint;

  /// No description provided for @searchResults.
  ///
  /// In id, this message translates to:
  /// **'{n} hasil'**
  String searchResults(int n);

  /// No description provided for @searchDays.
  ///
  /// In id, this message translates to:
  /// **'{n} hari'**
  String searchDays(int n);

  /// No description provided for @searchAvg.
  ///
  /// In id, this message translates to:
  /// **'rata² {amount}'**
  String searchAvg(String amount);

  /// No description provided for @searchMore.
  ///
  /// In id, this message translates to:
  /// **'liat {n} lagi'**
  String searchMore(int n);

  /// No description provided for @statsWeek.
  ///
  /// In id, this message translates to:
  /// **'minggu'**
  String get statsWeek;

  /// No description provided for @statsMonth.
  ///
  /// In id, this message translates to:
  /// **'bulan'**
  String get statsMonth;

  /// No description provided for @statsYear.
  ///
  /// In id, this message translates to:
  /// **'tahun'**
  String get statsYear;

  /// No description provided for @statsPrev.
  ///
  /// In id, this message translates to:
  /// **'periode sebelumnya'**
  String get statsPrev;

  /// No description provided for @statsNext.
  ///
  /// In id, this message translates to:
  /// **'periode berikutnya'**
  String get statsNext;

  /// No description provided for @statsOut.
  ///
  /// In id, this message translates to:
  /// **'keluar'**
  String get statsOut;

  /// No description provided for @statsOutWeek.
  ///
  /// In id, this message translates to:
  /// **'keluar minggu ini'**
  String get statsOutWeek;

  /// No description provided for @statsOutMonth.
  ///
  /// In id, this message translates to:
  /// **'keluar bulan ini'**
  String get statsOutMonth;

  /// No description provided for @statsOutYear.
  ///
  /// In id, this message translates to:
  /// **'keluar tahun ini'**
  String get statsOutYear;

  /// No description provided for @statsUp.
  ///
  /// In id, this message translates to:
  /// **'↑ {amount} vs {than}'**
  String statsUp(String amount, String than);

  /// No description provided for @statsDown.
  ///
  /// In id, this message translates to:
  /// **'↓ {amount} vs {than}'**
  String statsDown(String amount, String than);

  /// No description provided for @statsLastWeek.
  ///
  /// In id, this message translates to:
  /// **'minggu lalu'**
  String get statsLastWeek;

  /// No description provided for @statsWeekBefore.
  ///
  /// In id, this message translates to:
  /// **'minggu sebelumnya'**
  String get statsWeekBefore;

  /// No description provided for @statsPerMonth.
  ///
  /// In id, this message translates to:
  /// **'rata² {amount} / bulan'**
  String statsPerMonth(String amount);

  /// No description provided for @statsNowWeek.
  ///
  /// In id, this message translates to:
  /// **'hari ini'**
  String get statsNowWeek;

  /// No description provided for @statsNowMonth.
  ///
  /// In id, this message translates to:
  /// **'minggu ini'**
  String get statsNowMonth;

  /// No description provided for @statsNowYear.
  ///
  /// In id, this message translates to:
  /// **'bulan ini'**
  String get statsNowYear;

  /// No description provided for @statsBefore.
  ///
  /// In id, this message translates to:
  /// **'sebelumnya'**
  String get statsBefore;

  /// No description provided for @statsAvgLegend.
  ///
  /// In id, this message translates to:
  /// **'rata-rata'**
  String get statsAvgLegend;

  /// No description provided for @statsAvgShort.
  ///
  /// In id, this message translates to:
  /// **'rata²'**
  String get statsAvgShort;

  /// No description provided for @statsNotYet.
  ///
  /// In id, this message translates to:
  /// **'belum'**
  String get statsNotYet;

  /// No description provided for @statsGlance.
  ///
  /// In id, this message translates to:
  /// **'sekilas'**
  String get statsGlance;

  /// No description provided for @statsPeak.
  ///
  /// In id, this message translates to:
  /// **'paling boros'**
  String get statsPeak;

  /// No description provided for @statsBecause.
  ///
  /// In id, this message translates to:
  /// **'gara-gara'**
  String get statsBecause;

  /// No description provided for @statsPeakLabel.
  ///
  /// In id, this message translates to:
  /// **'paling boros {name}, {amount}, gara-gara {why}'**
  String statsPeakLabel(String name, String amount, String why);

  /// No description provided for @statsLow.
  ///
  /// In id, this message translates to:
  /// **'paling hemat'**
  String get statsLow;

  /// No description provided for @statsAvgDay.
  ///
  /// In id, this message translates to:
  /// **'rata²/hari'**
  String get statsAvgDay;

  /// No description provided for @statsAvgWeek.
  ///
  /// In id, this message translates to:
  /// **'rata²/minggu'**
  String get statsAvgWeek;

  /// No description provided for @statsAvgMonth.
  ///
  /// In id, this message translates to:
  /// **'rata²/bulan'**
  String get statsAvgMonth;

  /// No description provided for @statsFromDays.
  ///
  /// In id, this message translates to:
  /// **'dari {n} hari'**
  String statsFromDays(int n);

  /// No description provided for @statsFromWeeks.
  ///
  /// In id, this message translates to:
  /// **'dari {n} minggu'**
  String statsFromWeeks(int n);

  /// No description provided for @statsFromMonths.
  ///
  /// In id, this message translates to:
  /// **'dari {n} bulan'**
  String statsFromMonths(int n);

  /// No description provided for @statsTrack.
  ///
  /// In id, this message translates to:
  /// **'on track nggak?'**
  String get statsTrack;

  /// No description provided for @statsBudget.
  ///
  /// In id, this message translates to:
  /// **'budget {amount}'**
  String statsBudget(String amount);

  /// No description provided for @statsLimitWeek.
  ///
  /// In id, this message translates to:
  /// **'jatah seminggu'**
  String get statsLimitWeek;

  /// No description provided for @statsLimitMonth.
  ///
  /// In id, this message translates to:
  /// **'jatah sebulan'**
  String get statsLimitMonth;

  /// No description provided for @statsLimitYear.
  ///
  /// In id, this message translates to:
  /// **'jatah setahun'**
  String get statsLimitYear;

  /// No description provided for @statsPaceOver.
  ///
  /// In id, this message translates to:
  /// **'lewat budget'**
  String get statsPaceOver;

  /// No description provided for @statsPaceNear.
  ///
  /// In id, this message translates to:
  /// **'hampir abis'**
  String get statsPaceNear;

  /// No description provided for @statsPaceUnder.
  ///
  /// In id, this message translates to:
  /// **'di bawah budget'**
  String get statsPaceUnder;

  /// No description provided for @statsPaceFine.
  ///
  /// In id, this message translates to:
  /// **'aman'**
  String get statsPaceFine;

  /// No description provided for @statsScopeWeek.
  ///
  /// In id, this message translates to:
  /// **'minggu ini'**
  String get statsScopeWeek;

  /// No description provided for @statsScopeMonth.
  ///
  /// In id, this message translates to:
  /// **'bulan ini'**
  String get statsScopeMonth;

  /// No description provided for @statsOverBy.
  ///
  /// In id, this message translates to:
  /// **'kebablasan {amount} dari budget {scope}'**
  String statsOverBy(String amount, String scope);

  /// No description provided for @statsNearLeft.
  ///
  /// In id, this message translates to:
  /// **'tinggal {amount} buat {days} hari lagi, rem dikit ya'**
  String statsNearLeft(String amount, int days);

  /// No description provided for @statsLeft.
  ///
  /// In id, this message translates to:
  /// **'masih ada {amount} buat {days} hari lagi'**
  String statsLeft(String amount, int days);

  /// No description provided for @statsYearLeft.
  ///
  /// In id, this message translates to:
  /// **'sisa {amount} buat sisa {year}'**
  String statsYearLeft(String amount, String year);

  /// No description provided for @statsPastLeft.
  ///
  /// In id, this message translates to:
  /// **'sisa {amount} dari budget {scope}'**
  String statsPastLeft(String amount, String scope);

  /// No description provided for @statsUsed.
  ///
  /// In id, this message translates to:
  /// **'duit kepake'**
  String get statsUsed;

  /// No description provided for @statsTime.
  ///
  /// In id, this message translates to:
  /// **'waktu jalan'**
  String get statsTime;

  /// No description provided for @statsNoBudget.
  ///
  /// In id, this message translates to:
  /// **'pasang budget biar ketauan kamu on track nggak'**
  String get statsNoBudget;

  /// No description provided for @statsSetBudget.
  ///
  /// In id, this message translates to:
  /// **'pasang budget'**
  String get statsSetBudget;

  /// No description provided for @statsWhere.
  ///
  /// In id, this message translates to:
  /// **'larinya ke mana'**
  String get statsWhere;

  /// No description provided for @statsTop.
  ///
  /// In id, this message translates to:
  /// **'top {n}'**
  String statsTop(int n);

  /// No description provided for @statsMoreOne.
  ///
  /// In id, this message translates to:
  /// **'+ {name} {pct}%'**
  String statsMoreOne(String name, int pct);

  /// No description provided for @statsMoreN.
  ///
  /// In id, this message translates to:
  /// **'+ {n} lainnya'**
  String statsMoreN(int n);

  /// No description provided for @iconSheetTitle.
  ///
  /// In id, this message translates to:
  /// **'pilih ikon'**
  String get iconSheetTitle;

  /// No description provided for @iconSearchHint.
  ///
  /// In id, this message translates to:
  /// **'cari ikon… kopi, motor, kado'**
  String get iconSearchHint;

  /// No description provided for @iconSearchLabel.
  ///
  /// In id, this message translates to:
  /// **'cari ikon'**
  String get iconSearchLabel;

  /// No description provided for @iconCount.
  ///
  /// In id, this message translates to:
  /// **'{n} ikon'**
  String iconCount(int n);

  /// No description provided for @iconEmpty.
  ///
  /// In id, this message translates to:
  /// **'belum ada ikon “{q}”'**
  String iconEmpty(String q);

  /// No description provided for @iconEmptyTry.
  ///
  /// In id, this message translates to:
  /// **'coba kata lain, misalnya'**
  String get iconEmptyTry;

  /// No description provided for @iconGroup.
  ///
  /// In id, this message translates to:
  /// **'{group, select, makan{makan} jalan{jalan} rumah{rumah} belanja{belanja} hiburan{hiburan} hewan{hewan} duit{duit} sehat{sehat} sekolah{sekolah} kerja{kerja} sosial{sosial} other{semua}}'**
  String iconGroup(String group);

  /// No description provided for @searchTry.
  ///
  /// In id, this message translates to:
  /// **'coba cari'**
  String get searchTry;

  /// No description provided for @searchAllMonths.
  ///
  /// In id, this message translates to:
  /// **'di semua bulan'**
  String get searchAllMonths;

  /// No description provided for @searchSubKind.
  ///
  /// In id, this message translates to:
  /// **'di {kind} {month}'**
  String searchSubKind(String kind, String month);

  /// No description provided for @searchNotFound.
  ///
  /// In id, this message translates to:
  /// **'“{q}” nggak ketemu'**
  String searchNotFound(String q);

  /// No description provided for @searchFixPre.
  ///
  /// In id, this message translates to:
  /// **'maksud kamu “'**
  String get searchFixPre;

  /// No description provided for @searchFixPost.
  ///
  /// In id, this message translates to:
  /// **'”?'**
  String get searchFixPost;

  /// No description provided for @searchWayPre.
  ///
  /// In id, this message translates to:
  /// **'ada '**
  String get searchWayPre;

  /// No description provided for @searchWayIn.
  ///
  /// In id, this message translates to:
  /// **'{n} di {where}'**
  String searchWayIn(int n, String where);

  /// No description provided for @searchOtherMonths.
  ///
  /// In id, this message translates to:
  /// **'bulan lain'**
  String get searchOtherMonths;

  /// No description provided for @searchAllCount.
  ///
  /// In id, this message translates to:
  /// **'{n} hasil di semua bulan'**
  String searchAllCount(int n);

  /// No description provided for @searchBackTo.
  ///
  /// In id, this message translates to:
  /// **'balik ke {month}'**
  String searchBackTo(String month);

  /// No description provided for @searchRecent.
  ///
  /// In id, this message translates to:
  /// **'terakhir dicari'**
  String get searchRecent;

  /// No description provided for @searchRecentClear.
  ///
  /// In id, this message translates to:
  /// **'hapus semua'**
  String get searchRecentClear;

  /// No description provided for @searchRecentDel.
  ///
  /// In id, this message translates to:
  /// **'hapus {q} dari riwayat'**
  String searchRecentDel(String q);

  /// No description provided for @searchTryHint.
  ///
  /// In id, this message translates to:
  /// **'paling sering bulan ini'**
  String get searchTryHint;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In id, this message translates to:
  /// **'belum ada yang bisa dicari'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptySub.
  ///
  /// In id, this message translates to:
  /// **'catat dulu yuk, nanti semua bisa dicari di sini'**
  String get searchEmptySub;

  /// No description provided for @searchAllDays.
  ///
  /// In id, this message translates to:
  /// **'semua hari'**
  String get searchAllDays;

  /// No description provided for @searchTickDrag.
  ///
  /// In id, this message translates to:
  /// **'geser buat ganti hari'**
  String get searchTickDrag;

  /// No description provided for @searchTicksLabel.
  ///
  /// In id, this message translates to:
  /// **'hasil per tanggal, geser buat liat per hari'**
  String get searchTicksLabel;

  /// No description provided for @searchMoreDay.
  ///
  /// In id, this message translates to:
  /// **'liat {n} lagi di hari ini'**
  String searchMoreDay(int n);

  /// No description provided for @searchBadgeMixed.
  ///
  /// In id, this message translates to:
  /// **'campur'**
  String get searchBadgeMixed;

  /// No description provided for @searchBadgeDaily.
  ///
  /// In id, this message translates to:
  /// **'hampir tiap hari'**
  String get searchBadgeDaily;

  /// No description provided for @searchBadgeBusiest.
  ///
  /// In id, this message translates to:
  /// **'paling sering'**
  String get searchBadgeBusiest;

  /// No description provided for @searchBadgeBiggest.
  ///
  /// In id, this message translates to:
  /// **'paling gede'**
  String get searchBadgeBiggest;

  /// No description provided for @searchInsExpense.
  ///
  /// In id, this message translates to:
  /// **'pengeluaran {amount}'**
  String searchInsExpense(String amount);

  /// No description provided for @searchInsIncome.
  ///
  /// In id, this message translates to:
  /// **'pemasukan {amount}'**
  String searchInsIncome(String amount);

  /// No description provided for @searchInsDays.
  ///
  /// In id, this message translates to:
  /// **'{days} dari {today} hari'**
  String searchInsDays(int days, int today);

  /// No description provided for @searchInsStreak.
  ///
  /// In id, this message translates to:
  /// **'beruntun {n} hari'**
  String searchInsStreak(int n);

  /// No description provided for @searchInsTimes.
  ///
  /// In id, this message translates to:
  /// **'{n}×'**
  String searchInsTimes(int n);

  /// No description provided for @searchInsOnly.
  ///
  /// In id, this message translates to:
  /// **'satu-satunya bulan ini'**
  String get searchInsOnly;

  /// No description provided for @searchTickHeight.
  ///
  /// In id, this message translates to:
  /// **'tinggi = nominal'**
  String get searchTickHeight;

  /// No description provided for @searchTickWidth.
  ///
  /// In id, this message translates to:
  /// **'tebal = jumlah'**
  String get searchTickWidth;

  /// No description provided for @searchTickWhen.
  ///
  /// In id, this message translates to:
  /// **'kapan kejadiannya'**
  String get searchTickWhen;
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
