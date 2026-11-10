# Activity 14 — Firestore Product App + Firebase Cloud Messaging

This Android Flutter project keeps the Activity 12 **Autumn Product Manager** (Cloud Firestore CRUD, live snapshots, search, price filters, validation, edit/delete) and adds Activity 14 FCM foreground/background-tap/cold-start handling and T4 safe payload validation. Android is configured for the supplied Firebase project and the `com.example.my_product_app` app registration.

## First run (Windows PowerShell)

1. Install Flutter and Android Studio/Android SDK. In PowerShell run `flutter doctor` and `flutter devices`; connect the Android phone used for the activity and enable USB debugging.
2. Extract this ZIP. Open PowerShell in the extracted `Activity14_Firestore_FCM` folder.
3. Run:

```powershell
flutter pub get
flutter run
```

If you see a Gradle or package-resolution error, copy the full error text; don't replace Firebase versions at random. This code follows the Activity 14 hub's Firebase Core 4.x / Messaging 16.x API baseline and adds Cloud Firestore 6.x. Android app config is already present for the product app identifier.

## Firestore data

The app reads the Firestore `products` collection. Documents need a non-empty string `name` and a numeric nonnegative `price`. The Activity 12 project report/data should already have the five fictional product records. If the collection is empty, the app shows its empty-state message; Firebase Console setup and test rules are in the Activity 12 instructions. Do not publish permanent allow-all rules.

## Send the Activity 14 messages

1. Run the app once and tap the notification/key icon in the app bar. Copy the **current installation token** from the dialog. Keep it private; never include it in screenshots or commit it to GitHub.
2. In Firebase Console, open **Messaging / Cloud Messaging** and create a test notification. Set a notification title and body. Target the current installation token in the test-message flow.
3. Add custom data (string values): `action` = `update_ui`; `asset` = `promo`.
4. **T1:** keep app visible and send. The product app's FCM panel should show `onMessage`, title/body, promo image, and receipt metadata. A system banner is not expected while foregrounded.
5. **T2:** background the app, send, tap the notification. On return the panel should show `onMessageOpenedApp` and the same UI update.
6. **T3:** open app once, then dismiss it from recent apps (do not Force stop). Send a new notification and tap it to launch the app. Panel should show `getInitialMessage`.
7. **T4:** with app foregrounded send `action=update_ui` and `asset=unknown` (or omit `asset`). The app should show a rejection diagnostic, preserve the previous title/image, and stay open.

The data mapper accepts only `action=update_ui` plus `asset=default|promo`. `onBackgroundMessage` is a top-level background-isolate handler and intentionally does not update widget state. Message delivery depends on Android permission, network, payload, and device state; write down actual outcomes, including blocked tests.

## Submission checklist

- Push this exact tested Flutter source to an accessible GitHub repository; submit that URL.
- Capture one concise recording of T1–T4 or four labeled screenshots showing each handler and visible UI. Redact the installation token.
- Complete `docs/TEST_RECORD.md` and `docs/REFLECTION_TEMPLATE.md` from your observed results; do not claim an unrun test passed.
- Upload repository URL, evidence, and reflection to the LMS and verify the LMS submission confirmation.

The Activity 14 page lists November 9, 2026 at 11:59 PM EST as its deadline. Check the LMS for any instructor update.
