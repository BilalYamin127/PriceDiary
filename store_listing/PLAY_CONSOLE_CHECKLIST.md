# PriceDiary Play Console submission pack

Status: PREPARATION PACK — not submitted, not yet ready to publish.

## Files to copy or upload

| Field | File / value |
|---|---|
| App name (30-character limit) | `en-US/title.txt` |
| Short description (80-character limit) | `en-US/short-description.txt` |
| Full description (4,000-character limit) | `en-US/full-description.txt` |
| Release notes | `en-US/release-notes.txt` |
| Default language | English (United States), en-US |
| App or game | App |
| Suggested category | Shopping; confirm available Console categories |
| Support email | `en-US/support-email.txt` — DUMMY, replace |
| Privacy policy URL | `en-US/privacy-policy-url.txt` — PENDING |
| Store icon | `graphics/app-icon-512.png`, opaque RGB PNG, 512 × 512 |
| Feature graphic | `graphics/feature-graphic-1024x500.png`, RGB PNG, 1024 × 500 |
| Phone screenshot storyboard | `graphics/mockups/01-*.png` through `08-*.png`, 1080 × 1920 |
| Privacy policy Word document | `privacy/PriceDiary-Privacy-Policy.docx` |
| Web/Markdown policy | `privacy/privacy-policy.html`, `privacy/privacy-policy.md` |
| Android application ID | `com.pricediary.price_diary` |
| Current version | 1.1.0 (version code 2) |

These are plain text listing files, not Dart source, because Play Console needs text rather than executable code.

## Required before submission

- Replace every `privacy@example.invalid` occurrence with your working public support/privacy email. Replace “PriceDiary development team” with your legal/publisher identity where required by your account or applicable law. Regenerate the Word/HTML policy after changing the Markdown source.
- Host the final policy at a stable, public, read-only URL. It must open without signing in or asking permission. An editable Drive document or a restricted Drive link is not suitable. Prefer an accessible HTML page; if using Drive, verify that the published result is accessible and meets the Console's current policy requirements. A Word download alone should not be assumed sufficient.
- Paste that URL into `en-US/privacy-policy-url.txt` and Play Console, and add an accessible Privacy Policy link or policy screen inside the app (for example in Settings). No hosted URL has been invented or inserted here.
- **Replace all eight mockups with screenshots captured from the release app on a real device/emulator.** They have visible “ILLUSTRATIVE MOCKUP / SAMPLE DATA / NOT A LIVE CAPTURE” labels, and no app execution occurred. They show implemented capabilities but are not pixel-accurate runtime evidence. Use the storyboard's order and headlines with genuine app captures if desired. Do not present these drafts as actual screenshots.
- Test the release app on supported devices, including icons, file picker, backup/restore and share sheet. The icon source has been exported to platform launcher assets; no application was run to preview it.
- Build a signed Android App Bundle with your private distribution key. Debug-signed device builds are not Play Store releases. Choose an immutable application ID and increment version code for subsequent releases.
- Complete developer identity verification, public contact details, signing, countries/regions and pricing in your own Console account. Pricing and target audience remain publisher decisions.
- Complete the content-rating questionnaire, target-audience declaration, ads declaration, app access instructions and any additional forms shown by your account. Do not invent an IARC rating. If you select children as a target audience, review applicable Families requirements separately.
- Confirm current target Android API, account-specific testing requirements and review requirements at upload time. These change over time; this pack does not assert approval or compliance.

## Suggested declarations based on the current code

These are review notes, not a submitted Data safety form. Reassess whenever an SDK or feature changes.

- App access: all functionality is available without an account or login. No reviewer credentials are required. Add a product and shop to create an observation.
- Ads: no ads in the current app.
- Accounts: no user accounts or developer-held account records. An account-deletion web endpoint is not applicable to this version; diary deletion is available in Settings.
- Developer data collection: no automatic diary, analytics, advertising or crash-report collection to a developer server in the reviewed code.
- Developer data sharing: no automatic developer-directed third-party transfer. Users can deliberately share exported files through chosen destinations. Review the current Console definitions and exceptions for user-initiated sharing and platform backups when completing the form.
- Encryption: do not describe the local Hive database or JSON/CSV exports as app-encrypted. There is no application-server transport to describe as encrypted in transit. Select only Console answers that apply to the actual release.
- Permissions: the release manifest contains no explicit Internet, camera, microphone, location or broad-storage permission. File selection and sharing use system interfaces/plugins. Inspect the final merged release manifest before declaring permissions.
- Health, financial services, government affiliation and news: this app records user-entered product prices; it does not offer payments, banking, investment advice, medical services, government services or news. Answer the exact forms shown based on the final app and your business.

## Suggested screenshot sequence

1. Home dashboard: products, shops, observation counts and recent changes.
2. Product search: show brand and package sizes.
3. Add product: name, category, quantity and unit.
4. Record price: shop, amount, currency and date.
5. Compare: different shops, same package/currency, visible observation dates.
6. History: previous observations and same-shop percentage changes.
7. Chart: dated observations with shop/date filters.
8. Settings: local backup/restore, CSV export, themes and currency.

Use fictional sample data, not private records. The mockup sample uses USD and November 2026 dates. No savings are guaranteed. Tablet, Chromebook or other device screenshots should be captured separately if required for the devices you distribute to; resizing phone drafts is not evidence of those layouts.

## Reference links — verify current requirements before upload

- Listing preview assets: https://support.google.com/googleplay/android-developer/answer/9866151
- Store listing setup: https://support.google.com/googleplay/android-developer/answer/9859152
- Data safety: https://support.google.com/googleplay/android-developer/answer/10787469
- User Data policy: https://support.google.com/googleplay/android-developer/answer/10144311

No Play Console account was accessed, no listing was submitted, and no app was published.
