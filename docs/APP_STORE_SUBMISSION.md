# WorkWell — Mac App Store Submission Information

Last reviewed: 2026-07-19

> Status: **Code blockers resolved; App Store Connect assets and account fields remain.** The copy below is ready to paste, but screenshots and fields marked `TODO` must be completed before submission.

## 1. Build information

| Field | Value |
|---|---|
| App name | WorkWell |
| Platform | macOS |
| Bundle ID | `com.hihiteam.working.care` |
| Suggested SKU | `workwell-macos-2026` |
| Version | `1.0.18` |
| Build | `6` |
| Minimum macOS | macOS 15.0 or later |
| Primary category | Utilities |
| Suggested secondary category | Health & Fitness |
| Primary language | English (U.S.) |
| Additional localization | Vietnamese |
| Price | `TODO: Confirm Free or paid tier` |
| Copyright | `TODO: 2026 <legal person or company name>` |

Important consistency notes:

- The built app uses macOS 15.0 as its deployment target. Existing README/ProductHub text still says macOS 14.0 and must be updated.
- The app constant, UserDefaults key, Xcode target, and built product now consistently use `com.hihiteam.working.care`. Existing preferences stored under the legacy key are migrated automatically.
- The App Store Connect app record and App ID must use exactly `com.hihiteam.working.care`.

## 2. Must fix before upload

### RESOLVED — External self-update behavior removed

The App Store target no longer contains the GitHub Releases checker, DMG downloader/installer, update UI, update preference, or update menu actions. Mac App Store updates are handled only through the Store.

Removed from the binary:

- Automatic update check on launch.
- “Automatically check for updates” setting.
- “Check for Updates” menu/settings action.
- “Download & Install” and GitHub update window.
- `UpdateCheckService.swift`, `UpdateInstallService.swift`, and `UpdateAvailableView.swift`.

Reference: <https://developer.apple.com/app-store/review/guidelines/>

### CONFIGURED — Use the Mac App Store distribution flow

The existing GitHub release workflow signs with **Developer ID Application** and notarizes DMG/ZIP files. That workflow is for distribution outside the Mac App Store, not for App Store Connect.

For the Mac App Store build:

1. Xcode Release now uses automatic signing with team `GUPM456Q3M` and bundle ID `com.hihiteam.working.care`.
2. The explicit Release identity and manual provisioning override have been removed so Archive/Organizer can select the distribution identity and profile.
3. Archive using **Any Mac**.
4. In Organizer, choose **Distribute App → App Store Connect → Upload**.
5. Test the uploaded build with TestFlight before review.

### BLOCKER — Complete public URLs and legal/contact fields

- Privacy Policy URL: `https://github.com/padit69/work-well/blob/main/docs/PRIVACY_POLICY.md`
- Terms of Use URL: `https://github.com/padit69/work-well/blob/main/docs/TERMS_OF_USE.md`
- Support URL: `https://github.com/padit69/work-well/issues`
- Support email: `hihiteam.it@gmail.com`
- Copyright owner: `TODO_LEGAL_NAME`
- App Review contact name, email, and phone: `TODO`

The support page and both legal documents provide a public way to contact the developer at `hihiteam.it@gmail.com`.

### BLOCKER — Prepare screenshots

No App Store screenshots are currently present in the repository. Upload at least one and preferably five screenshots, all using one accepted 16:10 Mac size:

- 1280 × 800
- 1440 × 900
- 2560 × 1600
- 2880 × 1800

Recommended five-shot sequence:

1. Today dashboard and streak.
2. Water goal, logging, and seven-day progress.
3. Eye-rest 20–20–20 full-screen reminder.
4. Movement reminder with snooze/focus action.
5. Work schedule, reminder, appearance, and language settings.

Screenshots must not contain transparency. Use the same dimensions for every localization.

Reference: <https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/>

### Build cleanup before archive

