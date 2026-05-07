import 'package:google_fonts/google_fonts.dart';

/// Central font family constants sourced from the google_fonts package.
/// These resolve to the correct package-prefixed font family strings
/// so Flutter can find the fonts (downloaded at runtime from Google CDN).
///
/// Usage in TextStyle:
///   TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 16)
///   TextStyle(fontFamily: AppFonts.inter, fontSize: 12)
abstract class AppFonts {
  AppFonts._();

  static final String spaceGrotesk = GoogleFonts.spaceGrotesk().fontFamily!;
  static final String inter = GoogleFonts.inter().fontFamily!;
}
