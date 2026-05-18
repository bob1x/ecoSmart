import 'package:flutter/material.dart';

/// EcoSmart Classifier — Green / White / Black palette
/// Modern tri-tone: dark scaffold, lighter card surfaces, green accents.
abstract class AppColors {
  AppColors._();

  // ── Scaffold & Surfaces ──────────────────────────────────────
  static const scaffold      = Color(0xFF0C0C0C);  // near-black background
  static const surface       = Color(0xFF1A1A1A);  // card bg — lifted
  static const surfaceLight  = Color(0xFF242424);  // elevated elements
  static const surfaceWhite  = Color(0xFF2E2E2E);  // light surface for inputs
  static const border        = Color(0xFF333333);  // visible neutral border
  static const borderSubtle  = Color(0xFF222222);

  // ── Primary — Eco Green ──────────────────────────────────────
  static const ecoGreen      = Color(0xFF00D47E);  // vibrant mint
  static const ecoGreenDark  = Color(0xFF00A864);
  static const ecoGreenLight = Color(0xFF0F2D1F);  // dark green fill
  static const forestDark    = Color(0xFF0C1F16);
  static const forestMid     = Color(0xFF0F6E56);

  // ── AI / NLP accent — Violet ─────────────────────────────────
  static const aiPurple      = Color(0xFF8B5CF6);
  static const aiPurpleDark  = Color(0xFF151320);
  static const aiPurpleLight = Color(0xFF1F1B30);

  // ── MLOps / System accents ───────────────────────────────────
  static const mlopsBlue     = Color(0xFF38BDF8);
  static const mlopsGold     = Color(0xFFFBBF24);
  static const errorRed      = Color(0xFFF87171);
  static const orange        = Color(0xFFFB923C);

  // ── Status badges ────────────────────────────────────────────
  static const champion      = Color(0xFF00D47E);
  static const staging       = Color(0xFFFBBF24);
  static const archived      = Color(0xFF6B7280);
  static const production    = Color(0xFF00D47E);

  // ── Ink (text hierarchy) — bright whites ─────────────────────
  static const inkPrimary    = Color(0xFFFFFFFF);  // pure white
  static const inkSecondary  = Color(0xFFB0B0B0);  // light gray
  static const inkTertiary   = Color(0xFF737373);  // mid gray
  static const inkMuted      = Color(0xFF4A4A4A);  // dark gray

  // ── Pure whites ──────────────────────────────────────────────
  static const white         = Color(0xFFFFFFFF);
  static const white80       = Color(0xCCFFFFFF);
  static const white50       = Color(0x80FFFFFF);
  static const white10       = Color(0x1AFFFFFF);

  // ── Category semantic colors ─────────────────────────────────
  static const catPlastic    = Color(0xFF00D47E);
  static const catMetal      = Color(0xFF8B5CF6);
  static const catGlass      = Color(0xFF38BDF8);
  static const catCardboard  = Color(0xFFFBBF24);
  static const catOrganic    = Color(0xFF84CC16);
  static const catElectronic = Color(0xFFF87171);

  // ── Helper: category color lookup ────────────────────────────
  static Color forCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('plast')) return catPlastic;
    if (lower.contains('métal') || lower.contains('metal')) return catMetal;
    if (lower.contains('verre') || lower.contains('glass')) return catGlass;
    if (lower.contains('papier') ||
        lower.contains('carton') ||
        lower.contains('paper')) return catCardboard;
    if (lower.contains('organ')) return catOrganic;
    if (lower.contains('élect') || lower.contains('elect')) return catElectronic;
    return ecoGreen;
  }
}
