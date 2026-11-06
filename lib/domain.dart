import 'dart:convert';

class Product {
  final String id, name, categoryId, unitType;
  final String? brand, notes;
  final double unitQuantity;
  final DateTime createdAt;
  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.unitType,
    required this.unitQuantity,
    required this.createdAt,
    this.brand,
    this.notes,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'categoryId': categoryId,
    'unitType': unitType,
    'unitQuantity': unitQuantity,
    'createdAt': createdAt.toIso8601String(),
    'brand': brand,
    'notes': notes,
  };
  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'],
    name: j['name'],
    categoryId: j['categoryId'],
    unitType: j['unitType'],
    unitQuantity: (j['unitQuantity'] as num).toDouble(),
    createdAt: DateTime.parse(j['createdAt']),
    brand: j['brand'],
    notes: j['notes'],
  );
}

class Shop {
  final String id, name;
  final String? notes;
  final DateTime createdAt;
  const Shop({
    required this.id,
    required this.name,
    required this.createdAt,
    this.notes,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'notes': notes,
  };
  factory Shop.fromJson(Map<String, dynamic> j) => Shop(
    id: j['id'],
    name: j['name'],
    createdAt: DateTime.parse(j['createdAt']),
    notes: j['notes'],
  );
}

class PriceRecord {
  final String id, productId, shopId, currencyCode;
  final double price;
  final DateTime recordedAt, createdAt;
  final String? notes;
  const PriceRecord({
    required this.id,
    required this.productId,
    required this.shopId,
    required this.currencyCode,
    required this.price,
    required this.recordedAt,
    required this.createdAt,
    this.notes,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'shopId': shopId,
    'currencyCode': currencyCode,
    'price': price,
    'recordedAt': recordedAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'notes': notes,
  };
  factory PriceRecord.fromJson(Map<String, dynamic> j) => PriceRecord(
    id: j['id'],
    productId: j['productId'],
    shopId: j['shopId'],
    currencyCode: j['currencyCode'],
    price: (j['price'] as num).toDouble(),
    recordedAt: DateTime.parse(j['recordedAt']),
    createdAt: DateTime.parse(j['createdAt']),
    notes: j['notes'],
  );
}

class Category {
  final String id, name;
  final int color;
  const Category(this.id, this.name, this.color);
}

const categories = [
  Category('groceries', 'Groceries', 0xff00897b),
  Category('household', 'Household', 0xffef6c00),
  Category('electronics', 'Electronics', 0xff5c6bc0),
  Category('other', 'Other', 0xff78909c),
];
String canonicalShop(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
int chronological(PriceRecord a, PriceRecord b) {
  final date = a.recordedAt.compareTo(b.recordedAt);
  if (date != 0) return date;
  final created = a.createdAt.compareTo(b.createdAt);
  return created != 0 ? created : a.id.compareTo(b.id);
}

List<PriceRecord> latestByShop(
  Iterable<PriceRecord> records,
  String productId,
  String currency,
) {
  final result = <String, PriceRecord>{};
  for (final r in records.where(
    (r) => r.productId == productId && r.currencyCode == currency,
  )) {
    if (!result.containsKey(r.shopId) ||
        chronological(r, result[r.shopId]!) > 0) {
      result[r.shopId] = r;
    }
  }
  return result.values.toList()..sort((a, b) => a.price.compareTo(b.price));
}

double? percentageChange(double previous, double current) =>
    previous == 0 ? null : (current - previous) / previous * 100;
({String unit, double quantity}) normalizedQuantity(Product p) =>
    switch (p.unitType) {
      'g' => (unit: 'kg', quantity: p.unitQuantity / 1000),
      'ml' => (unit: 'L', quantity: p.unitQuantity / 1000),
      _ => (unit: p.unitType, quantity: p.unitQuantity),
    };
double normalizedPrice(Product p, double price) =>
    price / normalizedQuantity(p).quantity;
String csv(List<List<Object?>> rows) => rows
    .map(
      (r) => r
          .map((v) {
            var text = v?.toString() ?? '';
            if (RegExp(r'^[=+@\-\t\r]').hasMatch(text)) text = "'$text";
            return '"${text.replaceAll('"', '""')}"';
          })
          .join(','),
    )
    .join('\r\n');
Map<String, dynamic> decodeMap(String text) =>
    Map<String, dynamic>.from(jsonDecode(text) as Map);

/// Calendar-day age, independent of daylight-saving hour changes.
int observationAgeDays(DateTime observed, DateTime now) {
  final age = DateTime.utc(now.year, now.month, now.day)
      .difference(DateTime.utc(observed.year, observed.month, observed.day))
      .inDays;
  return age < 0 ? 0 : age;
}
