## Module: tools/step030_translation.py (+ 031/032/033/034/035/036)

### 概览
负责字幕与摘要的机器翻译：
- 生成摘要 summary.json（标题/摘要/标签等）
- 将 transcript.json 翻译为目标语言，生成 translation.json 并按句切分与时间轴对齐
- 路由多个翻译后端：LLM、本地/在线 OpenAI、Ernie、Qwen、Ollama、Google/Bing 翻译

---

### 关键函数（step030_translation.py）

#### get_necessary_info(info: dict) -> dict
提取 download.info.json 中必要字段：title/uploader/description/upload_date/tags。

#### ensure_transcript_length(transcript: str, max_length=4000) -> str
长文本截断：取前后各一半，限制总长度。

#### split_text_into_sentences(para: str) -> list[str]
按中英文句末标点与省略号规则切分句子。

#### translation_postprocess(result: str) -> str
翻译结果清洗与术语替换（如 AI→人工智能、变压器→Transformer）。

#### valid_translation(text: str, translation: str) -> (bool, str)
- 校验翻译格式是否仅包含结果（去除“翻译：”“译文：”等提示）
- 根据长度与禁用词检查是否需要重试，返回清洗后的文本或重试提示

#### split_sentences(translation: list[dict], use_char_based_end=True) -> list[dict]
- 依据翻译文本切分成更短句段
- 若 use_char_based_end=True，则用“平均每字符时长”内插新的 end 时间戳，并依次推进 start

#### summarize(info: dict, transcript: list, target_language='简体中文', method='LLM') -> dict
- LLM 生成视频的 JSON 摘要（title/summary），带若干重试与正则抽取
- 若 method 为 Google/Bing，则退化为直接翻译描述+全文

#### _translate(summary: dict, transcript: list, target_language='简体中文', method='LLM') -> list[str]
- 逐句翻译转写文本 text，累积上下文到 history 提示，提高一致性
- 支持 LLM/OpenAI/Ernie/Qwen/Ollama/Google/Bing，失败重试与 valid_translation 校验

#### translate(method, folder, target_language='简体中文') -> (dict, list[dict])
- 加载 info 与 transcript
- 生成/读取 summary.json
- 逐句翻译并写入 translation.json；随后调用 split_sentences 重排时间，写回 translation.json

#### translate_all_transcript_under_folder(folder, method, target_language)
- 遍历目录，处理所有包含 transcript.json 且缺少 translation.json 的子目录
- 返回状态 + 最后一次的 summary/translation 结果

---

### 后端适配（概述）
- step031_translation_openai.py：openai_response(messages)
- step032_translation_llm.py：llm_response(messages)
- step033_translation_translator.py：translator_response(text, to_language, translator_server)
- step034_translation_ernie.py：ernie_response(messages, system)
- step035_translation_qwen.py：qwen_response(messages)
- step036_translation_ollama.py：ollama_response(messages)

---

### 调用关系
- UI/webui 或 do_everything → translate_all_transcript_under_folder
  - → translate（加载 info/transcript → summarize → _translate → split_sentences → translation.json）

---

### 注意事项
- Google/Bing 翻译无需 LLM，但质量与一致性可能逊色
- LLM 翻译中，提示词包含用语风格与术语要求，有助于术语统一
- translation.json 的结构与时间戳被 TTS/合成模块直接依赖