- [x] App Sandbox is enabled consistently in the target and entitlements file.
- [x] Incoming and outgoing network entitlements were removed with the external updater.
- [x] `ITSAppUsesNonExemptEncryption = NO` is present in the built Info.plist.
- [x] Project and target development teams are consistently `GUPM456Q3M`.
- [x] All non-empty catalog strings now have Vietnamese translations.
- [x] Generic Release build succeeds as a universal `arm64 + x86_64` app with Xcode 26.6/macOS 26.5 SDK.
- [ ] Confirm the export-compliance answer in App Store Connect.
- Increase the build number for every upload if build `6` has already been uploaded.

## 3. App Information — English (U.S.)

### Name

```text
WorkWell
```

### Subtitle — 28 characters

```text
Healthy desk break reminders
```

### Promotional text

```text
Build healthier desk habits with smart water, eye-rest, and movement reminders tailored to your workday.
```

### Description

```text
WorkWell helps you build healthier habits while working at your Mac. It reminds you to drink water, rest your eyes with the 20–20–20 rule, and take short movement breaks throughout the day.

HEALTHY REMINDERS THAT FIT YOUR DAY
• Set separate intervals for water, eye-rest, and movement reminders.
• Limit reminders to your work hours and lunch schedule.
• Choose system notifications or clear full-screen break reminders.
• Use focus countdowns to give yourself time to complete each break.

SMART HYDRATION
• Estimate a daily water goal from your weight and selected profile.
• Log water by glass in milliliters or ounces.
• Review today's total and your recent progress.

EYE REST AND MOVEMENT
• Follow the 20–20–20 eye-rest routine with a configurable countdown.
• Receive short movement suggestions during long desk sessions.
• Snooze a movement reminder when you are in a meeting.

MADE FOR YOUR WORKSPACE
• English and Vietnamese interface.
• Light, dark, and system appearance.
• Optional start at login, enabled only when you choose it.
• Your preferences and activity records stay locally on your Mac.

WorkWell is a general wellness and habit-reminder tool. It does not provide medical advice, diagnosis, or treatment. Hydration estimates are general guidance and may not be appropriate for every person or health condition.
```

### Keywords — 89 bytes

```text
water reminder,eye rest,20-20-20,break timer,move reminder,desk health,hydration,wellness
```

### URLs

| Field | Value |
|---|---|
| Support URL | `https://github.com/padit69/work-well/issues` |
| Marketing URL | `https://github.com/padit69/work-well` |
| Privacy Policy URL | `https://github.com/padit69/work-well/blob/main/docs/PRIVACY_POLICY.md` |
| Terms of Use URL | `https://github.com/padit69/work-well/blob/main/docs/TERMS_OF_USE.md` |

## 4. App Information — Vietnamese

### Name

```text
WorkWell
```

### Subtitle — 27 characters

```text
Nhắc nghỉ khỏe khi làm việc
```

### Promotional text

```text
Xây dựng thói quen làm việc khỏe mạnh với lời nhắc uống nước, nghỉ mắt và vận động phù hợp lịch làm việc của bạn.
```

### Description

```text
WorkWell giúp bạn xây dựng thói quen lành mạnh hơn khi làm việc trên Mac. Ứng dụng nhắc bạn uống nước, nghỉ mắt theo quy tắc 20–20–20 và vận động ngắn trong ngày.

LỜI NHẮC PHÙ HỢP VỚI NGÀY LÀM VIỆC
• Đặt khoảng thời gian riêng cho nhắc uống nước, nghỉ mắt và vận động.
• Chỉ nhận lời nhắc trong giờ làm việc và ngoài giờ nghỉ trưa.
• Chọn thông báo hệ thống hoặc màn hình nhắc toàn màn hình rõ ràng.
• Dùng đếm ngược tập trung để dành đủ thời gian cho mỗi lần nghỉ.

UỐNG NƯỚC THÔNG MINH
• Ước tính mục tiêu nước mỗi ngày từ cân nặng và hồ sơ đã chọn.
• Ghi lượng nước theo ly bằng ml hoặc oz.
• Xem tổng lượng nước hôm nay và tiến độ gần đây.

NGHỈ MẮT VÀ VẬN ĐỘNG
• Thực hiện quy tắc nghỉ mắt 20–20–20 với thời gian đếm ngược tùy chỉnh.
• Nhận gợi ý vận động ngắn khi ngồi làm việc lâu.
• Tạm hoãn lời nhắc vận động khi bạn đang họp.

PHÙ HỢP VỚI KHÔNG GIAN LÀM VIỆC
• Giao diện tiếng Việt và tiếng Anh.
• Chế độ sáng, tối hoặc theo hệ thống.
• Tùy chọn mở khi đăng nhập, chỉ bật khi bạn chủ động chọn.
• Tùy chọn và dữ liệu hoạt động được lưu cục bộ trên máy Mac.

WorkWell là công cụ nhắc thói quen và chăm sóc sức khỏe nói chung. Ứng dụng không cung cấp tư vấn, chẩn đoán hoặc điều trị y tế. Mục tiêu uống nước chỉ mang tính tham khảo và có thể không phù hợp với mọi người hoặc mọi tình trạng sức khỏe.
```

