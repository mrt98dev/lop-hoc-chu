# Bộ ảnh nhân vật mới — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire bộ trang phục Casual Gen Z của cô Ngân, 4 tư thế học sinh mới, và hệ thống ảnh nền động vào game — sau khi ảnh PNG đã được tạo bằng DALL-E 3.

**Architecture:** Ba lớp thay đổi độc lập: (1) `tach-nen.py` xử lý ảnh nguồn → webp; (2) `config.ts` + `index.css` khai báo outfit và bg variant; (3) `GameStage.tsx` ánh xạ pose key và vẽ đúng ảnh. Tất cả code có thể viết trước khi có ảnh; chỉ cần ảnh để test trực quan.

**Tech Stack:** Python 3 + Pillow + scipy (tach-nen.py), TypeScript + React (GameStage), Tailwind CSS v4 (index.css)

**Spec:** `docs/superpowers/specs/2026-11-05-asset-nhan-vat-moi-design.md`

## Global Constraints

- Ảnh nguồn nền xám `#CCCCCC`, `tach-nen.py` tách bằng median border + connected components (TOL = 14).
- Output ảnh nhân vật: RGBA webp, `OUT_H = 560px`, tên file gốc giữ nguyên (`.stem + '.webp'`).
- Output ảnh nền: RGB webp 941×1672, `quality=92`.
- `POSE.nam` và `POSE.nu` phải đồng bộ key (cùng key name, có thể khác file name nếu cần).
- Bộ `casual-gen-z` dùng đúng tên file `01-dung` → `16-tu-tin` (giống `so-mi`/`ao-dai-xanh-ngoc`), không cần thêm row trong `OUTFIT_POSE`.
- Học sinh có sau-* (back pose) cho mọi tư thế trừ tư thế `ngu` (ngồi gục không cần lật).
- TypeScript type phải compile sạch (`npx tsc --noEmit`).

## Review Focus

- **Tư thế `ngu` (ngồi) + make_backs**: `make_backs` sẽ chạy trên `nam/` và `nu/` sau khi thêm `09-guc-dau.webp` — ảnh ngồi gục có thể làm hỏng `neck` detection cho các sau-* của tư thế cũ. Test: chạy `tach-nen.py` với ảnh giả, kiểm tra `sau-01-dung.webp` không thay đổi so với trước (Task 1).
- **TypeScript `PoseKey` type**: `PoseKey = keyof typeof POSE.nam` — thêm key mới vào `POSE.nam` phải compile. Test: `npx tsc --noEmit` phải pass (Task 3).
- **Outfit preloading thiếu**: nếu `casual-gen-z` không được thêm vào `ALL_IMGS`, đổi outfit sẽ nháy trắng. Test: start dev server, switch outfit và xem trước (Task 2).
- **CSS variable fallback**: nếu `--bg-url` chưa được set (server render), `.stage-bg` phải dùng `lop.webp` mặc định. Dùng `var(--bg-url, url('/assets/bg/lop.webp'))` thay vì chỉ `var(--bg-url)` (Task 2).
- **`after-` file từ tach-nen.py outfit loop**: script dùng `glob('*.png')` trên sub-folder — nếu sub-folder có file `.png` nằm sâu hơn hoặc file rác, sẽ tạo webp không mong muốn. Dùng `glob('0*.png')` (giống `make_backs`) để chỉ lấy file tư thế (Task 1).

---

## Task 1: Mở rộng tach-nen.py xử lý outfit sub-folders và ảnh nền mới

**Files:**
- Modify: `tools/tach-nen.py:13` (thêm hằng số OUTFITS)
- Modify: `tools/tach-nen.py:63-85` (hàm `main()`)

**Interfaces:**
- Produces: `public/assets/nv/co-ngan/<outfit>/01-dung.webp` ... `16-tu-tin.webp` cho mỗi outfit trong `OUTFITS`
- Produces: `public/assets/bg/<stem>.webp` cho mỗi `nhan-vat/nen-*.png` ngoài `nen-lop-hoc-rong-khong-nguoi-2d.png`

**Điều kiện tiên quyết**: ảnh PNG nguồn đã có trong thư mục tương ứng. Không cần ảnh để sửa code, nhưng phải có ảnh để chạy script.

- [ ] **Step 1: Thêm hằng số `OUTFITS` vào `tools/tach-nen.py` sau dòng `CHARS`**

```python
OUTFITS = ['so-mi', 'ao-dai-xanh-ngoc', 'casual-gen-z']  # sub-folder của co-giao-ngan
```

- [ ] **Step 2: Thêm hàm `process_outfit(src_subfolder, out_subfolder)` vào `tach-nen.py`**

