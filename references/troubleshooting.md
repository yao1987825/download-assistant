# 歌曲下载排错详解

> 按"现象 → 原因 → 怎么办"组织。每条都是这台镜像上真实踩过的坑。

---

## 1. 歌曲分区相关

### "错误: 歌曲分区目录不存在: /mnt/songdisk"

**原因**: U 盘没有按正确方式写入镜像。Rufus 必须选 **DD 模式**(不是 ISO 模式),
否则分区表布局跟镜像对不上。

**怎么办**: 重新用 Rufus 以 DD 模式写盘; 或确认是不是换了个 U 盘/换了个口。

### "警告: /mnt/songdisk 当前不是挂载点"

**原因**: 分区目录在,但没挂上。

**怎么办**: 脚本会先试 `sudo mount /mnt/songdisk`(免密 sudo,一般直接成)。
不行就手动:

```bash
sudo mount /mnt/songdisk
mountpoint -q /mnt/songdisk && echo "已挂载"
```

### "错误: 歌曲分区不可写: /mnt/songdisk"

**原因**: resize2fs 补完文件系统后,文件系统根 inode 属主会被重置成 `root:root`
(2026-10-31 真机踩到)。症状是"命令跑起来没反应"——写不进去,也不报错。

**办法**:

```bash
sudo usb-grow.sh --fix-mount
# 或者
sudo chown 1000:1000 /mnt/songdisk
```

修完再跑 `touch /mnt/songdisk/.probe && rm /mnt/songdisk/.probe` 验证可写。

### 写进去的东西重启就没了

**原因**: 落在了系统临时目录(比如 `/tmp`),不是歌曲分区。

**怎么办**: 下载时用 `--out` 指定歌曲分区或 `~/` 下的目录。

---

## 2. 搜索类

### 搜不到歌 / "没有搜到「xxx」"

**原因**: 站点搜索对**词序**敏感。`五月天 突然好想你` → 0 条,
`突然好想你 五月天` → 有结果。

**怎么办**:

```bash
download --list "夜曲"           # 只给歌名, 成功率最高
download --list "突然好想你 五月天"  # 歌手在前
```

`single.py` 的 `search_with_fallback()` 已经会自动倒序、逐词重试,但仍可能全空 ——
此时换关键词或换歌名拼写。

### 搜到的是翻唱 / 别的版本

**原因**: 站点收录很多版本,排序不一定是你要的那个。

**办法**: `download --list` 看全部候选 → `download --index N` 精确点名。
下载完看输出里的 `选中: <标题> - <歌手>` 确认是同一首。

### 浏览器能打开站点,命令却搜不到

**原因**: 代理。登录 shell 会经 `/etc/profile.d/99-proxy.sh` 自动导出 `http_proxy`,
而站点/夸克/封面走代理会全断(站点回 403 反爬页 → 0 条,夸克/酷我 SSL 失败)。

**怎么办**: 下载命令本身会摘代理变量,不用管。若仍异常:

```bash
proxy status
proxy off
```

摘代理只影响下载类命令,`git` / `pip` 这些真需要代理的不受影响。

---

## 3. 夸克 / 音质

### 下载报"夸克转存与低品质直链都不可用"

**原因**: 基本是**没有夸克 cookie**。站点目前把低品质直链接口限流了(403)。

**办法**:

```bash
quark login      # 扫码
quark status     # 确认状态正常
download --index 1 "歌名 歌手"   # 重下
```

### 夸克转存报 412

**原因**: 夸克 CDN 直链必须带新鲜的 `__puus` cookie。上游 `gequhai-downloader/quark.py`
需要打补丁(构建脚本里的 `scripts/patch-quark-puus.py` 会打)。

**办法**: 先 `quark login` 重新扫码换新 cookie;还不行就确认构建时补丁打上了:

```bash
grep -c "_refresh_puus" ~/projects/gequhai-downloader/quark.py
```

### 扫了码还是"未登录"

**原因**: cookie 没落盘,或者 `~/.config/music-shell` 目录不可写。