### Keywords — 74 bytes

Vietnamese keywords are intentionally written without accents to stay safely below App Store Connect's 100-byte limit.

```text
uong nuoc,nghi mat,van dong,suc khoe,20-20-20,giai lao,van phong,thoi quen
```

### URLs

| Field | Value |
|---|---|
| Support URL | `https://github.com/padit69/work-well/issues` |
| Marketing URL | `https://github.com/padit69/work-well` |
| Privacy Policy URL | `https://github.com/padit69/work-well/blob/main/docs/PRIVACY_POLICY.md` |
| Terms of Use URL | `https://github.com/padit69/work-well/blob/main/docs/TERMS_OF_USE.md` |

## 5. App Privacy answers

Use these answers only after confirming that the external updater has been removed from the App Store build and that no new analytics/SDKs have been added.

| Question | Suggested answer |
|---|---|
| Does this app collect data? | No, data is not collected |
| Is data used to track users? | No |
| Is user-entered weight/profile data transmitted off device? | No |
| Are activity records transmitted off device? | No |
| Does the app use advertising or analytics SDKs? | No |
| Does the app require an account? | No |

The app stores preferences and wellness activity records locally using UserDefaults/SwiftData. Local-only data that is never transmitted is not declared as “collected” in App Store privacy labels.

Privacy reference: <https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/>

## 6. Age rating, content rights, and compliance

| Field | Suggested response |
|---|---|
| Content rights | App does not contain, show, or access third-party content |
| Made for Kids | No |
| Regulated medical device | No — general wellness reminder only |
| Sign-in required | No |
| In-App Purchases | None |
| Advertising | None |
| User-generated content | None |
| Unrestricted web access | No |
| Gambling/contests/violence/sexual content | None |
| DSA trader status | `TODO: Complete account-level declaration` |
| Availability in Vietnam | Complete the field shown by App Store Connect; WorkWell is not a game |
| Export compliance | Uses Apple-provided HTTPS only; confirm exempt/non-exempt encryption questionnaire |

Complete every question in the current App Store Connect age-rating questionnaire. Based on the present app behavior, WorkWell should qualify for the lowest applicable age tier, but App Store Connect determines the final rating.

## 7. App Review Information

### Contact

| Field | Value |
|---|---|
| First name | `TODO` |
| Last name | `TODO` |
| Email | `TODO` |
| Phone | `TODO` |

### Sign-in information

```text
Sign-in is not required. WorkWell has no user accounts.
```

### Review notes

```text
WorkWell is a general wellness reminder app for macOS. It does not provide medical advice, diagnosis, or treatment, and it does not integrate with HealthKit.

No account or purchase is required. User preferences, weight/profile values, and activity records remain locally on the Mac and are not transmitted to the developer.

On first launch, the app requests notification permission so it can deliver water, eye-rest, and movement reminders. The app's full-screen reminder can be disabled in Settings, leaving only standard macOS notifications. “Start at Login” is off unless the user explicitly enables it.

Quick review path:
1. Launch WorkWell and allow notifications.
2. Open Settings to configure work hours and reminder intervals.
3. Use the Preview controls in the Water, Eye Rest, and Movement sections to test reminder screens without waiting for an interval.
4. Open the dashboard to view local activity totals and streak information.

This App Store build does not contain an external updater. Updates are distributed only through the Mac App Store.
```

