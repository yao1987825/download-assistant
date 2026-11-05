# download / songs / quark 命令契约

> 供 AI 精确调用这三个命令时查。参数以 `/usr/local/bin/` 下的真实脚本为准
> (`download` / `songs` / `quark`), 本文档与它们保持同步。

---

## download —— 搜索并下载歌曲

```
用法: download [选项] <关键词>
```

| 选项 | 含义 |
| --- | --- |
| `--list` | 只列出搜索结果, **不下载**(AI 调用时先跑这个) |
| `--index N` | 下载第 N 条搜索结果(1 起) |
| `--out DIR` | 输出目录, 默认歌曲分区(`/mnt/songdisk`) |
| `--no-quark` | 不走夸克网盘, 只用低品质直链(不需要夸克 cookie) |
| `--cookie` | 夸克 cookie(覆盖项目 `config.json` 里的配置) |
| `--project DIR` | 下载器项目目录, 默认 `~/projects/gequhai-downloader` |
| `--batch CSV` | 按歌单 CSV 批量下载(切换到 batch 模式) |
| `--gui` | 图形界面(需 PyQt6, 轻量镜像默认没装) |
| `--setup-gui` | 补装 PyQt6, 启用图形界面 |
| `--setup-playwright` | 补装 Playwright Chromium(需 root) |

### 模式

| 模式 | 触发方式 | 行为 |
| --- | --- | --- |
| single(默认) | `download "关键词"` | 搜 → 选一条 → 下载 → 归档 |
| list | `--list` | 只搜不下载, 打印候选列表 |
| batch | `--batch CSV` | 读 CSV 批量下载, 完事后自动转 mp3 |
| gui | `--gui` | 起 PyQt6 图形界面 |

### 参数顺序

选项放前放后都行(`download --list "夜曲"` 和 `download "夜曲" --list` 等价):
脚本自己扫一遍参数, 位置参数合并成关键词, 选项原样透传给 `single.py`。

### 选歌优先级(`single.py` 内部)

1. 显式 `--index N`
2. 标题与关键词**完全匹配**
3. 标题**包含**关键词
4. 交互式问用户(仅当 stdin/stdout 都是 TTY)← **AI 环境会跳过, 直接取第一条**
5. 第一条

### 落盘布局

```
<输出目录>/<歌手>/<歌名>-<歌手>.mp3      音频
<输出目录>/<歌手>/<歌名>-<歌手>.lrc      歌词(有才下)
<输出目录>/<歌手>/<歌名>-<歌手>.jpg      封面(有才下)
```

歌手目录名与文件名都过 `utils.safe_filename`, 去掉怪字符。

### 相关环境变量

| 变量 | 默认值 | 作用 |
| --- | --- | --- |
| `SONG_DIR` | `/mnt/songdisk` | 歌曲分区根目录 |
| `SINGLE_PY` | `/usr/local/lib/musictools/single.py` | 单曲下载实现 |
| `PROJ_GUI` | `~/projects/gequhai-downloader` | GUI 项目目录 |
| `PROJ_LIST` | `~/projects/gequhai-playlist-downloader` | 歌单项目目录 |
| `VENV_MUSIC` | `~/.venvs/music` | 单曲下载 venv(装 requests) |
| `VENV_GUI` | `~/.venvs/gequhai-gui` | GUI venv(装 PyQt6) |
| `VENV_LIST` | `~/.venvs/playlist` | 歌单 venv |
| `PLAYWRIGHT_BROWSERS_PATH` | `~/.cache/ms-playwright` | 浏览器安装位置 |

### 代理

下载相关命令**一律走直连**, 会显式摘掉
`http_proxy / https_proxy / all_proxy / HTTP_PROXY / HTTPS_PROXY / ALL_PROXY`。

原因: 站点/夸克/封面直连都是 200, 走 LAN 代理反而全断(站点回 403 反爬页 → 搜到 0 条,
夸克/酷我直接 SSL 失败)。登录 shell 会经 `/etc/profile.d/99-proxy.sh` 自动导出代理,
于是出现"浏览器能看、命令搜不到"。

### 依赖

| 依赖 | 路径 | 缺失时的表现 |
| --- | --- | --- |
| gequhai-downloader | `~/projects/gequhai-downloader` | "找不到项目目录" |
| playlist-downloader | `~/projects/gequhai-playlist-downloader` | 仅批量模式需要 |
| music venv | `~/.venvs/music` | "缺少 ~/.venvs/music" |
| playlist venv | `~/.venvs/playlist` | 仅批量模式需要 |
| PyQt6 | `~/.venvs/gequhai-gui` | 仅 GUI 模式需要 |

上游项目地址:
- https://github.com/Yannick-Mo/gequhai-downloader
- https://github.com/hoogrey/gequhai-playlist-downloader

`single.py` 依赖上游这几个接口, 变了就会报"项目源码的接口和本脚本对不上":
`gequhai.search_songs` / `gequhai.parse_play_page` / `gequhai.get_low_quality_url` /
`quark.download_from_quark` / `utils.load_config` / `utils.safe_filename` / `utils.download_file`。

---

## songs —— 歌曲分区管理

```
用法: songs [选项]
```

| 命令 | 行为 |
| --- | --- |
| `songs` | 列出分区内容(含歌手子目录) |
| `songs --path` | 打印分区路径 |
| `songs --reorg` | 把根目录的历史平铺文件按歌手归类 |

`songs --reorg` 的规则: 只处理根目录第一层的 `mp3/m4a/lrc/jpg/flac` 文件,
文件名必须是"歌名-歌手"这种**以最后一个 `-` 分隔**的样式(歌名自己可以带 `-`),
按最后一个 `-` 后面那段当歌手建目录。重名则跳过。

---

## quark —— 夸克网盘登录

```
用法: quark <子命令>
```

| 子命令 | 行为 |
| --- | --- |
| `quark login` | 扫码登录(纯 HTTP, 不需要浏览器/Playwright) |
| `quark status` | 检查 cookie 是否还有效、主凭证齐不齐 |
| `quark clear` | 清空 cookie |

实现在 `/usr/local/lib/musictools/quark_login.py`。
`quark login` 支持透传选项(如 `--url-only`、`--timeout`), 完整说明跑
`quark login --help`。

夸克 cookie 也可能写在下载器项目的 `config.json` 的 `quark_cookie` 字段里
(`single.py` 会读), 命令行 `--cookie` 优先级最高。

---

## 内部实现要点(改动脚本时要看)

- `single.py` 在 import 时就 `os.environ.pop()` 掉所有代理变量 —— 所以直接
  `python3 single.py "关键词"` 跑也是直连。
- 站点搜索对词序敏感: `五月天 突然好想你` → 0 条, `突然好想你 五月天` → 有结果。
  `single.py` 的 `search_with_fallback()` 会自动倒序、再逐词重试。
- 夸克分享链接在站点上做了混淆(`#`→`H`, `%`→`S` 之后 base64),
  `single.py` 会解出 `mp3_extra_url` 和 `mp3_extra_url2` 两个备用链接。
- 夸克 CDN 直链必须带新鲜的 `__puus` cookie —— 构建脚本会给上游 `quark.py`
  打补丁(`scripts/patch-quark-puus.py`), 补丁没打上会恒 412。
