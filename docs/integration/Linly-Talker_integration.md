## Linly‑Talker 集成指南（先手动验证，后代码集成）

本指南说明如何在“不改动 Linly‑Dubbing 现有代码”的前提下，先使用 Linly‑Talker 生成口型对齐视频并回填到本项目流水线；在验证质量与流程稳定后，再进行最小改动的代码级对接。

参考文档：
- Linly‑Talker 官方说明（中文）：https://github.com/Kedreamix/Linly-Talker/blob/main/README_zh.md
- 本项目安装（Python 3.11 + CUDA 12.1）：docs/INSTALL_py311_cu121.md

---

### 一、前置环境
- 推荐：Python 3.11，CUDA 12.1（驱动支持即可，无需本机 CUDA Toolkit）
- ffmpeg、Git 可用
- GPU：建议 ≥ 8GB 显存
- 已有 Linly‑Dubbing 工作目录，如：videos/<项目>/<视频名>/

---

### 二、阶段 A：不改代码的“手动联动”验证
目标：用 Linly‑Dubbing 产出的新配音音频驱动 Linly‑Talker 生成“对口型视频”，再回到 Linly 做字幕/BGM 合成。

#### A‑1 准备视频目录
- 方式 1：在 Linly WebUI 中“自动下载视频”获得 download.mp4
- 方式 2：手动将视频放到单视频目录：videos/<项目>/<视频名>/download.mp4

#### A‑2 提取原始音频（44.1kHz 双声道）
在单视频目录执行（Linux/macOS）：
```bash
ffmpeg -y -i download.mp4 -vn -ac 2 -ar 44100 audio.wav
```
Windows（PowerShell）：
```powershell
ffmpeg -y -i .\download.mp4 -vn -ac 2 -ar 44100 .\audio.wav
```

（如已使用 Linly 的“人声分离”面板，通常会自动得到 audio.wav，可跳过本步。）

#### A‑3 跑 Linly 后续步骤至“TTS 合成”
- 在 Linly WebUI：
  1) AI 智能语音识别（WhisperX/FunASR）→ 生成 transcript.json、SPEAKER 片段
  2) 字幕翻译 → 生成 translation.json
  3) AI 语音合成（XTTS/CosyVoice/Edge TTS 任选）→ 生成 audio_combined.wav（或至少生成逐句音频并拼接）

提示：若追求更自然的音色，可改为在外部使用 GPT‑SoVITS 进行克隆生成后回填（见“与 GPT‑SoVITS 协同”）。

#### A‑4 安装并启动 Linly‑Talker（外部项目）
- 克隆：
```bash
git clone https://github.com/Kedreamix/Linly-Talker.git
```
- 按其 README_zh.md 安装依赖与权重，并启动 WebUI 或脚本入口。

#### A‑5 用 Linly‑Talker 生成“对口型视频”
- 输入：
  - 新配音音频：优先 audio_combined.wav（或需纯人声时用 audio_vocals.wav）
  - 图像/参考视频：
    - 数字人口播：提供清晰正脸人像（或小样本参考视频）
    - 原片换口型：直接用 download.mp4（建议先按镜头分段处理）
- 设置输出分辨率/帧率与目标时长（建议与 Linly 合成参数一致，如 1080p/30fps）
- 导出结果，例如：talker_out.mp4

可选：若 Linly‑Talker 仅接受纯人声，先重采样人声到 44.1kHz 双声道：
```bash
ffmpeg -y -i audio_vocals.wav -ar 44100 -ac 2 vocals_44k.wav
```

#### A‑6 回填并合成最终视频
- 将 talker_out.mp4 放回单视频目录，并作为“底片”参与合成：
  - 简便做法：将 talker_out.mp4 重命名替换 download.mp4
  - 或在 Linly 的“一键流程/视频合成”中将原视频指向 talker_out.mp4
- 在 Linly WebUI 执行“视频合成”
  - 叠加字幕（SRT）、BGM、调速/水印、分辨率/帧率等
- 验证：口型贴合度、成片节奏、字幕对齐

---

### 三、流程建议与常见问题
- 分段更稳：多镜头/多脸场景，建议先按镜头作分段处理，再分别做对口型，最后拼接。
  - 片段切割（示例）：
```bash
# 取 00:00:00~00:00:10
ffmpeg -y -ss 0 -to 10 -i download.mp4 -c copy seg01.mp4
# 取 00:00:10~00:00:25
ffmpeg -y -ss 10 -to 25 -i download.mp4 -c copy seg02.mp4
```
  - 片段拼接（示例，concat 文件）：
```bash
printf "file 'seg01.mp4'\nfile 'seg02.mp4'\n" > concat.txt
ffmpeg -y -f concat -safe 0 -i concat.txt -c copy merged.mp4
```
- 采样率/时长一致性：Linly 的 TTS 阶段已做句级微调（audiostretchy 0.6–1.1），更利于口型同步；确保对口型使用的音频与字幕时长一致。
- 分辨率/帧率统一：Linly‑Talker 输出和 Linly 合成参数保持一致，减少重复转码损耗。

---

### 四、与 UVR5、GPT‑SoVITS 的协同（可选）
- UVR5（或 Demucs）先做人声/伴奏分离，将更干净的人声用于说话人聚合与 TTS 克隆素材抽取。
- GPT‑SoVITS 进行零样本/小样本克隆（或微调），得到更自然的音色；将逐句合成音频回填 Linly（或直接合成为整段 audio_combined.wav）。
- 使用 Linly‑Talker 驱动口型生成 talker_out.mp4；最后在 Linly 合成字幕/BGM/水印。

---

### 五、阶段 B：代码级对接（在 A 验证成功后实施）
为尽量减少依赖冲突，推荐“外部服务/CLI 调用”方式的最小改动集成：

- 新增模块（示例命名）：tools/step060_lipsync.py
  - run_linly_talker(image_or_video, audio_path, out_path, **params) → bool
  - 通过 HTTP/CLI 调用外部 Linly‑Talker 服务/脚本，不在本项目内直接安装其全部依赖。
- 在 tools/do_everything.py 中，在“视频合成”前插入可选步骤：
  - 若启用：生成 talker_out.mp4 并替换本次合成的底片
  - 若失败：保留原视频继续合成，并记录清晰错误
- WebUI：
  - “Linly‑Talker 对口型”入口参数化：引擎开关、输入图/参考视频路径、输出分辨率/帧率、是否分段与策略等。

（说明：以上为设计草案，待阶段 A 跑通、参数与质量确定后，再行落地。）

---

### 六、质量验收清单
- 口型贴合度：嘴形开合与辅音/元音同步，无明显延迟或提前
- 音色自然度：若使用 GPT‑SoVITS，更接近目标说话人音色与韵律
- 画面稳定性：无异常抖动/撕裂；镜头切换平滑
- 全链路一致性：字幕时间轴、视频时长、BGM/音量平衡合理

---

### 七、故障排查要点
- Linly‑Talker 报错/缺模型：按其 README_zh.md 下载权重，检查依赖与显存
- 音频不被接受：提供纯人声版本（audio_vocals.wav）并重采样到 44.1kHz 双声道
- 口型不同步：检查 TTS 是否做了句级时长微调；必要时缩小每句速度拉伸幅度
- 处理超时/显存不足：降低分辨率/帧率，或改分段处理

---

如需，我可以补充：
- 适配 Linly‑Talker 的统一外部服务接口样例（HTTP/CLI）
- 按你的目标视频分辨率/帧率/时长，给出参数模板与命令清单

