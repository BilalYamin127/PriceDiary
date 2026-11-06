import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'domain.dart';
import 'store.dart';
import 'forms.dart';

String money(double value, String currency) =>
    '$currency ${NumberFormat('#,##0.00').format(value)}';
String day(DateTime value) => DateFormat.yMMMd().format(value);
Widget heading(String title, String subtitle, [Widget? action]) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 16),
  child: Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(subtitle),
          ],
        ),
      ),
      ?action,
    ],
  ),
);
Widget empty(String title, String hint) => Padding(
  padding: const EdgeInsets.all(32),
  child: Column(
    children: [
      const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.teal),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(fontSize: 20)),
      Text(hint, textAlign: TextAlign.center),
    ],
  ),
);
Widget productCard(BuildContext context, DiaryStore s, Product p) {
  final prices = latestByShop(s.records, p.id, s.currency);
  return Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(
        backgroundColor: Color(
          categories.firstWhere((c) => c.id == p.categoryId).color,
        ).withValues(alpha: .15),
        child: const Icon(Icons.shopping_basket_outlined),
      ),
      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${p.brand?.isNotEmpty == true ? '${p.brand} · ' : ''}${p.unitQuantity} ${p.unitType}\n${prices.isEmpty ? 'No ${s.currency} observations' : 'Lowest latest observation: ${money(prices.first.price, s.currency)} · ${day(prices.first.recordedAt)}'}',
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/product/${p.id}'),
    ),
  );
}

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(storeProvider);
    final recent = [...s.products]
      ..sort((a, b) => s.updated(b).compareTo(s.updated(a)));
    final changes =
        <({Product product, PriceRecord old, PriceRecord current})>[];
    for (final p in s.products) {
      final groups = <String, List<PriceRecord>>{};
      for (final r in s.records.where((r) => r.productId == p.id)) {
        groups.putIfAbsent('${r.shopId}/${r.currencyCode}', () => []).add(r);
      }
      for (final group in groups.values) {
        group.sort(chronological);
        if (group.length > 1 &&
            group.last.price != group[group.length - 2].price) {
          changes.add((
            product: p,
            old: group[group.length - 2],
            current: group.last,
          ));
        }
      }
    }
    changes.sort((a, b) => chronological(b.current, a.current));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        heading(
          'PriceDiary',
          'Your personal memory for everyday prices',
          IconButton(
            onPressed: () => recordForm(context, s),
            icon: const Icon(Icons.add_circle, color: Colors.teal, size: 36),
            tooltip: 'Add price',
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              [
                    ('Products', s.products.length, Icons.inventory_2_outlined),
                    ('Shops', s.shops.length, Icons.storefront_outlined),
                    (
                      'Observations',
                      s.records.length,
                      Icons.receipt_long_outlined,
                    ),
                  ]
                  .map(
                    (v) => SizedBox(
                      width: 205,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(v.$3, color: Colors.teal),
                              Text(
                                '${v.$2}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(v.$1),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => recordForm(context, s),
          icon: const Icon(Icons.add),
          label: const Text('Record a price'),
        ),
        heading('Recently updated', 'Latest observations across your diary'),
        if (recent.isEmpty)
          empty(
            'Start your price diary',
            'Add a product and a shop, then save your first observed price.',
          ),
        ...recent.take(5).map((p) => productCard(context, s, p)),
        heading(
          'Price changes',
          'Compared with the previous observation at the same shop and currency',
        ),
        if (changes.isEmpty)
          const Text('No changes yet. Keep recording prices to see trends.'),
        ...changes.take(6).map((c) {
          final delta = c.current.price - c.old.price;
          final pct = percentageChange(c.old.price, c.current.price);
          return Card(
            child: ListTile(
              onTap: () => context.push('/product/${c.product.id}'),
              leading: Icon(
                delta > 0 ? Icons.trending_up : Icons.trending_down,
                color: delta > 0 ? Colors.orange : Colors.teal,
              ),
              title: Text(c.product.name),
              subtitle: Text(
                '${s.shopName(c.current.shopId)} · ${day(c.current.recordedAt)}',
              ),
              trailing: Text(
                '${delta > 0 ? '+' : ''}${money(delta, c.current.currencyCode)}\n${pct == null ? 'from zero' : '${pct.toStringAsFixed(1)}%'}',
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        const Text(
          'Recorded prices are observations, not guaranteed current offers.',
        ),
      ],
    );
  }
}

class ProductsScreen extends ConsumerStatefulWidget {
  final String? initialShop;
  const ProductsScreen({super.key, this.initialShop});
  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String query = '', category = '', sort = 'name';
  late String shop = widget.initialShop ?? '';
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(storeProvider);
    if (!s.shops.any((e) => e.id == shop)) shop = '';
    final list = s.products
        .where(
          (p) =>
              '${p.name} ${p.brand ?? ''}'.toLowerCase().contains(
                query.toLowerCase(),
              ) &&
              (category.isEmpty || p.categoryId == category) &&
              (shop.isEmpty ||
                  s.records.any(
                    (r) => r.productId == p.id && r.shopId == shop,
                  )),
        )
        .toList();
    double price(Product p) {
      final rs = latestByShop(
        s.records.where((r) => shop.isEmpty || r.shopId == shop),
        p.id,
        s.currency,
      );
      return rs.isEmpty ? double.infinity : rs.first.price;
    }

    list.sort(
      (a, b) => sort == 'recent'
          ? s.updated(b).compareTo(s.updated(a))
          : sort == 'price'
          ? price(a).compareTo(price(b))
          : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        heading(
          'Products',
          'Track the exact product and package size',
          IconButton(
            onPressed: () => productForm(context, s),
            icon: const Icon(Icons.add),
            tooltip: 'Add product',
          ),
        ),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search name or brand',
          ),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            filter('Category', category, {
              '': 'All categories',
              for (final c in categories) c.id: c.name,
            }, (v) => setState(() => category = v)),
            filter('Shop', shop, {
              '': 'All shops',
              for (final sh in s.shops) sh.id: sh.name,
            }, (v) => setState(() => shop = v)),
            filter('Sort', sort, {
              'name': 'Name',
              'recent': 'Recently updated',
              'price': 'Lowest observed (${s.currency})',
            }, (v) => setState(() => sort = v)),
          ],
        ),
        if (list.isEmpty)
          empty(
            'No products found',
            'Add a product or adjust your search filters.',
          ),
        ...list.map((p) => productCard(context, s, p)),
      ],
    );
  }
}

