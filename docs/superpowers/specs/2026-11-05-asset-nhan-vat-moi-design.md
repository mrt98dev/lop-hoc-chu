# Spec: Bộ ảnh nhân vật mới — Cô Ngân, Học sinh, Ảnh nền

**Ngày**: 2026-11-05  
**Công cụ AI**: DALL-E 3 (ChatGPT)  
**Phong cách**: 2D flat anime illustration, Vietnamese style

---

## 1. Character Style Guide

### 1.1 Cô Ngân

Phần mở đầu cố định cho mọi prompt cô Ngân:

```
2D flat anime illustration, clean linework, vibrant colors,
Vietnamese female teacher character named Ngan, 26 years old,
long black hair worn down (or in a bun for formal outfits),
round expressive eyes with thin eyeliner, light skin tone,
small golden cat-eye glasses.
```

**Ràng buộc kỹ thuật:**
- Nền xám đồng màu `#CCCCCC` (để `tach-nen.py` tách nền)
- Full body, nhân vật chiếm 90% chiều cao khung
- Chân ở mép dưới, căn giữa ngang
- Không đổ bóng, không hiệu ứng ánh sáng phức tạp
- Output: PNG 330×560px (hoặc cao hơn rồi scale xuống)

### 1.2 Học sinh

Phần mở đầu cố định cho mọi prompt học sinh:

```
2D flat anime illustration, clean linework, vibrant colors,
Vietnamese middle school student, [male/female],
chibi proportions (head-to-body ratio approximately 1:3),
[male: navy blue school uniform shirt and dark pants |
 female: white top with blue collar, navy blue skirt or pants].
```

**Ràng buộc kỹ thuật:**
- Nền xám `#CCCCCC`
- Full body, nhân vật chiếm 90% chiều cao (ngoại trừ tư thế ngồi)
- Chân ở mép dưới
- Không vẽ tóc quá chi tiết (game tự vẽ tóc bằng SVG ở bản sau lưng)
- Output: PNG ~264×560px (nam) / ~253×560px (nữ)

---

## 2. Bộ trang phục mới: Casual Gen Z

### 2.1 Thư mục

```
nhan-vat/co-giao-ngan/casual-gen-z/   ← ảnh nguồn PNG
public/assets/nv/co-ngan/casual-gen-z/ ← webp sau tach-nen.py
```

### 2.2 Mô tả trang phục

```
Wearing lilac pastel crop hoodie with tiny "✨ cô giáo" text print on chest,
white wide-leg pants, white sneakers with pink sole.
Hair worn down with small star-shaped hair clip.
Still wearing small golden cat-eye glasses.
```

### 2.3 Danh sách 16 tư thế + prompt

Mỗi prompt = **[STYLE GUIDE cô Ngân]** + **[TRANG PHỤC casual gen z]** + **[TƯ THẾ bên dưới]** + **[TECHNICAL]**

Phần TECHNICAL cố định:
```
Full body portrait, gray solid background (#CCCCCC),
transparent-ready, centered composition,
character fills 90% of vertical space, feet at bottom edge,
no shadow, no gradient background, flat style.
```