Signature: `def process_outfit(src: Path, out: Path) -> None`

Logic giống vòng lặp CHARS nhưng: (a) glob `0*.png` thay vì `*.png`; (b) không gọi `make_backs`; (c) crop box tính riêng cho bộ này (không dùng chung với bộ trắng).

```python
def process_outfit(src: Path, out: Path) -> None:
    files = sorted(src.glob('0*.png'))
    if not files:
        return
    imgs = [(f, np.array(Image.open(f).convert('RGB'))) for f in files]
    als = [alpha_of(a) for _, a in imgs]
    ys, xs = np.where(np.any(als, axis=0))
    box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    out.mkdir(parents=True, exist_ok=True)
    for (f, a), al in zip(imgs, als):
        im = Image.fromarray(np.dstack([a, al]), 'RGBA').crop(box)
        w = round(im.width * OUT_H / im.height)
        im.resize((w, OUT_H), Image.LANCZOS).save(out / (f.stem + '.webp'), quality=90)
    print(out.name, len(files), 'tư thế, khung', box)
```

- [ ] **Step 3: Cập nhật `main()` — gọi `process_outfit` cho mỗi outfit + xử lý bg mới**

Sau vòng lặp `CHARS` hiện tại (dòng 64-79), thêm:

```python
    # outfit sub-folders của co-giao-ngan
    ngan_src = SRC / 'co-giao-ngan'
    ngan_out = OUT / 'nv' / 'co-ngan'
    for outfit in OUTFITS:
        process_outfit(ngan_src / outfit, ngan_out / outfit)

    # ảnh nền mới: mọi nen-*.png ngoài file nền gốc
    bg_main = 'nen-lop-hoc-rong-khong-nguoi-2d.png'
    for f in sorted(SRC.glob('nen-*.png')):
        if f.name == bg_main:
            continue
        Image.open(f).convert('RGB').save(OUT / 'bg' / (f.stem + '.webp'), quality=92)
        print('bg', f.stem)
```

- [ ] **Step 4: Kiểm tra script parse sạch**

```bash
cd /Users/tuannda/Documents/lop-hoc-chu
python -m py_compile tools/tach-nen.py && echo "OK"
```

Expected: `OK`

- [ ] **Step 5: Chạy thử với ảnh thật (khi đã có PNG từ DALL-E)**

```bash
python tools/tach-nen.py
```

Expected: in ra `casual-gen-z 16 tư thế, khung (...)` và `bg nen-buoi-toi` (v.v.).  
Kiểm tra `public/assets/nv/co-ngan/casual-gen-z/01-dung.webp` tồn tại, mode RGBA, height 560.

- [ ] **Step 6: Xác nhận sau-* của học sinh không bị ảnh hưởng**

Sau khi thêm `09-guc-dau.webp` vào `nhan-vat/hoc-sinh-nam/`, chạy `tach-nen.py`, kiểm tra `sau-01-dung.webp` giống bản cũ (kích thước và nội dung không đổi). Nếu `make_backs` bị lệch neck detection do ảnh ngồi, thêm skip cho `09-guc-dau` trong `make_backs`:

```python
# trong make_backs, dòng glob:
for f in sorted(folder.glob('0*.webp')):
    if 'guc-dau' in f.name:  # tư thế ngồi không cần back pose
        continue
```

- [ ] **Step 7: Commit**

```bash
git add tools/tach-nen.py
git commit -m "feat(tools): tach-nen.py xử lý outfit sub-folders và ảnh nền mới"
```

---

## Task 2: config.ts + index.css — casual-gen-z outfit config và bg variant

**Files:**
- Modify: `src/game/config.ts:109`
- Modify: `src/game/config.ts` (thêm `bgVariants` sau `outfits`)
- Modify: `src/index.css:16`

**Interfaces:**
- Produces: `GAME.outfits` type includes `'casual-gen-z'`
- Produces: `GAME.bgVariants` mapping tên logic → tên file (không có extension)
- Produces: CSS class `.stage-bg` đọc `--bg-url` với fallback

- [ ] **Step 1: Viết failing type test cho casual-gen-z**

Mở `src/game/config.ts`, xác nhận dòng 109:
```ts
outfits: ['trang', 'so-mi', 'ao-dai-xanh-ngoc'] as const,
```
Thêm `casual-gen-z` → TypeScript phải compile.

- [ ] **Step 2: Sửa `outfits` trong config.ts dòng 109**

```ts
outfits: ['trang', 'so-mi', 'ao-dai-xanh-ngoc', 'casual-gen-z'] as const,
```

