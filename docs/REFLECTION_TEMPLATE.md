# Activity 14 Reflection

Fill in actual observations; target 150–250 words total across the three responses.

## 1. Setup and payload
I used the Activity 12 Firestore product manager and configured its Android app identifier, `com.example.my_product_app`, in Firebase project `afeef-inclass12-319d5`. I added Firebase Messaging alongside the existing Firestore dependency. The message uses `action=update_ui` and the allowed `asset` values `default` or `promo` to update the FCM panel. In T1, I observed [actual result; evidence reference].

## 2. Lifecycle and evidence
T1 used `onMessage` and [result]. T2 used `onMessageOpenedApp` after I tapped a notification while the app was backgrounded and [result]. T3 used `getInitialMessage` when a notification tap launched the app and [result]. The separate top-level `onBackgroundMessage` handler runs in a background isolate; it cannot directly change widget state. My evidence is [recording or screenshot references].

## 3. Validation and next step
For T4 I sent [invalid payload]. The app [actual diagnostic, preservation result, and crash/no-crash result]. One risk I checked or failure/fix I observed was [specific finding]. A feasible improvement is [one improvement], and I would verify it by [observable success condition]. This test used [device/OS and permission]; [limitation]. Assistance used: [accurate disclosure].
