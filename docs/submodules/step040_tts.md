## Module: tools/step040_tts.py (+ 042/043/044)

### 概览
将翻译后的台词（translation.json）合成为目标语言的配音音频：
- 后端支持：XTTS（Coqui）、CosyVoice、Edge TTS（命令行）
- 对每行进行文本规范化、时长适配、拼接为完整配音，并与伴奏混合生成 audio_combined.wav

---

### 核心函数（step040_tts.py）

#### preprocess_text(text: str) -> str
- 基于正则与中文归一化（cn_tx.TextNorm）进行清洗：
  - AI→人工智能，大写字母拆词，英文字母与数字之间加空格

#### adjust_audio_length(wav_path, desired_length, sample_rate=24000, min_speed_factor=0.6, max_speed_factor=1.1) -> (np.ndarray, float)
- 使用 audiostretchy 将合成音频拉伸/压缩到接近目标时长，受速度因子上下限约束
- 返回重采样后的波形与实际时长

#### generate_wavs(method, folder, target_language='中文', voice='zh-CN-XiaoxiaoNeural') -> (str, str)
- 读取 translation.json，收集 speakers 并逐行处理：
  - 根据 method 路由到：
    - step042_tts_xtts.tts(text, output, speaker_wav, target_language)
    - step043_tts_cosyvoice.tts(...)
    - step044_tts_edge_tts.tts(text, output, voice)
  - 调整每行音频长度以匹配原始时间片段（避免重叠，避让下一句 end）
  - 将各句拼接为 full_wav，并回写每行 start/end
- 与 audio_instruments.wav 对齐并混合，使用 save_wav_norm 输出 audio_combined.wav
- 返回（audio_combined.wav 路径, audio.wav 路径）

#### generate_all_wavs_under_folder(root_folder, method, target_language='中文', voice='zh-CN-XiaoxiaoNeural')
- 遍历目录，处理所有包含 translation.json 且缺少 audio_combined.wav 的子目录

---

### XTTS 适配（tools/step042_tts_xtts.py）
- init_TTS()/load_model(model_path="models/TTS/XTTS-v2", device='auto')：懒加载与设备选择
- tts(text, output_path, speaker_wav, model_name=..., device='auto', target_language='中文')：
  - language_map 将目标语言映射到 XTTS 的语言代码
  - 调用 model.tts 生成波形并保存

### CosyVoice 适配（tools/step043_tts_cosyvoice.py）
- init_cosyvoice()/load_model(model_path="models/TTS/CosyVoice-300M")：本地不存在则通过 modelscope 快速下载
- tts(text, output_path, speaker_wav, model_name=..., device='auto', target_language='中文')：
  - cross-lingual 推理：'<|lang|>text' + 16k 引导音
  - torchaudio.save 以 22050Hz 写出

### Edge TTS 适配（tools/step044_tts_edge_tts.py）
- tts(text, output_path, target_language='中文', voice='zh-CN-XiaoxiaoNeural')：
  - 直接调用 edge-tts 命令行写出 mp3（随后由上层读取/拉伸）

---

### 注意事项
- 支持语言清单见 tts_support_languages；调用前需校验目标语言是否受支持
- 合成结果做峰值对齐到原人声峰值，以保持感知响度
- 对于 Edge TTS，初始输出为 mp3，后续 adjust_audio_length 会转为 wav 进行处理
- 速度拉伸上下限保护：避免过度失真；必要时可二次切分翻译以适配更短片段

