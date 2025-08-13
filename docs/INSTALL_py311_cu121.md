## Linly-Dubbing 安装指南（Python 3.11 + CUDA 12.1）

本指南将指导你在 Python 3.11 环境下，使用 PyTorch cu121 轮子（CUDA 12.1 runtime）配置 GPU 加速的 Linly-Dubbing 运行环境。

注意事项：
- 仅需较新的 NVIDIA 驱动（建议 535+）；无需安装本机 CUDA Toolkit。
- 选择 Python 3.11 可避免部分第三方库在 3.12 的兼容性限制（例如 Coqui TTS）。

---

### 0. 系统准备
- 建议使用 Conda 管理 Python 环境（Miniconda/Anaconda/conda-forge 皆可）。
- 确认显卡驱动满足 CUDA 12.x runtime 需求。Linux 可执行：

```bash
nvidia-smi
```

---

### 1. 创建并激活 Python 3.11 环境
```bash
conda create -n linly_dubbing python=3.11 -y
conda activate linly_dubbing
python -m pip install -U pip setuptools wheel
```

可选：配置 PyPI 镜像（国内用户推荐）
```bash
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
```

---

### 2. 安装 PyTorch（CUDA 12.1 runtime）
选择 pip 官方 cu121 轮子（推荐）：

```bash
# PyTorch 2.3.1（稳定）
pip install --index-url https://download.pytorch.org/whl/cu121 \
  torch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1

# 或安装更新版本（2.4.x），也兼容 Python 3.11：
# pip install --index-url https://download.pytorch.org/whl/cu121 \
#   "torch==2.4.*" "torchvision==0.19.*" "torchaudio==2.4.*"
```

或使用 conda：
```bash
conda install pytorch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1 pytorch-cuda=12.1 -c pytorch -c nvidia
```

验证 GPU 可用：
```bash
python -c "import torch; print(torch.__version__, torch.version.cuda); print('CUDA Available:', torch.cuda.is_available())"
```

---

### 3. 安装系统工具与关键三方
- ffmpeg（建议 conda 安装）
```bash
conda install -y ffmpeg==7.0.2 -c conda-forge
```

- Pynini（WeTextProcessing 依赖；在 Py3.11 可用）
```bash
conda install -y pynini==2.1.6 -c conda-forge
# 若 x86_64 且从 PyPI 安装：
# pip install pynini==2.1.6
```
- Pynini（WeTextProcessing 依赖；在 Py3.11 可用）
pip install --no-deps WeTextProcessing==1.0.3
说明：项目中的中文文本归一化主要由 tools/cn_tx.py 完成；WeTextProcessing 为可选增强。

---

### 4. 安装项目依赖
在仓库根目录（Linly-Dubbing）执行：

```bash
# 若你希望启用 WeTextProcessing（可选），先确保已安装 pynini==2.1.6（见上一步）

# 先安装基础依赖
pip install -r requirements.txt  --no-deps

# 安装子模块依赖
pip install -r requirements_module.txt || echo "module requirements optional; continue"
```

WhisperX 依赖栈（仅当启用 WhisperX ASR）：
```bash
pip install -U ctranslate2 faster-whisper
# 若 PyPI 安装 whisperx 失败，可使用 GitHub 源：
pip install whisperx || pip install git+https://github.com/m-bain/whisperx.git
```

CosyVoice/ModelScope（TTS 使用）：
```bash
pip install -U modelscope
```

---

### 5. 下载模型
- Linux：
```bash
bash scripts/download_models.sh
```

- Windows：
```bash
python scripts/modelscope_download.py
# 额外（按 README）包含在scripts/download_models.sh：
wget -nc https://download.pytorch.org/torchaudio/models/wav2vec2_fairseq_base_ls960_asr_ls960.pth \
  -O models/ASR/whisper/wav2vec2_fairseq_base_ls960_asr_ls960.pth
```

---

### 6. 配置环境变量
将根目录 env.example 复制为 .env，并按需填写：
- HF_TOKEN（Hugging Face Token；如需说话人分离请申请 pyannote/speaker-diarization-3.1 访问）
- MODEL_NAME（如 Qwen/Qwen1.5-4B-Chat）
- OPENAI_API_KEY / OPENAI_API_BASE（若使用 OpenAI 接口）
- 其他可选：HF_ENDPOINT、Bytedance APPID/ACCESS_TOKEN、BAIDU_API_KEY/SECRET_KEY

---

### 7. 启动与验证
```bash
python webui.py
```
浏览器访问：http://127.0.0.1:6006

快速导入验证（可选）：
```bash
python -c "import whisperx; print('whisperx ok')"  # 若启用
python -c "from funasr import AutoModel; print('funasr ok')"  # 若启用
python -c "import gradio, librosa; print('gradio/librosa ok')"
```

---

## 故障排查

### A. WeTextProcessing / Pynini 安装失败
- 现象：pip install -r requirements.txt 失败，提示 WeTextProcessing 依赖 pynini。
- 解决：
  1) 确认已安装 `pynini==2.1.6`（conda-forge 或 PyPI）。
  2) 仅在确实需要 WeTextProcessing 时再安装；否则可在 requirements.txt 中注释掉 WeTextProcessing 行。

