#!/usr/bin/env bash
#
# preflight.sh —— 下载功能环境体检
#
# 干什么:
#   下载歌曲要同时满足好几件事: 命令在不在、歌曲分区挂没挂、能不能写、
#   下载器项目 clone 了没、venv 建了没、夸克 cookie 还有效没。
#   任何一环掉了, 下载都会失败, 而且报错信息经常指向别的地方。
#   这个脚本一次把全部状态列出来, 并给出可以直接抄的修复命令。
#
# 用法:
#   bash preflight.sh              # 体检并打印报告
#   bash preflight.sh --fix-hints  # 同上(默认就带修复提示, 这个开关只为兼容)
#
# 退出码:
#   0 = 全部就绪
#   1 = 有必须修的问题(缺命令/分区不可写/缺依赖)
#   2 = 能用但有降级项(例如没夸克 cookie, 只能下低品质直链)
#
set -uo pipefail

SONG_DIR="${SONG_DIR:-/mnt/songdisk}"
HOME_DIR="${HOME:-/home/user}"
VENV_MUSIC="${VENV_MUSIC:-${HOME_DIR}/.venvs/music}"
VENV_LIST="${VENV_LIST:-${HOME_DIR}/.venvs/playlist}"
VENV_GUI="${VENV_GUI:-${HOME_DIR}/.venvs/gequhai-gui}"
PROJ_SINGLE="${PROJ_SINGLE:-${HOME_DIR}/projects/gequhai-downloader}"
PROJ_LIST="${PROJ_LIST:-${HOME_DIR}/projects/gequhai-playlist-downloader}"

G=$'\033[1;32m'; R=$'\033[1;31m'; Y=$'\033[1;33m'; B=$'\033[1;34m'; D=$'\033[2;37m'; N=$'\033[0m'

problems=0
warnings=0

ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$1"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$1"; warnings=$((warnings + 1)); }
bad()  { printf '  %s✗%s %s\n' "$R" "$N" "$1"; problems=$((problems + 1)); }

echo
echo "== 1. 命令 =="
for c in download songs quark; do
  if command -v "$c" >/dev/null 2>&1; then
    ok "$c  ($(command -v "$c"))"
  else
    bad "$c  没装 —— 镜像装坏了, 或 PATH 里没有 /usr/local/bin"
  fi
done
# play 不在这个技能范围内, 但顺手看一眼, 免得用户问播放时才发现没有
command -v play >/dev/null 2>&1 && ok "play  (播放, 不属于本技能)" \
                                || warn "play  没装(不影响下载)"

echo
echo "== 2. 歌曲分区 (${SONG_DIR}) =="
if [[ ! -d "$SONG_DIR" ]]; then
  bad "目录不存在 —— U 盘可能不是用 Rufus 的 DD 模式写的, 重写一次"
elif ! mountpoint -q "$SONG_DIR" 2>/dev/null; then
  warn "不是挂载点 —— 先试: sudo mount ${SONG_DIR}"
  if command -v mount >/dev/null 2>&1 && sudo -n mount "$SONG_DIR" 2>/dev/null; then
    ok "已自动挂载"
  fi
fi
if [[ -d "$SONG_DIR" ]]; then
  if [[ -w "$SONG_DIR" ]]; then
    ok "可写"
  else
    bad "不可写 —— 修: sudo usb-grow.sh --fix-mount  或  sudo chown 1000:1000 ${SONG_DIR}"
  fi
  _free="$(df -h "$SONG_DIR" 2>/dev/null | awk 'NR==2 {print $4}')"
  [[ -n "${_free:-}" ]] && ok "剩余空间 ${_free}"
fi

echo
echo "== 3. 下载器项目 =="
for d in "$PROJ_SINGLE" "$PROJ_LIST"; do
  if [[ -d "$d" ]]; then
    ok "$d"
  else
    warn "$d 不存在 —— 需要批量下载时才用得上"
  fi
done

echo
echo "== 4. Python 虚拟环境 =="
if [[ -x "${VENV_MUSIC}/bin/python" ]]; then
  ok "${VENV_MUSIC}"
  if "${VENV_MUSIC}/bin/python" -c 'import requests' 2>/dev/null; then
    ok "requests 已装"
  else
    bad "requests 没装 —— 修: ${VENV_MUSIC}/bin/pip install requests"
  fi
else
  bad "${VENV_MUSIC} 不存在 —— 修: python3 -m venv ${VENV_MUSIC} && ${VENV_MUSIC}/bin/pip install requests"
fi
[[ -x "${VENV_LIST}/bin/python" ]] && ok "${VENV_LIST}" \
  || warn "${VENV_LIST} 不存在(只有批量下载需要)"
[[ -x "${VENV_GUI}/bin/python" ]] && ok "${VENV_GUI}" \
  || warn "${VENV_GUI} 不存在(只有 --gui 需要)"

echo
echo "== 5. 夸克网盘(高音质来源) =="
if command -v quark >/dev/null 2>&1; then
  if _qs="$(quark status 2>&1)"; then
    printf '%s\n' "$_qs" | sed 's/^/    /'
    if printf '%s' "$_qs" | grep -qiE '未登录|过期|失效|not.*logged|no cookie'; then
      warn "夸克没登录 —— 只能走低品质直链(容易被 403 限流): 跑 quark login 扫码"
    else
      ok "夸克状态正常"
    fi
  else
    warn "quark status 执行失败(上面是它的输出)"
  fi
else
  warn "quark 命令没装"
fi

echo
echo "== 结论 =="
if [[ $problems -gt 0 ]]; then
  printf '%s有 %d 项必须修的问题%s(上面每条都给了可直接抄的修复命令)\n' "$R" "$problems" "$N"
  exit 1
elif [[ $warnings -gt 0 ]]; then
  printf '%s可以下载, 但有 %d 项降级/提示项%s\n' "$Y" "$warnings" "$N"
  exit 2
else
  printf '%s全部就绪, 可以直接: download --list "歌名"%s\n' "$G" "$N"
  exit 0
fi
