import 'dart:convert';
import 'domain.dart';

/// Validated, versioned backup. Parsing never mutates the active diary.
class DiaryBackup {
  final List<Product> products;
  final List<Shop> shops;
  final List<PriceRecord> records;
  final String currency, theme;
  const DiaryBackup({
    required this.products,
    required this.shops,
    required this.records,
    required this.currency,
    required this.theme,
  });
  Map<String, dynamic> toJson() => {
    'format': 'PriceDiary',
    'version': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'products': products.map((p) => p.toJson()).toList(),
    'shops': shops.map((s) => s.toJson()).toList(),
    'records': records.map((r) => r.toJson()).toList(),
    'currency': currency,
    'theme': theme,
  };
  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());
  factory DiaryBackup.parse(String source) {
    try {
      final j = decodeMap(source);
      if (j['format'] != 'PriceDiary' || j['version'] != 1) {
        throw const FormatException('Unsupported backup format or version.');
      }
      final p = (j['products'] as List)
          .map((v) => Product.fromJson(Map<String, dynamic>.from(v)))
          .toList();
      final s = (j['shops'] as List)
          .map((v) => Shop.fromJson(Map<String, dynamic>.from(v)))
          .toList();
      final r = (j['records'] as List)
          .map((v) => PriceRecord.fromJson(Map<String, dynamic>.from(v)))
          .toList();
      void unique(Iterable<String> ids) {
        final list = ids.toList();
        if (list.any((id) => id.trim().isEmpty) ||
            list.toSet().length != list.length) {
          throw const FormatException('Empty or duplicate IDs.');
        }
      }

      unique(p.map((e) => e.id));
      unique(s.map((e) => e.id));
      unique(r.map((e) => e.id));
      if (p.any(
        (e) =>
            e.name.trim().isEmpty ||
            !e.unitQuantity.isFinite ||
            e.unitQuantity <= 0 ||
            !['kg', 'g', 'L', 'ml', 'piece'].contains(e.unitType) ||
            !categories.any((c) => c.id == e.categoryId),
      )) {
        throw const FormatException('Invalid product.');
      }
      if (s.any((e) => e.name.trim().isEmpty) ||
          s.map((e) => canonicalShop(e.name)).toSet().length != s.length) {
        throw const FormatException('Empty or duplicate shop names.');
      }
      final productIds = p.map((e) => e.id).toSet(),
          shopIds = s.map((e) => e.id).toSet();
      bool validCurrency(String c) => RegExp(r'^[A-Z]{3}$').hasMatch(c);
      if (r.any(
        (e) =>
            !productIds.contains(e.productId) ||
            !shopIds.contains(e.shopId) ||
            !e.price.isFinite ||
            e.price < 0 ||
            !validCurrency(e.currencyCode) ||
            e.recordedAt.isBefore(DateTime(1900)) ||
            e.recordedAt.isAfter(DateTime.now()),
      )) {
        throw const FormatException('Invalid or unlinked price record.');
      }
      final currency = j['currency'] as String, theme = j['theme'] as String;
      if (!validCurrency(currency) ||
          !['system', 'light', 'dark'].contains(theme)) {
        throw const FormatException('Invalid settings.');
      }
      return DiaryBackup(
        products: p,
        shops: s,
        records: r,
        currency: currency,
        theme: theme,
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
        'This file is not a valid PriceDiary backup.',
      );
    }
  }
}
