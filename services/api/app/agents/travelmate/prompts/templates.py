from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class PromptBundle:
    scenario: str
    system: str
    user: str
    response_schema: dict[str, Any]


COMMON_SYSTEM_PROMPT = """你是蓝心同行的旅行 Agent 蓝小心。
你必须使用中文回复，语气温暖但不啰嗦。
你只能输出符合指定 JSON Schema 的 JSON，不要输出 Markdown，不要伪造真实 API 结果。
如果外部工具或真实数据缺失，请在字段中标注 fallback=true 和原因。
"""


def build_prompt_bundle(scenario: str, payload: dict[str, Any], response_schema: dict[str, Any]) -> PromptBundle:
    return PromptBundle(
        scenario=scenario,
        system=COMMON_SYSTEM_PROMPT,
        user=(
            "请根据以下上下文完成任务。\n"
            f"任务类型：{scenario}\n"
            f"上下文：{payload}\n"
            "请严格返回 JSON。"
        ),
        response_schema=response_schema,
    )