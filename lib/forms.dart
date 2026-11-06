import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'domain.dart';
import 'store.dart';

const uuid = Uuid();
Future<void> attempt(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

Future<bool> confirm(BuildContext context, String message) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Please confirm'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
    false;
Future<void> productForm(
  BuildContext context,
  DiaryStore store, [
  Product? old,
]) => showDialog(
  context: context,
  builder: (_) => ProductForm(store: store, old: old),
);

class ProductForm extends StatefulWidget {
  final DiaryStore store;
  final Product? old;
  const ProductForm({super.key, required this.store, this.old});
  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final key = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.old?.name),
      brand = TextEditingController(text: widget.old?.brand),
      quantity = TextEditingController(
        text: widget.old?.unitQuantity.toString() ?? '1',
      ),
      notes = TextEditingController(text: widget.old?.notes);
  late String category = widget.old?.categoryId ?? 'groceries',
      unit = widget.old?.unitType ?? 'kg';
  bool busy = false;
  @override
  void dispose() {
    for (final c in [name, brand, quantity, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.old == null ? 'New product' : 'Edit product'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(name, 'Product name', required: true),
              field(brand, 'Brand (optional)'),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (v) => category = v!,
              ),
              const SizedBox(height: 12),
              field(quantity, 'Package quantity', number: true, positive: true),
              DropdownButtonFormField<String>(
                initialValue: unit,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: ['kg', 'g', 'L', 'ml', 'piece']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => unit = v!,
              ),
              const SizedBox(height: 12),
              field(notes, 'Notes (optional)'),
              if (widget.old != null &&
                  widget.store.records.any(
                    (r) => r.productId == widget.old!.id,
                  ))
                const Text(
                  'Package size cannot change while this product has price observations.',
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: busy
            ? null
            : () async {
                if (!key.currentState!.validate()) return;
                setState(() => busy = true);
                try {
                  await widget.store.saveProduct(
                    Product(
                      id: widget.old?.id ?? uuid.v4(),
                      name: name.text.trim(),
                      brand: brand.text.trim(),
                      categoryId: category,
                      unitType: unit,
                      unitQuantity: double.parse(quantity.text),
                      notes: notes.text.trim(),
                      createdAt: widget.old?.createdAt ?? DateTime.now(),
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    setState(() => busy = false);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
        child: const Text('Save product'),
      ),
    ],
  );
}

Widget field(
  TextEditingController controller,
  String label, {
  bool required = false,
  bool number = false,
  bool positive = false,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    keyboardType: number
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    validator: (v) {
      if (required && (v == null || v.trim().isEmpty)) return 'Required';
      if (number) {
        final n = double.tryParse(v ?? '');
        if (n == null || !n.isFinite || (positive ? n <= 0 : n < 0)) {
          return positive
              ? 'Enter a positive number'
              : 'Enter zero or a positive number';
        }
      }
      return null;
    },
  ),
);
Future<void> shopForm(
  BuildContext context,
  DiaryStore store, [
  Shop? old,
]) async {
  final name = TextEditingController(text: old?.name),
      notes = TextEditingController(text: old?.notes);
  await showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(old == null ? 'New shop' : 'Edit shop'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            field(name, 'Shop name'),
            field(notes, 'Notes (optional)'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => attempt(c, () async {
            await store.saveShop(
              Shop(
                id: old?.id ?? uuid.v4(),
                name: name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
                notes: notes.text.trim(),
                createdAt: old?.createdAt ?? DateTime.now(),
              ),
            );
            if (c.mounted) Navigator.pop(c);
          }),
          child: const Text('Save shop'),
        ),
      ],
    ),
  );
  // The route transition may still use the text fields; controllers are released after it completes.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  name.dispose();
  notes.dispose();
}

Future<void> recordForm(
  BuildContext context,
  DiaryStore store, {
  String? productId,
  PriceRecord? old,
}) async {
  if (store.products.isEmpty || store.shops.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add at least one product and one shop first.'),
      ),
    );
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (_) => RecordForm(store: store, productId: productId, old: old),
  );
}

class RecordForm extends StatefulWidget {
  final DiaryStore store;
  final String? productId;
  final PriceRecord? old;
  const RecordForm({super.key, required this.store, this.productId, this.old});
  @override
  State<RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<RecordForm> {
  final key = GlobalKey<FormState>();
  late String productId =
          widget.old?.productId ??
          widget.productId ??
          widget.store.products.first.id,
      shopId = widget.old?.shopId ?? widget.store.shops.first.id;
  late DateTime date =
      widget.old?.recordedAt ?? DateUtils.dateOnly(DateTime.now());
  late final price = TextEditingController(text: widget.old?.price.toString()),
      currency = TextEditingController(
        text: widget.old?.currencyCode ?? widget.store.currency,
      ),
      notes = TextEditingController(text: widget.old?.notes);
  bool busy = false;
  @override
  void dispose() {
    price.dispose();
    currency.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.old == null ? 'Record a price' : 'Correct observation'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: productId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Product'),
                items: widget.store.products
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          '${p.name} · ${p.unitQuantity} ${p.unitType}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => productId = v!,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: shopId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Shop'),
                items: widget.store.shops
                    .map(
                      (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                    )
                    .toList(),
                onChanged: (v) => shopId = v!,
              ),
              const SizedBox(height: 12),
              field(price, 'Observed price', number: true),
              TextFormField(
                controller: currency,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Currency code (e.g. USD, PKR, EUR)',
                ),
                validator: (v) =>
                    RegExp(
                      r'^[A-Z]{3}$',
                    ).hasMatch((v ?? '').trim().toUpperCase())
                    ? null
                    : 'Enter a three-letter code',
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month),
                title: Text(DateFormat.yMMMd().format(date)),
                subtitle: const Text('Observation date'),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => date = d);
                },
              ),
              field(notes, 'Notes (optional)'),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: busy
            ? null
            : () async {
                if (!key.currentState!.validate()) return;
                setState(() => busy = true);
                try {
                  await widget.store.saveRecord(
                    PriceRecord(
                      id: widget.old?.id ?? uuid.v4(),
                      productId: productId,
                      shopId: shopId,
                      price: double.parse(price.text),
                      currencyCode: currency.text.trim().toUpperCase(),
                      recordedAt: date,
                      createdAt: widget.old?.createdAt ?? DateTime.now(),
                      notes: notes.text.trim(),
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    setState(() => busy = false);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
        child: const Text('Save observation'),
      ),
    ],
  );
}
