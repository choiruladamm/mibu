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
  String get safeToSpendToday => 'aman jajan hari ini';

  @override
  String get overspentToday => 'kebablasan hari ini';

  @override
  String get uncategorized => 'lain-lain';

  @override
  String get onboardingSkip => 'skip';

  @override
  String get onboardingNext => 'lanjut';

  @override
  String get onboardingStart => 'mulai sekarang';

  @override
  String get onboardingFooter => 'masuk pakai google / apple';

  @override
  String get onboardingNoPassword => 'tanpa password';

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
  String get seeAll => 'liat semua';

  @override
  String get today => 'hari ini';

  @override
  String monthPickerLabel(String month) {
    return 'ganti bulan, sekarang $month';
  }

  @override
  String get homeMonthlyBalance => 'kepake per periode';

  @override
  String get homeTapMonthHint => 'tap periode buat intip';

  @override
  String get chartNow => 'berjalan';

  @override
  String get chartOverBudget => 'lewat budget';

  @override
  String chartBudget(String amount) {
    return 'budget $amount';
  }

  @override
  String get homeRecent => 'baru aja';

  @override
  String get homePockets => 'kantong';

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
    return 'semua transaksi ($n)';
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
  String get infoWhere => 'dari mana angkanya?';

  @override
  String get infoOk => 'oke, ngerti';

  @override
  String get infoBudgetTitle => 'sisa budget';

  @override
  String infoBudgetCalc(String budget, String spent) {
    return 'budget $budget − kepake $spent';
  }

  @override
  String infoBudgetTransition(int days, int normal) {
    return 'periode peralihan $days hari, budget dihitung $days/$normal';
  }

  @override
  String infoSafeCalc(String left, int days) {
    return 'sisa budget $left ÷ $days hari sampai gajian';
  }

  @override
  String infoSafeToday(String spent, String left) {
    return 'udah kepake $spent hari ini, jadi aman jajan hari ini tinggal $left.';
  }

  @override
  String infoJarCalc(String limit, String spent) {
    return 'total limit $limit − kepake di kantong $spent';
  }

  @override
  String infoJarOutside(String amount) {
    return 'bisa beda dari sisa budget, soalnya $amount kepake di luar kantong.';
  }

  @override
  String get infoBudgetNone =>
      'belum ada budget. pasang dulu biar aman jajan bisa dihitung.';

  @override
  String get infoSafeWaiting => 'nunggu budget dipasang';

  @override
  String get infoSafeTitle => 'aman jajan per hari';

  @override
  String get infoJarTitle => 'sisa jajan (kantong)';

  @override
  String get heroBudgetLeft => 'sisa budget';

  @override
  String get heroBudgetOver => 'kelewat budget';

  @override
  String get heroSpent => 'kepake bulan ini';

  @override
  String heroSpentEnd(String month) {
    return 'kepake $month';
  }

  @override
  String heroBudgetLeftEnd(String month) {
    return 'sisa budget $month';
  }

  @override
  String heroBudgetOverEnd(String month) {
    return 'kelewat budget $month';
  }

  @override
  String heroFromBudget(String amount) {
    return 'dari budget $amount';
  }

  @override
  String get heroSetBudgetChip => 'isi budget biar dapet aman jajan';

  @override
  String get heroEmptyTitle => 'atur budget periode ini';

  @override
  String heroEmptyBody(String spent) {
    return 'biar keliatan sisa budget & aman jajan per hari. kepake periode ini $spent.';
  }

  @override
  String get heroEmptyButton => 'atur budget';

  @override
  String get heroCatatGajian => 'udah gajian? catat';

  @override
  String get heroCatatGajianLate => 'gajian belum masuk? catat';

  @override
  String get heroRemDulu => 'rem dulu ya';

  @override
  String heroDaysLeft(int n) {
    return '$n hari lagi';
  }

  @override
  String get heroAvgDay => 'rata²/hari';

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
  String get balanceAfter => 'sisa budget abis ini';

  @override
  String get incomeAfter => 'pemasukan periode ini jadi';

  @override
  String leftAmount(String amount) {
    return 'sisa $amount';
  }

  @override
  String overAmount(String amount) {
    return 'lewat $amount';
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
  String get pickerRecent => 'terakhir dipakai';

  @override
  String get pickerWhere => 'di mana';

  @override
  String get placeHint => 'mis. warteg, indomaret, gofood';

  @override
  String placeHintFor(String places) {
    return 'mis. $places';
  }

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
  String get dateSheetTitle => 'tanggal berapa?';

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
  String pocketsBudgetTitle(String month) {
    return 'sisa budget $month';
  }

  @override
  String pocketsOverTitle(String month) {
    return 'kelewat budget $month';
  }

  @override
  String pocketsJarsTitle(String month) {
    return 'sisa di toples $month';
  }

  @override
  String pocketsJarsLeft(String left, String limit) {
    return 'di toples sisa $left dari $limit';
  }

  @override
  String pocketsJarsMore(String left) {
    return 'di toples sisa $left, lebih dari sisa budget';
  }

  @override
  String pocketsSpentOf(String spent, String limit) {
    return '$spent dari $limit kepake';
  }

  @override
  String pocketsCount(int n) {
    return '$n pakai limit';
  }

  @override
  String get pocketsSwipe => 'geser';

  @override
  String get pocketsIntroTitle => 'kantong = budget kamu, dipecah per toples';

  @override
  String get pocketsIntroBody =>
      'kayak amplop: makan Rp3jt, ngopi Rp600K, dst. biar ketauan bocornya di mana.';

  @override
  String pocketsIntroCount(int n, String total) {
    return '$n kantong $total';
  }

  @override
  String pocketsIntroFree(String amount) {
    return '$amount belum dijatah';
  }

  @override
  String pocketsIntroOver(String amount) {
    return 'lebih $amount dari budget';
  }

  @override
  String get pocketsIntroNoBudget => 'belum pasang budget';

  @override
  String get pocketsIntroOk => 'oke';

  @override
  String get infoPocketsLead => 'kantong = budget kamu, dipecah per toples.';

  @override
  String get infoPocketsBody =>
      'pasang limit ke makan, ngopi, ojol, mibu ngitung sisanya sampai gajian.';

  @override
  String get pocketsNewJar => 'pasang limit ke yang lain';

  @override
  String get pocketsFirstBody =>
      'kayak amplop: makan, ngopi, ojol. mibu ngabarin pas mau abis.';

  @override
  String get pocketsFirstButton => '+ pasang limit';

  @override
  String get pocketsFreeTitle => 'belum ada limit';

  @override
  String get pocketsNoLimit => 'belum ada limit';

  @override
  String get pocketsFreeSuffix => ' bulan ini';

  @override
  String pocketsFreeChip(String name) {
    return 'pasang limit buat $name';
  }

  @override
  String get pocketsFreeMore => 'liat yang lain belum ada limit';

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
  String get pocketStatusOver => '! lewat limit';

  @override
  String get pocketLeftLabel => 'jatah sisa';

  @override
  String get pocketOverLabel => 'kelewat';

  @override
  String pocketLimitOf(String limit) {
    return 'limit $limit';
  }

  @override
  String pocketOverDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'masih $n hari lagi, rem dulu ya',
      one: 'hari terakhir, rem dulu ya',
    );
    return '$_temp0';
  }

  @override
  String get pocketRaise => 'naikin limit';

  @override
  String pocketUsedPct(int pct) {
    return '$pct% kepake';
  }

  @override
  String pocketDaily(String amount) {
    return '≈ $amount/hari sampai gajian';
  }

  @override
  String get pocketManage => 'atur limit';

  @override
  String get pocketRelease => 'copot limit';

  @override
  String limitSetTitle(String name, String amount) {
    return 'limit $name $amount kepasang';
  }

  @override
  String limitSetSub(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n catatan langsung keitung',
      zero: 'toplesnya udah nongol',
    );
    return '$_temp0';
  }

  @override
  String limitReleasedTitle(String name) {
    return 'limit $name dicopot';
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
  String limitOffTitle(String name) {
    return 'copot limit $name?';
  }

  @override
  String limitOffSub(String name) {
    return 'toplesnya ilang, $name jadi “belum ada limit”.';
  }

  @override
  String limitOffBusyTitle(String name, int n) {
    return 'kamu udah $n× catat $name bulan ini';
  }

  @override
  String limitOffBusySub(String name) {
    return 'termasuk yang paling sering. tanpa limit, mibu nggak bakal ngingetin kalau $name mulai kebablasan.';
  }

  @override
  String get limitOffNoWarn => 'nggak ada peringatan “hampir abis” lagi';

  @override
  String limitOffFreed(String amount) {
    return '$amount balik jadi belum dijatah di budget';
  }

  @override
  String limitOffKept(int n, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n catatan ($amount) tetap aman, nggak kehapus',
      zero: 'catatan lama tetap aman, nggak kehapus',
    );
    return '$_temp0';
  }

  @override
  String get setLimitTitle => 'pasang limit ke…';

  @override
  String get setLimitHintOrder => 'urut paling kepake';

  @override
  String get setLimitHintCounts => 'catatan lama langsung keitung';

  @override
  String setLimitCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n catatan',
      zero: 'belum kepake',
    );
    return '$_temp0';
  }

  @override
  String setLimitSpent(String amount) {
    return '$amount udah kepake bulan ini';
  }

  @override
  String get setLimitUnused => 'belum kepake bulan ini';

  @override
  String setLimitFilled(int pct) {
    return 'keisi $pct%';
  }

  @override
  String setLimitLeft(String amount) {
    return 'sisa jatah $amount';
  }

  @override
  String get setLimitEmptyTitle => 'semua udah pakai limit';

  @override
  String get setLimitEmptyBody => 'mau yang lain? bikin baru';

  @override
  String get setLimitNewCategory => 'bikin baru';

  @override
  String get setLimitIncomeNote => 'pemasukan nggak pakai limit';

  @override
  String get setLimitBack => 'ganti';

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
  String get amountSuggested => 'kayak gaji terakhir, ketik buat ganti';

  @override
  String get amountTypeHint => 'ketik nominal';

  @override
  String amountInWords(String words) {
    return '$words rupiah';
  }

  @override
  String get undo => 'batalin';

  @override
  String get budgetTitle => 'budget per periode';

  @override
  String get budgetSub => 'berapa yang boleh kepake sampai gajian?';

  @override
  String budgetLastSpent(String amount) {
    return 'periode lalu kepake $amount';
  }

  @override
  String get budgetLabelNow => 'budget sekarang';

  @override
  String get budgetLabelSuggest => 'saran dari total limit';

  @override
  String get budgetAutoFilled => 'diisi otomatis';

  @override
  String get budgetInfoType => 'ketik budget kamu';

  @override
  String budgetInfoTotal(String total) {
    return 'total limit $total';
  }

  @override
  String budgetInfoShort(String amount) {
    return 'kurang $amount';
  }

  @override
  String get budgetFillFirst => 'isi dulu';

  @override
  String budgetPerMonth(String amount) {
    return '$amount / periode';
  }

  @override
  String get budgetDelete => 'hapus budget';

  @override
  String budgetSavedTitle(String amount) {
    return 'budget $amount kesimpen';
  }

  @override
  String get budgetSavedSub => 'budget di-track ulang';

  @override
  String get budgetDeletedTitle => 'budget dihapus';

  @override
  String get budgetDeletedSub => 'tracking budget off dulu';

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
  String get categorySuggest => 'saran ikon';

  @override
  String categorySuggestFor(String name) {
    return 'saran buat “$name”';
  }

  @override
  String categoryUseEmoji(String emoji) {
    return 'pakai $emoji';
  }

  @override
  String get categorySuggestSource => 'dari nama';

  @override
  String get categoryAllIcons => 'semua ikon';

  @override
  String get categoryChangeIcon => 'ganti ikon';

  @override
  String get categoryKindLabel => 'jenis';

  @override
  String get kindOut => 'duit keluar';

  @override
  String get kindIn => 'duit masuk';

  @override
  String get categoryPocket => 'limit bulanan';

  @override
  String get categoryPocketOn => 'muncul di kantong + diingetin';

  @override
  String get categoryPocketOff => 'opsional, bisa nanti';

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
  String categoryUsageYear(String amount) {
    return '$amount tahun ini';
  }

  @override
  String get categoryUnused => 'belum kepake';

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
    return '≈ $amount/hari';
  }

  @override
  String get limitEmpty => 'geser atau ketik';

  @override
  String limitOver(String amount) {
    return 'lewat $amount';
  }

  @override
  String limitFree(String amount) {
    return 'belum dijatah $amount';
  }

  @override
  String get limitSetBudget => '＋ pasang budget bulanan';

  @override
  String get manageTitle => 'buat apa aja';

  @override
  String get manageDone => 'beres';

  @override
  String get manageHintIcon => 'tap ikon = ganti ikon';

  @override
  String get manageHintIconBold => 'tap ikon';

  @override
  String get manageHintName => 'tap nama = edit';

  @override
  String get manageHintNameBold => 'tap nama';

  @override
  String get manageHintMove => 'tahan = geser';

  @override
  String manageUses(int count) {
    return '$count catatan';
  }

  @override
  String manageEdit(String name) {
    return 'edit $name';
  }

  @override
  String get manageTitleDelete => 'hapus yang mana?';

  @override
  String get manageDeleteMode => 'hapus buat apa';

  @override
  String get manageDeleteDone => 'selesai';

  @override
  String get manageHintMinus => 'tap − buat hapus';

  @override
  String get manageHintMinusBold => 'tap −';

  @override
  String get manageHintMoved => 'catatannya dipindahin dulu, nggak ilang';

  @override
  String get manageLocked => 'dikunci';

  @override
  String manageDelete(String name) {
    return 'hapus $name';
  }

  @override
  String get manageLockedNote =>
      'lain-lain & gajian nggak bisa dihapus. lain-lain jadi tempat pindahan catatan, gajian dipakai buat ngitung hari gajian.';

  @override
  String manageIcon(String name) {
    return 'ganti ikon $name';
  }

  @override
  String manageIconSwapped(String name) {
    return 'ikon $name diganti';
  }

  @override
  String get manageIconSwappedSub => 'toples, catatan & statistik ikut berubah';

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
  String deleteUsageIn(String amount, String name) {
    return '$amount di $name';
  }

  @override
  String get deleteUnused => 'belum ada catatan';

  @override
  String deleteMoveTo(int count) {
    return '$count catatan pindah ke';
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
    return '$count catatan udah pindah ke $emoji $name.';
  }

  @override
  String get deleteDoneEmpty => 'nggak ada catatan yang ikut pindah.';

  @override
  String get deleteCategory => 'hapus';

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
  String get txLeftover => 'sisa pemasukan';

  @override
  String get txFirstPeriod => 'periode pertama kamu';

  @override
  String txSameAs(String month) {
    return 'sama kayak $month';
  }

  @override
  String txUpFrom(String amount, String month) {
    return 'naik $amount dari $month';
  }

  @override
  String txDownFrom(String amount, String month) {
    return 'turun $amount dari $month';
  }

  @override
  String get txNoneYet => 'belum ada';

  @override
  String get txLogSalary => 'catat gajian dulu';

  @override
  String txNoCarry(String month) {
    return 'dihitung per periode, sisa $month nggak kebawa';
  }

  @override
  String get txNoCarryFirst =>
      'dihitung per periode, sisa periode lalu nggak kebawa';

  @override
  String txEmpty(String month) {
    return 'belum ada catatan di $month';
  }

  @override
  String txAllShown(String month) {
    return 'udah semua di $month';
  }

  @override
  String txSeeMonth(String month) {
    return 'liat $month';
  }

  @override
  String get txNoPrev => 'nggak ada bulan sebelumnya';

  @override
  String get txNotYet => 'bulan depan belum kejadian';

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
  String get receiptKind => 'jenis';

  @override
  String get receiptNote => 'catatan';

  @override
  String get receiptAddNote => '+ catatan';

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
    return 'ini aja makan $pct% jatah $name';
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
    return '$amount di $place, $date. tenang, masih bisa dibatalin.';
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
    return 'abis dihapus $pct%';
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
    return 'batalin $count perubahan';
  }

  @override
  String get editSave => 'simpan';

  @override
  String get editDelete => 'hapus catatan ini';

  @override
  String setupCounter(String step) {
    return 'setup $step/2';
  }

  @override
  String get setupBack => 'balik ke tanggal gajian';

  @override
  String get setupLater => 'nanti aja';

  @override
  String get setupBudgetBody =>
      'batas yang kamu pasang sendiri, bukan gaji. boleh kosong dulu.';

  @override
  String get setupBudgetTitle => 'budget per periode';

  @override
  String get setupOptional => 'opsional';

  @override
  String get setupPeriodNow => 'periode sekarang';

  @override
  String setupNextPayday(String date) {
    return 'gajian $date';
  }

  @override
  String get setupBalanceLabel => 'budget per periode';

  @override
  String get setupPaydayTitle => 'gajian tiap tanggal berapa?';

  @override
  String get setupPaydayBody => 'mibu nyatet semuanya per periode gajian.';

  @override
  String get paydayCommon => 'umum';

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
  String get setupUntil => 'sampai gajian';

  @override
  String get setupNext => 'lanjut';

  @override
  String get setupPocketsTitle => 'mau mulai pasang limit ke apa?';

  @override
  String get setupPocketsBody => 'pilih dulu, nominal bisa diubah nanti.';

  @override
  String setupPerMonth(String amount) {
    return '$amount/periode';
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
    return 'belum dijatah $free dari budget $balance';
  }

  @override
  String setupOver(String over) {
    return 'lebih $over dari budget';
  }

  @override
  String get setupLimitTotal => 'total limit per periode';

  @override
  String get setupTapHint => 'tap di atas buat mulai';

  @override
  String get setupDone => 'beres, ke beranda';

  @override
  String get settingsBudget => 'budget per periode';

  @override
  String get settingsBudgetUnit => '/ periode';

  @override
  String get settingsBudgetEmpty => 'belum diisi';

  @override
  String get settingsBudgetEdit => 'atur budget';

  @override
  String get settingsBudgetSet => 'pasang budget per periode';

  @override
  String settingsPeriod(String range) {
    return 'periode $range';
  }

  @override
  String settingsLimits(int n) {
    return '$n kantong';
  }

  @override
  String get settingsMoney => 'duit';

  @override
  String get settingsCategories => 'buat apa aja';

  @override
  String get settingsCategoriesHint => 'nama, ikon & limit';

  @override
  String settingsCategoriesMore(int n) {
    return '+$n';
  }

  @override
  String get settingsPayday => 'tanggal gajian';

  @override
  String settingsPaydayEvery(int day) {
    return 'tiap tgl $day';
  }

  @override
  String get settingsPaydayEnd => 'akhir bulan';

  @override
  String paydayIn(int n) {
    return 'gajian lagi $n hari';
  }

  @override
  String get paydayToday => 'gajian hari ini';

  @override
  String paydayLate(int n) {
    return 'gajian telat $n hari';
  }

  @override
  String get paydaySheetTitle => 'gajian tiap tanggal berapa?';

  @override
  String get paydaySheetBody =>
      'semua angka di mibu dihitung dari gajian ke gajian.';

  @override
  String paydayShiftNote(String day, String weekday) {
    return '$day jatuh hari $weekday → dihitung jumat';
  }

  @override
  String get paydaySaturday => 'sabtu';

  @override
  String get paydaySunday => 'minggu';

  @override
  String get paydayOther => 'lainnya';

  @override
  String get paydayOtherLabel => 'tanggal lain';

  @override
  String paydayOtherDay(int day) {
    return 'tgl $day';
  }

  @override
  String paydayDayLabel(int n) {
    return 'tanggal $n';
  }

  @override
  String get paydayNext => 'gajian berikutnya';

  @override
  String get paydayNextToday => 'hari ini';

  @override
  String paydayNextIn(int n) {
    return '$n hari lagi';
  }

  @override
  String get paydayBudgetNote =>
      'budget & limit ngikut gajian. ganti tanggal atau weekend berlaku mulai periode berikutnya.';

  @override
  String get paydayWeekendLabel => 'kalau jatuh sabtu / minggu';

  @override
  String get paydayWeekendFriday => 'mundur ke jumat';

  @override
  String get paydayWeekendKeep => 'tetap tanggalnya';

  @override
  String get paydaySaveShift => 'simpan';

  @override
  String paydaySavedKeepTitle(String label) {
    return 'gajian tetap di $label';
  }

  @override
  String get paydaySavedFridayTitle => 'weekend dihitung jumat';

  @override
  String paydaySave(String label) {
    return 'simpan $label';
  }

  @override
  String get paydayOk => 'oke';

  @override
  String paydaySavedTitle(String label) {
    return 'gajian jadi $label';
  }

  @override
  String paydaySavedSubLater(String date) {
    return 'berlaku mulai $date, periode ini selesai dulu';
  }

  @override
  String get paydaySavedSubToday =>
      'gajian hari ini, aman jajan dihitung ulang';

  @override
  String paydaySavedSub(int n) {
    return 'aman jajan dihitung sampai $n hari lagi';
  }

  @override
  String paydaySavedSubMerged(String date) {
    return 'periode ini jadi sampai $date';
  }

  @override
  String paydayPreviewRange(String range) {
    return 'periode ini jadi $range';
  }

  @override
  String paydayPreviewDays(int n) {
    return '$n hari';
  }

  @override
  String paydayPreviewBudget(String amount) {
    return 'budget $amount';
  }

  @override
  String get settingsLimitMonthly => 'limit kantong';

  @override
  String get settingsPrivacy => 'privasi';

  @override
  String get settingsHide => 'sembunyiin nominal';

  @override
  String get hideNone => 'nggak';

  @override
  String get hideIncome => 'pemasukan aja';

  @override
  String get hideAll => 'semua nominal';

  @override
  String get hideSheetSub => 'buat yang suka buka app di tempat rame';

  @override
  String get hideNoneSub => 'semua angka keliatan';

  @override
  String get hideIncomeSub =>
      'gaji, bonus & sisa pemasukan jadi •••. pengeluaran & budget tetap keliatan';

  @override
  String get hideAllSub => 'semua angka jadi •••, termasuk budget & kepake';

  @override
  String get hideNew => 'baru';

  @override
  String get hideExample => 'contoh di transaksi';

  @override
  String get hideExSalary => 'gajian';

  @override
  String get hideExFood => 'makan';

  @override
  String get hideExRide => 'ojol';

  @override
  String get hidePeekNote =>
      'tap angka utama buat intip 5 detik, abis itu ketutup lagi';

  @override
  String get hideLaterNote => 'bisa diubah kapan aja di pengaturan';

  @override
  String get hideOk => 'oke';

  @override
  String get hideSave => 'simpan';

  @override
  String get hideToastNone => 'nggak disembunyiin';

  @override
  String get hideToastIncome => 'pemasukan disembunyiin';

  @override
  String get hideToastAll => 'semua nominal disembunyiin';

  @override
  String get hideToastNoneSub => 'semua angka keliatan lagi';

  @override
  String get hideToastIncomeSub => 'gaji & sisa pemasukan jadi •••';

  @override
  String get hideToastAllSub => 'tap angka utama buat intip 5 detik';

  @override
  String get peekOpen => 'intip 5 detik';

  @override
  String get peekClose => 'tutup lagi';

  @override
  String get amountHidden => 'disembunyiin';

  @override
  String get settingsData => 'data';

  @override
  String get settingsExport => 'export ke csv';

  @override
  String get settingsExportHint => 'semua catatan, satu file';

  @override
  String get settingsImport => 'import dari csv';

  @override
  String get settingsImportHint => 'balikin catatan dari file export mibu';

  @override
  String get importNew => 'catatan baru';

  @override
  String importExpenses(int n) {
    return '$n pengeluaran';
  }

  @override
  String importIncomes(int n) {
    return '$n pemasukan';
  }

  @override
  String get importAdded => 'ikut ditambahin';

  @override
  String get importAddedInfo => 'belum ada di mibu, tanpa limit';

  @override
  String importCount(int n) {
    return '$n catatan';
  }

  @override
  String importDupes(int n) {
    return '$n udah ada, dilewatin';
  }

  @override
  String importBad(int n) {
    return '$n baris nggak kebaca';
  }

  @override
  String importButton(int n) {
    return 'import $n catatan';
  }

  @override
  String get importSameTitle => 'semua udah ada';

  @override
  String importSameSub(int n) {
    return '$n catatan di file ini udah kecatat di mibu, nggak ada yang baru';
  }

  @override
  String get importOk => 'oke';

  @override
  String get importWrongTitle => 'file-nya bukan dari mibu';

  @override
  String get importWrongSub =>
      'import cuma bisa dari file hasil export mibu. buka mibu di hp lama, pengaturan › export ke csv, terus pilih file itu di sini';

  @override
  String get importPickAgain => 'pilih file lain';

  @override
  String importToast(int n) {
    return '$n catatan masuk';
  }

  @override
  String importToastSub(String names) {
    return '$names ikut ditambahin';
  }

  @override
  String get settingsLicenses => 'lisensi';

  @override
  String settingsVersion(String v) {
    return 'versi $v';
  }

  @override
  String searchSub(String month) {
    return 'di $month';
  }

  @override
  String txSearchSub(String q) {
    return '“$q”';
  }

  @override
  String get searchClear => 'hapus pencarian';

  @override
  String get searchHint => 'cari apa aja…';

  @override
  String searchResults(int n) {
    return '$n hasil';
  }

  @override
  String searchDays(int n) {
    return '$n hari';
  }

  @override
  String searchAvg(String amount) {
    return 'rata² $amount';
  }

  @override
  String searchMore(int n) {
    return 'liat $n lagi';
  }

  @override
  String get statsWeek => 'minggu';

  @override
  String get statsMonth => 'bulan';

  @override
  String get statsYear => 'tahun';

  @override
  String get statsPrev => 'periode sebelumnya';

  @override
  String get statsNext => 'periode berikutnya';

  @override
  String get statsOut => 'kepake';

  @override
  String statsOutPast(String month) {
    return 'kepake $month';
  }

  @override
  String get statsOutWeek => 'kepake minggu ini';

  @override
  String get statsOutMonth => 'kepake bulan ini';

  @override
  String get statsOutYear => 'kepake tahun ini';

  @override
  String statsUp(String amount, String than) {
    return '↑ $amount vs $than';
  }

  @override
  String statsDown(String amount, String than) {
    return '↓ $amount vs $than';
  }

  @override
  String get statsLastWeek => 'minggu lalu';

  @override
  String get statsWeekBefore => 'minggu sebelumnya';

  @override
  String statsPerMonth(String amount) {
    return 'rata² $amount / periode';
  }

  @override
  String get statsNowWeek => 'hari ini';

  @override
  String get statsNowMonth => 'minggu ini';

  @override
  String get statsNowYear => 'bulan ini';

  @override
  String get statsBefore => 'sebelumnya';

  @override
  String get statsAvgLegend => 'rata-rata';

  @override
  String get statsAvgShort => 'rata²';

  @override
  String get statsNotYet => 'belum';

  @override
  String get statsGlance => 'sekilas';

  @override
  String get statsPeak => 'paling boros';

  @override
  String get statsBecause => 'gara-gara';

  @override
  String statsPeakLabel(String name, String amount, String why) {
    return 'paling boros $name, $amount, gara-gara $why';
  }

  @override
  String get statsLow => 'paling hemat';

  @override
  String get statsAvgDay => 'rata²/hari';

  @override
  String get statsAvgWeek => 'rata²/minggu';

  @override
  String get statsAvgMonth => 'rata²/periode';

  @override
  String statsFromDays(int n) {
    return 'dari $n hari';
  }

  @override
  String statsFromWeeks(int n) {
    return 'dari $n minggu';
  }

  @override
  String statsFromMonths(int n) {
    return 'dari $n periode';
  }

  @override
  String get statsTrack => 'on track nggak?';

  @override
  String statsBudget(String amount) {
    return 'budget $amount';
  }

  @override
  String get statsLimitWeek => 'jatah seminggu';

  @override
  String get statsLimitMonth => 'jatah periode ini';

  @override
  String statsLimitPast(String month) {
    return 'jatah periode $month';
  }

  @override
  String get statsLimitYear => 'jatah setahun';

  @override
  String get statsPaceOver => 'lewat budget';

  @override
  String get statsPaceNear => 'hampir abis';

  @override
  String get statsPaceUnder => 'di bawah budget';

  @override
  String get statsPaceFine => 'aman';

  @override
  String get statsScopeWeek => 'minggu ini';

  @override
  String get statsScopeMonth => 'periode ini';

  @override
  String statsScopePeriod(String month) {
    return 'periode $month';
  }

  @override
  String statsOverBy(String amount, String scope) {
    return 'kebablasan $amount dari budget $scope';
  }

  @override
  String statsNearLeft(String amount, int days) {
    return 'tinggal $amount buat $days hari lagi, rem dikit ya';
  }

  @override
  String statsLeft(String amount, int days) {
    return 'masih ada $amount buat $days hari lagi';
  }

  @override
  String statsYearLeft(String amount, String year) {
    return 'sisa $amount buat sisa $year';
  }

  @override
  String statsPastLeft(String amount, String scope) {
    return 'sisa $amount dari budget $scope';
  }

  @override
  String get statsUsed => 'duit kepake';

  @override
  String get statsTime => 'waktu jalan';

  @override
  String get statsNoBudget => 'pasang budget biar ketauan kamu on track nggak';

  @override
  String get statsSetBudget => 'pasang budget';

  @override
  String get statsWhere => 'larinya ke mana';

  @override
  String statsTop(int n) {
    return 'top $n';
  }

  @override
  String statsMoreOne(String name, int pct) {
    return '+ $name $pct%';
  }

  @override
  String statsMoreN(int n) {
    return '+ $n lainnya';
  }

  @override
  String get iconSheetTitle => 'pilih ikon';

  @override
  String get iconSearchHint => 'cari ikon… kopi, motor, kado';

  @override
  String get iconSearchLabel => 'cari ikon';

  @override
  String iconCount(int n) {
    return '$n ikon';
  }

  @override
  String iconEmpty(String q) {
    return 'belum ada ikon “$q”';
  }

  @override
  String get iconEmptyTry => 'coba kata lain, misalnya';

  @override
  String iconGroup(String group) {
    String _temp0 = intl.Intl.selectLogic(group, {
      'makan': 'makan',
      'jalan': 'jalan',
      'rumah': 'rumah',
      'belanja': 'belanja',
      'hiburan': 'hiburan',
      'hewan': 'hewan',
      'duit': 'duit',
      'sehat': 'sehat',
      'sekolah': 'sekolah',
      'kerja': 'kerja',
      'sosial': 'sosial',
      'other': 'semua',
    });
    return '$_temp0';
  }

  @override
  String get searchTry => 'coba cari';

  @override
  String get searchAllMonths => 'di semua bulan';

  @override
  String searchSubKind(String kind, String month) {
    return 'di $kind $month';
  }

  @override
  String searchNotFound(String q) {
    return '“$q” nggak ketemu';
  }

  @override
  String get searchFixPre => 'maksud kamu “';

  @override
  String get searchFixPost => '”?';

  @override
  String get searchWayPre => 'ada ';

  @override
  String searchWayIn(int n, String where) {
    return '$n di $where';
  }

  @override
  String get searchOtherMonths => 'bulan lain';

  @override
  String searchAllCount(int n) {
    return '$n hasil di semua bulan';
  }

  @override
  String searchBackTo(String month) {
    return 'balik ke $month';
  }

  @override
  String get searchRecent => 'terakhir dicari';

  @override
  String get searchRecentClear => 'hapus semua';

  @override
  String searchRecentDel(String q) {
    return 'hapus $q dari riwayat';
  }

  @override
  String get searchTryHint => 'paling sering bulan ini';

  @override
  String get searchEmptyTitle => 'belum ada yang bisa dicari';

  @override
  String get searchEmptySub =>
      'catat dulu yuk, nanti semua bisa dicari di sini';

  @override
  String get searchAllDays => 'semua hari';

  @override
  String get searchTickDrag => 'geser buat ganti hari';

  @override
  String get searchTicksLabel => 'hasil per tanggal, geser buat liat per hari';

  @override
  String searchMoreDay(int n) {
    return 'liat $n lagi di hari ini';
  }

  @override
  String get searchBadgeMixed => 'campur';

  @override
  String get searchBadgeDaily => 'hampir tiap hari';

  @override
  String get searchBadgeBusiest => 'paling sering';

  @override
  String get searchBadgeBiggest => 'paling gede';

  @override
  String searchInsExpense(String amount) {
    return 'pengeluaran $amount';
  }

  @override
  String searchInsIncome(String amount) {
    return 'pemasukan $amount';
  }

  @override
  String searchInsDays(int days, int today) {
    return '$days dari $today hari';
  }

  @override
  String searchInsStreak(int n) {
    return 'beruntun $n hari';
  }

  @override
  String searchInsTimes(int n) {
    return '$n×';
  }

  @override
  String get searchInsOnly => 'satu-satunya bulan ini';

  @override
  String get searchTickHeight => 'tinggi = nominal';

  @override
  String get searchTickWidth => 'tebal = jumlah';

  @override
  String get searchTickWhen => 'kapan kejadiannya';
}