| # | File | Tư thế (en cho DALL-E) | Dùng khi |
|---|------|------------------------|----------|
| 01 | `01-dung.png` | Standing straight, natural relaxed pose, slight smile, arms loosely at sides | Mặc định |
| 02 | `02-giang-bai.png` | Pointing at something to the left with right index finger, body slightly turned, explaining expression | Đọc đề |
| 03 | `03-chi-trai.png` | Pointing left with full arm extended, looking toward that direction, friendly face | Giới thiệu trái |
| 04 | `04-chi-phai.png` | Pointing right with full arm extended, looking toward that direction, friendly face | Giới thiệu phải |
| 05 | `05-cuoi-tuoi.png` | Big bright smile, both hands lightly clapping together at chest level, happy pose | Khen học sinh |
| 06 | `06-cuoi-che-mieng.png` | Holding a small bouquet of flowers with both hands, covering mouth with hand while smiling, slightly blushing | Nhận hoa |
| 07 | `07-vo-tay.png` | Clapping hands together above waist level, wide happy smile, celebratory | Vỗ tay cả lớp |
| 08 | `08-like.png` | Right thumb up clearly visible, slight proud smile, other hand on hip | Trả lời đúng |
| 09 | `09-nghiem-nhe.png` | Arms crossed lightly at chest, one eyebrow raised slightly, mild stern expression but still cute | Đứng phạt HS |
| 10 | `10-bat-ngo.png` | Both hands on cheeks, eyes wide open, mouth open in surprise, comically exaggerated surprise | Đố mẹo lừa |
| 11 | `11-suy-nghi.png` | One hand on chin thinking pose, eyes looking up slightly, contemplative expression | Gãi đầu thêm giờ |
| 12 | `12-nhun-vai.png` | Shrugging both shoulders, palms facing up, slightly exasperated but cute expression | Không ai đúng |
| 13 | `13-vay-chao.png` | Waving goodbye with right hand raised, warm smile, weight shifted to one side casually | Ra chơi |
| 14 | `14-co-vu.png` | Both fists raised up in cheering pose, big excited smile, leaning slightly forward | Câu vàng / quà |
| 15 | `15-chao-don.png` | Both arms open wide in welcoming gesture, warm inviting smile | Đầu tiết |
| 16 | `16-tu-tin.png` | Left hand on hip, standing confidently, calm proud smile, slight chin up | Tổng kết tiết |

### 2.4 Thay đổi code cần thiết

**`src/game/config.ts`** — thêm `'casual-gen-z'` vào mảng `GAME.outfits`:
```ts
outfits: ['trắng', 'so-mi', 'ao-dai-xanh-ngoc', 'casual-gen-z'],
```

**`src/game/GameStage.tsx`** — thêm mapping tư thế trong `OUTFIT_POSE`:
```ts
const OUTFIT_POSE: Record<string, string> = {
  // ... mapping hiện tại ...
  // Thêm nếu tên tư thế khác bộ trắng:
  // 'casual-gen-z' dùng tên giống bộ so-mi/ao-dai-xanh-ngoc
  // nên không cần thêm row mới nếu tên file đồng nhất
};
```
Kiểm tra `OUTFIT_POSE` để xác nhận tên file bộ mới khớp. Nếu dùng đúng tên `01-dung` → `16-tu-tin` như bộ sơ mi, không cần sửa.

**`tools/tach-nen.py`** — sub-folder `casual-gen-z` được xử lý tự động qua vòng lặp outfit folders (kiểm tra xem `tach-nen.py` có loop qua sub-folder không, nếu chưa thì thêm `casual-gen-z` vào danh sách xử lý).

---

## 3. Học sinh — 4 tư thế mới (09–12)

### 3.1 Thư mục

```
nhan-vat/hoc-sinh-nam/   ← thêm 09-*.png, 10-*.png, 11-*.png, 12-*.png
nhan-vat/hoc-sinh-nu/    ← như trên
public/assets/nv/nam/    ← tach-nen.py tự tạo webp + sau-*.webp
public/assets/nv/nu/     ← như trên
```

### 3.2 Tư thế 09 — Gục đầu ngủ gật

**Mô tả tư thế:**
```
Sitting at a desk, head slumped down onto folded arms on the desk,
eyes closed, sleeping or dozing off, small "zzz" near head optional.
Viewed from front-side angle. Body visible from waist up,
seat/chair visible below. Compose so feet are near bottom edge.
```

**Lưu ý**: Nhân vật ngồi → chiều cao hiển thị thấp hơn, nhưng vẫn để ảnh 560px với nhân vật bắt đầu từ giữa-dưới khung. Bản `sau-*.webp` được `tach-nen.py` tạo tự động bằng cách lật ngang + xoá đầu — với tư thế ngồi gục bàn kết quả có thể không tự nhiên; chấp nhận hoặc không dùng pose ngồi cho bản sau lưng (học sinh ngủ gật vẫn ngồi tại chỗ, không cần sau lưng).

