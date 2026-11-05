---
name: download-assistant
description: 搜索并下载歌曲(单曲/歌单批量)、管理歌曲分区、登录夸克网盘拿高音质 —— 配套 `download` / `songs` / `quark` 三个命令。Use when the user asks 下载歌曲、下歌、下载歌单、批量下载、搜歌、找歌、歌曲下载失败/搜不到歌、夸克登录/夸克cookie/网盘登录、歌曲分区/歌曲管理/按歌手归类, or asks to download music files, download a playlist, or fix a failed song download on this toolbox image.
---

# 歌曲下载与歌曲分区管理

这台机器是 Omarchy 便携工具箱 U 盘,音乐下载这块已经拆成**三个独立命令**
(一个命令一件事):

| 命令 | 干什么 | 什么时候用 |
| --- | --- | --- |
| `download` | 搜索并下载歌曲(单曲 / 歌单批量 / 图形界面) | 用户要"下歌" |
| `songs` | 歌曲分区管理(列出 / 按歌手归类 / 打印路径) | 用户问"我有哪些歌/歌在哪" |
| `quark` | 夸克网盘扫码登录(纯 HTTP, 不要浏览器) | 下载要拿高音质前 |

> 播放(`play`)不在本技能范围内 —— 那是另一件事, 用户说"放首歌"时直接用 `play` 命令。

---

## 一、下载一首歌(最常用)

**关键词是"歌名 + 歌手"**, 中文直接写, 不用加引号也能被拆开合并:

```bash
download "周杰伦 夜曲"          # 搜索并下载最佳匹配 ★最常用
```

下载流程内部会先搜站点 → 选一条 → 优先走夸克网盘转存(高音质) → 失败再退低品质直链 →
自动按 `<歌手>/<歌名>-<歌手>.mp3` 归档, 歌词 `.lrc` 和封面 `.jpg` 落在同一目录。

### ⚠️ AI 调用时不要用交互式选歌

`download` 在"没有完全匹配的结果"时会**弹提示要你输编号**, 在非交互环境里这会挂住。
所以分两步走,永远先看候选再点名:

```bash
download --list "夜曲"           # 第一步: 只列候选, 不下载
download --index 2 "夜曲"        # 第二步: 明确下载第 2 条
```

`--index N` 的优先级最高, 压过标题完全匹配。所以**列出来的候选里挑对了再下载**,
不要下载完才发现选错歌再回头删。

选歌时看输出里的 `标题 - 歌手` 两栏, 别只看标题。

---

## 二、下载歌单(批量)

```bash
download --batch playlist.csv    # 按歌单 CSV 批量下载
```

- CSV 路径可以是相对路径(相对 `~/projects/gequhai-playlist-downloader`)或绝对路径;
- CSV 的列名要跟上游 `gequhai-playlist-downloader` 一致 —— **不确定就先看样例**:
  ```bash
  head -3 ~/projects/gequhai-playlist-downloader/*.csv 2>/dev/null
  ls ~/projects/gequhai-playlist-downloader/
  ```
- 批量跑完会自动把 `aac/acc` 转成 `mp3`。
- 批量很慢(每首都要走一次搜索+转存), **别在对话里干等**, 跑完再汇报。

---

## 三、夸克网盘(高音质的前提)

夸克转存出来的是高音质; 没有 cookie 只能退低品质直链, 而站点对直链接口限流,
大概率 403 失败。**所以下载前先看状态**:

```bash
quark status       # cookie 还在不在、主凭证齐不齐
quark login        # 扫码登录(纯 HTTP, 不需要浏览器, 也不需要 Playwright)
quark clear        # 清空 cookie(登录态乱掉时用)
```

`quark login` 会输出二维码, 把它展示给用户扫。扫完确认状态:

```bash
quark status
```

### 登录不上的常见原因

| 现象 | 原因 / 怎么办 |
| --- | --- |
| 二维码过期 | 重新跑 `quark login`, 换一个二维码 |
| 扫码后状态还是"未登录" | cookie 没落盘: 检查 `~/.config/music-shell` 目录可写 |
| `quark status` 说 cookie 过期 | `quark login` 重新扫一次 |

