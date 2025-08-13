## Module: tools/step010_demucs_vr.py

### 概览
封装 Demucs 人声/伴奏分离流程，负责：
- 从视频中抽取音频（download.mp4 → audio.wav）
- 使用 Demucs 拆出人声与伴奏（audio_vocals.wav / audio_instruments.wav）
- 管理模型加载、重用与释放（避免重复初始化与显存泄露）

依赖：demucs、ffmpeg、torch、loguru；工具函数 save_wav、normalize_wav。

---

### 全局状态
- auto_device: 自动选择 cuda/cpu
- separator: demucs.api.Separator 实例（懒加载）
- model_loaded: 当前是否已加载模型
- current_model_config: 当前模型配置（model_name/device/shifts），用于判断是否需要重载

---

### 函数与职责

#### init_demucs() -> None
- 若未加载，则调用 load_model()；已加载则跳过

#### load_model(model_name="htdemucs_ft", device='auto', progress=True, shifts=5) -> Separator
- 按配置加载 Demucs 模型（Separator）
- 若已有实例且配置一致，直接复用；否则释放旧实例并重新加载
- 记录 current_model_config 与 model_loaded 状态

#### release_model() -> None
- 释放 Separator 引用，gc.collect()，以及 torch.cuda.empty_cache()（如可用）
- 清空 model_loaded 与 current_model_config

#### separate_audio(folder, model_name="htdemucs_ft", device='auto', progress=True, shifts=5) -> (str|None, str|None)
- 输入：视频工作目录，要求包含 audio.wav（若无可先调用 extract_audio_from_video）
- 逻辑：
  - 若目标输出已存在则直接返回
  - 确保模型按给定配置就绪（必要时重载）
  - separator.separate_audio_file(audio.wav) → 得到各 stem（human、drums等）
  - 汇总非 vocals 的其余 stem 相加为伴奏
  - 保存人声与伴奏到 audio_vocals.wav / audio_instruments.wav
- 返回：两条输出路径；遇错会释放模型并抛出异常

#### extract_audio_from_video(folder) -> bool
- 使用 ffmpeg 从 download.mp4 抽取音频为 audio.wav（44100Hz、双声道）
- 已存在则跳过

#### separate_all_audio_under_folder(root_folder, model_name="htdemucs_ft", device='auto', progress=True, shifts=5) -> (str, str|None, str|None)
- 遍历 root_folder 下所有包含 download.mp4 的子目录
  - 缺少 audio.wav 时先 extract_audio_from_video
  - 缺少拆分结果时调用 separate_audio
- 返回：状态字符串、人声与伴奏路径（最后一次处理的结果）

---

### 调用关系
- UI/webui → separate_all_audio_under_folder
  - → extract_audio_from_video（必要时）
  - → separate_audio
    - → load_model（必要时）
    - → Separator.separate_audio_file
    - → save_wav 保存输出

---

### 注意事项
- Demucs shifts 提高稳健性但会增加耗时；UI 中可配置
- 释放模型 release_model 在出错时会被调用，防止 GPU 内存占用
- 输出采样率固定为 44100Hz；后续 TTS 阶段通常在 24kHz 进行处理

