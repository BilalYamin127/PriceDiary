import 'package:flutter_test/flutter_test.dart';
import 'package:price_diary/domain.dart';

void main() {
  final date = DateTime(2026, 1, 1);
  PriceRecord record(
    String id,
    String shop,
    double price,
    DateTime observed, {
    String currency = 'USD',
    String product = 'p',
    DateTime? created,
  }) => PriceRecord(
    id: id,
    productId: product,
    shopId: shop,
    currencyCode: currency,
    price: price,
    recordedAt: observed,
    createdAt: created ?? observed,
  );
  Product product(double quantity, String unit) => Product(
    id: 'p',
    name: 'Rice',
    categoryId: 'groceries',
    unitType: unit,
    unitQuantity: quantity,
    createdAt: date,
  );
  test('Percentage changes handle increases, decreases and zero safely', () {
    expect(percentageChange(100, 125), 25);
    expect(percentageChange(100, 75), -25);
    expect(percentageChange(100, 0), -100);
    expect(percentageChange(0, 10), isNull);
    expect(percentageChange(0, 0), isNull);
  });
  test('Latest observations use observed dates rather than entry order', () {
    final old = record('old', 's1', 10, date);
    final latest = record(
      'latest',
      's1',
      20,
      date.add(const Duration(days: 2)),
    );
    final backdated = record(
      'backdated',
      's1',
      5,
      date.add(const Duration(days: 1)),
      created: date.add(const Duration(days: 3)),
    );
    final otherShop = record('other', 's2', 15, date);
    expect(
      latestByShop(
        [latest, old, otherShop, backdated],
        'p',
        'USD',
      ).map((r) => r.id),
      ['other', 'latest'],
    );
  });
  test('Currencies and products are never mixed', () {
    final records = [
      record('usd', 's', 10, date),
      record('eur', 's', 1, date, currency: 'EUR'),
      record('other', 's2', 0, date, product: 'other'),
    ];
    expect(latestByShop(records, 'p', 'USD').single.id, 'usd');
    expect(latestByShop(records, 'p', 'EUR').single.id, 'eur');
    expect(latestByShop(records, 'p', 'PKR'), isEmpty);
  });
  test('Same-day observations break ties by creation time', () {
    expect(
      latestByShop(
        [
          record('a', 's', 1, date),
          record(
            'b',
            's',
            2,
            date,
            created: date.add(const Duration(hours: 1)),
          ),
        ],
        'p',
        'USD',
      ).single.id,
      'b',
    );
  });
  test('Mass and volume normalize to compatible base units', () {
    expect(normalizedPrice(product(500, 'g'), 10), 20);
    expect(normalizedPrice(product(2, 'kg'), 40), 20);
    expect(normalizedPrice(product(250, 'ml'), 5), 20);
    expect(normalizedQuantity(product(1, 'L')).unit, 'L');
    expect(normalizedQuantity(product(1, 'kg')).unit, 'kg');
    expect(normalizedQuantity(product(3, 'piece')).unit, 'piece');
  });
  test('Duplicate shop normalization ignores spaces and capitalization', () {
    expect(canonicalShop('  Local   STORE  '), canonicalShop('local store'));
  });
  test('CSV escapes quotes, commas, newlines and spreadsheet formulas', () {
    final text = csv([
      ['a,b', 'He said "hi"', 'line\nbreak', '=SUM(A1)', null],
    ]);
    expect(text, '"a,b","He said ""hi""","line\nbreak","\'=SUM(A1)",""');
  });
  test('Models survive JSON round trips including optional values', () {
    final p = product(1.5, 'kg');
    expect(Product.fromJson(p.toJson()).toJson(), p.toJson());
    final r = record('r', 's', 0, date);
    expect(PriceRecord.fromJson(r.toJson()).toJson(), r.toJson());
    final s = Shop(id: 's', name: 'Shop', createdAt: date);
    expect(Shop.fromJson(s.toJson()).toJson(), s.toJson());
  });
}