- [ ] **Step 3: Thêm `bgVariants` vào `GAME` object (ngay sau `outfits`)**

```ts
bgVariants: {
  default:    'lop',
  night:      'lop-dem',       // 22h–5h
  tet:        'lop-tet',
  christmas:  'lop-giang-sinh',
  dark:       'lop-toi',
} as const,
```

- [ ] **Step 4: Sửa `.stage-bg` trong `src/index.css`**

Dòng 16 hiện tại:
```css
background: #c8642a url('/assets/bg/lop.webp?v=goc') top center / 1080px auto no-repeat;
```

Đổi thành (dùng CSS variable với fallback):
```css
background: #c8642a var(--bg-url, url('/assets/bg/lop.webp')) top center / 1080px auto no-repeat;
```

Lưu ý: bỏ `?v=goc` (cache bust không còn cần sau khi có tên file rõ ràng).

- [ ] **Step 5: Kiểm tra TypeScript compile**

```bash
npx tsc --noEmit
```

Expected: 0 errors.

- [ ] **Step 6: Commit**

```bash
git add src/game/config.ts src/index.css
git commit -m "feat(config): casual-gen-z outfit, bgVariants config, CSS bg variable"
```

---

## Task 3: GameStage.tsx — POSE keys, preloading, studentPose, FlowerWalk, Punished, bg động

**Files:**
- Modify: `src/game/GameStage.tsx:34-37` (POSE)
- Modify: `src/game/GameStage.tsx:72-80` (ALL_IMGS)
- Modify: `src/game/GameStage.tsx:1218-1227` (studentPose)
- Modify: `src/game/GameStage.tsx:1295-1309` (seat render, nhay cho first)
- Modify: `src/game/GameStage.tsx:1379-1403` (FlowerWalk)
- Modify: `src/game/GameStage.tsx:1415-1437` (Punished)
- Modify: `src/game/GameStage.tsx` (thêm bg variant logic)

**Interfaces:**
- Consumes: `GAME.outfits` includes `'casual-gen-z'` (Task 2)
- Consumes: `GAME.bgVariants` mapping (Task 2)
- Consumes: `public/assets/nv/nam/09-guc-dau.webp` ... `12-nhay-mung.webp` (Task 1)

- [ ] **Step 1: Thêm 4 key mới vào `POSE` (dòng 34-37)**

Hiện tại:
```ts
const POSE = {
  nam: { dung: '01-dung', tay: '02-giong-tay', nghi: '03-suy-nghi', vui: '05-vui-mung', buon: '06-buon', ngac: '07-ngac-nhien', chao: '08-vay-chao' },
  nu:  { dung: '01-dung', tay: '02-giong-tay', nghi: '03-suy-nghi', vui: '05-vui-mung', buon: '06-buon', ngac: '07-ngac-nhien', chao: '08-vay-chao' },
};
```

Đổi thành:
```ts
const POSE = {
  nam: { dung: '01-dung', tay: '02-giong-tay', nghi: '03-suy-nghi', vui: '05-vui-mung', buon: '06-buon', ngac: '07-ngac-nhien', chao: '08-vay-chao',
         ngu: '09-guc-dau', hoa: '10-dua-hoa', phat: '11-dung-phat', nhay: '12-nhay-mung' },
  nu:  { dung: '01-dung', tay: '02-giong-tay', nghi: '03-suy-nghi', vui: '05-vui-mung', buon: '06-buon', ngac: '07-ngac-nhien', chao: '08-vay-chao',
         ngu: '09-guc-dau', hoa: '10-dua-hoa', phat: '11-dung-phat', nhay: '12-nhay-mung' },
};
```

- [ ] **Step 2: Chạy TypeScript compile — xác nhận PoseKey type mở rộng**

```bash
npx tsc --noEmit
```

Expected: 0 errors (PoseKey giờ bao gồm `'ngu' | 'hoa' | 'phat' | 'nhay'`).

- [ ] **Step 3: Cập nhật `ALL_IMGS` preloading (dòng 72-80)**

Phần học sinh (dòng 72-73) hiện dùng `Object.values(POSE.nam)` — sẽ tự thêm 4 file mới khi POSE được cập nhật. Không cần sửa.

Dòng 78 — thêm `'casual-gen-z'` vào array outfit:
```ts
...['so-mi', 'ao-dai-xanh-ngoc', 'casual-gen-z'].flatMap((o) => Object.values(OUTFIT_POSE).map((p) => `/assets/nv/co-ngan/${o}/${p}.webp`)),
```

