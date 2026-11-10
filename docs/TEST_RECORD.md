# Activity 14 — observed test record

Student: [name]  
Repository URL: [accessible link]  
Device/OS: [Android phone model and Android version]  
Build/source revision: [commit or build]  
Notification permission: [authorized / denied / other exact status]  
Firebase app: `com.example.my_product_app` in `afeef-inclass12-319d5`  
Evidence files: [recording or screenshot filenames; token redacted]

Valid payload: notification title/body [exact values]; `action=update_ui`, `asset=promo`.  
T4 invalid payload: [asset missing or exact unsupported asset value].

| Test | Expected handler/result | Actual observed result | Pass/Fail/Blocked | Evidence reference |
|---|---|---|---|---|
| T1 Foreground | `onMessage`; update visible panel | [fill from device] | [ ] | [ ] |
| T2 Background notification tap | `onMessageOpenedApp`; update panel | [fill from device] | [ ] | [ ] |
| T3 Notification cold-start tap | `getInitialMessage`; update panel | [fill from device] | [ ] | [ ] |
| T4 Invalid payload | Diagnostic, previous title/image preserved, no crash | [fill from device] | [ ] | [ ] |

Limitations/blocked conditions: [actual conditions only]
