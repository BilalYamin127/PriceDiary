import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'backup.dart';
import 'forms.dart';
import 'store.dart';

class BackupSettings extends StatefulWidget {
  final DiaryStore store;
  const BackupSettings({super.key, required this.store});
  @override
  State<BackupSettings> createState() => _BackupSettingsState();
}

class _BackupSettingsState extends State<BackupSettings> {
  bool busy = false;
  Future<void> perform(Future<void> Function() action) async {
    setState(() => busy = true);
    await attempt(context, action);
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        enabled: !busy,
        leading: const Icon(Icons.backup_outlined),
        title: const Text('Save a full backup'),
        subtitle: const Text(
          'Transfer all products, shops, history and settings to another device',
        ),
        onTap: () => perform(() async {
          final bytes = Uint8List.fromList(
            utf8.encode(widget.store.backup.encode()),
          );
          final box = context.findRenderObject() as RenderBox?;
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile.fromData(bytes, mimeType: 'application/json')],
              fileNameOverrides: [
                'PriceDiary-backup-${DateTime.now().toIso8601String().substring(0, 10)}.json',
              ],
              sharePositionOrigin: box == null
                  ? const Rect.fromLTWH(0, 0, 1, 1)
                  : box.localToGlobal(Offset.zero) & box.size,
            ),
          );
        }),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        enabled: !busy,
        leading: const Icon(Icons.restore_page_outlined),
        title: const Text('Restore a backup'),
        subtitle: const Text(
          'Preview and validate a JSON backup before replacing this diary',
        ),
        onTap: () => perform(() async {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['json'],
            withData: true,
          );
          if (result == null) return;
          final file = result.files.single;
          if (file.size > 10 * 1024 * 1024) {
            throw const FormatException('Backup exceeds the 10 MB limit.');
          }
          final bytes = file.bytes;
          if (bytes == null) {
            throw const FormatException('Unable to read the selected file.');
          }
          final backup = DiaryBackup.parse(utf8.decode(bytes));
          if (!context.mounted) return;
          final restore = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('Replace your diary?'),
              content: Text(
                'Backup contains ${backup.products.length} products, ${backup.shops.length} shops and ${backup.records.length} observations.\n\nThis replaces all existing data and settings; it does not merge diaries. Save a backup of your current diary first. This cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('Replace and restore'),
                ),
              ],
            ),
          );
          if (restore != true || !context.mounted) return;
          await widget.store.restore(backup);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup restored successfully.')),
            );
          }
        }),
      ),
      if (busy) const LinearProgressIndicator(),
    ],
  );
}
