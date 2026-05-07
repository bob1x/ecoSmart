import 'package:flutter/material.dart';

/// EcoSmart Classifier — Dark-only color palette
/// Inspired by premium fintech dashboards applied to environmental science.
abstract class AppColors {
  AppColors._();

  // ── Scaffold & Surfaces ──────────────────────────────────────
  static const scaffold      = Color(0xFF0B1610);  // near-black with green tint
  static const surface       = Color(0xFF111E18);  // card / container bg
  static const surfaceLight  = Color(0xFF162A1F);  // slightly elevated surface
  static const border        = Color(0x1A22C55E);  // 10% ecoGreen border
  static const borderSubtle  = Color(0x0DFFFFFF);  // 5% white

  // ── Primary eco palette ──────────────────────────────────────
  static const ecoGreen      = Color(0xFF22C55E);
  static const ecoGreenDark  = Color(0xFF16A34A);
  static const ecoGreenLight = Color(0xFF1A3D2A);  // dark green tint for fills
  static const forestDark    = Color(0xFF0A3D2E);
  static const forestMid     = Color(0xFF0F6E56);

  // ── AI / NLP palette ─────────────────────────────────────────
  static const aiPurple      = Color(0xFF7C3AED);
  static const aiPurpleDark  = Color(0xFF1E1B4B);
  static const aiPurpleLight = Color(0xFF2D2450);

  // ── MLOps palette ────────────────────────────────────────────
  static const mlopsBlue     = Color(0xFF0EA5E9);
  static const mlopsGold     = Color(0xFFF59E0B);
  static const errorRed      = Color(0xFFEF4444);
  static const orange        = Color(0xFFF97316);

  // ── Status badges ────────────────────────────────────────────
  static const champion      = Color(0xFF22C55E);
  static const staging       = Color(0xFFF59E0B);
  static const archived      = Color(0xFF6B7280);
  static const production    = Color(0xFF22C55E);

  // ── Ink (text hierarchy) ─────────────────────────────────────
  static const inkPrimary    = Color(0xFFE8F5EE);  // bright white-green
  static const inkSecondary  = Color(0xFF9EBBA8);  // muted green-gray
  static const inkTertiary   = Color(0xFF5E7D6A);  // dark muted
  static const inkMuted      = Color(0xFF3D5A48);  // very muted

  // ── Pure whites (for special emphasis) ───────────────────────
  static const white         = Color(0xFFFFFFFF);
  static const white80       = Color(0xCCFFFFFF);
  static const white50       = Color(0x80FFFFFF);
  static const white10       = Color(0x1AFFFFFF);

  // ── Category semantic colors ─────────────────────────────────
  static const catPlastic    = Color(0xFF22C55E);
  static const catMetal      = Color(0xFF7C3AED);
  static const catGlass      = Color(0xFF0EA5E9);
  static const catCardboard  = Color(0xFFF59E0B);
  static const catOrganic    = Color(0xFF84CC16);
  static const catElectronic = Color(0xFFEF4444);

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
