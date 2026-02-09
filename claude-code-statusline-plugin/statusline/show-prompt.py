#!/usr/bin/env python3
"""
Claude Code 状态栏插件 - AI 智能摘要版（带缓存）

利用 Claude Code 的代理 API 生成智能摘要，
使用缓存避免执行过程中状态栏频繁变化。

作者: MrSong9957
许可证: MIT
版本: 2.3.0
"""

import sys
import json
import os
import re
import urllib.request
import urllib.error
import hashlib

# ========== 可配置参数 ==========
# 中文显示字数限制
CHINESE_MAX_LENGTH = 15
# 英文显示单词数限制
ENGLISH_MAX_WORDS = 10
# 状态栏显示格式
STATUS_FORMAT = "[最新指令:{summary}]"
# =================================

# API 配置（使用 Claude Code 的代理）
API_KEY = os.environ.get('ANTHROPIC_API_KEY', 'dummy')
BASE_URL = os.environ.get('ANTHROPIC_BASE_URL', 'http://host.docker.internal:15721')

# 缓存文件
CACHE_DIR = os.path.expanduser('~/.claude/cache')
CACHE_FILE = os.path.join(CACHE_DIR, 'statusline-summary.txt')
CACHE_KEY_FILE = os.path.join(CACHE_DIR, 'statusline-key.txt')


def get_cache_key(text):
    """生成缓存键"""
    return hashlib.md5(text.encode('utf-8')).hexdigest()


def load_cached_summary():
    """从缓存读取摘要"""
    try:
        if os.path.exists(CACHE_FILE):
            with open(CACHE_FILE, 'r') as f:
                return f.read().strip()
    except Exception:
        pass
    return None


def save_cached_summary(summary, key):
    """保存摘要到缓存"""
    try:
        os.makedirs(CACHE_DIR, exist_ok=True)
        with open(CACHE_FILE, 'w') as f:
            f.write(summary)
        with open(CACHE_KEY_FILE, 'w') as f:
            f.write(key)
    except Exception:
        pass


def is_cache_valid(current_key):
    """检查缓存是否有效"""
    try:
        if not os.path.exists(CACHE_KEY_FILE):
            return False
        with open(CACHE_KEY_FILE, 'r') as f:
            cached_key = f.read().strip()
        return cached_key == current_key
    except Exception:
        return False


def call_claude_api(prompt):
    """通过 Claude Code 代理调用 AI 生成摘要"""

    if not BASE_URL:
        return None

    # 使用最轻量的模型
    data = {
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 50,
        'messages': [{'role': 'user', 'content': prompt}],
    }

    headers = {
        'x-api-key': API_KEY,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
    }

    try:
        req = urllib.request.Request(
            f'{BASE_URL}/v1/messages',
            data=json.dumps(data).encode('utf-8'),
            headers=headers,
            method='POST'
        )

        # 设置超时（状态栏需要快速响应）
        with urllib.request.urlopen(req, timeout=2) as response:
            result = json.loads(response.read().decode('utf-8'))
            summary = result.get('content', [{}])[0].get('text', '').strip()

            # 清理返回结果
            summary = summary.split('\n')[0]  # 只取第一行
            summary = re.sub(r'[*_`#\s]+', '', summary)  # 去除 markdown 符号

            if summary and len(summary) > 1:
                return summary

    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError) as e:
        # API 调用失败，回退到规则提取
        pass
    except Exception:
        pass

    return None


def ai_extract_summary(text):
    """使用 AI 提取智能摘要"""

    if not text or len(text) < 5:
        return None

    # 限制输入长度
    if len(text) > 500:
        text = text[:500] + "..."

    prompt = f"""从以下用户输入中提取核心任务/指令。注意：用户可能先列出一些规则或要求，真正的任务通常在后面。

示例：
输入：规则：创建 agent teams。完成任务：按照建议修复
输出：按照建议修复

输入：请帮我创建一个 Django 项目
输出：创建 Django 项目

现在请处理：
{text}

只返回任务摘要（5-15个字），不要解释："""

    return call_claude_api(prompt)