---

## 四、歌曲分区管理

```bash
songs              # 列出已下载的歌曲(含歌手子目录)
songs --path       # 打印歌曲分区路径(默认 /mnt/songdisk)
songs --reorg      # 把根目录的历史平铺文件按歌手归类
```

分区根目录 = `/mnt/songdisk`(可用环境变量 `SONG_DIR` 覆盖)。

---

## 五、标准作业流程(照着做)

用户说"帮我下载周杰伦的夜曲"时:

1. **查环境** — `bash <技能目录>/scripts/preflight.sh`
   确认歌曲分区在、夸克 cookie 在、venv 在。任一项红就先修,别急着下载。
2. **列候选** — `download --list "周杰伦 夜曲"`, 把候选列给用户看。
3. **下载** — 明确哪一条 → `download --index N "周杰伦 夜曲"`。
4. **确认落盘** — 输出里会打印 `音频: /mnt/songdisk/<歌手>/<歌名>-<歌手>.mp3`。
   必要时 `ls -lh` 复核文件大小(几十 KB 说明是低品质直链,几 MB 才是正常音质)。
5. **汇报** — 见下一节。

---

## 六、汇报给用户时

- 说清楚**文件落在哪个绝对路径**(带文件名), 不要只说"下载好了";
- 说清楚**音质来源**:夸克转存 = 高音质,直链 = 低品质(直链文件通常只有几十 KB);
- 顺便告诉用户歌词 `.lrc` 和封面 `.jpg` 也一起下载了(同一个目录);
- 下载失败就**直接给原因 + 给一条能抄的修复命令**, 不要只说"失败了"。

---

## 七、会遇到的情况(排错)

| 现象 | 原因 / 怎么办 |
| --- | --- |
| "歌曲分区目录不存在" | U 盘没按 DD 模式写入: 用 Rufus 重新以 **DD 模式** 写 |
| "歌曲分区不可写" | 文件系统属主被重置: `sudo usb-grow.sh --fix-mount` 或 `sudo chown 1000:1000 /mnt/songdisk` |
| "命令跑起来没反应" | 分区没挂上(同上, 分区预检会先 auto mount); 或"当前不是挂载点"警告后仍写不进去 |
| 搜不到歌 / 搜到 0 条 | 站点搜索**对词序敏感**: `download --list "夜曲"` 单关键词先试, 或用 `歌手 歌名` 顺序(脚本会自动倒序/拆词重试) |
| 下载报 403 / 直链失败 | 基本是**没有夸克 cookie**, 或 cookie 过期: `quark login` 后重下 |
| 夸克转存报 412 | 夸克 CDN 需要新鲜 `__puus` cookie, 重新 `quark login` |
| 报"导入项目模块失败" | `~/projects/gequhai-downloader` 不存在或没装依赖: `~/.venvs/music/bin/pip install requests` |
| 报"项目源码的接口和本脚本对不上" | 上游仓库改了接口: `cd ~/projects/gequhai-downloader && git pull`, 再按上游 README 对一下接口名 |
| 浏览器能打开站点但命令搜不到 | 代理问题 —— 下载命令会自动摘掉 `http_proxy` 等环境变量; 若仍异常, `proxy off` 再试 |
| `download --gui` 报未安装 | 轻量镜像不含 PyQt6: `download --setup-gui` |

更细的说明见 `references/troubleshooting.md`,命令的完整参数见 `references/download_cli.md`。

---

## 八、边界与版权

- 本技能只做**个人学习/离线欣赏**用途;下载的音频著作权归原权利人所有,
  不要用于公开分发或商业用途。
- 不要动: 用户的歌曲分区内容、`~/projects` 下的下载器项目、夸克登录态
  (`~/.config/music-shell`、cookie 文件) —— 删了要重新登录/重新 clone。
- 删除用户已下载的歌曲前**先跟用户确认**, 那是用户的数据。
