## 外部子模块（UVR5 / GPT-SoVITS / Linly-Talker）集成说明

为便于手动联动与后续最小改动接入，推荐将三者以 git submodule 的方式纳入本项目。

### 一、子模块路径与仓库
- submodules/UVR5 → https://github.com/Anjok07/ultimatevocalremovergui.git
- submodules/GPT-SoVITS → https://github.com/RVC-Boss/GPT-SoVITS.git
- submodules/Linly-Talker → https://github.com/Kedreamix/Linly-Talker.git

### 二、首次添加（已为你完成的命令）
在项目根目录：
```bash
git submodule add --name UVR5 https://github.com/Anjok07/ultimatevocalremovergui.git submodules/UVR5
git submodule add --name GPT-SoVITS https://github.com/RVC-Boss/GPT-SoVITS.git submodules/GPT-SoVITS
git submodule add --name Linly-Talker https://github.com/Kedreamix/Linly-Talker.git submodules/Linly-Talker
```

### 三、克隆/更新包含子模块的仓库
- 首次克隆：
```bash
git clone --recurse-submodules <this-repo-url>
```
- 若已克隆：
```bash
git submodule update --init --recursive
```
- 更新到上游最新（如跟踪分支）：
```bash
git submodule update --remote --merge
```

### 四、环境隔离与安装脚本
为避免依赖冲突，建议分别创建虚拟环境。我们提供了最小化的安装助手脚本：
- scripts/submodules/setup_uvr5.sh
- scripts/submodules/setup_gptsovits.sh
- scripts/submodules/setup_linly_talker.sh

用法示例（Linux/macOS）：
```bash
bash scripts/submodules/setup_uvr5.sh
bash scripts/submodules/setup_gptsovits.sh
bash scripts/submodules/setup_linly_talker.sh
```
激活环境后，进入各子模块目录，严格按其 README 安装依赖与模型。

### 五、与 Linly-Dubbing 的手动联动（摘要）
- UVR5：输入 videos/<项目>/<视频>/audio.wav，分离出 vocals/instrumental，回填为 audio_vocals.wav 与 audio_instruments.wav
- GPT-SoVITS：用 SPEAKER_XX.wav 做零/小样本或微调，逐句合成 → 句级时长微调 → 拼接 → 与伴奏混合成 audio_combined.wav
- Linly-Talker：用 audio_combined.wav 驱动口型生成 talker_out.mp4，在“视频合成”阶段替换底片（或直接替换 download.mp4）

### 六、版本固定与更新策略
- 若你希望锁定到稳定提交：
```bash
cd submodules/UVR5 && git checkout <tag-or-commit> && cd -
cd submodules/GPT-SoVITS && git checkout <tag-or-commit> && cd -
cd submodules/Linly-Talker && git checkout <tag-or-commit> && cd -
# 回到主仓库提交子模块指针
git add submodules/* .gitmodules && git commit -m "chore: pin submodules"
```
- 若要跟踪上游分支，在 .gitmodules 中为子模块设置 branch 字段，然后：
```bash
git submodule update --remote --merge
```

### 七、模型与大文件
- 不将模型权重纳入 git，统一放置在 models/ 或各子模块默认目录，并在 .gitignore 中忽略。

### 八、常见问题
- 子模块下载慢：可使用 git -c http.lowSpeedLimit=0 submodule update --init --recursive
- 权限不足：检查子模块目录权限或以合适用户运行
- 依赖冲突：务必使用独立虚拟环境；参考 docs/INSTALL_py311_cu121.md 的“F. 一键补齐依赖”

