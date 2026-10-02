// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'mibu';

  @override
  String get tabHome => 'beranda';

  @override
  String get tabPockets => 'kantong';

  @override
  String get tabStats => 'statistik';

  @override
  String get tabSettings => 'pengaturan';

  @override
  String get balanceLabel => 'saldo kamu';

  @override
  String get safeToSpendToday => 'aman jajan hari ini';

  @override
  String get overspentToday => 'kebablasan hari ini';

  @override
  String get uncategorized => 'tanpa kategori';

  @override
  String get onboardingSkip => 'lewati';

  @override
  String get onboardingNext => 'lanjut';

  @override
  String get onboardingStart => 'mulai sekarang';

  @override
  String get onboardingFooter => 'masuk pakai google / apple · tanpa password';

  @override
  String onboardingCounter(int step) {
    return '0$step / 03';
  }

  @override
  String onboardingStepLabel(int step) {
    return 'langkah $step';
  }

  @override
  String get onboarding1Title => 'duit kamu, ada kantongnya.';

  @override
  String get onboarding1Body =>
      'bagi gaji ke kantong-kantong kecil. makan, ngopi, liburan — semuanya jelas jatahnya.';

  @override
  String get onboarding2Title => 'tau jatah jajan hari ini.';

  @override
  String get onboarding2Body =>
      'mibu ngitungin berapa yang aman dipake hari ini, biar tanggal tua nggak makan mie terus.';

  @override
  String get onboarding3Title => 'catat 3 detik, beres.';

  @override
  String get onboarding3Body =>
      'ketik nominal, pilih kategori, simpan. nggak perlu spreadsheet, nggak perlu ribet.';

  @override
  String get onboardingSalaryIn => 'gajian masuk';

  @override
  String get pocketFood => 'makan';

  @override
  String get pocketCoffee => 'ngopi';

  @override
  String get pocketHoliday => 'liburan';

  @override
  String get addEntry => 'catat';

  @override
  String get search => 'cari';

  @override
  String get seeAll => 'lihat semua';

  @override
  String get today => 'hari ini';

  @override
  String get prediction => 'prediksi';

  @override
  String monthPickerLabel(String month) {
    return 'ganti bulan, sekarang $month';
  }

  @override
  String get homeMonthlyBalance => 'saldo per bulan';

  @override
  String get homeTapMonthHint => 'tap bulannya buat intip';

  @override
  String get homeRecent => 'baru aja';

  @override
  String get close => 'tutup';

  @override
  String get expense => 'pengeluaran';

  @override
  String get income => 'pemasukan';

  @override
  String saveEntry(String kind) {
    return 'simpan $kind';
  }

  @override
  String get pickOtherDate => 'pilih tanggal lain';

  @override
  String get pickCategory => 'pilih kategori';

  @override
  String get noteButton => 'catatan';

  @override
  String editNote(String note) {
    return 'edit catatan: $note';
  }

  @override
  String get clearNote => 'hapus catatan';

  @override
  String pocketAfter(String emoji, String name) {
    return '$emoji kantong $name abis ini';
  }

  @override
  String get balanceAfter => 'saldo abis ini';

  @override
  String leftAmount(String amount) {
    return 'sisa $amount';
  }

  @override
  String overAmount(String amount) {
    return 'kelebihan $amount';
  }

  @override
  String get keyThreeZeros => 'tambah tiga nol';

  @override
  String get keyBackspace => 'hapus satu angka';

  @override
  String get pickerTitle => 'ini buat apa?';

  @override
  String get pickerSearch => 'cari kategori';

  @override
  String get pickerRecent => 'terakhir · sekali tap langsung keisi';

  @override
  String get pickerWhere => 'di mana';

  @override
  String pickerUse(String emoji, String name) {
    return 'pakai $emoji $name';
  }

  @override
  String get pickerNoMatch => 'nggak ada kategori yang cocok';

  @override
  String get yesterday => 'kemarin';

  @override
  String get twoDaysAgo => 'kemarin lusa';

  @override
  String daysAgo(int n) {
    return '$n hari lalu';
  }

  @override
  String get thisWeek => 'minggu ini';

  @override
  String get lastWeek => 'minggu lalu';

  @override
  String weeksAgo(int n) {
    return '$n minggu lalu';
  }

  @override
  String backTo(String day) {
    return 'balik ke $day';
  }

  @override
  String get prevWeek => 'minggu sebelumnya';

  @override
  String get nextWeek => 'minggu berikutnya';

  @override
  String get notYet => 'belum kejadian';

  @override
  String pickDayIn(String range) {
    return 'pilih hari, $range';
  }

  @override
  String get dateSheetTitle => 'kapan kejadiannya?';

  @override
  String get startOfMonth => 'awal bulan';

  @override
  String get prevMonth => 'bulan sebelumnya';

  @override
  String get nextMonth => 'bulan berikutnya';

  @override
  String entriesThatDay(int n) {
    return 'udah ada $n catatan — jangan dobel ya';
  }

  @override
  String get noEntriesThatDay => 'belum ada catatan di hari ini';

  @override
  String useDate(String date) {
    return 'pakai $date';
  }

  @override
  String get noteFor => 'buat';

  @override
  String get notePlaceholder => 'buat apa, sama siapa, kenapa…';

  @override
  String get noteQuickTags => 'tag cepet · maks 3';

  @override
  String get noteWroteBefore => 'pernah kamu tulis';

  @override
  String get noteSave => 'simpan catatan';

  @override
  String get noteLeaveEmpty => 'nggak jadi, kosongin';

  @override
  String get pocketsNew => 'baru';

  @override
  String pocketsLeftTitle(String month) {
    return 'sisa jajan $month';
  }

  @override
  String pocketsSpentOf(String spent, String limit, int days) {
    return '$spent dari $limit kepake · $days hari lagi';
  }

  @override
  String get pocketsEmpty =>
      'belum ada kantong. bikin satu biar jajan ada batasnya.';

  @override
  String pocketJarLabel(String name, int pct) {
    return '$name, $pct% kepake';
  }

  @override
  String get pocketSelected => 'kantong yang dipilih';

  @override
  String get pocketStatusSafe => 'aman';

  @override
  String get pocketStatusAlmostOut => 'hampir abis';

  @override
  String get pocketStatusUnused => 'belum kepake';

  @override
  String pocketLeftOf(String limit) {
    return 'sisa dari $limit';
  }

  @override
  String pocketDaily(String amount, int days) {
    return 'kira-kira $amount sehari buat $days hari ke depan';
  }

  @override
  String pocketOver(String amount) {
    return 'kelebihan $amount bulan ini';
  }

  @override
  String get pocketManage => 'atur kantong';

  @override
  String get keyPlus => 'tambah nominal lain';

  @override
  String get keyTwoZeros => 'tambah dua nol';

  @override
  String get keyClear => 'kosongin semua';

  @override
  String get keyClearShort => 'kosongin';

  @override
  String get keySave => 'simpan';

  @override
  String get amountTypeHint => 'ketik nominal';

  @override
  String amountInWords(String words) {
    return '$words rupiah';
  }
}
