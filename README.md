# PriceDiary – Personal Price Tracker

An offline Flutter app for remembering and comparing prices across shops. No backend, sign-in, paid APIs, analytics or runtime network services.

## Setup on another machine

Use **Flutter 3.47.9 / Dart 3.13.7** (the SDK used to generate and check this project), or a compatible later stable SDK. Install the Android/iOS/desktop toolchain for your target, then:

```sh
git clone https://github.com/BilalYamin127/PriceDiary.git
cd PriceDiary
flutter pub get
flutter analyze
flutter test
flutter run
```

The application was not launched during development, as requested. Platform projects for Android, iOS, web, Windows, macOS and Linux are included. Native platform builds require their usual host OS and SDKs. Dependencies are locked in `pubspec.lock`.

## Included features

- Dashboard with counts, recent products and latest price changes per shop/currency.
- Product creation, editing, category/brand search, shop/category filters and sorting.
- Shop creation, editing, duplicate-name checks and recorded-product lists.
- Independent dated price observations, including free products (zero price), correction and deletion.
- Latest-observed comparison per shop and currency, historical low, price spread, dated history and safe percentage changes.
- Normalized prices per kg, liter or piece. Optional cross-package comparison requires matching name, brand and category, plus compatible unit dimensions. Review product equivalence before using these comparisons.
- Price charts with separate shop series, product context, currency and date-range filters.
- Light/dark/system theme, configurable three-letter default currency, CSV sharing and confirmed data clearing.
- Full JSON backup/restore with validation and a replacement preview for moving between devices.
- Record again from history: reuses product/shop/currency, asks for a fresh price and saves a new dated observation.
- Comparison warnings for observations at least 30 days old and dated historical-low details.
- Responsive scrollable layouts, empty states and persistence error messages.

## Data and comparison rules

Hive CE stores a versioned JSON snapshot in the platform's application documents directory (browser storage on web). Writes complete before the UI reports success. Price records retain their observation date and entry date; older observations are never replaced by a new record. Same-day ties use creation time and then record ID. Backdated entries are compared by observation date.

Comparisons never convert or combine currencies. Default-currency changes affect new entries and default views only. History changes are calculated against the preceding observation at the **same shop and currency**. A previous price of zero yields an unavailable percentage rather than division by zero. Recorded prices are not guaranteed current offers.

A product with observations cannot change its package quantity/unit: create another product for a different size. Shops and products with linked records cannot be deleted until their observations are removed. Shop names ignore capitalization and repeated whitespace for duplicate detection. Categories are built-in: Groceries, Household, Electronics and Other.

CSV export shares `products.csv`, `shops.csv` and `price_records.csv` through the operating system share/save UI. Files include IDs, dates, currencies and relationships. CSV is for spreadsheets. Use **Save a full backup** and **Restore a backup** in Settings for device transfers. Restore accepts PriceDiary JSON files up to 10 MB, validates IDs, relationships, prices, units, categories and settings, and replaces the entire diary after confirmation. It does not merge diaries. Backups are unencrypted; store them somewhere private. Spreadsheet formula prefixes are escaped. The database is local and is not encrypted; use device security and export copies regularly. Uninstalling the app or clearing browser data can delete the diary.

## Structure

- `lib/domain.dart`: models, calculation, normalization, ordering and CSV helpers.
- `lib/store.dart`: Hive persistence, CRUD and relationship validation.
- `lib/backup.dart` and `lib/backup_settings.dart`: validated backup format and save/restore flow.
- `lib/forms.dart`: validated product, shop and observation forms.
- `lib/screens.dart`: dashboard, lists, comparisons, history, charts and settings.
- `lib/main.dart`: startup, Riverpod, Material 3 themes and GoRouter.
- `test/`: calculation/serialization tests and real Hive close/reopen persistence tests.

## Release preparation

No application execution or release builds were performed here. To build on your target machine:

```sh
flutter build apk --release
flutter build appbundle --release
flutter build ios --release --no-codesign  # macOS + Xcode required
flutter build web --release
flutter build windows --release          # Windows + Visual Studio required
flutter build macos --release            # macOS + Xcode required
flutter build linux --release            # Linux desktop development tools required
```

Android release builds use the generated debug key by default for convenient testing on another device. For a Play Store release, create a private signing key, copy `android/key.properties.example` to `android/key.properties`, enter your own values and build the app bundle. Keep the key and passwords out of Git. Configure your Apple team, signing and distribution in Xcode before an iOS/macOS store release. Replace the default Flutter icons and confirm application identifiers before store publication.

The **Verify and build** GitHub Actions workflow is manual only. Run it from the Actions tab to analyze and test; optionally produce a device-test release APK. It does not launch the app or publish anything.

## Play Store listing assets

The [store submission pack](store_listing/PLAY_CONSOLE_CHECKLIST.md) includes listing copy, a 512 px icon, 1024 × 500 feature graphic, eight 1080 × 1920 **illustrative mockups**, and a privacy policy in Word/HTML/Markdown formats. The launcher icons use the new PriceDiary artwork. Mockups are visibly labeled drafts; replace them with real release-app screenshots before submission. The contact email is intentionally a dummy and the public privacy-policy URL is pending. See the checklist for remaining publisher decisions and upload requirements.

To rebuild the compositions/documents on Linux, install `Pillow` and `python-docx`, then run `python3 store_listing/source/create_assets.py` and `python3 store_listing/source/create_documents.py`. The asset script uses DejaVu Sans fonts from `/usr/share/fonts/truetype/dejavu`. Run `python3 store_listing/source/validate_pack.py` to check dimensions, text lengths and the policy document. `source/icon-master.png` is the original AI-generated artwork.
