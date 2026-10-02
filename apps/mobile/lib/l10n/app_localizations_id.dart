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
      'ketik nominal, pilih buat apa, simpan. nggak perlu spreadsheet, nggak perlu ribet.';

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
  String get homePockets => 'kantong · paling kepake duluan';

  @override
  String homeTodayTotal(String total) {
    return '$total hari ini';
  }

  @override
  String homeRecentIn(String month) {
    return 'terakhir di $month';
  }

  @override
  String homeAllCount(int n) {
    return 'liat semua transaksi ($n)';
  }

  @override
  String homeAllIn(String month, int n) {
    return 'liat semua di $month ($n)';
  }

  @override
  String get homeTodayEmpty => 'belum ada catatan hari ini';

  @override
  String get homeNoEntriesTitle => 'belum ada catatan';

  @override
  String get homeNoEntriesBody => 'catat jajan pertama kamu, cuma 3 detik.';

  @override
  String homeMonthEmpty(String month) {
    return 'belum ada catatan di $month';
  }

  @override
  String homeBalanceEnd(String month) {
    return 'saldo akhir $month';
  }

  @override
  String get homeLeftEnd => 'sisa akhir bulan';

  @override
  String get homeOverEnd => 'lewat budget';

  @override
  String homePocketPill(String name, int pct) {
    return 'buka kantong $name, $pct% kepake';
  }

  @override
  String get monthMenuTitle => 'pilih bulan';

  @override
  String get monthMenuPrevYear => 'tahun sebelumnya';

  @override
  String get monthMenuNextYear => 'tahun berikutnya';

  @override
  String get monthMenuLegend => 'total pengeluaran';

  @override
  String get monthMenuNow => 'bulan ini';

  @override
  String monthMenuCell(String month, int year) {
    return '$month $year';
  }

  @override
  String get monthMenuFuture => 'belum kejadian';

  @override
  String get monthMenuEarly => 'belum ada catatan';

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
  String get pickCategory => 'buat apa?';

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
    return '$emoji jatah $name abis ini';
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
  String get pickerTitle => 'buat apa?';

  @override
  String get pickerSearch => 'cari atau bikin…';

  @override
  String get pickerRecent => 'terakhir · sekali tap langsung keisi';

  @override
  String get pickerWhere => 'di mana';

  @override
  String pickerUse(String emoji, String name) {
    return 'pakai $emoji $name';
  }

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
  String get notePlaceholder => 'sama siapa, kenapa, detailnya…';

  @override
  String get noteQuickTags => 'tag cepet';

  @override
  String noteTagsMax(int n) {
    return 'maks $n';
  }

  @override
  String get noteWroteBefore => 'pernah kamu tulis';

  @override
  String get noteSave => 'simpan catatan';

  @override
  String get noteLeaveEmpty => 'nggak jadi, kosongin';

  @override
  String get pocketsSetLimit => 'pasang limit';

  @override
  String get pocketsJarNew => 'limit';

  @override
  String pocketsLeftTitle(String month) {
    return 'sisa jajan $month';
  }

  @override
  String pocketsSpentOf(String spent, String limit) {
    return '$spent dari $limit kepake · ';
  }

  @override
  String pocketsCount(int n) {
    return '$n pakai limit';
  }

  @override
  String get pocketsOrder => ' · urut dari yang paling kepake';

  @override
  String get pocketsSwipe => 'geser';

  @override
  String get pocketsNewJar => 'pasang limit ke yang lain';

  @override
  String get pocketsFirstTitle => 'pasang limit pertama';

  @override
  String get pocketsFirstBody =>
      'pasang limit ke makan, ngopi, atau ojol. catatan bulan ini langsung keitung.';

  @override
  String get pocketsFirstButton => 'pasang limit';

  @override
  String get pocketsFreeTitle => 'belum ada limit · ';

  @override
  String get pocketsFreeSuffix => ' bulan ini';

  @override
  String get pocketsFreeManage => 'semua';

  @override
  String pocketsFreeChip(String name) {
    return 'pasang limit buat $name';
  }

  @override
  String get pocketsFreeMore => 'liat yang lain belum ada limit';

  @override
  String get categoryChipPocket => 'dari: pasang limit ke…';

  @override
  String get categoryChipCatat =>
      'abis dibikin, langsung kepake di catatan ini';

  @override
  String get categoryChipAtur => 'nambah ke buat apa aja';

  @override
  String get categoryChipEdit => 'dari: buat apa aja';

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
    return 'jatah sisa dari limit $limit';
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
  String get pocketManage => 'atur limit';

  @override
  String get pocketRelease => 'lepas limit';

  @override
  String limitSetTitle(String name, String amount) {
    return 'limit $name $amount kepasang';
  }

  @override
  String limitSetSub(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n catatan bulan ini langsung keitung',
      zero: 'toplesnya udah nongol',
    );
    return '$_temp0';
  }

  @override
  String limitReleasedTitle(String name) {
    return 'limit $name dilepas';
  }

  @override
  String limitReleasedSub(int n, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$name & $n catatannya tetap ada',
      zero: '$name tetap ada, cuma nggak dibatesin',
    );
    return '$_temp0';
  }

  @override
  String get setLimitTitle => 'pasang limit ke…';

  @override
  String get setLimitHint =>
      'yang belum pakai limit, urut dari paling kepake bulan ini. catatan bulan ini langsung keitung.';

  @override
  String setLimitMeta(int n, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n catatan · $amount udah kepake bulan ini',
      zero: 'belum dipakai bulan ini',
    );
    return '$_temp0';
  }

  @override
  String get setLimitEmptyTitle => 'semua buat apa udah pakai limit';

  @override
  String get setLimitEmptyBody => 'mau ngatur yang lain? bikin baru aja.';

  @override
  String get setLimitNewCategory => 'bikin kategori baru';

  @override
  String get setLimitIncomeNote =>
      'pemasukan (gajian dkk) nggak bisa dikasih limit';

  @override
  String get setLimitBack => 'ganti';

  @override
  String setLimitFill(int pct, String amount) {
    return 'toples langsung keisi $pct% · sisa jatah $amount';
  }

  @override
  String setLimitSave(String amount) {
    return 'pasang limit $amount';
  }

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

  @override
  String get undo => 'batalin';

  @override
  String get budgetTitle => 'budget bulanan';

  @override
  String get budgetSub => 'berapa yang boleh kepake sebulan?';

  @override
  String get budgetLabelNow => 'budget sekarang';

  @override
  String get budgetLabelSuggest => 'saran dari total limit';

  @override
  String get budgetAutoFilled => 'diisi otomatis';

  @override
  String budgetInfoType(String total) {
    return 'total limit kamu $total · ketik budget kamu';
  }

  @override
  String budgetInfoFree(String total, String free) {
    return 'total limit kamu $total · sisa bebas $free';
  }

  @override
  String budgetInfoShort(String amount) {
    return 'kurang $amount buat nutup semua limit';
  }

  @override
  String get budgetFillFirst => 'isi dulu';

  @override
  String budgetPerMonth(String amount) {
    return '$amount / bln';
  }

  @override
  String get budgetDelete => 'hapus budget';

  @override
  String budgetSavedTitle(String amount) {
    return 'budget $amount kesimpen';
  }

  @override
  String get budgetSavedSub => 'ritme budget dihitung ulang';

  @override
  String get budgetDeletedTitle => 'budget dihapus';

  @override
  String get budgetDeletedSub => 'ritme budget libur dulu';

  @override
  String pocketsBudget(String amount) {
    return 'budget $amount';
  }

  @override
  String get pocketsSetBudget => 'pasang budget';

  @override
  String pocketsDaysLeft(int days) {
    return '$days hari lagi';
  }

  @override
  String get pickerManage => 'atur';

  @override
  String get categoryNew => 'baru';

  @override
  String categoryCreateNamed(String name) {
    return 'bikin “$name”';
  }

  @override
  String get categoryNewTitle => 'bikin baru';

  @override
  String get categoryEditTitle => 'edit';

  @override
  String get cancel => 'batal';

  @override
  String get categoryNameHint => 'kasih nama';

  @override
  String get categoryNameLabel => 'buat apa?';

  @override
  String get categorySuggest => 'saran';

  @override
  String categorySuggestFor(String name) {
    return 'buat “$name”';
  }

  @override
  String categoryUseEmoji(String emoji) {
    return 'pakai $emoji';
  }

  @override
  String get categoryKindLabel => 'masuk ke';

  @override
  String get categoryPocket => 'limit bulanan';

  @override
  String get categoryPocketOn => 'jadi toples · mibu ngingetin kalau mau abis';

  @override
  String get categoryPocketOff => 'nggak wajib, bisa dipasang nanti';

  @override
  String categoryCreate(String emoji, String name) {
    return 'bikin $emoji $name';
  }

  @override
  String categoryCreateUse(String emoji, String name) {
    return 'bikin & pakai $emoji $name';
  }

  @override
  String categorySave(String emoji, String name) {
    return 'simpan $emoji $name';
  }

  @override
  String get categoryFallbackName => 'baru';

  @override
  String categoryUsage(int count, String amount) {
    return '$count catatan · $amount tahun ini';
  }

  @override
  String get categoryUnused => 'belum dipakai';

  @override
  String get limitPerMonth => '/ bulan';

  @override
  String get limitFieldLabel => 'limit per bulan';

  @override
  String get limitSliderLabel => 'geser limit';

  @override
  String get limitMax => 'maks Rp100jt per limit';

  @override
  String limitPerDay(String amount) {
    return '≈ $amount sehari';
  }

  @override
  String get limitEmpty => 'geser atau ketik';

  @override
  String limitOver(String amount) {
    return 'lewat $amount';
  }

  @override
  String limitFree(String amount) {
    return 'sisa budget $amount';
  }

  @override
  String get limitSetBudget => '＋ pasang budget bulanan';

  @override
  String get manageTitle => 'buat apa aja';

  @override
  String get manageDone => 'beres';

  @override
  String get manageHint =>
      'tap buat edit · − buat hapus · tahan & geser buat urutin';

  @override
  String manageUses(int count) {
    return '$count catatan';
  }

  @override
  String manageEdit(String name) {
    return 'edit $name';
  }

  @override
  String manageDelete(String name) {
    return 'hapus $name';
  }

  @override
  String manageIncomeNote(String name) {
    return '$name itu pemasukan, nggak pernah dikasih limit.';
  }

  @override
  String manageJarNote(String limit) {
    return 'yang ada $limit jadi toples di tab kantong.';
  }

  @override
  String get manageJarNoteLimit => 'limit';

  @override
  String manageLimit(String amount) {
    return 'limit $amount';
  }

  @override
  String deleteTitle(String name) {
    return 'hapus $name?';
  }

  @override
  String deleteUsage(int count, String amount) {
    return '$count catatan · $amount pakai kategori ini';
  }

  @override
  String get deleteUnused => 'belum ada catatan pakai kategori ini';

  @override
  String deleteMoveTo(int count) {
    return 'pindahin $count catatan itu ke';
  }

  @override
  String deleteCount(int count) {
    return '$count catatan';
  }

  @override
  String get deleteHold => 'tahan buat hapus';

  @override
  String get deleteHolding => 'tahan terus…';

  @override
  String deleteHoldLabel(String name) {
    return 'tahan buat hapus $name';
  }

  @override
  String get deleteCancel => 'nggak jadi';

  @override
  String deleteDoneTitle(String name) {
    return '$name udah dihapus';
  }

  @override
  String deleteDoneMoved(int count, String emoji, String name) {
    return '$count catatan sekarang pindah ke $emoji $name.';
  }

  @override
  String get deleteDoneEmpty => 'nggak ada catatan yang ikut pindah.';

  @override
  String get deleteCategory => 'hapus kategori';

  @override
  String get limitLabel => 'limit per bulan';

  @override
  String get txTitle => 'transaksi';

  @override
  String get home => 'beranda';

  @override
  String txCount(int count) {
    return '$count catatan';
  }

  @override
  String get txAll => 'semua';

  @override
  String get txNet => 'selisih';

  @override
  String txEmpty(String month) {
    return 'belum ada catatan di $month';
  }

  @override
  String txAllShown(String month) {
    return 'udah semua buat $month';
  }

  @override
  String txSeeMonth(String month) {
    return 'liat $month';
  }

  @override
  String get txNoPrev => 'nggak ada bulan sebelumnya';

  @override
  String txNotYet(String month) {
    return '$month belum kejadian';
  }

  @override
  String txBackToNow(String month, int year) {
    return 'balik ke $month $year';
  }

  @override
  String txPickMonth(String month, int year) {
    return '$month $year, ganti bulan';
  }

  @override
  String get receiptTitle => 'struk';

  @override
  String receiptPaid(String date) {
    return 'dibayar $date';
  }

  @override
  String receiptReceived(String date) {
    return 'masuk $date';
  }

  @override
  String get receiptKind => 'jenis';

  @override
  String get receiptNote => 'catatan';

  @override
  String get receiptAddNote => 'tambahin catatan';

  @override
  String receiptPocket(String emoji, String name) {
    return '$emoji $name';
  }

  @override
  String receiptLeftOf(String left, String limit) {
    return 'jatah sisa $left dari limit $limit';
  }

  @override
  String receiptOverOf(String over, String limit) {
    return 'kelebihan $over dari limit $limit';
  }

  @override
  String receiptShare(int pct, String name) {
    return 'transaksi ini aja udah makan $pct% jatah $name.';
  }

  @override
  String get receiptAgain => 'catat lagi';

  @override
  String get receiptEdit => 'edit catatan';

  @override
  String get entryDelete => 'hapus catatan';

  @override
  String get receiptDeleted => 'dihapus';

  @override
  String get receiptBack => 'balik ke transaksi';

  @override
  String get confirmDeleteTitle => 'hapus catatan ini?';

  @override
  String confirmDeleteBody(String amount, String place, String date) {
    return '$amount di $place, $date. tenang, abis ini masih bisa dibatalin.';
  }

  @override
  String confirmPocket(String emoji, String name) {
    return '$emoji jatah $name';
  }

  @override
  String confirmPocketAfter(String amount) {
    return 'balik jadi sisa $amount';
  }

  @override
  String confirmNow(int pct) {
    return 'sekarang $pct% kepake';
  }

  @override
  String confirmAfter(int pct) {
    return 'abis ini $pct%';
  }

  @override
  String get confirmDelete => 'hapus';

  @override
  String get confirmCancel => 'nggak jadi';

  @override
  String get entryDeletedToast => 'catatan dihapus';

  @override
  String entryDeletedPocket(String name, String amount) {
    return 'jatah $name balik jadi sisa $amount';
  }

  @override
  String get editAmount => 'nominal';

  @override
  String get editCategory => 'buat apa?';

  @override
  String get editPlace => 'di mana';

  @override
  String get editDay => 'kapan';

  @override
  String get editChanged => 'diubah';

  @override
  String get editNoChanges => 'belum ada perubahan';

  @override
  String editChanges(int count) {
    return '$count perubahan · batalin';
  }

  @override
  String get editSave => 'simpan';

  @override
  String get editDelete => 'hapus catatan ini';

  @override
  String setupCounter(String step) {
    return 'atur awal · $step / 02';
  }

  @override
  String get setupBack => 'balik ke saldo';

  @override
  String get setupLater => 'nanti aja';

  @override
  String get setupBalanceTitle => 'saldo kamu sekarang berapa?';

  @override
  String get setupBalanceLabel => 'saldo awal';

  @override
  String get setupPaydayTitle => 'gajian tiap tanggal berapa?';

  @override
  String get setupPaydayBody =>
      'biar jatah harian dihitung sampai gajian berikutnya';

  @override
  String get setupPaydayEnd => 'akhir';

  @override
  String get setupPaydayEndLabel => 'akhir bulan';

  @override
  String setupPaydayLabel(int day) {
    return 'tanggal $day';
  }

  @override
  String get setupDaily => 'aman jajan per hari';

  @override
  String setupUntil(int days) {
    return 'sampai gajian · $days hari lagi';
  }

  @override
  String get setupNext => 'lanjut';

  @override
  String get setupPocketsTitle => 'mau mulai pasang limit ke apa?';

  @override
  String get setupPocketsBody =>
      'pilih aja dulu, nominalnya bisa diubah nanti.';

  @override
  String setupPerMonth(String amount) {
    return '$amount/bln';
  }

  @override
  String setupPocketCount(int count) {
    return '$count dikasih limit';
  }

  @override
  String get setupNoPockets => 'belum ada limit';

  @override
  String get setupSummary => 'ringkasan limit';

  @override
  String setupFree(String free, String balance) {
    return 'sisa bebas $free dari saldo $balance';
  }

  @override
  String setupOver(String over) {
    return 'lebih $over dari saldo — santai, nanti gajian nambah';
  }

  @override
  String get setupTapHint => 'tap di atas buat mulai';

  @override
  String get setupDone => 'beres, ke beranda';
}
