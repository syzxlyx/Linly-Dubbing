# Linly-Dubbing 子模块文档索引

本索引汇总了项目核心处理流水线各阶段的“文件级”文档，便于按职责快速定位与理解代码。

处理流水线（自上而下）：
- 下载 Download → 人声分离 Separation → 语音识别 ASR → 翻译/摘要 Translation → 语音合成 TTS → 视频合成 Synthesis

## 文档一览

- 下载 Download
  - [tools/step000_video_downloader.md](./step000_video_downloader.md)
    - 基于 yt-dlp 的下载封装：解析 URL（单视频/播放列表/频道）、生成规范目录、下载视频/信息/缩略图

- 人声分离 Separation（Demucs）
  - [tools/step010_demucs_vr.md](./step010_demucs_vr.md)
    - 从 download.mp4 抽取音频，并用 Demucs 分离出 audio_vocals.wav 与 audio_instruments.wav；带模型懒加载与释放

- 语音识别 ASR（WhisperX / FunASR）
  - [tools/step020_asr.md](./step020_asr.md)
    - 统一入口、说话人音频聚合、WhisperX 对齐与可选说话人分离、FunASR 中文优化

- 翻译与摘要 Translation（LLM / OpenAI / Ernie / Qwen / Ollama / Google / Bing）
  - [tools/step030_translation.md](./step030_translation.md)
    - 生成 summary.json（标题/摘要/标签）、翻译 transcript.json 为 translation.json，并按句切分与时间轴调整

- 语音合成 TTS（XTTS / CosyVoice / Edge TTS）
  - [tools/step040_tts.md](./step040_tts.md)
    - 文本规范化、逐句合成与时长适配、拼接 full_wav，与伴奏混合生成 audio_combined.wav

- 视频合成 Synthesis（SRT/变速/BGM/水印/硬字幕）
  - [tools/step050_synthesize_video.md](./step050_synthesize_video.md)
    - 生成字幕 SRT，按分辨率/帧率/变速合成视频，可选叠加 BGM 与硬字幕

## 入口与编排（参考）
- 应用入口与 Web UI：webui.py（Gradio 多标签页界面）
- 全流程编排：tools/do_everything.py（串联下载→分离→ASR→翻译→TTS→合成）

如需也为上述入口文件生成详细文档，请告知，我可以补充。

## 功能实现情况
已实现
- 完成 AI 配音和智能翻译功能的基础实现
证据：完整流水线
tools/do_everything.py；翻译
tools/step030_translation.py；TTS
tools/step040_tts.py；视频合成
tools/step050_synthesize_video.py
- 集成 CosyVoice 的 AI 声音克隆，实现高质量音频翻译
证据：
tools/step043_tts_cosyvoice.py（CosyVoice 加载与推理）
- 增加 FunASR 的 AI 语音识别算法（中文优化）
证据：tools/step022_asr_funasr.py（FunASR 加载与识别）
- 利用 Qwen 大语言模型实现多语言翻译
证据：tools/step035_translation_qwen.py（在 tools/step030_translation.py 中路由可选）
- 开发 Linly-Dubbing WebUI，一键生成视频并支持多参数
证据：webui.py（Gradio 多标签页面板，一键处理与各阶段面板）
## 未实现（规划中）
- 加入 UVR5 进行人声/伴奏分离和混响移除（参考 GPT-SoVITS）
当前使用 Demucs（tools/step010_demucs_vr.py），未见 UVR5 集成
- 提升声音克隆的自然度，使用 GPT-SoVITS 微调/接入
未见 GPT-SoVITS 推理/训练代码接入
- 实现并优化数字人对口型技术
webui.py 中 “Linly-Talker 对口型” 为占位（开发中），未提供实际推理流程




## 依赖补齐（pip resolver 警告/缺包时可用）
遇到 pip 提示某些包缺失时，可使用以下一键命令（带官方 PyPI 兜底，已为 < / > 做引号）：

```bash
python -m pip install -U pip setuptools wheel

pip install --extra-index-url https://pypi.org/simple \
  importlib-metadata \
  "imageio<3.0" "imageio-ffmpeg>=0.2.0" "proglog<=1.0.0" \
  "cloudscraper>=1.2.71" "cryptography>=42.0.4" "exejs>=0.0.4" \
  "httpx<1,>=0.28.1" "lxml>=5.4.0" "niquests>=3.14.0" "pathos>=0.3.4" \
  "anyio<5" "distro>=1.7.0" "jiter>=0.4.0" sniffio \
  "aiofiles<25.0" brotli "fastapi<1.0" ffmpy "gradio-client==1.11.1" "groovy~=0.1" \
  "orjson~=3.0" pydub "python-multipart>=0.0.18" \
  "ruff>=0.9.3" "safehttpx>=0.1.6,<0.2.0" "semantic-version~=2.0" \
  "starlette<1.0" "tomlkit>=0.12,<0.14" uvicorn \
  beautifulsoup4 \
  "editdistance>=0.5.2" "hydra-core>=1.3.2" jaconv "kaldiio>=2.17.0" oss2 pytorch-wpe torch-complex

# 快速校验
pip check
python - <<'PY'
import httpx, anyio, fastapi, starlette, gradio, imageio
print('imports ok')
PY
```





关于 ttsfrd 提示
这是可选前端；缺失时自动回退到 WeTextProcessing，不影响基本功能
若后续确实要用 ttsfrd（部分中文前端特性），需要按 CosyVoice 官方 README 获取兼容的 wheel 包安装；不同平台提供情况不一，很多环境无法直接从 PyPI 装。暂时建议继续使用回退方案

执行这个报错，没空间了
pip install -U "whisperx @ git+https://github.com/m-bain/whisperx.git"
