# Learn English — Ứng dụng học từ vựng với Spaced Repetition

Ứng dụng Flutter Web (PWA) giúp lưu và ôn luyện từ vựng tiếng Anh theo thuật toán SM-2 (Spaced Repetition), chạy trên iPhone/iPad qua Safari.

## Tính năng

- **Lưu từ nhanh** — Dán từ clipboard, chọn loại (Từ / Cụm từ / Idiom / Câu), điền nghĩa và ví dụ
- **Ôn tập thông minh** — Flashcard lật tay, tự đánh giá mức độ nhớ (Lại / Khó / Tốt / Dễ)
- **Spaced Repetition (SM-2)** — App tự tính ngày ôn tiếp theo, từ khó ôn thường hơn, từ dễ giãn dần
- **Đánh dấu đã thuộc** — Ẩn từ khỏi hàng đợi ôn tập khi đã thành thạo
- **PWA trên iPhone** — Cài như app thật qua Safari → Share → Add to Home Screen

## Cấu trúc dự án

```
lib/
├── main.dart                      # Entry point, khởi tạo Hive DB
├── models/
│   └── vocabulary_item.dart       # Data model + SM-2 fields
├── services/
│   ├── srs_service.dart           # Thuật toán SM-2
│   └── storage_service.dart       # CRUD với Hive (IndexedDB trên web)
├── screens/
│   ├── home_screen.dart           # Danh sách từ + thống kê + tìm kiếm
│   ├── add_screen.dart            # Thêm / sửa từ, detect clipboard
│   ├── review_screen.dart         # Flashcard ôn tập với animation lật
│   └── detail_screen.dart         # Chi tiết từ, toggle mastered, xoá
└── widgets/
    └── vocabulary_card.dart       # Card component dùng trong danh sách
web/
├── index.html                     # PWA meta tags cho iOS Safari
└── manifest.json                  # PWA manifest (icon, theme, standalone)
```

## Data Model

| Field | Kiểu | Mô tả |
|---|---|---|
| `content` | String | Từ / cụm từ / câu cần lưu |
| `type` | String | word / phrase / idiom / sentence |
| `meaning` | String | Nghĩa tiếng Việt hoặc Anh |
| `example` | String | Ví dụ sử dụng |
| `videoLink` | String | Link YouTube hoặc video |
| `source` | String | Tên tài liệu / website / video |
| `easeFactor` | double | Hệ số khó (SM-2, min 1.3, default 2.5) |
| `interval` | int | Số ngày đến lần ôn tiếp theo |
| `repetitions` | int | Số lần đã ôn thành công |
| `nextReview` | DateTime | Ngày ôn tiếp theo |
| `mastered` | bool | Đã thuộc, ẩn khỏi queue |

## Thuật toán SM-2

Sau mỗi lần ôn, người dùng đánh giá 1 trong 4 mức:

| Nút | Quality | Kết quả |
|---|---|---|
| Lại | 0 | Reset, ôn lại ngày mai |
| Khó | 3 | Interval tăng chậm |
| Tốt | 4 | Interval tăng bình thường |
| Dễ | 5 | Interval tăng nhanh, easeFactor tăng |

## Cài đặt & Chạy

```bash
# Cài dependencies
flutter pub get

# Chạy trên Chrome (development)
flutter run -d chrome

# Build PWA (production)
flutter build web --release

# Deploy lên Firebase Hosting
firebase deploy
```

## Yêu cầu

- Flutter SDK >= 3.3.0
- Chrome (để test)
- Firebase CLI (để deploy)

## Deploy lên iPhone

1. `flutter build web --release`
2. Deploy thư mục `build/web/` lên Firebase Hosting (hoặc Netlify, Vercel)
3. Mở link trên Safari iPhone
4. Nhấn **Share → Add to Home Screen**
