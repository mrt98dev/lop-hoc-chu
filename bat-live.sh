#!/bin/bash
cd "$(dirname "$0")"

if [ ! -d node_modules ]; then
  echo "Lần đầu chạy: đang cài thư viện, đợi 1-2 phút..."
  npm install
fi

echo "Đang bật game... Nhấn Ctrl+C để tắt game."
echo "Link cho TikTok LIVE Studio: http://lvh.me:3006/?view=stage  (1080 x 1920)"
echo "Báo cáo sau buổi live: http://localhost:3006/bao-cao"

export LIVE_MODE=1
export PORT=3006

# Mở trình duyệt sau 8 giây
(sleep 8 && open http://localhost:3006) &

# Treo live cả ngày: server bị tắt thì tự bật lại sau 5 giây
while true; do
  npm run dev
  echo ""
  echo "[$(date)] Server bị tắt, tự bật lại sau 5 giây... (nhấn Ctrl+C để tắt hẳn)"
  sleep 5
done
