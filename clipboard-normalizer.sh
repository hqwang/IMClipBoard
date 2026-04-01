#!/bin/bash
# 启动 clipboard-normalizer（会话级，非 LaunchAgent）
# 由 Claude Code SessionStart hook 调用

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY="$SCRIPT_DIR/clipboard-normalizer"
PID_FILE="/tmp/clipboard-normalizer.pid"

# 如果已有实例在跑，先停掉
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    kill "$OLD_PID" 2>/dev/null || true
    rm -f "$PID_FILE"
    echo "[$(TZ=Asia/Shanghai date "+%Y-%m-%d %H:%M:%S +0800")] restarted (killed old PID $OLD_PID)" >> /tmp/clipboard-normalizer.log
fi

# 后台启动，日志追加到同一文件
"$BINARY" >> /tmp/clipboard-normalizer.log 2>&1 &
echo $! > "$PID_FILE"
