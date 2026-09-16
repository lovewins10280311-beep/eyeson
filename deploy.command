#!/bin/bash
# eyes on 一键部署脚本（双击或终端运行均可）
# 用法: bash deploy.command "本次改动说明"
# 链路: eyes on.html -> index.html -> git push(SSH 免 Token) -> Cloudflare 自动部署 eyeson-me.pages.dev
# 与 money / 追文记 deploy.command 同源，仅路径/产物名/站点不同。
set -e

BASE="/Users/mumu/WorkBuddy/eyes"
SRC="$BASE/eyes on.html"
DEPLOYED="$BASE/index.html"
BACKUP_DIR="$BASE/backups"

# 0) 无变更则跳过（主文件需与已部署版本不同才算有改动）
SRC_MD5=$(md5 -q "$SRC")
CUR_MD5=$(md5 -q "$DEPLOYED" 2>/dev/null || echo "")
if [ "$SRC_MD5" = "$CUR_MD5" ]; then
  echo "▶ 主文件与已部署版本一致，无变更，跳过。"
  exit 0
fi

# 1) 推送前自动备份旧版
mkdir -p "$BACKUP_DIR"
TS=$(date +%Y%m%d_%H%M%S)
[ -f "$DEPLOYED" ] && cp "$DEPLOYED" "$BACKUP_DIR/eyeson_${TS}.html"
echo "▶ 已备份旧版 → backups/eyeson_${TS}.html"
ls -1t "$BACKUP_DIR"/eyeson_*.html 2>/dev/null | tail -n +31 | xargs rm -f 2>/dev/null || true

# 2) 同步主文件到部署入口
cp "$SRC" "$DEPLOYED"
echo "▶ 已同步 eyes on.html → index.html"

# 3) MD5 校验
MAIN_MD5=$(md5 -q "$SRC")
DEP_MD5=$(md5 -q "$DEPLOYED")
if [ "$MAIN_MD5" = "$DEP_MD5" ]; then
  echo "  ✓ MD5 一致 ($MAIN_MD5)"
else
  echo "  ✗ MD5 不一致，终止推送。"
  exit 1
fi

# 4) 提交并推送（触发 Cloudflare 自动部署）
cd "$BASE"
git add index.html
git commit -m "${1:-更新 eyes on}" || echo "  (无新提交)"
git push origin main

echo "✅ 已推送！Cloudflare 正在自动部署到 eyeson-me.pages.dev（硬刷新即可见）"
echo "   如需回滚: cp \"$BACKUP_DIR/eyeson_${TS}.html\" \"$DEPLOYED\" && git add index.html && git commit -m '回滚到 ${TS}' && git push"
echo "▶ 等待 Cloudflare 重新部署(约 8 秒)后打开验收页面…"
sleep 8
open "https://eyeson-me.pages.dev" || true
echo "   已打开 eyeson-me.pages.dev，若看到旧版请 Cmd+Shift+R 硬刷新。"

if [ -t 0 ]; then
  echo ""
  echo "按回车键关闭窗口…"
  read -r
fi