### Version release setting

Recommended for the first submission: **Manual release after approval**.

## 8. Screenshot captions

### English

1. `Healthier work habits, one break at a time`
2. `Stay on track with smart hydration reminders`
3. `Give your eyes a proper 20–20–20 break`
4. `Stand, stretch, and move throughout your day`
5. `Reminders that respect your work schedule`

### Vietnamese

1. `Thói quen làm việc khỏe hơn sau mỗi lần nghỉ`
2. `Uống đủ nước với lời nhắc thông minh`
3. `Cho mắt nghỉ đúng theo quy tắc 20–20–20`
4. `Đứng dậy và vận động trong suốt ngày làm việc`
5. `Lời nhắc tôn trọng lịch làm việc của bạn`

## 9. Privacy policy draft to publish

Publish this text at the public Privacy Policy URL and replace every `TODO` value before submission.

```text
WorkWell Privacy Policy
Effective date: July 19, 2026

WorkWell is designed to work locally on your Mac. The app does not require an account and does not collect, sell, rent, or share personal data with the developer or advertising companies.

Information stored on your Mac
WorkWell stores your reminder preferences, work schedule, optional weight/profile settings, water records, reminder activity, and streak information locally on your device. This information is used only to provide the app's features and is not transmitted to the developer.

Notifications and Start at Login
WorkWell requests macOS notification permission to deliver reminders. You can change notification access in macOS System Settings. Start at Login is optional and is enabled only when you explicitly turn it on. You can disable it at any time in WorkWell or macOS settings.

Analytics, advertising, and tracking
WorkWell does not include advertising SDKs, analytics SDKs, or cross-app tracking.

Data retention and deletion
Local data remains on your Mac until you remove it through the app, reset the app's data, or uninstall the app and its local container. The developer does not hold a server-side copy of this data.

Children
WorkWell is a general wellness utility and is not specifically directed to children. The app does not knowingly collect personal information from children.

Medical disclaimer
WorkWell provides general wellness reminders only. It does not provide medical advice, diagnosis, or treatment. Hydration estimates are general guidance and may not be appropriate for every person or medical condition.

Changes to this policy
This policy may be updated when WorkWell's features or data practices change. The effective date above will be updated when a revised policy is published.

Contact
For privacy questions or support, contact:
TODO_LEGAL_NAME
TODO_PUBLIC_SUPPORT_EMAIL
TODO_PUBLIC_SUPPORT_URL
```

## 10. Final pre-submit checklist

- [ ] External GitHub/DMG updater is absent from the App Store target.
- [ ] Release archive uses App Store distribution signing, not Developer ID/notarization.
- [ ] Effective signed entitlements contain App Sandbox and only required capabilities.
- [ ] App ID, target, archive, and App Store Connect all use `com.hihiteam.working.care`.
- [ ] Version/build are unique and match App Store Connect.
- [ ] macOS 15.0 requirement is consistent everywhere.
- [ ] Release build succeeds with Xcode 26 or later and the current macOS SDK.
- [ ] Archive validation succeeds in Organizer with no errors.
- [ ] TestFlight build installs and all reminder flows work in the sandbox.
- [ ] English and Vietnamese metadata are entered.
- [ ] At least one valid 16:10 Mac screenshot is uploaded per required localization.
- [ ] Public Privacy Policy URL works without login.
- [ ] Public Support URL shows working contact information.
- [ ] App Privacy questionnaire is published.
- [ ] Current age-rating questionnaire is completed.
- [ ] Content rights, DSA status, availability, and export compliance are completed.
- [ ] App Review contact and review notes are filled in.
- [ ] Agreements, tax, banking, price, and availability are configured as applicable.
- [ ] Release option is selected.
- [ ] Final build is added to the submission and submitted for review.

Official references:

- <https://developer.apple.com/help/app-store-connect/reference/app-information/app-information>
- <https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information>
- <https://developer.apple.com/help/app-store-connect/reference/app-information/required-localizable-and-editable-properties/>
- <https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app>
- <https://developer.apple.com/news/upcoming-requirements/>