### 3.3 Tư thế 10 — Đưa hoa lên bục tặng cô

**Mô tả tư thế:**
```
Standing, holding a small bouquet of flowers with both hands extended forward,
offering the flowers, slight bow or respectful posture, happy smile.
```

### 3.4 Tư thế 11 — Đứng phạt giơ tay

**Nam:**
```
Standing straight, one arm raised high above head (punishment pose),
other arm at side, slightly embarrassed expression but accepting.
```

**Nữ:**
```
Standing straight, one arm raised high above head (punishment pose),
other hand covering mouth, embarrassed blushing expression.
```

### 3.5 Tư thế 12 — Nhảy lên mừng

```
Jumping up joyfully, both arms raised high in a V shape or
waving excitedly, big happy grin, eyes curved upward in joy.
Feet off the ground, slight upward trajectory.
```

**Lưu ý compositing**: Nhảy → chân rời đất → padding dưới. Vẫn để nền xám đầy đủ 560px, nhân vật có thể không chạm mép dưới.

### 3.6 Thay đổi code cần thiết

**`src/game/GameStage.tsx`** — cập nhật mapping `POSE` để include tư thế mới:
```ts
// Tìm const POSE hoặc tương đương
// Thêm:
'sleeping': 'sau-09-guc-dau',   // 💤 icon → pose 09
'gift':     '10-dua-hoa',       // đưa hoa lên bục
'punished': '11-dung-phat',     // đứng phạt
'jump':     '12-nhay-mung',     // nhảy mừng
```
Kiểm tra code xử lý `💤`, tặng hoa, đứng phạt, nhảy mừng để wire đúng key.

---

## 4. Ảnh nền mới

### 4.1 Ràng buộc bắt buộc

- **Kích thước**: 941×1672px chính xác
- **Vị trí bảng đen, ghế, bàn**: giữ nguyên theo ảnh gốc `nen-lop-hoc-rong-khong-nguoi-2d.png`
- **Style**: 2D flat illustration, không có nhân vật, góc nhìn từ sau lớp nhìn lên bảng
- Output: PNG → xử lý → `public/assets/bg/*.webp`

### 4.2 Danh sách 4 ảnh nền

#### bg-1: `nen-buoi-toi.png` → `bg/lop-dem.webp`

**Dùng khi**: Live khuya (22h–5h), `GAME.bgNight`

**Prompt:**
```
2D flat anime illustration style classroom, 941x1672px, no characters,
viewed from back of classroom toward the blackboard.
Evening scene: warm yellow ceiling lights turned on, 
windows showing dark night sky with stars visible outside,
warm amber lighting creating soft glow on walls and furniture,
same layout as a typical Vietnamese school classroom,
blackboard on front wall, rows of desks and chairs, wooden floor.
Cozy evening atmosphere, slight warm color cast over the room.
Flat illustration, clean lines, no shadows, vibrant but warm palette.
```

#### bg-2: `nen-tet.png` → `bg/lop-tet.webp`

**Dùng khi**: Dịp Tết Nguyên Đán, `GAME.bgTet`

**Prompt:**
```
2D flat anime illustration style Vietnamese classroom decorated for Tet holiday,
941x1672px, no characters.
Lunar New Year decorations: red and gold color scheme,
red lanterns hanging from ceiling, yellow mai blossom branch in corner,
"CHÚC MỪNG NĂM MỚI" banner on front wall (replace normal banner),
red envelopes (phong bao lì xì) scattered decoratively,
same classroom layout but festive atmosphere.
Flat illustration, clean lines, vibrant reds and golds.
```

#### bg-3: `nen-giang-sinh.png` → `bg/lop-giang-sinh.webp`

**Dùng khi**: Dịp Giáng Sinh, `GAME.bgChristmas`

