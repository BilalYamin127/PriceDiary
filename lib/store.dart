import "package:flutter/foundation.dart";
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'domain.dart';
import 'backup.dart';

final storeProvider = ChangeNotifierProvider<DiaryStore>(
  (ref) => throw UnimplementedError('Override with the opened database'),
);

class DiaryStore extends ChangeNotifier {
  final Box<String> box;
  bool _saving = false;
  List<Product> products = [];
  List<Shop> shops = [];
  List<PriceRecord> records = [];
  String currency = 'USD', theme = 'system';
  DiaryStore(this.box) {
    final raw = box.get('diary');
    if (raw != null) {
      final j = decodeMap(raw);
      products = (j['products'] as List)
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      shops = (j['shops'] as List)
          .map((e) => Shop.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      records = (j['records'] as List)
          .map((e) => PriceRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      currency = j['currency'] ?? 'USD';
      theme = j['theme'] ?? 'system';
    }
  }
  Future<void> _save(
    List<Product> p,
    List<Shop> s,
    List<PriceRecord> r,
    String c,
    String t,
  ) async {
    if (_saving) {
      throw StateError("A save is in progress. Please try again in a moment.");
    }
    _saving = true;
    try {
      await box.put(
        'diary',
        jsonEncode({
          'version': 1,
          'products': p.map((e) => e.toJson()).toList(),
          'shops': s.map((e) => e.toJson()).toList(),
          'records': r.map((e) => e.toJson()).toList(),
          'currency': c,
          'theme': t,
        }),
      );
      products = p;
      shops = s;
      records = r;
      currency = c;
      theme = t;
      notifyListeners();
    } finally {
      _saving = false;
    }
  }

  Future<void> saveProduct(Product p) {
    if (p.name.trim().isEmpty ||
        !p.unitQuantity.isFinite ||
        p.unitQuantity <= 0) {
      throw ArgumentError('Enter a name and a positive quantity.');
    }
    final old = products.where((e) => e.id == p.id).firstOrNull;
    if (old != null &&
        records.any((r) => r.productId == p.id) &&
        (old.unitType != p.unitType || old.unitQuantity != p.unitQuantity)) {
      throw ArgumentError(
        'A product with observations must keep its package size. Create a separate product for another size.',
      );
    }
    return _save(
      [...products.where((e) => e.id != p.id), p],
      shops,
      records,
      currency,
      theme,
    );
  }

  Future<void> saveShop(Shop s) {
    if (s.name.trim().isEmpty) throw ArgumentError('Enter a shop name.');
    if (shops.any(
      (e) => e.id != s.id && canonicalShop(e.name) == canonicalShop(s.name),
    )) {
      throw ArgumentError('A shop with this name already exists.');
    }
    return _save(
      products,
      [...shops.where((e) => e.id != s.id), s],
      records,
      currency,
      theme,
    );
  }

  Future<void> saveRecord(PriceRecord r) {
    if (!r.price.isFinite || r.price < 0) {
      throw ArgumentError('Price must be a finite, nonnegative number.');
    }
    if (!products.any((p) => p.id == r.productId) ||
        !shops.any((s) => s.id == r.shopId)) {
      throw ArgumentError('Select an existing product and shop.');
    }
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(r.currencyCode)) {
      throw ArgumentError('Use a three-letter currency code.');
    }
    return _save(
      products,
      shops,
      [...records.where((e) => e.id != r.id), r],
      currency,
      theme,
    );
  }

  Future<void> deleteProduct(String id) {
    if (records.any((r) => r.productId == id)) {
      throw ArgumentError('Delete this product’s price records first.');
    }
    return _save(
      products.where((e) => e.id != id).toList(),
      shops,
      records,
      currency,
      theme,
    );
  }

  Future<void> deleteShop(String id) {
    if (records.any((r) => r.shopId == id)) {
      throw ArgumentError(
        'This shop has linked price records. Delete those records first.',
      );
    }
    return _save(
      products,
      shops.where((e) => e.id != id).toList(),
      records,
      currency,
      theme,
    );
  }

  Future<void> deleteRecord(String id) => _save(
    products,
    shops,
    records.where((r) => r.id != id).toList(),
    currency,
    theme,
  );
  Future<void> settings(String c, String t) {
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(c) ||
        !['system', 'light', 'dark'].contains(t)) {
      throw ArgumentError('Select a valid currency code and theme.');
    }
    return _save(products, shops, records, c, t);
  }

  DiaryBackup get backup => DiaryBackup(
    products: products,
    shops: shops,
    records: records,
    currency: currency,
    theme: theme,
  );
  Future<void> restore(DiaryBackup data) {
    // Revalidate at the persistence boundary, including programmatic callers.
    final checked = DiaryBackup.parse(data.encode());
    return _save(
      checked.products,
      checked.shops,
      checked.records,
      checked.currency,
      checked.theme,
    );
  }

  Future<void> clear() => _save([], [], [], currency, theme);
  Product product(String id) => products.firstWhere((p) => p.id == id);
  String shopName(String id) => shops.firstWhere((s) => s.id == id).name;
  DateTime updated(Product p) {
    final rs = records.where((r) => r.productId == p.id).toList()
      ..sort(chronological);
    return rs.isEmpty ? p.createdAt : rs.last.recordedAt;
  }
}
