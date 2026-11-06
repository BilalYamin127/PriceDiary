import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:price_diary/backup.dart';
import 'package:price_diary/domain.dart';

void main() {
  final date = DateTime(2026, 1, 1);
  DiaryBackup backup() => DiaryBackup(
    products: [
      Product(
        id: 'p',
        name: 'Milk',
        categoryId: 'groceries',
        unitType: 'L',
        unitQuantity: 1,
        createdAt: date,
      ),
    ],
    shops: [Shop(id: 's', name: 'Local Store', createdAt: date)],
    records: [
      PriceRecord(
        id: 'r',
        productId: 'p',
        shopId: 's',
        price: 0,
        currencyCode: 'USD',
        recordedAt: date,
        createdAt: date,
      ),
    ],
    currency: 'PKR',
    theme: 'dark',
  );
  test('Backup round trip retains all models, relationships and settings', () {
    final restored = DiaryBackup.parse(backup().encode());
    expect(
      restored.products.single.toJson(),
      backup().products.single.toJson(),
    );
    expect(restored.shops.single.toJson(), backup().shops.single.toJson());
    expect(restored.records.single.toJson(), backup().records.single.toJson());
    expect(restored.currency, 'PKR');
    expect(restored.theme, 'dark');
  });
  test('Malformed files and future backup versions are rejected', () {
    for (final text in [
      'no JSON',
      '[]',
      '{}',
      jsonEncode({...backup().toJson(), 'version': 2}),
    ]) {
      expect(() => DiaryBackup.parse(text), throwsFormatException);
    }
  });
  test('Duplicate IDs and duplicate normalized shop names are rejected', () {
    final j = backup().toJson();
    (j['products'] as List).add(backup().products.single.toJson());
    expect(() => DiaryBackup.parse(jsonEncode(j)), throwsFormatException);
    final shops = backup().toJson();
    (shops['shops'] as List).add({
      ...backup().shops.single.toJson(),
      'id': 'different',
      'name': ' LOCAL   STORE ',
    });
    expect(() => DiaryBackup.parse(jsonEncode(shops)), throwsFormatException);
  });
  test(
    'Broken relationships, prices, currencies and future dates are rejected',
    () {
      for (final change in [
        {'productId': 'missing'},
        {'shopId': 'missing'},
        {'price': -1},
        {'currencyCode': 'usd'},
        {
          'recordedAt': DateTime.now()
              .add(const Duration(days: 3))
              .toIso8601String(),
        },
      ]) {
        final j = backup().toJson();
        (j['records'] as List)[0] = {
          ...backup().records.single.toJson(),
          ...change,
        };
        expect(() => DiaryBackup.parse(jsonEncode(j)), throwsFormatException);
      }
    },
  );
  test('Unsupported units, categories and settings are rejected', () {
    for (final change in [
      {'unitType': 'unknown'},
      {'categoryId': 'missing'},
      {'unitQuantity': 0},
    ]) {
      final j = backup().toJson();
      (j['products'] as List)[0] = {
        ...backup().products.single.toJson(),
        ...change,
      };
      expect(() => DiaryBackup.parse(jsonEncode(j)), throwsFormatException);
    }
    expect(
      () => DiaryBackup.parse(
        jsonEncode({...backup().toJson(), 'theme': 'invalid'}),
      ),
      throwsFormatException,
    );
  });
  test('Observation age uses calendar days and clamps future dates', () {
    expect(
      observationAgeDays(DateTime(2026, 1, 1, 23, 59), DateTime(2026, 1, 2)),
      1,
    );
    expect(observationAgeDays(DateTime(2026, 1, 1), DateTime(2026, 1, 31)), 30);
    expect(observationAgeDays(DateTime(2026, 2, 1), DateTime(2026, 1, 1)), 0);
  });
}