**Prompt:**
```
2D flat anime illustration style Vietnamese classroom decorated for Christmas,
941x1672px, no characters.
Christmas decorations: small Christmas tree in corner with colorful lights,
fairy lights string along the top of the blackboard,
holly wreaths on door and windows, snowflake paper cutouts hanging,
same classroom layout with festive winter theme.
Flat illustration, clean lines, red green and white color accents.
```

#### bg-4: `nen-toi-hon.png` → `bg/lop-toi.webp`

**Dùng khi**: Luân phiên xen kẽ với ảnh nền ngày, `GAME.bgDark`

**Prompt:**
```
2D flat anime illustration style Vietnamese classroom,
941x1672px, no characters, same layout as the standard daytime classroom.
Slightly darker atmosphere: overcast sky outside windows,
slightly dimmed lighting as if late afternoon or cloudy day,
same furniture and blackboard position, muted but still warm color palette.
30% darker overall tone than standard bright classroom version.
Flat illustration, clean lines.
```

### 4.3 Thay đổi code cần thiết

**`src/game/config.ts`** — thêm key bg variants:
```ts
bgVariants: {
  default: 'lop',
  night:   'lop-dem',
  tet:     'lop-tet',
  christmas: 'lop-giang-sinh',
  dark:    'lop-toi',
},
```

**`src/game/GameStage.tsx`** — đọc bg variant theo giờ hoặc config:
```ts
// Ví dụ: tự động đổi sang lop-dem khi 22h–5h
const bgKey = isNight ? 'lop-dem' : 'lop';
// <img src={`/assets/bg/${bgKey}.webp`} ...>
```

---

## 5. Quy trình tạo ảnh

### 5.1 Session DALL-E 3 (ChatGPT)

Nhóm theo **1 session = 1 bộ** để giữ nhất quán trong bộ:
- Session A: Cô Ngân casual gen z (16 tư thế)
- Session B: Học sinh nam tư thế mới (4 tư thế)
- Session C: Học sinh nữ tư thế mới (4 tư thế)
- Session D: Ảnh nền (4 ảnh)

Trong mỗi session, bắt đầu bằng tư thế đơn giản nhất (`01-dung` hoặc `standing neutral`), lưu lại, rồi dùng "edit this image" hoặc re-describe với cùng style guide để giữ nhất quán.

### 5.2 Quy trình xử lý sau khi có ảnh PNG

```bash
# 1. Đặt ảnh PNG vào thư mục nguồn:
#    nhan-vat/co-giao-ngan/casual-gen-z/01-dung.png  (v.v.)
#    nhan-vat/hoc-sinh-nam/09-guc-dau.png (v.v.)

# 2. Chạy tach-nen.py để tách nền + tạo webp:
python tools/tach-nen.py

# 3. Kiểm tra output trong public/assets/nv/
# 4. Khởi động server và xem thử ở ?view=stage&mute=1
```

### 5.3 Checklist QA mỗi ảnh

- [ ] Nền xám đều màu, không gradient hay texture → `tach-nen.py` xử lý tốt
- [ ] Nhân vật đứng căn giữa, chân gần mép dưới
- [ ] Không bị cắt đầu hoặc cắt chân
- [ ] Mode RGBA sau tach-nen (kiểm tra bằng `PIL.Image.open().mode == 'RGBA'`)
- [ ] Tư thế sau lưng (`sau-*.webp`) tóc đã bị xoá (game tự vẽ)
- [ ] Kích thước phù hợp: cô Ngân ~330×560, học sinh ~260×560, ảnh nền 941×1672

---

## 6. Tóm tắt thay đổi code

| File | Thay đổi |
|------|----------|
| `src/game/config.ts` | Thêm `'casual-gen-z'` vào `outfits`, thêm `bgVariants` |
| `src/game/GameStage.tsx` | Kiểm tra `OUTFIT_POSE`, thêm key pose mới vào `POSE` mapping, logic chọn `bgKey` theo giờ |
| `tools/tach-nen.py` | Kiểm tra xem sub-folder `casual-gen-z` có được xử lý tự động không |
