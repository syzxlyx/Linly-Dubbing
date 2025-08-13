## Module: tools/step020_asr.py (+ step021_asr_whisperx.py, step022_asr_funasr.py)

### 概览
ASR（语音识别）阶段的门面与后端适配：
- step020_asr.py：统一入口，负责目录扫描、调用后端、生成 transcript.json、按说话人聚合音频样本
- step021_asr_whisperx.py：WhisperX 后端（含对齐与可选说话人分离）
- step022_asr_funasr.py：FunASR 后端（含中文优化、VAD/标点/说话人）

---

### step020_asr.py

#### merge_segments(transcript, ending=...) -> list
- 将相邻且句末无终止标点的片段合并，得到更完整的语句级片段

#### generate_speaker_audio(folder, transcript) -> None
- 读取 audio_vocals.wav（24kHz），按转写片段的时间范围裁剪音频并按 speaker 聚合
- 输出到 SPEAKER/{SPEAKER_XX}.wav，供 TTS 声纹提示使用

#### transcribe_audio(method, folder, model_name='large', download_root='models/ASR/whisper', device='auto', batch_size=32, diarization=True, min_speakers=None, max_speakers=None) -> list|bool
- 若 transcript.json 已存在则跳过
- 根据 method 选择 WhisperX 或 FunASR 进行识别
- 将识别结果 merge_segments 后写入 transcript.json，并生成说话人聚合音频
- 返回转写列表；失败时返回 False

#### transcribe_all_audio_under_folder(folder, asr_method, whisper_model_name='large', device='auto', batch_size=32, diarization=False, min_speakers=None, max_speakers=None) -> (str, list|dict|None)
- 遍历给定目录，遇到 audio_vocals.wav 且缺少 transcript.json 则调用 transcribe_audio
- 已有 transcript.json 则直接读取
- 返回状态字符串与最后一次处理的结果

---

### step021_asr_whisperx.py

#### 全局缓存
- whisper_model、align_model、diarize_model 采用懒加载并缓存

#### init_whisperx() / init_diarize()
- 便捷初始化封装：分别加载识别与说话人分离模型

#### load_whisper_model(model_name='large', download_root='models/ASR/whisper', device='auto')
- large → 优先映射到 models/ASR/whisper/faster-whisper-large-v3（存在则用本地）
- device=cpu 时使用 compute_type='int8' 以加速/降内存

#### load_align_model(language='en', device='auto', model_dir='models/ASR/whisper')
- 加载对齐模型与元数据，按语言缓存（language_code）

#### load_diarize_model(device='auto')
- 使用 whisperx.DiarizationPipeline；需要环境变量 HF_TOKEN 才能下载 pyannote 模型

#### whisperx_transcribe_audio(wav_path, model_name='large', download_root=..., device='auto', batch_size=32, diarization=True, min_speakers=None, max_speakers=None) -> list
- 识别 → 语言检测 → 文本对齐 → 可选说话人分离 → 生成 {start, end, text, speaker}

---

### step022_asr_funasr.py

#### init_funasr() / load_funasr_model(device='auto')
- 优先使用本地 models/ASR/FunASR/* 目录；否则回退到在线模型名（paraformer-zh 等）

#### funasr_transcribe_audio(wav_path, device='auto', batch_size=1, diarization=True) -> list
- funasr_model.generate(..., return_spk_res=diarization, sentence_timestamp=True, ...) → 解析 sentence_info
- 输出 {start, end, text, speaker} 列表（时间戳从毫秒转秒）

---

### 调用关系
- UI/webui 或 do_everything → step020.transcribe_all_audio_under_folder
  - → transcribe_audio（method 路由）
    - → whisperx_transcribe_audio 或 funasr_transcribe_audio
  - → merge_segments → transcript.json
  - → generate_speaker_audio（聚合说话人音频）

---

### 注意事项
- WhisperX 说话人分离需要 HF_TOKEN 授权；未配置则自动跳过
- transcript.json 的结构被后续翻译/TTS/合成模块依赖
- device='auto' 会自动选择 cuda/cpu；CPU 上 large-v3 采用 int8 计算类型

