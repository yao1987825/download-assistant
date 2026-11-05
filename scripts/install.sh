#!/usr/bin/env bash
#
# install.sh —— 把本技能装进 opencode 的技能目录
#
# 装完之后, opencode(以及任何认 SKILL.md 的 AI 客户端)就能按需加载这个技能。
# 镜像里已经预装过的, 重装是安全的(只覆盖 SKILL.md / references / scripts,
# .env 和 data/ 这种运行期数据不动)。
#
# 用法:
#   bash install.sh                 # 装到 ~/.config/opencode/skills/download-assistant
#   SKILLS_DIR=/somewhere bash install.sh   # 装到别处
#
set -Eeuo pipefail

SKILL_NAME="download-assistant"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${SKILLS_DIR:-${HOME}/.config/opencode/skills}"
TARGET="${SKILLS_DIR}/${SKILL_NAME}"

if [[ ! -f "${HERE}/SKILL.md" ]]; then
  echo "错误: ${HERE} 下没有 SKILL.md, 这不是一个技能目录" >&2
  exit 1
fi

mkdir -p "${TARGET}"

# SKILL.md / references / scripts 覆盖安装; 运行期数据(本技能没有)不动
for item in SKILL.md references scripts; do
  [[ -e "${HERE}/${item}" ]] || continue
  rm -rf "${TARGET:?}/${item}"
  cp -r "${HERE}/${item}" "${TARGET}/${item}"
done

# 脚本要有可执行位
if [[ -d "${TARGET}/scripts" ]]; then
  find "${TARGET}/scripts" -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
fi

cat <<EOF

已安装: ${TARGET}

下一步:
  1. 重启 opencode(或新开一个会话), 让它重新扫描技能目录
  2. 体检:  bash ${TARGET}/scripts/preflight.sh
  3. 试一把: download --list "歌名"

EOF