**办法**:

```bash
ls -ld ~/.config/music-shell
quark clear && quark login   # 清干净重来
```

### 下载出来的 mp3 只有几十 KB

**原因**: 走的是低品质直链,不是夸克转存。

**办法**: 配好夸克 cookie 后重新下载,正常音质应该是几 MB。

### `quark login` 一直失败

**原因**: 纯 HTTP 扫码需要能连通夸克域名;代理状态下可能被拦。

**办法**: `proxy off` 再试;或换网络环境。

---

## 4. 环境 / 依赖

### "错误: 缺少 ~/.venvs/music"

**原因**: 单曲下载的 Python venv 没建(轻量镜像可能跳过预装)。

**办法**:

```bash
python3 -m venv ~/.venvs/music
~/.venvs/music/bin/pip install requests
```

没有 python3 就先 `sudo pacman -S --needed python python-pip`。

### "错误: 导入项目模块失败"

**原因**: `~/projects/gequhai-downloader` 不存在,或 venv 里没装 requests。

**办法**:

```bash
ls ~/projects/gequhai-downloader
# 没有就 clone
git clone --depth 1 https://github.com/Yannick-Mo/gequhai-downloader.git ~/projects/gequhai-downloader
~/.venvs/music/bin/pip install requests
```

### "项目源码的接口和本脚本对不上, 缺少: ..."

**原因**: 上游仓库改了接口名。

**办法**:

```bash
cd ~/projects/gequhai-downloader && git pull
```

然后按上游 README 对一下接口名(要的是 `search_songs` / `parse_play_page` /
`get_low_quality_url` / `download_from_quark` / `load_config` / `safe_filename` /
`download_file`)。改上游之前先想清楚,这个 venv 里还有 GUI 共用。

### `download --gui` 说未安装

**原因**: 轻量镜像默认不含 PyQt6。

**办法**: `download --setup-gui`(会建 `~/.venvs/gequhai-gui` 并装 PyQt6 requests)。

### `download --setup-playwright` 说要 root

**原因**: 要装 Chromium 的系统依赖。

**办法**: `sudo download --setup-playwright`。
注意 Arch 上**没有** `playwright install --with-deps`(那条路走 apt),
系统依赖用 pacman 单独装,浏览器本体再 `playwright install chromium`。

---

## 5. 批量下载

### `--batch` 说找不到项目目录

**原因**: `~/projects/gequhai-playlist-downloader` 没 clone。

**办法**:

```bash
git clone --depth 1 https://github.com/hoogrey/gequhai-playlist-downloader.git \
  ~/projects/gequhai-playlist-downloader
python3 -m venv ~/.venvs/playlist
~/.venvs/playlist/bin/pip install -r ~/projects/gequhai-playlist-downloader/requirements.txt
```

### `--batch` 找不到 CSV

**原因**: CSV 是相对 `~/projects/gequhai-playlist-downloader` 解析的。

**办法**: 传绝对路径,例如 `download --batch ~/playlists/我的歌单.csv`。

### CSV 解析出来全是空

**原因**: 表头跟上游期望的列名不一致。

**办法**: 看上游样例 —— `head -3 ~/projects/gequhai-playlist-downloader/*.csv`,
或读它的 README。

### 批量跑到一半停了

**原因**: 夸克 cookie 过期,后续转存全失败。

**办法**: `quark status` → `quark login` → 重跑 `--batch`。
批量是按歌逐首处理的,已下好的不会重复浪费(站点侧去重靠文件名,注意可能覆盖)。

---

## 6. 什么时候该停下来问用户

- 要删用户已下载的歌曲 / 覆盖已有文件 —— 先确认;
- 要 `quark clear`(等于把用户的登录态清掉)—— 先确认;
- 要重建 venv 或重新 clone 上游项目 —— 这会动 `~/projects` 和 `~/.venvs`,先确认;
- 批量下载超过几十首 —— 先跟用户确认歌单和预计耗时。
