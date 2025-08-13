## Module: tools/step050_synthesize_video.py

### 概览
负责“视频合成”阶段：将已下载的原视频、合成好的配音音频、生成的字幕等资源，按参数（分辨率、帧率、加速、BGM、音量、浮水印）进行综合处理，产出最终视频文件。

- 依赖：
  - 系统可用的 ffmpeg / ffprobe
  - Python: json, os, shutil, subprocess, time, random, traceback, loguru
  - 字体文件：默认引用 ./font/SimHei.ttf（字幕渲染使用）

- 约定的输入文件（位于每个视频的工作目录下）：
  - download.mp4：原始下载视频
  - audio_combined.wav：合成后的目标语音
  - translation.json：翻译/对齐后的字幕数据（含 start/end/text/translation/speaker）

- 主要输出：
  - subtitles.srt：生成的 SRT 字幕文件
  - video.mp4：最终合成的视频（可能经过 BGM 与字幕叠加）

---

### 函数与职责

#### split_text(input_data, punctuations=[...]) -> list
按中文标点与最小长度将翻译文本拆分为更短的句段，并根据原始片段的时长按“字符平均分配”推算每个句段的结束时间。

- 输入：翻译条目列表 [{start, end, text, translation, speaker?}]
- 逻辑：
  - 遍历每条翻译，逐字符扫描 translation
  - 遇到句末标点或满足长度阈值时切分
  - 新条目保留原始 text，translation 替换为拆分后的句段
  - 句段时间使用 duration_per_char 进行线性内插
- 输出：拆分后的条目列表

#### format_timestamp(seconds) -> str
将秒数转换为 SRT 格式时间戳（HH:MM:SS,mmm）。

#### generate_srt(translation, srt_path, speed_up=1, max_line_char=30)
根据 translation 列表生成 SRT 文件。
- 逻辑：
  - 调用 split_text 预切分
  - 时间戳按 speed_up 进行缩放（start/end 均除以 speed_up）
  - 文本按 max_line_char 尝试均分换行
  - 以 SRT 序号、时间轴、文本写入 srt_path

#### get_aspect_ratio(video_path) -> float
调用 ffprobe 获取视频宽高，返回宽高比（width/height）。

#### convert_resolution(aspect_ratio, resolution='1080p') -> (width, height)
根据目标“短边像素”与视频宽高比，计算整除 2 的 width/height。传入的分辨率字符串如 '1080p'，函数会解析为短边像素值。

#### synthesize_video(folder, subtitles=True, speed_up=1.00, fps=30, resolution='1080p', background_music=None, watermark_path=None, bgm_volume=0.5, video_volume=1.0) -> str
核心合成流程，产出 folder/video.mp4。

- 先决条件：folder 下存在 translation.json、audio_combined.wav、download.mp4；缺失则直接返回
- 步骤：
  1) 读取 translation.json，调用 generate_srt 生成 subtitles.srt
  2) 调用 get_aspect_ratio/convert_resolution 计算 width/height 与分辨率字符串
  3) 构建滤镜：
     - 视频变速：setpts=PTS/speed_up
     - 音频变速：atempo=speed_up
     - 字体/字幕样式：通过 subtitles filter 设定（SimHei、Outline、WrapStyle 等）
  4) 构造并执行 ffmpeg 命令：
     - 基础输入：原视频（-i download.mp4）、目标配音（-i audio_combined.wav）
     - 可选水印：额外输入 -i watermark.png + overlay 滤镜
     - 编码：-c:v libx264 -c:a aac，指定 -r fps、-s 分辨率
     - 产物：video.mp4
  5) 若指定 BGM：
     - 再次用 ffmpeg 将 video.mp4 的音轨与 BGM 混音（amix），并按 video_volume/bgm_volume 调整增益
     - 替换原 video.mp4
  6) 若开启字幕标注（subtitles=True）：
     - 通过 add_subtitles 将 SRT 烧录进视频（默认 ffmpeg 方案）
     - 将带字幕的视频重命名回 video.mp4

- 返回：最终视频文件路径 folder/video.mp4

提示：ffmpeg 的 atempo 有实用范围（0.5~2.0），若 speed_up 超过范围，可能需要链式 atempo 叠加；当前实现使用单次 atempo。

#### add_subtitles(video_path, srt_path, output_path, subtitle_filter=None, method='ffmpeg') -> bool
为视频添加硬字幕，默认使用 ffmpeg 路径；也支持 moviepy（不推荐用于大视频）。

- 防御式临时文件处理：
  - 将输入视频与 SRT 拷贝到 temp/ 目录，随机命名以避免并发冲突
  - 使用绝对路径调用 ffmpeg，执行 subtitles 过滤器
  - 成功后复制回 output_path，并清理临时文件
- 错误处理：
  - 捕获 CalledProcessError，打印 stderr；确保失败时返回 False
  - finally 中尝试删除所有临时文件，忽略删除失败

#### synthesize_all_video_under_folder(folder, subtitles=True, speed_up=1.00, fps=30, background_music=None, bgm_volume=0.5, video_volume=1.0, resolution='1080p', watermark_path='f_logo.png') -> (str, str|None)
遍历 folder 下的子目录，发现包含 download.mp4 的目录即调用 synthesize_video 执行合成。
- watermark_path 若不存在则置为 None（不加水印）
- 返回：状态字符串与最后一次合成的视频路径（若有）

---

### 关键逻辑路径（调用图）
- 一键/手动入口（webui.py / tools/do_everything.py）
  - → synthesize_all_video_under_folder
    - → synthesize_video
      - → generate_srt
        - → split_text
      - → get_aspect_ratio → convert_resolution
      - → ffmpeg 合成（原视频 + 目标语音 [+ 水印]）
      - → 可选 BGM 混音（amix）
      - → 可选 add_subtitles（硬字幕）

---

### 参数与可调项
- subtitles: 是否烧录硬字幕
- speed_up: 统一变速倍率（视频 setpts，音频 atempo）
- fps: 输出帧率
- resolution: 目标分辨率短边（字符串如 '1080p'），按源宽高比折算另一个边
- background_music: BGM 路径（可选）
- bgm_volume / video_volume: 混音前对两路音轨的音量比例
- watermark_path: 浮水印图片路径（右下角，按原尺寸 15% 缩放）

---

### 假设与依赖注意事项
- 运行环境必须安装 ffmpeg/ffprobe 并在 PATH 中
- ./font/SimHei.ttf 可用；否则字幕字体可能不生效/报错
- translation.json 的字段结构需包含 start/end/text/translation（本模块按此结构生成 SRT）
- speed_up 不宜极端（>2 或 <0.5），否则 atempo 可能不生效或音质变差
- amix 会以 duration=first 截断到主视频长度

---

### 最小示例（以 Python 调用）
```python
from tools.step050_synthesize_video import synthesize_all_video_under_folder

status, output = synthesize_all_video_under_folder(
    folder='videos/my_project',
    subtitles=True,
    speed_up=1.0,
    fps=30,
    resolution='1080p',
    background_music='examples/bk_music.mp3',
    bgm_volume=0.5,
    video_volume=1.0,
    watermark_path='docs/linly_watermark.png'
)
print(status, output)
```