### B. WhisperX 安装失败
- 升级构建工具：`python -m pip install -U pip setuptools wheel`
- 预装底层依赖：`pip install -U ctranslate2 faster-whisper`
- 使用 GitHub 源：`pip install git+https://github.com/m-bain/whisperx.git`

### C. SciPy / PyArrow 等编译失败或无轮子
- 升级 pip 后重试；选择带 py311 轮子的版本（如 SciPy 1.11/1.12 系列）。
- 必要时用 conda 安装这些重量级包（`conda install -c conda-forge scipy pyarrow`）。

### D. cuDNN/动态库找不到（Linux）
- 参考 README 的 TIP，导出 torch 自带 cudnn 路径：
```bash
export LD_LIBRARY_PATH=`python3 -c 'import os, torch; print(os.path.dirname(os.path.dirname(torch.__file__)) +"/nvidia/cudnn/lib")'`:$LD_LIBRARY_PATH
```

### E. ModelScope 依赖冲突
- 升级 modelscope：`pip install -U modelscope`
- 参考其 release notes 选择与 py311 兼容的版本。

### F. 一键补齐依赖（pip resolver 警告/缺包）
当你看到 “pip's dependency resolver does not currently take into account all the packages that are installed” 且列出一串缺失依赖时，可用以下命令一次性补齐（带官方 PyPI 兜底，并对带 < / > 的版本做了引号避免 shell 解析错误）。

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

# 校验
pip check
python - <<'PY'
import httpx, anyio, fastapi, starlette, gradio, imageio
print('imports ok')
PY
```

网络/代理提示：若使用代理导致握手超时，可在执行前临时绕过代理或为 pypi 域名加 no_proxy，例如：
```bash
# 临时绕过代理安装（示例）
env -u http_proxy -u https_proxy pip install --extra-index-url https://pypi.org/simple <packages> --default-timeout 120
# 或：为 PyPI 域名添加 no_proxy
export no_proxy="pypi.org,files.pythonhosted.org,pypi.python.org,pythonhosted.org,*.pythonhosted.org"
```


### G. WhisperX/pyannote 说话人分离加载失败（Hub 无法下载/找不到文件）
现象：启动或运行 ASR（WhisperX）时，加载说话人分离模型失败，提示无法从 Hugging Face Hub 定位/下载。

常见原因：
- 未配置 HF_TOKEN 或未申请 pyannote/speaker-diarization-3.1 的 gated 访问
- 网络受限（代理/内网），无法连到 huggingface.co
- 未预下载模型到本地缓存

解决路径：
- 路径 1（最快）：先跳过分离跑通流程
  - 在 WebUI 的 ASR 设置里关闭“说话人分离/聚类”（或在 .env 内临时禁用相关开关），先完成 ASR→翻译→TTS→合成。
- 路径 2（在线直连）：获取 Token + 预下载
  1) 在模型页申请访问并同意条款：
     - https://huggingface.co/pyannote/speaker-diarization-3.1
  2) 配置并登录：
     ```bash
     # .env 中填写（示例）
     HF_TOKEN=xxxxxxxxxxxxxxxx

     pip install -U "huggingface_hub[cli]" hf_transfer
     huggingface-cli login --token $HF_TOKEN
     export HF_HUB_ENABLE_HF_TRANSFER=1
     ```
  3) 预下载到本地目录（推荐）：
     ```bash
     huggingface-cli download pyannote/speaker-diarization-3.1 \
       --local-dir models/pyannote/speaker-diarization-3.1
     # 其他常见依赖模型（按需）：
     # huggingface-cli download pyannote/segmentation-3.0 --local-dir models/pyannote/segmentation-3.0
     # huggingface-cli download pyannote/voice-activity-detection --local-dir models/pyannote/voice-activity-detection
     ```
  4) 运行：`python webui.py`
  - 自检（可选）：
     ```bash
     python - <<'PY'
     import os
     from huggingface_hub import model_info
     print(model_info('pyannote/speaker-diarization-3.1', token=os.getenv('HF_TOKEN')))
     PY
     ```
- 路径 3（大陆网络/离线）：镜像与缓存
  - 设置镜像与缓存目录（按需）：
    ```bash
    export HF_ENDPOINT=https://hf-mirror.com
    export HUGGINGFACE_HUB_CACHE=$PWD/.hf_cache   # 或：export HF_HOME=$PWD/.hf_home
    ```
  - 使用 huggingface-cli download 将模型拉到本地指定目录（同上），确保成功后再运行 webui。
  - 若使用代理，确保 https_proxy/http_proxy 正确；或为 huggingface 域名添加 no_proxy 以直连。

提示：若返回 403/404，大多是未获模型 gated 访问权限；先到模型页申请并同意条款。


---

## 变更记录
- v1: 初版，Python 3.11 + CUDA 12.1 安装流程与排障指引

