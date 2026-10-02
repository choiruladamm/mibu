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

  /// No description provided for @homePockets.
  ///
  /// In id, this message translates to:
  /// **'kantong · paling kepake duluan'**
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
  /// **'liat semua transaksi ({n})'**
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

  /// No description provided for @homeBalanceEnd.
  ///
  /// In id, this message translates to:
  /// **'saldo akhir {month}'**
  String homeBalanceEnd(String month);

  /// No description provided for @homeLeftEnd.
  ///
  /// In id, this message translates to:
  /// **'sisa akhir bulan'**
  String get homeLeftEnd;

  /// No description provided for @homeOverEnd.
  ///
  /// In id, this message translates to:
  /// **'lewat budget'**
  String get homeOverEnd;

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
  /// **'cari atau bikin kategori'**
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
  /// **'{spent} dari {limit} kepake · '**
  String pocketsSpentOf(String spent, String limit);

  /// No description provided for @pocketsEmpty.
  ///
  /// In id, this message translates to:
  /// **'belum ada kantong. bikin satu biar jajan ada batasnya.'**
  String get pocketsEmpty;

  /// No description provided for @pocketsCount.
  ///
  /// In id, this message translates to:
  /// **'{n} kantong'**
  String pocketsCount(int n);

  /// No description provided for @pocketsOrder.
  ///
  /// In id, this message translates to:
  /// **' · urut dari yang paling kepake'**
  String get pocketsOrder;

  /// No description provided for @pocketsSwipe.
  ///
  /// In id, this message translates to:
  /// **'geser'**
  String get pocketsSwipe;

  /// No description provided for @pocketsNewJar.
  ///
  /// In id, this message translates to:
  /// **'bikin kantong baru'**
  String get pocketsNewJar;

  /// No description provided for @pocketsFirstTitle.
  ///
  /// In id, this message translates to:
  /// **'bikin kantong pertama'**
  String get pocketsFirstTitle;

  /// No description provided for @pocketsFirstBody.
  ///
  /// In id, this message translates to:
  /// **'kasih batas buat makan, ngopi, atau ojol. mibu ngingetin kalau udah mau abis.'**
  String get pocketsFirstBody;

  /// No description provided for @pocketsFirstButton.
  ///
  /// In id, this message translates to:
  /// **'bikin kantong'**
  String get pocketsFirstButton;

  /// No description provided for @pocketsFreeTitle.
  ///
  /// In id, this message translates to:
  /// **'tanpa kantong · '**
  String get pocketsFreeTitle;

  /// No description provided for @pocketsFreeSuffix.
  ///
  /// In id, this message translates to:
  /// **' bulan ini'**
  String get pocketsFreeSuffix;

  /// No description provided for @pocketsFreeManage.
  ///
  /// In id, this message translates to:
  /// **'atur'**
  String get pocketsFreeManage;

  /// No description provided for @pocketsFreeChip.
  ///
  /// In id, this message translates to:
  /// **'pasang batas buat {name}'**
  String pocketsFreeChip(String name);

  /// No description provided for @pocketsFreeMore.
  ///
  /// In id, this message translates to:
  /// **'liat kategori lain tanpa kantong'**
  String get pocketsFreeMore;

  /// No description provided for @categoryNewPocketTitle.
  ///
  /// In id, this message translates to:
  /// **'kantong baru'**
  String get categoryNewPocketTitle;

  /// No description provided for @categoryChipPocket.
  ///
  /// In id, this message translates to:
  /// **'kantong = pengeluaran dengan batas bulanan'**
  String get categoryChipPocket;

  /// No description provided for @categoryChipCatat.
  ///
  /// In id, this message translates to:
  /// **'abis dibikin, langsung kepasang di catatan kamu'**
  String get categoryChipCatat;

  /// No description provided for @categoryChipAtur.
  ///
  /// In id, this message translates to:
  /// **'nambah ke daftar kategori kamu'**
  String get categoryChipAtur;

  /// No description provided for @categoryCreatePocket.
  ///
  /// In id, this message translates to:
  /// **'bikin kantong {emoji} {name}'**
  String categoryCreatePocket(String emoji, String name);

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
  /// **'budget bulanan'**
  String get budgetTitle;

  /// No description provided for @budgetSub.
  ///
  /// In id, this message translates to:
  /// **'berapa yang boleh kepake sebulan?'**
  String get budgetSub;

  /// No description provided for @budgetLabelNow.
  ///
  /// In id, this message translates to:
  /// **'budget sekarang'**
  String get budgetLabelNow;

  /// No description provided for @budgetLabelSuggest.
  ///
  /// In id, this message translates to:
  /// **'saran dari total kantong'**
  String get budgetLabelSuggest;

  /// No description provided for @budgetAutoFilled.
  ///
  /// In id, this message translates to:
  /// **'diisi otomatis'**
  String get budgetAutoFilled;

  /// No description provided for @budgetInfoType.
  ///
  /// In id, this message translates to:
  /// **'kantong kamu total {total} · ketik budget kamu'**
  String budgetInfoType(String total);

  /// No description provided for @budgetInfoFree.
  ///
  /// In id, this message translates to:
  /// **'kantong kamu total {total} · sisa bebas {free}'**
  String budgetInfoFree(String total, String free);

  /// No description provided for @budgetInfoShort.
  ///
  /// In id, this message translates to:
  /// **'kurang {amount} buat nutup semua kantong'**
  String budgetInfoShort(String amount);

  /// No description provided for @budgetFillFirst.
  ///
  /// In id, this message translates to:
  /// **'isi dulu'**
  String get budgetFillFirst;

  /// No description provided for @budgetPerMonth.
  ///
  /// In id, this message translates to:
  /// **'{amount} / bln'**
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
  /// **'ritme budget dihitung ulang'**
  String get budgetSavedSub;

  /// No description provided for @budgetDeletedTitle.
  ///
  /// In id, this message translates to:
  /// **'budget dihapus'**
  String get budgetDeletedTitle;

  /// No description provided for @budgetDeletedSub.
  ///
  /// In id, this message translates to:
  /// **'ritme budget libur dulu'**
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
  /// **'kategori baru'**
  String get categoryNewTitle;

  /// No description provided for @categoryEditTitle.
  ///
  /// In id, this message translates to:
  /// **'edit kategori'**
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
  /// **'nama kategori'**
  String get categoryNameLabel;

  /// No description provided for @categorySuggest.
  ///
  /// In id, this message translates to:
  /// **'saran'**
  String get categorySuggest;

  /// No description provided for @categorySuggestFor.
  ///
  /// In id, this message translates to:
  /// **'buat “{name}”'**
  String categorySuggestFor(String name);

  /// No description provided for @categoryUseEmoji.
  ///
  /// In id, this message translates to:
  /// **'pakai {emoji}'**
  String categoryUseEmoji(String emoji);

  /// No description provided for @categoryKindLabel.
  ///
  /// In id, this message translates to:
  /// **'masuk ke'**
  String get categoryKindLabel;

  /// No description provided for @categoryPocket.
  ///
  /// In id, this message translates to:
  /// **'kantong bulanan'**
  String get categoryPocket;

  /// No description provided for @categoryPocketOn.
  ///
  /// In id, this message translates to:
  /// **'mibu ngingetin kalau udah mau abis'**
  String get categoryPocketOn;

  /// No description provided for @categoryPocketOff.
  ///
  /// In id, this message translates to:
  /// **'tanpa batas, cuma dicatat'**
  String get categoryPocketOff;

  /// No description provided for @categoryCreate.
  ///
  /// In id, this message translates to:
  /// **'bikin {emoji} {name}'**
  String categoryCreate(String emoji, String name);

  /// No description provided for @categorySave.
  ///
  /// In id, this message translates to:
  /// **'simpan {emoji} {name}'**
  String categorySave(String emoji, String name);

  /// No description provided for @categoryFallbackName.
  ///
  /// In id, this message translates to:
  /// **'kategori'**
  String get categoryFallbackName;

  /// No description provided for @categoryUsage.
  ///
  /// In id, this message translates to:
  /// **'{count} catatan · {amount} tahun ini'**
  String categoryUsage(int count, String amount);

  /// No description provided for @categoryUnused.
  ///
  /// In id, this message translates to:
  /// **'belum dipakai'**
  String get categoryUnused;

  /// No description provided for @limitPerMonth.
  ///
  /// In id, this message translates to:
  /// **'/ bulan'**
  String get limitPerMonth;

  /// No description provided for @limitFieldLabel.
  ///
  /// In id, this message translates to:
  /// **'batas kantong per bulan'**
  String get limitFieldLabel;

  /// No description provided for @limitSliderLabel.
  ///
  /// In id, this message translates to:
  /// **'geser batas kantong'**
  String get limitSliderLabel;

  /// No description provided for @limitMax.
  ///
  /// In id, this message translates to:
  /// **'maks Rp100jt per kantong'**
  String get limitMax;

  /// No description provided for @limitPerDay.
  ///
  /// In id, this message translates to:
  /// **'≈ {amount} sehari'**
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
  /// **'sisa budget {amount}'**
  String limitFree(String amount);

  /// No description provided for @limitSetBudget.
  ///
  /// In id, this message translates to:
  /// **'＋ pasang budget bulanan'**
  String get limitSetBudget;

  /// No description provided for @manageTitle.
  ///
  /// In id, this message translates to:
  /// **'kategori kamu'**
  String get manageTitle;

  /// No description provided for @manageDone.
  ///
  /// In id, this message translates to:
  /// **'beres'**
  String get manageDone;

  /// No description provided for @manageHint.
  ///
  /// In id, this message translates to:
  /// **'tap buat edit · − buat hapus · tahan & geser buat urutin'**
  String get manageHint;

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

  /// No description provided for @manageDelete.
  ///
  /// In id, this message translates to:
  /// **'hapus {name}'**
  String manageDelete(String name);

  /// No description provided for @manageIncomeNote.
  ///
  /// In id, this message translates to:
  /// **'{name} itu buat pemasukan, jadi cuma muncul pas kamu catat pemasukan.'**
  String manageIncomeNote(String name);

  /// No description provided for @deleteTitle.
  ///
  /// In id, this message translates to:
  /// **'hapus {name}?'**
  String deleteTitle(String name);

  /// No description provided for @deleteUsage.
  ///
  /// In id, this message translates to:
  /// **'{count} catatan · {amount} pakai kategori ini'**
  String deleteUsage(int count, String amount);

  /// No description provided for @deleteUnused.
  ///
  /// In id, this message translates to:
  /// **'belum ada catatan pakai kategori ini'**
  String get deleteUnused;

  /// No description provided for @deleteMoveTo.
  ///
  /// In id, this message translates to:
  /// **'pindahin {count} catatan itu ke'**
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
  /// **'{count} catatan sekarang pindah ke {emoji} {name}.'**
  String deleteDoneMoved(int count, String emoji, String name);

  /// No description provided for @deleteDoneEmpty.
  ///
  /// In id, this message translates to:
  /// **'nggak ada catatan yang ikut pindah.'**
  String get deleteDoneEmpty;

  /// No description provided for @deleteCategory.
  ///
  /// In id, this message translates to:
  /// **'hapus kategori'**
  String get deleteCategory;

  /// No description provided for @limitLabel.
  ///
  /// In id, this message translates to:
  /// **'batas per bulan'**
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

  /// No description provided for @txEmpty.
  ///
  /// In id, this message translates to:
  /// **'belum ada catatan di {month}'**
  String txEmpty(String month);

  /// No description provided for @txAllShown.
  ///
  /// In id, this message translates to:
  /// **'udah semua buat {month}'**
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
  /// **'{month} belum kejadian'**
  String txNotYet(String month);

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

  /// No description provided for @receiptPaid.
  ///
  /// In id, this message translates to:
  /// **'dibayar {date}'**
  String receiptPaid(String date);

  /// No description provided for @receiptReceived.
  ///
  /// In id, this message translates to:
  /// **'masuk {date}'**
  String receiptReceived(String date);

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
  /// **'tambahin catatan'**
  String get receiptAddNote;

  /// No description provided for @receiptPocket.
  ///
  /// In id, this message translates to:
  /// **'kantong {name}'**
  String receiptPocket(String name);

  /// No description provided for @receiptLeftOf.
  ///
  /// In id, this message translates to:
  /// **'sisa {left} dari {limit}'**
  String receiptLeftOf(String left, String limit);

  /// No description provided for @receiptOverOf.
  ///
  /// In id, this message translates to:
  /// **'kelebihan {over} dari {limit}'**
  String receiptOverOf(String over, String limit);

  /// No description provided for @receiptShare.
  ///
  /// In id, this message translates to:
  /// **'transaksi ini aja udah makan {pct}% kantong.'**
  String receiptShare(int pct);

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
  /// **'{amount} di {place}, {date}. tenang, abis ini masih bisa dibatalin.'**
  String confirmDeleteBody(String amount, String place, String date);

  /// No description provided for @confirmPocket.
  ///
  /// In id, this message translates to:
  /// **'{emoji} kantong {name}'**
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
  /// **'abis ini {pct}%'**
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
  /// **'kantong {name} balik jadi sisa {amount}'**
  String entryDeletedPocket(String name, String amount);

  /// No description provided for @editAmount.
  ///
  /// In id, this message translates to:
  /// **'nominal'**
  String get editAmount;

  /// No description provided for @editCategory.
  ///
  /// In id, this message translates to:
  /// **'kategori'**
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
  /// **'{count} perubahan · batalin'**
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
  /// **'atur awal · {step} / 02'**
  String setupCounter(String step);

  /// No description provided for @setupBack.
  ///
  /// In id, this message translates to:
  /// **'balik ke saldo'**
  String get setupBack;

  /// No description provided for @setupLater.
  ///
  /// In id, this message translates to:
  /// **'nanti aja'**
  String get setupLater;

  /// No description provided for @setupBalanceTitle.
  ///
  /// In id, this message translates to:
  /// **'saldo kamu sekarang berapa?'**
  String get setupBalanceTitle;

  /// No description provided for @setupBalanceLabel.
  ///
  /// In id, this message translates to:
  /// **'saldo awal'**
  String get setupBalanceLabel;

  /// No description provided for @setupPaydayTitle.
  ///
  /// In id, this message translates to:
  /// **'gajian tiap tanggal berapa?'**
  String get setupPaydayTitle;

  /// No description provided for @setupPaydayBody.
  ///
  /// In id, this message translates to:
  /// **'biar jatah harian dihitung sampai gajian berikutnya'**
  String get setupPaydayBody;

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
  /// **'sampai gajian · {days} hari lagi'**
  String setupUntil(int days);

  /// No description provided for @setupNext.
  ///
  /// In id, this message translates to:
  /// **'lanjut'**
  String get setupNext;

  /// No description provided for @setupPocketsTitle.
  ///
  /// In id, this message translates to:
  /// **'mau mulai dari kantong apa?'**
  String get setupPocketsTitle;

  /// No description provided for @setupPocketsBody.
  ///
  /// In id, this message translates to:
  /// **'pilih aja dulu, nominalnya bisa diubah nanti.'**
  String get setupPocketsBody;

  /// No description provided for @setupPerMonth.
  ///
  /// In id, this message translates to:
  /// **'{amount}/bln'**
  String setupPerMonth(String amount);

  /// No description provided for @setupPocketCount.
  ///
  /// In id, this message translates to:
  /// **'{count} kantong'**
  String setupPocketCount(int count);

  /// No description provided for @setupNoPockets.
  ///
  /// In id, this message translates to:
  /// **'belum ada kantong'**
  String get setupNoPockets;

  /// No description provided for @setupSummary.
  ///
  /// In id, this message translates to:
  /// **'ringkasan kantong'**
  String get setupSummary;

  /// No description provided for @setupFree.
  ///
  /// In id, this message translates to:
  /// **'sisa bebas {free} dari saldo {balance}'**
  String setupFree(String free, String balance);

  /// No description provided for @setupOver.
  ///
  /// In id, this message translates to:
  /// **'lebih {over} dari saldo — santai, nanti gajian nambah'**
  String setupOver(String over);

  /// No description provided for @setupTapHint.
  ///
  /// In id, this message translates to:
  /// **'tap kantong di atas buat mulai'**
  String get setupTapHint;

  /// No description provided for @setupDone.
  ///
  /// In id, this message translates to:
  /// **'beres, ke beranda'**
  String get setupDone;
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
