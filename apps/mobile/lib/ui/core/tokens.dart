// Tokens from design board 00.1 · fondasi. Only use these — no new colors/sizes.
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

abstract final class AppColors {
  static const ink = Color(0xFF111111); // teks, isian, kepilih
  static const grey700 = Color(0xFF555555); // porsi kategori ke-2
  static const muted = Color(0xFF666666); // teks sekunder
  static const subtle = Color(0xFF737373); // label nonaktif
  static const grey400 = Color(0xFF9A9A9A); // bar di bawah budget, prediksi
  static const onInkMuted = Color(0xFFBDBDBD); // caption di atas ink aja
  static const line = Color(0xFFCFCFCF); // garis tipis, handle, garis putus
  static const pressed = Color(0xFFDCDCDC); // tombol ditekan
  static const divider = Color(0xFFE3E3E3); // baris di kartu, tepi tab bar
  static const track = Color(0xFFEBEBEB); // track progres
  static const mist = Color(0xFFF2F2F2); // tombol keypad, kartu, input
  static const paper = Color(0xFFFFFFFF); // semua screen
  static const scrim = Color(0x73111111); // ink 45%

  // Putih di atas ink.
  static const onInk = paper; // bar sekarang, pill nilai
  static const onInk72 = Color(0xB8FFFFFF); // bar kepilih
  static const onInk45 = Color(0x73FFFFFF); // garis rata-rata
  static const onInk42 = Color(0x6BFFFFFF); // bar sebelumnya
  static const onInk12 = Color(0x1FFFFFFF); // chip di atas ink
  static const onInk8 = Color(0x14FFFFFF); // track bar
}

abstract final class AppSpace {
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s48 = 48.0;
  static const s64 = 64.0;

  static const gutter = s24; // tepi screen
  static const cardInset = s16; // kartu dari tepi
  static const section = s32; // antar section
  static const contentTop = 56.0; // atas konten (56–64)
  static const row = 48.0; // baris list
  static const settingsRow = 60.0;
  static const minTouch = 44.0;
  static const tabBarClearance = 100.0; // padding bawah list di bawah TabBar
}

abstract final class AppRadius {
  static const tile = 16.0;
  static const statTile = 20.0;
  static const groupCard = 24.0;
  static const inkCard = 28.0;
  static const sheet = 32.0;
  static const pill = 999.0;
}

abstract final class AppStroke {
  static const hairline = 1.0; // garis tipis
  static const outline = 1.5; // outline, pill, garis bawah
  static const chart = 3.0; // grafik
  static const icon = 1.5; // hugeicons
  static const iconOnInkSmall = 2.0; // ikon di tombol ink kecil
}

abstract final class AppShadows {
  // flat = no shadow.
  // float: tab bar capsule. Pair with Border.all(color: AppColors.divider).
  static const float = [
    BoxShadow(color: Color(0x1F111111), offset: Offset(0, 10), blurRadius: 30),
  ];
  // lift: tombol +.
  static const lift = [
    BoxShadow(color: Color(0x40111111), offset: Offset(0, 10), blurRadius: 24),
  ];
  // paper: struk, pill nilai.
  static const paper = [
    BoxShadow(color: Color(0x14111111), offset: Offset(0, 12), blurRadius: 24),
  ];
}

abstract final class AppMotion {
  static const select = Duration(milliseconds: 200); // pill/bar pindah
  static const fill = Duration(milliseconds: 300); // isi toples
  static const sheet = Duration(milliseconds: 280); // sheet naik
  static const cursorBlink = Duration(seconds: 1);
  static const hold = Duration(seconds: 1); // tahan buat hapus, linear
  static const ease = Curves.easeOut;
}

abstract final class AppText {
  static const family = 'Instrument Sans';
  static const _tnum = [FontFeature.tabularFigures()];

  // letterSpacing = fontSize × design %.
  static const displayXl = TextStyle(
    fontFamily: family,
    fontSize: 68,
    fontWeight: FontWeight.w500,
    letterSpacing: -2.72,
    fontFeatures: _tnum,
  );
  static const displayL = TextStyle(
    fontFamily: family,
    fontSize: 64,
    fontWeight: FontWeight.w500,
    letterSpacing: -2.56,
    fontFeatures: _tnum,
  );
  static const display = TextStyle(
    fontFamily: family,
    fontSize: 56,
    fontWeight: FontWeight.w500,
    letterSpacing: -2.24,
    fontFeatures: _tnum,
  );
  static const displayS = TextStyle(
    fontFamily: family,
    fontSize: 48,
    fontWeight: FontWeight.w500,
    letterSpacing: -1.92,
    fontFeatures: _tnum,
  );
  static const inputXl = TextStyle(
    fontFamily: family,
    fontSize: 40,
    fontWeight: FontWeight.w500,
    letterSpacing: -1.2,
    fontFeatures: _tnum,
  );
  static const title = TextStyle(
    fontFamily: family,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.56,
  );
  static const sheetTitle = TextStyle(
    fontFamily: family,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.52,
  );
  static const headline = TextStyle(
    fontFamily: family,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.48,
    fontFeatures: _tnum,
  );
  static const body = TextStyle(
    fontFamily: family,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    fontFeatures: _tnum,
  );
  static const label = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFeatures: _tnum,
  );
  static const caption = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    fontFeatures: _tnum,
  );
  static const micro = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    fontFeatures: _tnum,
  );

  // wordmark "mibu" — onboarding, beranda, pengaturan. Archivo 900 / -6%.
  static TextStyle wordmark(double size) => TextStyle(
    fontFamily: 'Archivo',
    fontSize: size,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.06 * size,
    height: 0.82,
  );
}

/// Icons the design draws itself (hugeicons format, use with HugeIcon).
abstract final class AppIcons {
  static const _stroke = {
    'stroke': 'currentColor',
    'strokeWidth': '1.5',
    'strokeLinecap': 'round',
    'strokeLinejoin': 'round',
  };

  /// Keypad backspace (03.1).
  static const backspace = [
    [
      'path',
      {
        'key': '0',
        'd': 'M9.5 5H18a3 3 0 0 1 3 3v8a3 3 0 0 1-3 3H9.5a2 2 0 0 1-1.5-.68L3.6 13.3a2 2 0 0 1 0-2.6L8 5.68A2 2 0 0 1 9.5 5z',
        ..._stroke,
      },
    ],
    [
      'path',
      {'key': '1', 'd': 'M12.5 9.5l5 5M17.5 9.5l-5 5', ..._stroke},
    ],
  ];
}