Widget filter(
  String label,
  String value,
  Map<String, String> values,
  ValueChanged<String> changed,
) => SizedBox(
  width: 240,
  child: DropdownButtonFormField<String>(
    key: ValueKey('$label/$value/${values.length}'),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: values.entries
        .map(
          (e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: (v) => changed(v!),
  ),
);

class ShopsScreen extends ConsumerWidget {
  const ShopsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(storeProvider);
    final shops = [...s.shops]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        heading(
          'Shops',
          'Remember where you found each price',
          IconButton(
            onPressed: () => shopForm(context, s),
            icon: const Icon(Icons.add),
            tooltip: 'Add shop',
          ),
        ),
        if (shops.isEmpty)
          empty(
            'Add your first shop',
            'Shop names are checked for duplicates, ignoring case and extra spaces.',
          ),
        ...shops.map((sh) {
          final rs = s.records.where((r) => r.shopId == sh.id).toList();
          return Card(
            child: ListTile(
              leading: const Icon(Icons.storefront),
              title: Text(sh.name),
              subtitle: Text(
                '${rs.map((r) => r.productId).toSet().length} products · ${rs.length} observations${sh.notes?.isNotEmpty == true ? '\n${sh.notes}' : ''}',
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(sh.name)),
                    body: ProductsScreen(initialShop: sh.id),
                  ),
                ),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') {
                    await shopForm(context, s, sh);
                  } else if (await confirm(
                    context,
                    'Delete ${sh.name}? Shops with linked observations cannot be deleted.',
                  )) {
                    if (context.mounted) {
                      await attempt(context, () => s.deleteShop(sh.id));
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class ProductScreen extends ConsumerStatefulWidget {
  final String id;
  const ProductScreen({super.key, required this.id});
  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  String? currency;
  String shop = '';
  DateTimeRange? range;
  bool normalized = false;
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(storeProvider);
    final p = s.products.where((p) => p.id == widget.id).firstOrNull;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product')),
        body: empty(
          'Product unavailable',
          'This product may have been deleted.',
        ),
      );
    }
    final currencies = {
      s.currency,
      ...s.records.where((r) => r.productId == p.id).map((r) => r.currencyCode),
    }.toList()..sort();
    final selectedCurrency = currencies.contains(currency)
        ? currency!
        : s.currency;
    final all =
        s.records
            .where(
              (r) => r.productId == p.id && r.currencyCode == selectedCurrency,
            )
            .toList()
          ..sort(chronological);
    final latest = latestByShop(all, p.id, selectedCurrency);
    final filtered = all
        .where(
          (r) =>
              (shop.isEmpty || r.shopId == shop) &&
              (range == null ||
                  (!r.recordedAt.isBefore(range!.start) &&
                      r.recordedAt.isBefore(
                        range!.end.add(const Duration(days: 1)),
                      ))),
        )
        .toList();
    final comparable = s.products
        .where(
          (other) =>
              other.name.trim().toLowerCase() == p.name.trim().toLowerCase() &&
              (other.brand ?? '').trim().toLowerCase() ==
                  (p.brand ?? '').trim().toLowerCase() &&
              other.categoryId == p.categoryId &&
              normalizedQuantity(other).unit == normalizedQuantity(p).unit,
        )
        .toList();
    final normalizedRows = <({Product product, PriceRecord record})>[];
    for (final other in comparable) {
      for (final r in latestByShop(s.records, other.id, selectedCurrency)) {
        normalizedRows.add((product: other, record: r));
      }
    }
    normalizedRows.sort(
      (a, b) => normalizedPrice(
        a.product,
        a.record.price,
      ).compareTo(normalizedPrice(b.product, b.record.price)),
    );
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(p.name),
          actions: [
            IconButton(
              tooltip: 'Edit product',
              onPressed: () => productForm(context, s, p),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete product',
              onPressed: () async {
                if (await confirm(
                  context,
                  'Delete ${p.name}? Delete linked observations first.',
                )) {
                  if (context.mounted) {
                    await attempt(context, () async {
                      await s.deleteProduct(p.id);
                      if (context.mounted) context.pop();
                    });
                  }
                }
              },
              icon: const Icon(Icons.delete_outline),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Compare'),
              Tab(text: 'History'),
              Tab(text: 'Chart'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => recordForm(context, s, productId: p.id),
          icon: const Icon(Icons.add),
          label: const Text('Add price'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p.unitQuantity} ${p.unitType} · ${categories.firstWhere((c) => c.id == p.categoryId).name}${p.brand?.isNotEmpty == true ? ' · ${p.brand}' : ''}',
                      ),
                      if (p.notes?.isNotEmpty == true) Text(p.notes!),
                      const SizedBox(height: 12),
                      filter('Currency', selectedCurrency, {
                        for (final c in currencies) c: c,
                      }, (v) => setState(() => currency = v)),
                      const SizedBox(height: 8),
                      const Text(
                        'Latest observed prices only. Check the date: a shop’s actual price may have changed.',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Compare normalized unit prices'),
                            subtitle: const Text(
                              'Includes matching name, brand and category with compatible units. Verify that packages are equivalent.',
                            ),
                            value: normalized,
                            onChanged: (v) => setState(() => normalized = v),
                          ),
                          if (!normalized) ...[
                            if (latest.isEmpty)
                              empty(
                                'No observations in this currency',
                                'Add a price to start comparing shops.',
                              ),
                            if (latest.isNotEmpty)
                              Card(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Lowest latest observation: ${money(latest.first.price, selectedCurrency)}\nSpread: ${money(latest.last.price - latest.first.price, selectedCurrency)}\nHistorical low: ${money(all.map((r) => r.price).reduce((a, b) => a < b ? a : b), selectedCurrency)}',
                                  ),
                                ),
                              ),
                            ...latest.map(
                              (r) => Card(
                                child: ListTile(
                                  leading: Icon(
                                    r.price == latest.first.price
                                        ? Icons.savings_outlined
                                        : Icons.storefront,
                                    color: r.price == latest.first.price
                                        ? Colors.teal
                                        : Colors.orange,
                                  ),
                                  title: Text(s.shopName(r.shopId)),
                                  subtitle: Text(
                                    'Observed ${day(r.recordedAt)}\n${money(normalizedPrice(p, r.price), selectedCurrency)} / ${normalizedQuantity(p).unit}',
                                  ),
                                  trailing: Text(
                                    '${money(r.price, selectedCurrency)}\n${r.price == latest.first.price
                                        ? 'Lowest'
                                        : r.price == latest.last.price
                                        ? 'Highest'
                                        : '+${money(r.price - latest.first.price, selectedCurrency)}'}',
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            if (normalizedRows.isEmpty)
                              empty(
                                'No comparable observations',
                                'Save an observation for this product and currency.',
                              ),
                            ...normalizedRows.map(
                              (row) => Card(
                                child: ListTile(
                                  title: Text(
                                    '${row.product.name} · ${row.product.unitQuantity} ${row.product.unitType}',
                                  ),
                                  subtitle: Text(
                                    '${s.shopName(row.record.shopId)} · ${day(row.record.recordedAt)}\nPackage: ${money(row.record.price, selectedCurrency)}',
                                  ),
                                  trailing: Text(
                                    '${money(normalizedPrice(row.product, row.record.price), selectedCurrency)}\n/ ${normalizedQuantity(row.product).unit}',
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        children: [
                          if (all.isEmpty)
                            empty(
                              'No price history yet',
                              'Each observation is saved independently.',
                            ),
                          ...all.reversed.map((r) {
                            final previous = all
                                .where(
                                  (a) =>
                                      a.shopId == r.shopId &&
                                      chronological(a, r) < 0,
                                )
                                .lastOrNull;
                            final delta = previous == null
                                ? null
                                : r.price - previous.price;
                            final pct = previous == null
                                ? null
                                : percentageChange(previous.price, r.price);
                            return Card(
                              child: ListTile(
                                title: Text(
                                  '${money(r.price, r.currencyCode)} · ${s.shopName(r.shopId)}',
                                ),
                                subtitle: Text(
                                  '${day(r.recordedAt)}${delta == null ? '\nFirst observation at this shop' : '\nChange: ${delta >= 0 ? '+' : ''}${money(delta, r.currencyCode)} · ${pct == null ? 'percentage unavailable (previous price zero)' : '${pct.toStringAsFixed(1)}%'}'}${r.notes?.isNotEmpty == true ? '\n${r.notes}' : ''}',
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    if (v == 'edit') {
                                      await recordForm(context, s, old: r);
                                    } else if (await confirm(
                                      context,
                                      'Delete this observation permanently?',
                                    )) {
                                      if (context.mounted) {
                                        await attempt(
                                          context,
                                          () => s.deleteRecord(r.id),
                                        );
                                      }
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              filter('Shop', shop, {
                                '': 'All shops',
                                for (final sh in s.shops) sh.id: sh.name,
                              }, (v) => setState(() => shop = v)),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.date_range),
                                label: Text(
                                  range == null
                                      ? 'Choose date range'
                                      : '${day(range!.start)} – ${day(range!.end)}',
                                ),
                                onPressed: () async {
                                  final chosen = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                    initialDateRange: range,
                                  );
                                  if (chosen != null) {
                                    setState(() => range = chosen);
                                  }
                                },
                              ),
                              if (range != null)
                                TextButton(
                                  onPressed: () => setState(() => range = null),
                                  child: const Text('Clear dates'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (filtered.isEmpty)
                            empty(
                              'No observations for these filters',
                              'Choose a different shop, date range or currency.',
                            )
                          else
                            PriceChart(records: filtered, store: s),
                          const SizedBox(height: 12),
                          const Text(
                            'Lines connect recorded observations at each shop; they do not estimate prices between visits.',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PriceChart extends StatelessWidget {
  final List<PriceRecord> records;
  final DiaryStore store;
  const PriceChart({super.key, required this.records, required this.store});
  @override
  Widget build(BuildContext context) {
    final shops = records.map((r) => r.shopId).toSet().toList();
    const colors = [
      Colors.teal,
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.brown,
    ];
    double x(PriceRecord r) =>
        r.recordedAt.millisecondsSinceEpoch / Duration.millisecondsPerDay;
    final minX = x(records.first), maxX = x(records.last);
    final maxY = records.map((r) => r.price).reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: Padding(
            padding: const EdgeInsets.only(right: 20, top: 20),
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX == minX ? maxX + 1 : maxX,
                minY: 0,
                maxY: maxY == 0 ? 1 : maxY * 1.15,
                lineBarsData: [
                  for (var i = 0; i < shops.length; i++)
                    LineChartBarData(
                      color: colors[i % colors.length],
                      barWidth: 3,
                      isCurved: false,
                      spots: records
                          .where((r) => r.shopId == shops[i])
                          .map((r) => FlSpot(x(r), r.price))
                          .toList(),
                      dotData: const FlDotData(show: true),
                    ),
                ],
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: ((maxX - minX) / 3).ceilToDouble().clamp(
                        1,
                        double.infinity,
                      ),
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat.MMMd().format(
                            DateTime.fromMillisecondsSinceEpoch(
                              (value * Duration.millisecondsPerDay).round(),
                            ),
                          ),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 55),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map(
                          (spot) => LineTooltipItem(
                            '${store.shopName(shops[spot.barIndex])}\n${day(DateTime.fromMillisecondsSinceEpoch((spot.x * Duration.millisecondsPerDay).round()))}\n${money(spot.y, records.first.currencyCode)}',
                            const TextStyle(color: Colors.white),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
        Wrap(
          spacing: 16,
          children: [
            for (var i = 0; i < shops.length; i++)
              Chip(
                avatar: CircleAvatar(
                  backgroundColor: colors[i % colors.length],
                  radius: 6,
                ),
                label: Text(store.shopName(shops[i])),
              ),
          ],
        ),
      ],
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(storeProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        heading('Settings', 'Your diary stays on this device'),
        filter('Theme', s.theme, {
          'system': 'Follow system',
          'light': 'Light',
          'dark': 'Dark',
        }, (v) => attempt(context, () => s.settings(s.currency, v))),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Default currency'),
          subtitle: Text(
            '${s.currency} · changing this does not convert existing observations',
          ),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () async {
            final controller = TextEditingController(text: s.currency);
            final value = await showDialog<String>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Default currency'),
                content: TextField(
                  controller: controller,
                  maxLength: 3,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: 'USD, PKR, EUR…'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final value = controller.text.trim().toUpperCase();
                      if (RegExp(r'^[A-Z]{3}$').hasMatch(value)) {
                        Navigator.pop(c, value);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
            if (value != null && context.mounted) {
              await attempt(context, () => s.settings(value, s.theme));
            }
          },
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.file_upload_outlined),
          title: const Text('Export CSV files'),
          subtitle: const Text('Products, shops and all price observations'),
          onTap: () => attempt(context, () async {
            final products = csv([
              [
                'id',
                'name',
                'brand',
                'category',
                'unit_type',
                'unit_quantity',
                'notes',
                'created_at',
              ],
              ...s.products.map(
                (p) => [
                  p.id,
                  p.name,
                  p.brand,
                  p.categoryId,
                  p.unitType,
                  p.unitQuantity,
                  p.notes,
                  p.createdAt.toIso8601String(),
                ],
              ),
            ]);
            final shops = csv([
              ['id', 'name', 'notes', 'created_at'],
              ...s.shops.map(
                (sh) => [
                  sh.id,
                  sh.name,
                  sh.notes,
                  sh.createdAt.toIso8601String(),
                ],
              ),
            ]);
            final records = csv([
              [
                'id',
                'product_id',
                'product_name',
                'shop_id',
                'shop_name',
                'price',
                'currency',
                'observed_at',
                'notes',
                'created_at',
              ],
              ...s.records.map(
                (r) => [
                  r.id,
                  r.productId,
                  s.product(r.productId).name,
                  r.shopId,
                  s.shopName(r.shopId),
                  r.price,
                  r.currencyCode,
                  r.recordedAt.toIso8601String(),
                  r.notes,
                  r.createdAt.toIso8601String(),
                ],
              ),
            ]);
            final box = context.findRenderObject() as RenderBox?;
            await SharePlus.instance.share(
              ShareParams(
                files: [
                  for (final text in [products, shops, records])
                    XFile.fromData(
                      Uint8List.fromList(utf8.encode('\uFEFF$text')),
                      mimeType: 'text/csv',
                    ),
                ],
                fileNameOverrides: [
                  'products.csv',
                  'shops.csv',
                  'price_records.csv',
                ],
                sharePositionOrigin: box == null
                    ? const Rect.fromLTWH(0, 0, 1, 1)
                    : box.localToGlobal(Offset.zero) & box.size,
              ),
            );
          }),
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          textColor: Theme.of(context).colorScheme.error,
          iconColor: Theme.of(context).colorScheme.error,
          leading: const Icon(Icons.delete_forever_outlined),
          title: const Text('Clear all diary data'),
          subtitle: const Text(
            'Permanently delete products, shops and observations',
          ),
          onTap: () async {
            if (await confirm(
              context,
              'Permanently delete every product, shop and observation? Export CSV first if you need a copy. This cannot be undone.',
            )) {
              if (context.mounted) await attempt(context, s.clear);
            }
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'PriceDiary · 1.0.0\nCompletely offline. No account, backend or currency conversion.\nExport regularly; uninstalling the app may remove its local data.',
        ),
      ],
    );
  }
}
