#!/bin/bash
# 停止 clipboard-normalizer
# 由终端 EXIT trap 调用

PID_FILE="/tmp/clipboard-normalizer.pid"

if [ -f "$PID_FILE" ]; then
    kill "$(cat "$PID_FILE")" 2>/dev/null || true
    rm -f "$PID_FILE"
    echo "[$(TZ=Asia/Shanghai date "+%Y-%m-%d %H:%M:%S +0800")] stopped" >> /tmp/clipboard-normalizer.log
fi

rm -f /tmp/clipboard-normalizer-image.png