def smart_extract_task(text):
    """规则提取 - 作为 AI 的后备方案"""

    if not text:
        return ""

    # 删除所有换行符，确保单行显示
    text = text.replace('\n', ' ').replace('\r', ' ')
    # 将多个连续空格合并为一个
    text = re.sub(r'\s+', ' ', text).strip()

    # ========== 优先级1：识别明确的任务标记 ==========
    task_patterns = [
        r'(?:完成任务|执行任务|任务|Task|请)[：:：]\s*[-•*]\s*(.*?)(?:$|\.|！|！)',
        r'(?:完成任务|执行任务|任务|Task|请)[：:：]\s*(.*?)(?:$|\.|！|！)',
        r'(?:帮我|麻烦你|请你|请)\s*[-•*]\s*(.*?)(?:$|\.|，|,)',
        r'(?:帮我|麻烦你|请你|请)\s*(.*?)(?:$|\.|，|,)',
        r'(?:需要|想要|希望)\s*(.*?)(?:$|\.|，|,)',
        r'(?:创建|写|修改|修复|删除|添加|实现|生成)\s*(.*?)(?:$|\.|，|)',
    ]

    for pattern in task_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            result = match.group(1).strip()
            if len(result) > 2:
                return result

    # ========== 优先级2：跳过规则部分，提取实际任务 ==========
    rule_indicators = [
        '遵循规则', '按照规则', '根据规则', '注意事项', '注意',
        '要求：', '要求:', '规则：', '规则:', '配置：',
        '遵循', '按照', '根据', '参考',
        'environment', 'context', 'system', 'instructions'
    ]

    for indicator in rule_indicators:
        if indicator in text.lower():
            parts = text.split(indicator, 1)
            if len(parts) > 1:
                after_rule = parts[1]
                task_keywords = ['创建', '写', '修改', '修复', '删除', '添加', '实现', '生成',
                                 '完成', '执行', '处理', '分析', '检查', '测试',
                                 'create', 'write', 'fix', 'delete', 'add', 'implement']
                for keyword in task_keywords:
                    if keyword in after_rule.lower():
                        idx = after_rule.lower().find(keyword)
                        return after_rule[idx:].strip()

    # ========== 优先级3：去除常见的对话前缀 ==========
    prefixes = [
        '好吧，', '好吧,', '好的，', '好的,', '那么，', '那么,',
        '我上一条输入', '上一条输入', '我上一条', '上一条',
        '预期的状态', '实际上显示', '未能实现', '但是，', '不过，',
        '请帮我', '帮我', '麻烦你', '麻烦',
    ]
    for p in prefixes:
        if text.startswith(p):
            text = text[len(p):].strip()
            break

    # ========== 优先级4：按标点分割，取第一句有意义的 ==========
    sentences = re.split(r'[。！？!?\.]', text)
    for sentence in sentences:
        sentence = sentence.strip()
        rule_keywords = ['规则', '要求', '遵循', '按照', '注意', '配置', 'environment', 'system']
        if not any(kw in sentence.lower() for kw in rule_keywords):
            if len(sentence) > 3:
                return sentence

    return text


def extract_task_summary(text):
    """智能提取任务摘要 - AI优先，规则后备"""
    if not text:
        return ""

    # 优先级1：使用 AI 提取（通过 Claude Code 代理）
    ai_summary = ai_extract_summary(text)
    if ai_summary:
        return ai_summary[:CHINESE_MAX_LENGTH] + "..." if len(ai_summary) > CHINESE_MAX_LENGTH else ai_summary

    # 优先级2：回退到规则提取
    text = smart_extract_task(text)
    if not text:
        return ""

    # 去除列表符号前缀
    text = re.sub(r'^[-•*]\s+', '', text)

    # 检测是否包含中文
    has_chinese = any('\u4e00' <= c <= '\u9fff' for c in text)

    if has_chinese:
        text = re.sub(r'^(一下|一下儿|一下子|去|来|帮我|替我)', '', text)
        for sep in ['，', ',', '。', '？', '?', '！', '!']:
            if sep in text:
                text = text.split(sep)[0].strip()
        if len(text) > CHINESE_MAX_LENGTH:
            text = text[:CHINESE_MAX_LENGTH] + "..."
    else:
        prefixes = [
            'Could you please ', 'could you please ',
            'Would you please ', 'would you please ',
            'Can you please ', 'can you please ',
        ]
        for p in prefixes:
            if text.lower().startswith(p.lower()):
                text = text[len(p):].strip()
                break
        for sep in ['. ', ',', '? ', '! ', ';']:
            if sep in text:
                text = text.split(sep)[0].strip()
        words = text.split()
        if len(words) > ENGLISH_MAX_WORDS:
            text = ' '.join(words[:ENGLISH_MAX_WORDS]) + "..."

    return text if text else ""


def get_latest_user_instruction(transcript_path):
    """从会话记录中获取最新用户指令"""
    try:
        if not os.path.exists(transcript_path):
            return ""

        with open(transcript_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        # 从最后往前找，找到第一个包含实际文本的用户消息（跳过 tool_result）
        for line in reversed(lines):
            try:
                entry = json.loads(line.strip())
                entry_type = entry.get('type', '')

                if entry_type == 'user':
                    message = entry.get('message', {})
                    content = message.get('content', '')

                    if isinstance(content, list):
                        texts = []
                        has_tool_result = False
                        has_text = False
                        for item in content:
                            if isinstance(item, dict):
                                if item.get('type') == 'text':
                                    text = item.get('text', '')
                                    if text:
                                        texts.append(text)
                                        has_text = True
                                elif item.get('type') == 'tool_result':
                                    has_tool_result = True

                        # 只返回有实际文本的用户消息，跳过纯 tool_result
                        if has_tool_result and not has_text:
                            continue

                        if texts:
                            return ' '.join(texts)
                    return str(content) if content else ""

            except (json.JSONDecodeError, KeyError):
                continue

        return ""
    except Exception:
        return ""


def main():
    # 读取 stdin JSON（由 Claude Code 传入）
    input_data = sys.stdin.read()

    try:
        data = json.loads(input_data)

        # 从会话记录文件获取最新用户指令
        transcript_path = data.get("transcript_path", "")
        instruction = get_latest_user_instruction(transcript_path)

        if not instruction:
            print("[]")
            sys.exit(0)

        # 生成缓存键
        cache_key = get_cache_key(instruction)

        # 检查缓存是否有效
        if is_cache_valid(cache_key):
            # 使用缓存的摘要，避免执行过程中状态变化
            cached_summary = load_cached_summary()
            if cached_summary:
                print(STATUS_FORMAT.format(summary=cached_summary))
                sys.exit(0)

        # 生成新摘要
        summary = extract_task_summary(instruction)

        if summary:
            # 保存到缓存
            save_cached_summary(summary, cache_key)
            print(STATUS_FORMAT.format(summary=summary))
        else:
            print("[]")

    except json.JSONDecodeError:
        print("[Claude]")

    sys.exit(0)


if __name__ == "__main__":
    main()
