# download-assistant

把 Omarchy 便携工具箱 U 盘上的**歌曲下载**能力封装成一个 AI 技能(Skill)。

模型加载这个技能后,就知道该敲哪条命令、参数怎么传、失败了怎么修 ——
不用每次都现查脚本。

> 只管**下载**。播放(`play`)是另一件事,不在本技能范围内。

## 它覆盖什么

| 能力 | 底层命令 |
| --- | --- |
| 搜索并下载单曲 | `download "周杰伦 夜曲"` |
| 只看候选、不下载 | `download --list "夜曲"` |
| 精确下载第 N 条 | `download --index 2 "夜曲"` |
| 按歌单批量下载 | `download --batch playlist.csv` |
| 夸克网盘扫码登录(高音质) | `quark login` / `quark status` / `quark clear` |
| 歌曲分区管理 / 按歌手归类 | `songs` / `songs --path` / `songs --reorg` |

## 前置条件

这台技能是给 **Omarchy 便携工具箱 U 盘镜像**用的,依赖镜像里已经装好的东西:

- `/usr/local/bin/` 下的 `download` / `songs` / `quark` 三个命令
- `~/projects/gequhai-downloader`(单曲下载器项目)
- `~/projects/gequhai-playlist-downloader`(歌单下载器项目,批量时才需要)
- `~/.venvs/music` / `~/.venvs/playlist` Python venv
- 歌曲分区 `/mnt/songdisk` 已挂载且可写

先跑一次体检:

```bash
bash scripts/preflight.sh
```

它会逐项检查并给出可直接抄的修复命令。退出码:`0` 全部就绪 / `1` 有必须修的 / `2` 能用但有降级项。

## 安装

```bash
git clone https://github.com/<你的账号>/download-assistant.git
cd download-assistant
bash scripts/install.sh
```

装到 `~/.config/opencode/skills/download-assistant/`,重启 opencode 后即可被自动发现。

镜像里已经预装过的话,重装是安全的(只覆盖 `SKILL.md` / `references` / `scripts`)。

## 目录结构

```
download-assistant/
├── SKILL.md                        # 技能本体: 入口, 模型主要读这个
├── references/
│   ├── download_cli.md             # 三个命令的完整参数/环境变量/依赖契约
│   └── troubleshooting.md          # 现象 → 原因 → 修复, 按坑逐条排
├── scripts/
│   ├── preflight.sh                # 环境体检
│   └── install.sh                  # 安装到 opencode 技能目录
└── README.md
```

## 给 AI 的关键约定

1. **先 `--list` 再 `--index`**。`download` 在没有完全匹配时会弹交互提示要编号,
   非交互环境会挂住 —— 永远分两步走。
2. **先体检再下载**。分区没挂、cookie 过期、venv 缺失,报错信息都指向别处,
   容易白折腾。
3. **汇报要给绝对路径和音质来源**(夸克转存 = 高音质,直链 = 低品质)。
4. **删用户已下载的歌曲、清 cookie、重建 venv 之前先问用户**。

## 版权

本技能只做个人学习/离线欣赏用途。下载到的音频著作权归原权利人所有,
请勿公开分发或商业使用。
