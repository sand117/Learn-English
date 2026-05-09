# CLAUDE.md — Context cho dự án Learn English

## Mục tiêu dự án

App Flutter Web (PWA) giúp người dùng học tiếng Anh bằng cách:
1. Lưu từ / cụm từ / idiom / câu khi đọc tài liệu hoặc xem video
2. Ôn tập theo thuật toán Spaced Repetition (SM-2) để không quên
3. Chạy trên iPhone/iPad qua Safari (PWA — Add to Home Screen)

## Target platform

- **Primary**: iPhone / iPad (iOS Safari PWA)
- **Development**: Flutter Web chạy trên Chrome
- **Không dùng**: Native iOS build (không có Mac), Android

## Tech stack

- **Framework**: Flutter (Web target)
- **Database**: Hive + hive_flutter (dùng IndexedDB trên web, không cần code generation)
- **Storage pattern**: Lưu item dưới dạng `Map<String, dynamic>` trong Hive box tên `'vocabulary'`, convert sang `VocabularyItem` khi đọc
- **SRS**: SM-2 algorithm trong `SrsService.processReview()`

## Kiến trúc quan trọng

### Database (Hive)
- Không dùng TypeAdapter hay code generation
- Tất cả items lưu trong một box duy nhất: `Hive.box('vocabulary')`
- Key = `item.id` (UUID v4), value = `item.toMap()`
- `StorageService` là singleton static, UI dùng `ValueListenableBuilder` để reactive update

### SRS Fields trên VocabularyItem
- `easeFactor`: double, min 1.3, default 2.5
- `interval`: int (ngày), bắt đầu = 1
- `repetitions`: int, reset về 0 khi quên
- `nextReview`: DateTime, null = chưa ôn lần nào = due ngay
- `isDueForReview`: so sánh theo ngày (không tính giờ)

### Capture từ màn hình
- Dùng `Clipboard.getData()` từ `flutter/services.dart`
- iOS Safari yêu cầu user gesture để đọc clipboard → có nút "Dán từ Clipboard" trong AddScreen
- Auto-detect type dựa theo số từ: 1 từ → word, ≤5 từ → phrase, nhiều hơn → sentence

## Quy ước code

- Không dùng `setState` trong `StorageService`, UI tự rebuild qua `ValueListenableBuilder(Hive.box('vocabulary').listenable())`
- Màu theo loại từ: word=#3F51B5, phrase=#009688, idiom=#9C27B0, sentence=#E91E63
- Rating buttons: Lại(đỏ/q=0), Khó(cam/q=3), Tốt(xanh lá/q=4), Dễ(xanh dương/q=5)
- Tất cả text UI bằng tiếng Việt

## Các file chính

| File | Vai trò |
|---|---|
| `lib/main.dart` | Khởi tạo Hive, runApp |
| `lib/models/vocabulary_item.dart` | Data model, toMap/fromMap, isDueForReview |
| `lib/services/srs_service.dart` | SM-2 algorithm, nextReviewText |
| `lib/services/storage_service.dart` | CRUD: getAll, getDueItems, save, delete |
| `lib/screens/home_screen.dart` | SliverAppBar + stats + review banner + list |
| `lib/screens/add_screen.dart` | Form thêm/sửa từ, clipboard detection |
| `lib/screens/review_screen.dart` | Flashcard với 3D flip animation |
| `lib/screens/detail_screen.dart` | Chi tiết, edit, delete, toggle mastered |
| `lib/widgets/vocabulary_card.dart` | Card item trong danh sách |
| `web/index.html` | PWA meta tags iOS Safari |
| `web/manifest.json` | PWA manifest |

## Tính năng chưa có (có thể thêm sau)

- [ ] Push notification nhắc ôn tập hàng ngày (Web Push API)
- [ ] Export/import data (JSON)
- [ ] Thống kê chi tiết (biểu đồ tiến độ)
- [ ] Dark mode
- [ ] Share Extension iOS (cần native build)
- [ ] Text-to-speech phát âm từ
- [ ] Tích hợp từ điển API (Oxford, Merriam-Webster)
