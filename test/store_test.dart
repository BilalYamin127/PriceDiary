import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:price_diary/domain.dart';
import 'package:price_diary/backup.dart';
import 'package:price_diary/store.dart';

void main() {
  late Directory directory;
  late Box<String> box;
  late DiaryStore store;
  final now = DateTime(2026, 1, 1);
  Product product({double quantity = 1}) => Product(
    id: 'p',
    name: 'Milk',
    categoryId: 'groceries',
    unitType: 'L',
    unitQuantity: quantity,
    createdAt: now,
  );
  Shop shop(String id, String name) => Shop(id: id, name: name, createdAt: now);
  PriceRecord record(String id, double price, {String productId = 'p'}) =>
      PriceRecord(
        id: id,
        productId: productId,
        shopId: 's',
        currencyCode: 'USD',
        price: price,
        recordedAt: now,
        createdAt: now,
      );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('price_diary_test_');
    Hive.init(directory.path);
    box = await Hive.openBox<String>('diary');
    store = DiaryStore(box);
    await store.saveProduct(product());
    await store.saveShop(shop('s', 'Local Store'));
  });
  tearDown(() async {
    store.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  test('Data and settings survive closing and reopening Hive', () async {
    await store.saveRecord(record('first', 10));
    await store.saveRecord(record('second', 12));
    await store.settings('PKR', 'dark');
    await box.close();
    box = await Hive.openBox<String>('diary');
    final restored = DiaryStore(box);
    expect(restored.products.single.name, 'Milk');
    expect(restored.shops.single.name, 'Local Store');
    expect(restored.records.map((r) => r.price), [10, 12]);
    expect(restored.currency, 'PKR');
    expect(restored.theme, 'dark');
    restored.dispose();
  });
  test(
    'New records preserve history and corrections replace only matching id',
    () async {
      await store.saveRecord(record('one', 10));
      await store.saveRecord(record('two', 20));
      await store.saveRecord(record('one', 11));
      expect(store.records.length, 2);
      expect(store.records.firstWhere((r) => r.id == 'two').price, 20);
      await store.deleteRecord('one');
      expect(store.records.single.id, 'two');
    },
  );
  test('Invalid prices and broken links are rejected', () async {
    for (final price in [-1.0, double.nan, double.infinity]) {
      expect(() => store.saveRecord(record('bad', price)), throwsArgumentError);
    }
    expect(
      () => store.saveRecord(record('bad', 1, productId: 'missing')),
      throwsArgumentError,
    );
    await store.saveRecord(record('zero', 0));
    expect(store.records.single.price, 0);
  });
  test(
    'Duplicate shops and package mutation with history are rejected',
    () async {
      expect(
        () => store.saveShop(shop('duplicate', '  LOCAL   store ')),
        throwsArgumentError,
      );
      await store.saveRecord(record('one', 10));
      expect(
        () => store.saveProduct(product(quantity: 2)),
        throwsArgumentError,
      );
      expect(() => store.deleteShop('s'), throwsArgumentError);
      expect(() => store.deleteProduct('p'), throwsArgumentError);
    },
  );
  test(
    'Unlinked deletion and clearing persist without dangling references',
    () async {
      await store.saveShop(shop('unused', 'Other'));
      await store.deleteShop('unused');
      expect(store.shops.length, 1);
      await store.saveRecord(record('one', 10));
      await store.clear();
      final restored = DiaryStore(box);
      expect(restored.products, isEmpty);
      expect(restored.shops, isEmpty);
      expect(restored.records, isEmpty);
      restored.dispose();
    },
  );
  test('Overlapping saves cannot overwrite each other silently', () async {
    final first = store.saveRecord(record('first', 10));
    await expectLater(store.saveRecord(record('second', 20)), throwsStateError);
    await first;
    await store.saveRecord(record('second', 20));
    expect(store.records.length, 2);
  });
  test('Invalid product quantities and settings are rejected', () {
    for (final quantity in [0.0, -1.0, double.nan, double.infinity]) {
      expect(
        () => store.saveProduct(product(quantity: quantity)),
        throwsArgumentError,
      );
    }
    expect(() => store.settings('US', 'dark'), throwsArgumentError);
    expect(() => store.settings('USD', 'unknown'), throwsArgumentError);
  });
  test(
    'Restored data and settings persist after reopening the database',
    () async {
      await store.saveRecord(record('backup', 42));
      await store.settings('EUR', 'light');
      final exported = store.backup.encode();
      await store.clear();
      await store.restore(DiaryBackup.parse(exported));
      await box.close();
      box = await Hive.openBox<String>('diary');
      final restored = DiaryStore(box);
      expect(restored.records.single.price, 42);
      expect(restored.products.single.id, 'p');
      expect(restored.shops.single.id, 's');
      expect(restored.currency, 'EUR');
      expect(restored.theme, 'light');
      restored.dispose();
    },
  );
  test('Invalid restoration leaves current diary intact', () async {
    await store.saveRecord(record('existing', 7));
    final invalid = DiaryBackup(
      products: [],
      shops: [],
      records: [record('broken', 10)],
      currency: 'USD',
      theme: 'dark',
    );
    expect(() => store.restore(invalid), throwsFormatException);
    expect(store.records.single.id, 'existing');
    expect(DiaryStore(box).records.single.price, 7);
  });
}