Sau-* của 4 tư thế mới cũng preload: sau `Object.values(POSE.nam)`, preload thêm `sau-` cho 4 key mới. Nhưng vì `ALL_IMGS` đã map `Object.values(POSE.nam)` và bản sau-* cũng được load trong `<img src=...sau-${POSE[g][pose]}>`, preload sau-* hiện tại chưa có. Thêm sau-* preloading:

```ts
  ...Object.values(POSE.nam).map((p) => `/assets/nv/nam/sau-${p}.webp`),
  ...Object.values(POSE.nu).map((p) => `/assets/nv/nu/sau-${p}.webp`),
```

Thêm 2 dòng này ngay sau dòng hiện có `...Object.values(POSE.nu).map(...)`.

- [ ] **Step 4: Cập nhật `studentPose` (dòng 1218-1227)**

Thêm cases cho `ngu` và `nhay`:

```ts
function studentPose(s: StageView['seats'][number], v: StageView, rank: number, now: number): PoseKey {
  if (v.clapping) return 'vui';
  if (now - s.joinedAt < 3000) return 'chao';
  const asking = v.phase === 'asking';
  if (s.answered === 'right') {
    return v.correctTop[0]?.username === s.username ? 'nhay' : 'vui';       // ← nhay cho first correct
  }
  if (s.answered === 'wrong') return asking ? 'buon' : 'ngac';
  if (s.sleeping) return 'ngu';                                              // ← sau answered, trước active
  if (asking) return now - s.lastActive < 2500 ? 'tay' : 'nghi';
  if ((v.phase === 'results' || v.phase === 'praise') && rank < 3 && s.score > 0) return 'vui';
  if (now - (s.desk[s.desk.length - 1]?.at ?? 0) < 3000) return 'vui';
  return now - s.lastActive < 2500 ? 'tay' : 'dung';
}
```

Lưu ý: `ngu` đặt sau `answered` check — học sinh ngủ gật nhưng trả lời đúng vẫn hiện `vui`/`nhay` (tiết học vẫn tính điểm). Chỉ hiện `ngu` khi không có trả lời gần đây.

- [ ] **Step 5: Cập nhật `FlowerWalk` — dùng `hoa` thay `vui` (dòng ~1395)**

Dòng hiện tại:
```ts
<img src={`/assets/nv/${g}/${POSE[g].vui}.webp`} ...
```

Đổi thành:
```ts
<img src={`/assets/nv/${g}/${POSE[g].hoa}.webp`} ...
```

- [ ] **Step 6: Cập nhật `Punished` — dùng `phat` thay `tay` (dòng ~1427)**

Dòng hiện tại:
```ts
src={`/assets/nv/${g}/${POSE[g].tay}.webp`}
```

Đổi thành:
```ts
src={`/assets/nv/${g}/${POSE[g].phat}.webp`}
```

- [ ] **Step 7: Thêm bg variant logic vào `GameStage` component**

Thêm hàm helper trước `export function GameStage`:

```ts
function bgFile(now: number): string {
  const h = new Date(now).getHours();
  if (h >= 22 || h < 5) return GAME.bgVariants.night;
  return GAME.bgVariants.default;
}
```

Trong `GameStage`, trong `useEffect` (cùng chỗ preload ảnh, dòng ~94-96), thêm cập nhật CSS variable:

```ts
useEffect(() => {
  for (const src of ALL_IMGS) new Image().src = src;
  // cập nhật bg theo giờ
  const updateBg = () => {
    document.documentElement.style.setProperty('--bg-url', `url('/assets/bg/${bgFile(Date.now())}.webp')`);
  };
  updateBg();
  const t = setInterval(updateBg, 60_000); // kiểm tra mỗi phút
  return () => clearInterval(t);
}, []);
```

- [ ] **Step 8: Chạy TypeScript compile**

```bash
npx tsc --noEmit
```

Expected: 0 errors.

- [ ] **Step 9: Chạy dev server và kiểm tra visual**

```bash
npm run dev
```

Mở `http://localhost:3006/?view=stage&mute=1`, kiểm tra:
- Outfit chọn `casual-gen-z` hiện đúng ảnh cô Ngân (khi ảnh đã có)
- Học sinh bị phạt giơ tay (`phat` pose thay vì `tay`)
- Học sinh đi lên bục (`hoa` pose thay vì `vui`)
- Học sinh đúng đầu tiên nhảy (`nhay` trước khi về `vui`)
- Học sinh ngủ gật hiện tư thế gục đầu (thay vì `dung`)

- [ ] **Step 10: Commit**

```bash
git add src/game/GameStage.tsx
git commit -m "feat(stage): 4 POSE keys mới (ngu/hoa/phat/nhay), casual-gen-z preload, bg variant theo giờ"
```
