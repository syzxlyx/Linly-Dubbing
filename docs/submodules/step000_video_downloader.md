## Module: tools/step000_video_downloader.py

### 概览
基于 yt-dlp 的下载封装：解析 URL（单视频/播放列表/频道）、生成安全的落盘目录结构、按目标分辨率下载视频+信息文件+缩略图。

---

### 函数与职责

#### sanitize_title(title: str) -> str
- 过滤标题中的非法字符，仅保留数字/字母/中文/空格/下划线/连字符，并压缩多余空格

#### get_target_folder(info: dict, folder_path: str) -> str|None
- 按「uploader/上传日期 标题」生成规范化的工作目录
- 若 upload_date 缺失（'Unknown'）返回 None（调用方可回退）

#### download_single_video(info: dict, folder_path: str, resolution='1080p') -> str|None
- 目标目录已存在 download.mp4 则跳过
- 使用 yt-dlp：
  - format: bestvideo[ext=mp4][height<=res]+bestaudio[ext=m4a]/best[ext=mp4]/best
  - writeinfojson / writethumbnail
  - outtmpl: .../download
  - 可选 cookiefile（cookies.txt 存在时）
- 返回输出目录路径

#### download_videos(info_list: list, folder_path: str, resolution='1080p') -> str
- 逐条调用 download_single_video；返回最后一次输出目录

#### get_info_list_from_url(url: str|list, num_videos: int)
- 以 dumpjson 模式提取信息，不下载媒体；支持列表迭代（yield）
- 对含 entries 的结果逐条 yield，每条为视频元信息 dict

#### download_from_url(url: str|list, folder_path: str, resolution='1080p', num_videos=5) -> (str, str, dict)
- 统一入口：先 dumpjson 聚合 video_info_list，再执行 download_videos
- 返回：状态字符串、示例下载视频路径（.../download.mp4）、下载信息 JSON（download.info.json）

---

### 目录结构约定（下载后）
- {folder_path}/{uploader}/{upload_date} {title}/
  - download.mp4
  - download.info.json
  - download.jpg/png（缩略图）

---

### 注意事项
- Bilibili/YouTube 某些资源需要 cookies 才能拿到高清/受限视频；可通过 yt-dlp 提取浏览器 cookies.txt
- resolution 解析为数值（去掉 p），作为 height<= 的上限
- get_info_list_from_url 提供生成器形式，适合上层自定义遍历

