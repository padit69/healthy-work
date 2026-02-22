
<a href="https://unikorn.vn/p/work-well?ref=embed" target="_blank"><img src="https://unikorn.vn/api/widgets/badge/work-well?theme=light" alt="WorkWell trên Unikorn.vn" style="width: 256px; height: 64px;" width="256" height="64" /></a>

# WorkWell – Healthy Work Reminder

[![Build](https://github.com/padit69/work-well/actions/workflows/build.yml/badge.svg)](https://github.com/padit69/work-well/actions/workflows/build.yml)
[![Release](https://github.com/padit69/work-well/actions/workflows/release.yml/badge.svg)](https://github.com/padit69/work-well/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**WorkWell** (WorkWell) là ứng dụng macOS giúp bạn làm việc lành mạnh hơn bằng cách nhắc uống nước, nghỉ mắt (20–20–20) và đứng dậy vận động. Phù hợp cho dân văn phòng, lập trình viên, designer, học sinh – sinh viên.

**WorkWell** is a macOS app that reminds you to stay hydrated, rest your eyes (20–20–20 rule), and take short movement breaks—designed for desk workers, developers, designers, and students...

---

## ✨ Tính năng chính / Features

| Feature | Mô tả |
|--------|--------|
| 💧 **Nhắc uống nước** | Tính lượng nước/ngày theo cân nặng & giới tính, nhắc theo khoảng thời gian hoặc khung giờ làm việc, ghi nhận và biểu đồ theo ngày/tuần |
| 👀 **Nhắc nghỉ mắt (20–20–20)** | Mỗi 20 phút nhắc nhìn xa 6m trong 20 giây, có countdown, chế độ nhẹ không làm gián đoạn |
| 🚶 **Nhắc đứng dậy** | Nhắc vận động mỗi 30/45/60 phút, gợi ý duỗi lưng/xoay cổ/đi lại, có chế độ “đang họp” (tạm hoãn) |
| 📊 **Thống kê & streak** | Số lần uống nước, nghỉ mắt, đứng dậy; streak theo ngày và đánh giá mức độ tuân thủ |

### Cài đặt / Settings

- **Thời gian làm việc**: Giờ bắt đầu/kết thúc, nghỉ trưa; chỉ nhắc trong giờ làm việc
- **Nhắc nhở**: Bật/tắt từng loại, tần suất (15/20/30/45/60 phút), kiểu thông báo (banner/âm thanh/snooze)
- **Nước**: Cân nặng, mục tiêu/ngày, đơn vị (ml/oz), ly mặc định (200ml/250ml/custom)
- **Nghỉ mắt**: Bật/tắt 20–20–20, thời gian đếm ngược, chế độ nhẹ/tập trung
- **Giao diện**: Light/Dark mode, Tiếng Việt/English, chế độ tối giản

### Quyền & quyền riêng tư

- Chỉ yêu cầu quyền thông báo (Notification).
- Không thu thập dữ liệu nhạy cảm; dữ liệu lưu local (tuỳ chọn iCloud/Google).

---

## 📋 Yêu cầu / Requirements

- **macOS** 14.0 (Sonoma) trở lên
- **Xcode** 15+ (chỉ cần khi build từ source)

---

## 🚀 Cài đặt / Installation

### Cách 1: Tải bản phát hành (khuyến nghị)

1. Vào [Releases](https://github.com/padit69/work-well/releases).
2. Tải file **WorkWell-vX.X.X.dmg** (hoặc `.zip`) của phiên bản mới nhất.
3. Mở DMG, kéo **WorkWell.app** vào **Applications**.
4. Chạy app; lần đầu có thể cần: **System Settings → Privacy & Security** → cho phép app.

### Cách 2: Build từ source

```bash
# Clone repo
git clone https://github.com/padit69/work-well.git
cd work-well

# Build bằng script (khuyến nghị)
./scripts/test-build.sh

# Hoặc build thủ công
cd WorkWell
xcodebuild \
  -project WorkWell.xcodeproj \
  -scheme WorkWell \
  -configuration Release \
  -derivedDataPath ./build \
  build
```

App build xong nằm tại: `WorkWell/build/Build/Products/Release/WorkWell.app`.

---

## 🛠️ Tech Stack

| Thành phần | Công nghệ |
|------------|-----------|
| **Platform** | macOS (SwiftUI) |
| **Language** | Swift |
| **Storage** | Local (UserDefaults / file) |
| **Notifications** | Local Notifications |
| **CI/CD** | GitHub Actions (build, release, DMG) |

---

## 📁 Cấu trúc project / Project Structure

```
work-well/
├── WorkWell/                    # Xcode project
│   ├── WorkWell.xcodeproj
│   └── WorkWell/               # Source code (SwiftUI)
│       ├── Core/
│       ├── Features/
│       ├── Models/
│       ├── Services/
│       └── ...
├── scripts/
│   ├── test-build.sh              # Kiểm tra build nhanh
│   ├── release.sh                 # Tạo release (tag, notes)
│   └── create-dmg.sh              # Tạo file DMG
├── .github/workflows/
│   ├── build.yml                  # CI: build trên push/PR
│   ├── release.yml                # Release: build + DMG khi push tag v*
│   └── pr-check.yml               # PR checks
├── README.md
├── LICENSE
└── CONTRIBUTING.md                # Hướng dẫn đóng góp (nếu có)
```

---

## 🔐 Ký & notarize (cho maintainer)

Để bản release không bị lỗi **"damaged and can't be opened"** trên máy user, cần bật **code signing** và **notarization** trong CI. Xem hướng dẫn đầy đủ: [docs/SIGNING.md](docs/SIGNING.md).

---

## 🤝 Đóng góp / Contributing

Mọi đóng góp đều được chào đón (báo lỗi, đề xuất tính năng, pull request). Nếu bạn muốn đóng góp code:

1. **Fork** repo và tạo branch từ `main` (ví dụ: `feature/your-feature` hoặc `fix/issue-123`).
2. Đảm bảo build thành công: chạy `./scripts/test-build.sh`.
3. Tạo **Pull Request** vào `main`, mô tả rõ thay đổi và (nếu có) link issue.

Nếu repo có file **CONTRIBUTING.md**, vui lòng đọc thêm hướng dẫn chi tiết ở đó.

---

## 📄 License

Dự án này sử dụng **MIT License**. Chi tiết xem file [LICENSE](LICENSE).

---

## 🗺️ Roadmap (gợi ý)

- ⏱ Pomodoro mode
- 🧍 Nhắc tư thế ngồi
- ⌚ Apple Watch / Wear OS
- 💤 Nhắc ngủ – nghỉ ngơi

---

## 📜 Changelog

Các thay đổi đáng chú ý được ghi trong [Releases](https://github.com/padit69/work-well/releases). Phiên bản tuân theo [Semantic Versioning](https://semver.org/) (tag: `v1.0.0`, `v1.1.0`, ...).

---

**WorkWell** – Giữ sức khỏe mỗi ngày khi làm việc với máy tính. 💧👀🚶
