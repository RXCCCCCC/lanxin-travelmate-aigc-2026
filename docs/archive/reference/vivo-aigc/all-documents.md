# vivo AIGC Documentation Mirror

> Source: https://aigc.vivo.com.cn/#/document/index
> Fetched at: 2026-06-29T02:23:55.919927+00:00
> Purpose: local reference knowledge base for integrating vivo/Lanxin AIGC capabilities in this repository.

---

## 使用指引

- Source: https://aigc.vivo.com.cn/#/document/index?id=1746
- Path: 文档中心 / 使用指引

| 能力名称 | 应用范围 | 能力类型 | 更新时间 | 更新说明 | |
| [大模型](https://aigc.vivo.com/#/document/index?id=1745) | 内容创作、知识问答、逻辑推理、代码生成、信息提取 | 云端api | | | |
| [图片生成](https://aigc.vivo.com/#/document/index?id=1732) | 文生图、图生图、风格转换、智能扩图/消除 | 云端api | 2026/06/05 | 新增Doubao-Seedream-5.0-lite模型，调整限制次数说明 | |
| [视频生成](https://aigc.vivo.com/#/document/index?id=2201) | 文生视频、图生视频、视频风格化、动态照片生成 | 云端api | 2026/06/05 | 新增Doubao-Seedance-2.0系列模型，调整限制次数说明 | |
| [通用OCR](https://aigc.vivo.com/#/document/index?id=1737) | 文档电子化、智能批改/阅卷、拍照或截图识别、文本审核与管理 | 云端api | | | |
| [实时短语音识别](https://aigc.vivo.com/#/document/index?id=1738) | 语音搜索、聊天输入、游戏娱乐、人机交互 | 云端api | | | |
| [方言自由说](https://aigc.vivo.com/#/document/index?id=2065) | 方言自由说 | 云端api | | | |
| [同声传译](https://aigc.vivo.com/#/document/index?id=2068) | 同声传译 | 云端api | | | |
| [长语音听写](https://aigc.vivo.com/#/document/index?id=1740) | 视频字幕、实时会议记录、智能外呼&客服 | 云端api | | | |
| [长语音转写](https://aigc.vivo.com/#/document/index?id=1739) | 电话客服、会议记录、字幕生成、语音质检 | 云端api | | | |
| [音频生成](https://aigc.vivo.com/#/document/index?id=1735) | 有声阅读、新闻播报、电话客服、信息播报、出行导航 | 云端api | | | |
| [超拟人音色](https://aigc.vivo.com/#/document/index?id=1735) | 超拟人音色 | 云端api | | | |
| [声音复制](https://aigc.vivo.com/#/document/index?id=2062) | 声音复刻 | 云端api | | | |
| [文本翻译](https://aigc.vivo.com/#/document/index?id=1733) | 文档电子化、智能批改/阅卷、拍照或截图识别、文本审核与管理 | 云端api | | | |
| [文本向量](https://aigc.vivo.com/#/document/index?id=1734) | 信息推荐、文档检索、知识挖掘 | 云端api | | | |
| [文本相似度](https://aigc.vivo.com/#/document/index?id=2060) | 文本相似度 | 云端api | | | |
| [查询改写](https://aigc.vivo.com/#/document/index?id=2061) | 查询改写 | 云端api | | | |
| [地理编码(POI搜索)](https://aigc.vivo.com/#/document/index?id=1736) | 生活购物、旅游规划 | 云端api | | | |

---

## 接入流程

- Source: https://aigc.vivo.com.cn/#/document/index?id=1677
- Path: 文档中心 / 鉴权方式

### []AppKEY获取

官网地址: https://aigc.vivo.com.cn/#/platform

### []使用

从[AIGC官网](https://aigc.vivo.com.cn/#/platform)中获取AppKey，替换接口文档中的`AppKey`，即可使用当前脚本能力。

| 参数 | 类型 | 是否必须 | 值 | |
| Authorization | String | 是 | Bearer AppKey | |

### []异常说明

若鉴权失败，接口将返回HTTP 401状态码，常见错误及解决方式如下：

| 响应体内容 | 说明 | 解决方法 | |
| `{"message":"missing required app_id in the request header"}` | 认证串格式或内容无效 | 检查请求头是否正确携带AppKey | |
| `{"message":"invalid api-key"}` | app_key无效 | 检查app_key是否正确 | |
| `{"message":"not having this ability, you need to apply for it"}` | 当前应用没有该能力 | 联系系统管理员 | |

### []参考示例

```

#!/usr/bin/env python
# encoding: utf-8

import requests
import base64
import uuid

# 请注意替换AppKey、PIC_FILE
AppKey = "your_AppKey"
DOMAIN = 'api-ai.vivo.com.cn'
URI = '/ocr/general_recognition'
METHOD = 'POST'
PIC_FILE = './test.jpg'

def ocr_test():
 picture = PIC_FILE
 with open(picture, "rb") as f:
 b_image = f.read()
 image = base64.b64encode(b_image).decode("utf-8")
 post_data = {"image": image, "pos": 2, "businessid": "aigc"+AppId}
 params = {
 "requestId": str(uuid.uuid4())
 }
 print(params['requestId'])
 headers = {
 # 注意该鉴权头的格式
 "Authorization": f"Bearer {AppKey}",
 "Content-type": "application/x-www-form-urlencoded",
 }
 url = 'http://{}{}'.format(DOMAIN, URI)
 response = requests.post(url, data=post_data, headers=headers,params=params, timeout=3)
 if response.status_code == 200:
 print(response.json())
 else:
 print(response.status_code, response.text)

if __name__ == '__main__':
 test()

```

---

## 大模型

- Source: https://aigc.vivo.com.cn/#/document/index?id=1745
- Path: 文档中心 / 接口文档 / 文本生成 / 大模型

### []接口说明

接口说明：该接口支持主流OpenAI协议格式、Responses API协议格式，以及三方自定义协议格式。

访问地址：https://api-ai.vivo.com.cn/v1/chat/completions

请求方式：POST

### []请求头：

| 参数 | 类型 | 是否必须 | 值 | |
| Content-Type | string | 是 | application/json | |
| Authorization | String | 是 | Bearer AppKey | |

### []请求参数：

| 参数 | 类型 | 是否必须 | 值 | |
| requestId | uuid | 是 | uuid | |

### []body参数

#### []通用参数

| 参数 | 子参数 | 是否必须 | 类型 | 参数值 | |
| model | | 是 | String | Volc-DeepSeek-V3.2
Doubao-Seed-2.0-mini
Doubao-Seed-2.0-lite
Doubao-Seed-2.0-pro
qwen3.5-plus | |
| messages | | 否 | object | | |
| | role | 是 | String | 发送消息的角色
可选角色：`system`, `user` | |
| | content | 是 | String / object | 系统消息的内容 | |
| stream | | 否 | bool | True：流式调用，False：非流式调用 | |
| **max_tokens** | | 否 | integer | 模型回答最大长度（单位 token）不包含思考内容。
默认值 4096 | |
| **max_completion_tokens** | | 否 | integer | 取值范围：[0, 65,536]
控制模型输出的最大长度（包括模型回答和模型思维链内容长度，单位 token） | |
| **reasoning_effort** | | 否 | String | 限制思考的工作量。减少思考深度可提升速度，思考花费的 token 更少。
minimal：关闭思考，直接回答。 （默认）
low：轻量思考，侧重快速响应
medium：均衡模式，兼顾速度与深度。
high：深度分析，处理复杂问题。 | |
| **temperature** | | 否 | float | 取值范围[0 , 2 ] , 默认值1 | |
| **top_p** | | 否 | float | 默认值0.7 | |
| 深度思考 | | 否 | | 模型：Volc-DeepSeek-V3.2 （默认 disabled）、Doubao-Seed-2.0-mini （默认 enabled）、Doubao-Seed-2.0-lite（默认 enabled）、Doubao-Seed-2.0-pro（默认 enabled）
字段：thinking.**type** ： "enable"

类型：String
enabled：开启思考模式，模型强制先思考再回答。
disabled：关闭思考模式，模型直接回答问题，不进行思考。

模型： qwen3.5-plus（默认 true）
字段：enable_thinking
类型：bool
设为`true`时：模型在思考后回复；
 设为`false`时：模型直接回复； | |
| **frequency_penalty** | | 否 | float | 取值范围为 [-2.0, 2.0]
频率惩罚系数。如值为正，根据新 token 在文本中的出现频率对其进行惩罚，从而降低模型逐字重复的可能性。 | |
| **presence_penalty** | | 否 | float | 取值范围为 [-2.0, 2.0]
存在惩罚系数。如果值为正，会根据新 token 到目前为止是否出现在文本中对其进行惩罚，从而增加模型谈论新主题的可能性。 | |
| tools | | 否 | | 示例：
[
 {
 “type”: “function”,
 “function”: {
 “name”: “get_current_weather”,
 “description”: “当你想查询指定城市的天气时非常有用。”,
 “parameters”: {
 “type”: “object”,
 “properties”: {
 “location”: {
 “type”: “string”,
 “description”: “城市或县区，比如北京市、杭州市、余杭区等。”
 }
 },
 “required”: [
 “location”
 ]
 }
 }
 }
] | |

### []请求示例

-
**curl格式**

-
默认

```

curl https://api-ai.vivo.com.cn/v1/chat/completions \
 -H "Content-Type: application/json" \
 -H "Authorization: Bearer $AppKey" \
 -d '{
 "model": "Volc-DeepSeek-V3.2",
 "messages": [
 {
 "role": "system",
 "content": "You are a helpful assistant."
 },
 {
 "role": "user",
 "content": "Hello!"
 }
 ]
 }'

```

-
流式

```

curl https://api-ai.vivo.com.cn/v1/chat/completions \
 -H "Content-Type: application/json" \
 -H "Authorization: Bearer $AppKey" \
 -d $'{
 "messages": [
 {
 "content": "You are a helpful assistant.",
 "role": "system"
 },
 {
 "content": "hello",
 "role": "user"
 }
 ],
 "model": "Volc-DeepSeek-V3.2",
 "stream": true
}'

```

-
图片理解

```

curl https://api-ai.vivo.com.cn/v1/chat/completions \
 -H "Content-Type: application/json" \
 -H "Authorization: Bearer $AppKey" \
 -d $'{
 "model": "Volc-DeepSeek-V3.2",
 "messages": [
 {
 "content": [
 {
 "image_url": {
 "url": "https://ark-project.tos-cn-beijing.volces.com/images/view.jpeg"
 },
 "type": "image_url"
 },
 {
 "text": "图片主要讲了什么?",
 "type": "text"
 }
 ],
 "role": "user"
 }
 ]
}'

```

-
**python-openai库**

-
同步请求

```

import uuid

import requests
from openai import OpenAI

AppKey = "your_AppKey"
BASE_URL = "https://api-ai.vivo.com.cn/v1"
MODEL_NAME = "Doubao-Seed-2.0-mini"

request_id = str(uuid.uuid4())
client = OpenAI(
 api_key=AppKey,
 base_url=BASE_URL,
 default_headers={
 "Content-Type": "application/json; charset=utf-8"
 },
 default_query={"request_id": request_id}
)

def sync_chat():
 try:
 response = client.chat.completions.create(
 model=MODEL_NAME,
 messages=[
 {"role": "user", "content": "你好，请介绍下你自己"}
 ],
 temperature=0.7,
 max_tokens=1024,
 stream=False,
 )
 content = response.choices[0].message.content
 print(f"回复内容：{content}")
 return content
 except Exception as e:
 print(f"请求出错，request_id={request_id}，错误信息：{str(e)}")

if __name__ == "__main__":
 sync_chat()

```

-
流式请求

```

import uuid
from openai import OpenAI

AppKey = "your_AppKey"
BASE_URL = "https://api-ai.vivo.com.cn/v1"
MODEL_NAME = "Doubao-Seed-2.0-mini"

client = OpenAI(
 api_key=AppKey,
 base_url=BASE_URL,
 default_headers={
 "Content-Type": "application/json; charset=utf-8"
 },
 default_query={"request_id": request_id}
)

def stream_chat():
 request_id = str(uuid.uuid4())
 try:
 response = client.chat.completions.create(
 model=MODEL_NAME,
 messages=[
 {"role": "user", "content": "你好，请介绍下你自己"}
 ],
 temperature=0.7,
 max_tokens=1024,
 stream=True,
 stream_options={"include_usage": True}
 )

 full_content = ""
 usage = None
 print("流式输出：\n")
 for chunk in response:
 if hasattr(chunk, 'usage') and chunk.usage:
 usage = chunk.usage
 continue
 if not chunk.choices:
 continue
 delta = chunk.choices[0].delta.content
 if delta:
 full_content += delta
 print(delta, end="", flush=True)
 print(f"\n\n===== 完整回复 =====\n{full_content}")
 if usage:
 print(f"\n===== Token消耗 =====\n输入：{usage.prompt_tokens}\n输出：{usage.completion_tokens}\n总计：{usage.total_tokens}")
 return full_content

 except Exception as e:
 print(f"请求出错，request_id={request_id}，错误信息：{str(e)}")

if __name__ == "__main__":
 stream_chat()

```

-
图片理解

```

import uuid
import base64
from openai import OpenAI

# 配置参数
AppKey = "your_AppKey"
BASE_URL = "https://api-ai.vivo.com.cn/v1"
MODEL_NAME = "Volc-DeepSeek-V3.2"

client = OpenAI(
 api_key=AppKey,
 base_url=BASE_URL,
 default_headers={
 "Content-Type": "application/json; charset=utf-8"
 },
 default_query={"request_id": request_id}
)

# 本地图片转base64工具函数，传本地图时使用
def image_to_base64(image_path):
 with open(image_path, "rb") as f:
 base64_str = base64.b64encode(f.read()).decode("utf-8")
 return f"data:image/jpeg;base64,{base64_str}"

def sync_image_chat():
 request_id = str(uuid.uuid4())
 try:
 response = client.chat.completions.create(
 model=MODEL_NAME,
 messages=[
 {
 "role": "user",
 "content": [
 {"type": "text", "text": "请描述这张图片里的内容，越详细越好"},
 {"type": "image_url", "image_url": {
 # 方式1：在线公共图片URL
 "url": "https://lf3-static.bytednsdoc.com/obj/eden-cn/ptlz_zlp/ljhwZthlaukjlkulzlp/root-web-sites/doubao_intro.png"
 # 方式2：本地图片转base64（需要取消下行注释并注释掉上方URL）
 # 需注意：传入Base64编码遵循格式 data:image/<IMAGE_FORMAT>;base64,{base64_image}：
 # PNG图片："url": f"data:image/png;base64,{base64_image}"
 # JPEG图片："url": f"data:image/jpeg;base64,{base64_image}"
 # WEBP图片："url": f"data:image/webp;base64,{base64_image}"
 # "url": f"data:image/<IMAGE_FORMAT>;base64,{base64_image}"
 # "url": image_to_base64("./test.jpg")
 }}
 ]
 }
 ],
 temperature=0.3,
 max_tokens=2048,
 stream=False,

 )
 content = response.choices[0].message.content
 usage = response.usage

 print(f"===== 图片解析结果 =====\n{content}")
 print(f"\n===== Token消耗 =====\n输入：{usage.prompt_tokens}\n输出：{usage.completion_tokens}\n总计：{usage.total_tokens}")
 return content

 except Exception as e:
 print(f"请求出错，request_id={request_id}，错误信息：{str(e)}")

if __name__ == "__main__":
 sync_image_chat()

```

-
**python-requests库**

-
同步请求

```

import uuid
import requests

AppKey = "your_AppKey"
BASE_URL = "https://api-ai.vivo.com.cn/v1"
MODEL_NAME = "Doubao-Seed-2.0-mini"

request_id = str(uuid.uuid4())

def sync_chat():
 url = f"{BASE_URL}/chat/completions"
 headers = {
 "Content-Type": "application/json; charset=utf-8",
 "Authorization": f"Bearer {AppKey}"
 }
 params = {
 "request_id": request_id
 }
 payload = {
 "model": MODEL_NAME,
 "messages": [
 {"role": "user", "content": "你好，请介绍下你自己"}
 ],
 "temperature": 0.7,
 "max_tokens": 1024,
 "stream": False
 }

 try:
 response = requests.post(
 url,
 headers=headers,
 params=params,
 json=payload,
 timeout=30
 )
 response.raise_for_status()
 response_data = response.json()
 content = response_data['choices'][0]['message']['content']
 print(f"回复内容：{content}")
 return content

 except Exception as e:
 print(f"请求出错，request_id={request_id}，错误信息：{str(e)}")
 if 'response' in locals() and response is not None:
 print(f"详细错误响应：{response.text}")

if __name__ == "__main__":
 sync_chat()

```

-
流式请求

```

import uuid
import requests
import json

AppKey = "your_AppKey"
BASE_URL = "https://api-ai.vivo.com.cn/v1"
MODEL_NAME = "Doubao-Seed-2.0-mini"

request_id = str(uuid.uuid4())

def stream_chat():
 url = f"{BASE_URL}/chat/completions"
 headers = {
 "Content-Type": "application/json; charset=utf-8",
 "Authorization": f"Bearer {AppKey}"
 }
 params = {
 "request_id": request_id
 }
 payload = {
 "model": MODEL_NAME,
 "messages": [
 {"role": "user", "content": "你好，请介绍下你自己，并计算一下9.9和9.11哪个大"}
 ],
 "temperature": 0.7,
 "max_tokens": 1024,
 "stream": True
 }

 try:
 response = requests.post(
 url,
 headers=headers,
 params=params,
 json=payload,
 timeout=30,
 stream=True
 )
 response.raise_for_status()

 full_thought = "" # 用于拼接完整思考过程
 full_content = "" # 用于拼接完整回复内容

 has_printed_thought_header = False
 has_printed_content_header = False

 for line in response.iter_lines():
 if line:
 decoded_line = line.decode('utf-8')
 if decoded_line.startswith("data:"):
 data_str = decoded_line.replace("data:", "", 1).strip()
 if data_str == "[DONE]":
 break
 try:
 data_json = json.loads(data_str)
 delta = data_json.get('choices', [{}])[0].get('delta', {})
 thought_piece = delta.get('reasoning_content', "")
 if thought_piece:
 if not has_printed_thought_header:
 print("\n🤔 思考过程：\n", end="", flush=True)
 has_printed_thought_header = True

 print(thought_piece, end="", flush=True)
 full_thought += thought_piece
 content_piece = delta.get('content', "")
 if content_piece:
 if not has_printed_content_header:
 print("\n\n🤖 回复内容：\n", end="", flush=True)
 has_printed_content_header = True

 print(content_piece, end="", flush=True)
 full_content += content_piece

 except json.JSONDecodeError:
 pass

 print()
 return {
 "thought": full_thought,
 "content": full_content
 }

 except Exception as e:
 print(f"\n请求出错，request_id={request_id}，错误信息：{str(e)}")
 if 'response' in locals() and response is not None:
 try:
 print(f"详细错误响应：{response.text}")
 except:
 pass

if __name__ == "__main__":
 result = stream_chat()

```

-
图片理解

```

import uuid
import base64
import requests

# 配置参数
AppKey = "your_AppKey" # 请替换为你自己的 AppKey
BASE_URL = "https://api-ai.vivo.com.cn/v1"
MODEL_NAME = "Doubao-Seed-2.0-mini"

# 本地图片转base64工具函数，传本地图时使用
def image_to_base64(image_path):
 with open(image_path, "rb") as f:
 base64_str = base64.b64encode(f.read()).decode("utf-8")
 return f"data:image/jpeg;base64,{base64_str}"

def sync_image_chat():
 request_id = str(uuid.uuid4())
 url = f"{BASE_URL}/chat/completions"

 headers = {
 "Content-Type": "application/json; charset=utf-8",
 "Authorization": f"Bearer {AppKey}"
 }

 params = {
 "request_id": request_id
 }
 payload = {
 "model": MODEL_NAME,
 "messages": [
 {
 "role": "user",
 "content": [
 {"type": "text", "text": "请描述这张图片里的内容，越详细越好"},
 {
 "type": "image_url",
 "image_url": {
 # 方式1：在线公共图片URL
 "url": "https://lf3-static.bytednsdoc.com/obj/eden-cn/ptlz_zlp/ljhwZthlaukjlkulzlp/root-web-sites/doubao_intro.png"

 # 方式2：本地图片转base64（需要取消下行注释并注释掉上方URL）
 # 需注意：传入Base64编码遵循格式 data:image/<IMAGE_FORMAT>;base64,{base64_image}：
 # PNG图片："url": f"data:image/png;base64,{base64_image}"
 # JPEG图片："url": f"data:image/jpeg;base64,{base64_image}"
 # WEBP图片："url": f"data:image/webp;base64,{base64_image}"
 # "url": f"data:image/<IMAGE_FORMAT>;base64,{base64_image}"
 # "url": image_to_base64("./test.jpg")
 }
 }
 ]
 }
 ],
 "temperature": 0.3,
 "max_tokens": 2048,
 "stream": False
 }

 try:
 response = requests.post(
 url,
 headers=headers,
 params=params,
 json=payload,
 timeout=60
 )
 response.raise_for_status()
 response_data = response.json()
 content = response_data['choices'][0]['message']['content']
 usage = response_data.get('usage', {})

 print(f"===== 图片解析结果 =====\n{content}")
 print(f"\n===== Token消耗 =====\n"
 f"输入：{usage.get('prompt_tokens', 0)}\n"
 f"输出：{usage.get('completion_tokens', 0)}\n"
 f"总计：{usage.get('total_tokens', 0)}")

 return content

 except Exception as e:
 print(f"\n请求出错，request_id={request_id}，错误信息：{str(e)}")
 if 'response' in locals() and response is not None:
 try:
 print(f"详细错误响应：{response.text}")
 except:
 pass

if __name__ == "__main__":
 sync_image_chat()

```

### []响应示例

-
同步请求

```

{
 "choices": [
 {
 "finish_reason": "stop",
 "index": 0,
 "logprobs": null,
 "message": {
 "content": "很抱歉呀，我没办法获取实时的日期和时间呢。你可以直接查看手机、电脑的状态栏或者日历应用来确认今天是星期几哦。如果需要我帮你推算特定日期对应的星期几，可以告诉我具体的日期和时区~",
 "reasoning_content": "用户现在问今天星期几，首先我需要说明我没办法获取实时的日期和时间哦，因为我的数据截止到2023年10月，而且没有实时联网的功能。然后可以告诉用户怎么看自己设备上的时间，比如手机、电脑的状态栏之类的。还要友好一点，比如如果用户需要确认具体日期的话，可以告诉我所在的时区或者大概的日期范围，我可以帮忙推算？不对，首先先明确，我没有实时数据，所以先解释清楚，然后给出建议。比如：“很抱歉呀，我没办法获取实时的日期和时间呢。你可以直接查看手机、电脑的状态栏或者日历应用来确认今天是星期几哦。如果需要我帮你推算特定日期对应的星期几，可以告诉我具体的日期和时区~” 对，这样应该就可以了，语气友好一点，符合豆包的设定。",
 "role": "assistant"
 }
 }
 ],
 "created": 1773715271,
 "id": "0217737152674454577c52c8dbdc08ff5e13b330e16e209c24544",
 "model": "doubao-seed-2.0-mini",
 "service_tier": "default",
 "object": "chat.completion",
 "usage": {
 "completion_tokens": 242,
 "prompt_tokens": 55,
 "total_tokens": 297,
 "prompt_tokens_details": {
 "cached_tokens": 0
 },
 "completion_tokens_details": {
 "reasoning_tokens": 189
 }
 }
}

```

-
流式请求

```

{"choices":[{"delta":{"content":"Hello","role":"assistant"},"index":0}],"created":1742632436,"id":"021742632435712396f12d018b5d576a7a55349c2eba0815061fc","model":"doubao-1-5-pro-32k-250115","service_tier":"default","object":"chat.completion.chunk","usage":null}

{"choices":[{"delta":{"content":"!","role":"assistant"},"index":0}],"created":1742632436,"id":"021742632435712396f12d018b5d576a7a55349c2eba0815061fc","model":"doubao-1-5-pro-32k-250115","service_tier":"default","object":"chat.completion.chunk","usage":null}

{"choices":[{"delta":{"content":" How","role":"assistant"},"index":0}],"created":1742632436,"id":"021742632435712396f12d018b5d576a7a55349c2eba0815061fc","model":"doubao-1-5-pro-32k-250115","service_tier":"default","object":"chat.completion.chunk","usage":null}

{"choices":[{"delta":{"content":" can","role":"assistant"},"index":0}],"created":1742632436,"id":"021742632435712396f12d018b5d576a7a55349c2eba0815061fc","model":"doubao-1-5-pro-32k-250115","service_tier":"default","object":"chat.completion.chunk","usage":null}

{"choices":[{"delta":{"content":" I","role":"assistant"},"index":0}],"created":1742632436,"id":"021742632435712396f12d018b5d576a7a55349c2eba0815061fc","model":"doubao-1-5-pro-32k-250115","service_tier":"default","object":"chat.completion.chunk","usage":null}

{"choices":[{"delta":{"content":" help","role":"assistant"},"index":0}],"created":1742632436,"id":"021742632435712396f12d018b5d576a7a55349c2eba0815061fc","model":"doubao-1-5-pro-32k-250115","service_tier":"default","object":"chat.completion.chunk","usage":null}

{"choices":[{"delta":{"content":" you","role":"assistant"},"index":0}],"created":1742632436,"id":"021742632435712396f12d018b5d576a7a55349c2eba0815061fc","model":"doubao-1-5-pro-32k-250115","service_tier":"default","object":"chat.completion.chunk","usage":null}

{"choices":[{"delta":{"content":" today","role":"assistant"},"index":0}],"created":1742632436,"id":"021742632435712396f12d018b5d576a7a55349c2eba0815061fc","model":"doubao-1-5-pro-32k-250115","service_tier":"default","object":"chat.completion.chunk","usage":null}

{"choices":[{"delta":{"content":"?","role":"assistant"},"index":0}],"created":1742632436,"id":"021742632435712396f12d018b5d576a7a55349c2eba0815061fc","model":"doubao-1-5-pro-32k-250115","service_tier":"default","object":"chat.completion.chunk","usage":null}

{"choices":[{"delta":{"content":"","role":"assistant"},"finish_reason":"stop","index":0}],"created":1742632436,"id":"021742632435712396f12d018b5d576a7a55349c2eba0815061fc","model":"doubao-1-5-pro-32k-250115","service_tier":"default","object":"chat.completion.chunk","usage":null}

[DONE]

```

### []常见问题

#### []错误码说明

| code | 错误信息 | 备注 | |
| 1001 | param ‘requestId’ can’t be empty 等等 | 参数异常，通常是缺少必填参数 | |
| 1007 | 抱歉，xxx | 触发审核后系统干预返回的内容 | |
| 30001 | no model access permission permission expires | 没有访问权限，或者权限到期，请联系官网客服 | |
| 30001 | hit model rate limit | 触发模型 QPS 限流，请降低请求频率 | |
| 2003 | today usage limit | 触发单日用量限制，请次日再重试 | |

#### []限流问题

触发限流后，data为null，msg为429或inner error，如果业务需要对触发限流没有返回结果的文本重新请求取得结果，建议增加重试机制，并且是间隔一段时间重试，但无法保证重试一定成功。注意代码逻辑正确性，不要出现无限重试的情况。

#### []messages如何使用？

messages中必须前面user和assistant成对出现，最后再加一个user。前面的user和assistant对表示用户的历史对话内容，历史对话内容可以是多轮，最后一个user表示最新一次用户的输入，只能有一个。一轮历史对话内容加最新输入的示例格式如下，按此格式扩展即可：

```

"messages": [
 {
 "role": "user",
 "content": "你是谁？"
 },
 {
 "role": "assistant",
 "content": "你好，我是蓝心小V，你的虚拟伙伴和闲聊好友。无论你心情如何，希望与你分享的话题有多么轻松或深奥，我都在这里随时准备和你聊上几句。所以，告诉我，今天的你，想要开始我们的对话从哪里呢？"
 },
 {
 "role": "user",
 "content": "你会做什么？"
 }
]

```

---

## Function calling

- Source: https://aigc.vivo.com.cn/#/document/index?id=1805
- Path: 文档中心 / 接口文档 / 文本生成 / Function calling

## []Function Call使用指南

### []Messages说明

直接调用API的话，需要用户自己封装system和解析数据。

Function call需要使用messages来进行调用，messages为一个列表，包含一条或者多条消息，一个完整的function call的messages示例如下：

```

[
 {'role':'system','content':'''你是一个AI助手，尽你所能回答用户的问题。

你可以使用的工具如下:
<APIs>
[
 {
 "name": "get_current_weather",
 "description": "Get the current weather",
 "parameters": {
 "type": "object",
 "properties": {
 "location": {
 "type": "string",
 "description": "The city and state, e.g. San Francisco, CA",
 },
 "format": {
 "type": "string",
 "enum": ["celsius", "fahrenheit"],
 "description": "The temperature unit to use. Infer this from the users location.",
 },
 },
 "required": ["location", "format"],
 },
 }
]
</APIs>

如果用户的问题需要调用工具，输出格式为：
<APIs>
[{"name": "函数名","parameters": {"参数名": "参数"}}]
</APIs>
否则直接回复用户。'''},
 {'role':'user','content':'杭州天气怎么样'},
 {"role":'assistant','content':'<APIs>[{"name": "get_current_weather", "parameters": {"location": "Hangzhou", "format": "celsius"}}]</APIs>'},
 {'role':'function','content':'杭州天气晴，27度'},
 {"role":'assistant','content':'您好，杭州天气晴朗，27度，祝您有个好心情。'}
]

```

每一条message为字典结构，包含role和content两个字段，其中role为角色，content为对应的内容。

| **角色** | **说明** | **举例** | |
| system | 系统角色，可以用于指定人设、回复格式、API说明、额外知识等内容。可以放任何你想让模型知道的内容。 | 你是蓝心小V，请你用萌妹子的口吻回复用户。 | |
| user | 用户的输入内容 | 你好 | |
| assistant | 大模型的回复，function call也是在这里 | [{“name”: “get_current_weather”, “parameters”: {“location”: “Hangzhou”, “format”: “celsius”}}] | |
| function | function调用结果，如果模型输出了function call，开发者需要将function call的结果通过这个角色给到大模型 | 杭州天气晴，27度 | |

## []System构成

一个基本的function call的system包含的信息如下，只需要将您的api定义替换掉{api_desc}即可。

-
3-12行为固定格式，建议保持一致。

-
角色和功能说明 system：填入您自定义的system内容

-
APIs：API的说明，后面会详细介绍

-
**格式返回说明：要求模型返回结构化的字段，包括回复和function call两个信息，二者只会有一个有值。建议先用默认格式，因为训练数据中大部分都为这种格式。**

- 这块比较核心，如果没有指定返回格式，则无法判断何时为function call何时为正常回复

-
如果有额外的信息需要模型知道，请参考LUI格式使用格式将信息放在角色和功能说明中

```
你是xxxx，你可以xxxx

用户的信息如下：
<Knowledge>
姓名：小白
年龄：33
爱好：看书、跑步
</Knowledge>

你需要xxxxx

你可以使用的工具如下:
...
否则直接回复用户。

```

#### []API定义

API推荐使用json格式。

使用Json格式定义API的好处

- 训练数据中大部分API都是采用Json格式定义，因此，在使用时采用和训练一致的API格式可以更好保证效果

- 业界统一使用Json格式的API定义，如OpenAI，Claude，智谱等，方便切换接口，或者使用其他接口构建数据

如下例：

```

{
 "name": "get_current_weather",
 "description": "Get the current weather",
 "parameters": {
 "type": "object",
 "properties": {
 "location": {
 "type": "string",
 "description": "The city and state, e.g. San Francisco, CA",
 },
 "format": {
 "type": "string",
 "enum": ["celsius", "fahrenheit"],
 "description": "The temperature unit to use. Infer this from the users location.",
 },
 },
 "required": ["location", "format"],
 },
}

```

每个API说明包含3个必须的字段：

- name: API的名称，最终模型返回时会使用这个name
- description: API的说明，说明这个API的功能和作用，也可以包含API的限制，以及一些示例
- parameters: API的参数，核心是properties，包含了参数名称(key)，和参数的类型和说明（value）。required指定哪些是必须的参数。

参考：

- https://platform.openai.com/docs/api-reference/chat/create#chat-create-tools
- https://docs.anthropic.com/claude/docs/tool-use#specifying-tools
- https://open.bigmodel.cn/dev/howuse/functioncall

---

## 图片生成

- Source: https://aigc.vivo.com.cn/#/document/index?id=1732
- Path: 文档中心 / 接口文档 / 图片生成 / 图片生成

#### []接口说明

接口说明：该接口提供图片生成能力，可根据输入的文本或图片生成图片

访问地址：https://api-ai.vivo.com.cn/api/v1/image_generation

限制说明：每个模型每天限制提交50次图片生成任务，总共限制提交500次任务，请勿滥用接口

#### []请求参数

请求头

| 参数 | 类型 | 是否必须 | 值 | |
| Content-Type | string | 是 | application/josn | |
| Authorization | String | 是 | Bearer AppKey | |

URL参数

| 参数 | 类型 | 说明 | 是否必填 | 备注 | |
| module | string | 模块名称 | 是 | 填写“aigc" | |
| request_id | string | 请求id | 是 | 使用uuid | |
| system_time | int | 时间戳 | 是 | 请求时的Unix时间戳，以秒为单位 | |

Body参数

| 参数 | 类型 | 说明 | 是否必填 | 备注 | |
| model | string | 模型名称 | 是 | 支持的模型：
Doubao-Seedream-4.5
Doubao-Seedream-5.0-lite | |
| prompt | string | 文本 | 是 | | |
| image | string/list | 图片链接/图片base64编码 | 否 | 单张图使用url或base64编码，多张图使用[url, url]或[base64, base64]
（1）图片URL：请确保图片URL有效且可被访问。
（2）base64编码：请遵循此格式`data:image/<图片格式>;base64,<Base64编码>`。注意`<图片格式>`需小写，如`data:image/png;base64,<base64_image>` | |
| parameters | object | 其它参数 | 否 | 其他额外支持的参数放到parameters中 | |
| ↳ size | string | 图像分辨率 | 否 | 指定生成图片的尺寸或分辨率。 | |
| ↳ sequential_image_generation | string | 组图开关 | 否 | 默认 `disabled`。选值：`auto` (自动生成组图), `disabled` (单图)。 | |
| ↳ sequential_image_generation_options | object | 组图配置 | 否 | 组图功能的配置项，仅当 `sequential_image_generation` 为 `auto` 时生效。 | |

##### []请求body示例

1.文生图

```

{
 "model": "Doubao-Seedream-4.5",
 "prompt": "一张温暖的日落海边照片，细节丰富，自然色彩"
}

```

2.文生图（指定分辨率）

```

{
 "model": "Doubao-Seedream-4.5",
 "prompt": "梦幻森林场景，光束穿透树冠，超清细节",
 "parameters": {
 "size": "2K"
 }
}

```

3.文生图（使用base64编码）

```

{
 "model": "Doubao-Seedream-4.5",
 "prompt": "画一个少女骑自行车的图片",
 "image": "data:image/webp;base64,UklGRrqAAABXRUJ******XlmUQG6Y0szwqYAAAA==",
 "parameters": {
 "prompt_extend": false,
 "size": "2K"
 }
}

```

4.图生图

```

{
 "model": "Doubao-Seedream-4.5",
 "prompt": "将参考图片转换成油画风格，同时保持主体构图一致",
 "image": "https://example.com/reference.jpg",
 "parameters": {
 "size": "2048x2048",
 "watermark": false
 }
}

```

##### []响应结果

响应header

| 字段 | 类型 | 说明 | |
| Content-Type | string | application/json | |

响应Body

| 参数 | 类型 | 说明 | 是否必填 | 备注 | |
| code | int | 错误码 | 是 | 0为响应正常，其它表示异常 | |
| message | string | 错误信息 | 是 | | |
| trace_id | string | 追溯id | 是 | 用于排查问题 | |
| data | object | 响应数据 | 是 | | |
| -image | string | 图片链接 | 是 | 即将废弃，生成的图片建议统一从images中获取（2026/04/13更新） | |
| -images | list | 生成的图片列表 | 是 | | |
| –url | string | 图片链接 | 是 | | |
| –size | string | 图片大小 | 是 | | |
| -finish_reason | string | 结束原因 | 是 | | |
| -usage | object | 输出信息 | 是 | | |
| –image_count | int | 生成图片数量 | 是 | | |
| –width | int | 图片宽度 | 是 | | |
| –height | int | 图片高度 | 是 | | |
| –input_tokens | int | 输入tokens | 否 | | |
| –output_tokens | int | 输出tokens | 否 | | |
| –total_tokens | int | 总tokens | 否 | | |
| -provider_request_id | string | 模型侧响应id | 是 | | |

正常响应示例

1.响应单张图

```

{
 "code": 0,
 "message": "success",
 "trace_id": "4880ae91-c429-4a70-ae67-1ffe6eaca958",
 "data": {
 "image": "https://ark-content-generation-v2-cn-beijing.tos-cn-beijing.volces.com/doubao-seedream-4-5/021775716043487a1f159c8749400f11e6b8ebd4b19bd2e1b4edd_0.jpeg?X-Tos-Algorithm=TOS4-HMAC-SHA256&X-Tos-Credential=AKLTYWJkZTExNjA1ZDUyNDc3YzhjNTM5OGIyNjBhNDcyOTQ%2F20260409%2Fcn-beijing%2Ftos%2Frequest&X-Tos-Date=20260409T062732Z&X-Tos-Expires=86400&X-Tos-Signature=8387f70531f2426287e2cf19eea1db225441aacbd27ca43133d55c19da804de7&X-Tos-SignedHeaders=host",
 "images": [
 {
 "url": "https://ark-content-generation-v2-cn-beijing.tos-cn-beijing.volces.com/doubao-seedream-4-5/021775716043487a1f159c8749400f11e6b8ebd4b19bd2e1b4edd_0.jpeg?X-Tos-Algorithm=TOS4-HMAC-SHA256&X-Tos-Credential=AKLTYWJkZTExNjA1ZDUyNDc3YzhjNTM5OGIyNjBhNDcyOTQ%2F20260409%2Fcn-beijing%2Ftos%2Frequest&X-Tos-Date=20260409T062732Z&X-Tos-Expires=86400&X-Tos-Signature=8387f70531f2426287e2cf19eea1db225441aacbd27ca43133d55c19da804de7&X-Tos-SignedHeaders=host",
 "size": "2048x2048"
 }
 ],
 "finish_reason": "stop",
 "usage": {
 "image_count": 1,
 "input_tokens": null,
 "output_tokens": 16384,
 "total_tokens": 16384
 },
 "provider_request_id": ""
 }
}

```

2.响应多张图

```

{
 "code": 0,
 "message": "success",
 "trace_id": "6f016d94-b3e1-4a39-bed0-ce1f2ecd9dc5",
 "data": {
 "image": "https://ark-acg-cn-beijing.tos-cn-beijing.volces.com/doubao-seedream-5-0/021775717005703746a7620dda4a28d54e5c02b79b9456a84af80_0.png?X-Tos-Algorithm=TOS4-HMAC-SHA256&X-Tos-Credential=AKLTYWJkZTExNjA1ZDUyNDc3YzhjNTM5OGIyNjBhNDcyOTQ%2F20260409%2Fcn-beijing%2Ftos%2Frequest&X-Tos-Date=20260409T064431Z&X-Tos-Expires=86400&X-Tos-Signature=e32e72b0f77323c8e644bb302145cb341253cf40918769000579f681ce27d9e0&X-Tos-SignedHeaders=host",
 "images": [
 {
 "url": "https://ark-acg-cn-beijing.tos-cn-beijing.volces.com/doubao-seedream-5-0/021775717005703746a7620dda4a28d54e5c02b79b9456a84af80_0.png?X-Tos-Algorithm=TOS4-HMAC-SHA256&X-Tos-Credential=AKLTYWJkZTExNjA1ZDUyNDc3YzhjNTM5OGIyNjBhNDcyOTQ%2F20260409%2Fcn-beijing%2Ftos%2Frequest&X-Tos-Date=20260409T064431Z&X-Tos-Expires=86400&X-Tos-Signature=e32e72b0f77323c8e644bb302145cb341253cf40918769000579f681ce27d9e0&X-Tos-SignedHeaders=host",
 "size": "2048x2048"
 },
 {
 "url": "https://ark-acg-cn-beijing.tos-cn-beijing.volces.com/doubao-seedream-5-0/021775717005703746a7620dda4a28d54e5c02b79b9456a84af80_1.png?X-Tos-Algorithm=TOS4-HMAC-SHA256&X-Tos-Credential=AKLTYWJkZTExNjA1ZDUyNDc3YzhjNTM5OGIyNjBhNDcyOTQ%2F20260409%2Fcn-beijing%2Ftos%2Frequest&X-Tos-Date=20260409T064438Z&X-Tos-Expires=86400&X-Tos-Signature=b66c4225f03807ca7f587a77e10f6740d98345a4f2b2a7b904c0dad081f65dd5&X-Tos-SignedHeaders=host",
 "size": "2048x2048"
 },
 {
 "url": "https://ark-acg-cn-beijing.tos-cn-beijing.volces.com/doubao-seedream-5-0/021775717005703746a7620dda4a28d54e5c02b79b9456a84af80_2.png?X-Tos-Algorithm=TOS4-HMAC-SHA256&X-Tos-Credential=AKLTYWJkZTExNjA1ZDUyNDc3YzhjNTM5OGIyNjBhNDcyOTQ%2F20260409%2Fcn-beijing%2Ftos%2Frequest&X-Tos-Date=20260409T064444Z&X-Tos-Expires=86400&X-Tos-Signature=4e2d25c74a7fc6d5ae74f22975201fab041619e51f98ab2c2e8b84d54f421147&X-Tos-SignedHeaders=host",
 "size": "2048x2048"
 },
 {
 "url": "https://ark-acg-cn-beijing.tos-cn-beijing.volces.com/doubao-seedream-5-0/021775717005703746a7620dda4a28d54e5c02b79b9456a84af80_3.png?X-Tos-Algorithm=TOS4-HMAC-SHA256&X-Tos-Credential=AKLTYWJkZTExNjA1ZDUyNDc3YzhjNTM5OGIyNjBhNDcyOTQ%2F20260409%2Fcn-beijing%2Ftos%2Frequest&X-Tos-Date=20260409T064449Z&X-Tos-Expires=86400&X-Tos-Signature=1bc94bbeb7725fac8488fb49e8b7c7846467482bf9b772a23fd3797450b4e0df&X-Tos-SignedHeaders=host",
 "size": "2048x2048"
 }
 ],
 "finish_reason": "stop",
 "usage": {
 "image_count": 4,
 "input_tokens": null,
 "output_tokens": 65536,
 "total_tokens": 65536
 },
 "provider_request_id": ""
 }
}

```

#### []错误响应

code说明

| http状态码 | code | 说明 | |
| 200 | 1001 | 请求参数错误，请检查url和body参数是否符合要求 | |
| 200 | 1002 | 没有权限 | |
| 200 | 1003 | 触发限流，提交任务过于频繁，超出限流阈值 | |
| 200 | 1004 | 输入/输出内容审核不通过 | |
| 200 | 3001 | 接口响应异常 | |
| 500 | 5001 | 未知错误 | |
| 500 | 5002 | 系统错误 | |

错误响应示例

1.触发限流

```

{
 "code": 1003,
 "message": "Rate limit exceeded for model Doubao-Seedream-4.5",
 "trace_id": "893fc939-26e4-4494-9772-282a414260b2",
 "data": {
 "rate_limit": {
 "allowed": false,
 "app_id": "2026899407",
 "category": "image",
 "total_limit": 300, # 总的任务提交次数限制
 "total_used": 11, # 已提交的任务次数
 "total_remaining": 289, # 剩余可提交的任务次数
 "daily_limit": 10, # 今日可提交的任务次数
 "daily_used": 10, # 今日已提交的任务次数
 "daily_remaining": 0 # 今日剩余可提交的任务次数
 }
 }
}

```

2.权限缺失

出现这个问题请在用户群联系小助手

```

{
 "code": 1002,
 "message": "app_id not have model permission",
 "trace_id": "5bebe957-4c05-410b-abff-c30ddd0d4c2f",
 "data": null,
}

```

#### []使用须知

1、生成图片耗时

一般情况下生成一张图片需要10-30秒左右，图片越高清生成耗时则越高，如果生成多张图片，则生成耗时可能增加翻几倍，接口请求超时时间建议最少设置为60秒。

---

## 视频生成

- Source: https://aigc.vivo.com.cn/#/document/index?id=2201
- Path: 文档中心 / 接口文档 / 视频生成 / 视频生成

#### []接口说明

接口介绍

- 提交任务：提交视频生成任务
- 查询任务：根据task_id查询任务的状态和结果

限制：每个模型每天限制提交10次视频生成任务，总共限制生成200个视频，请勿滥用接口

#### []提交任务

URL：https://api-ai.vivo.com.cn/api/v1/submit_task

请求方式：POST

| 参数 | 类型 | 是否必须 | 值 | |
| Content-Type | string | 是 | application/json | |
| Authorization | String | 是 | Bearer AppKey | |

##### []请求参数

URL参数

| 参数 | 类型 | 说明 | 是否必填 | 备注 | |
| request_id | string | 请求id | 是 | 使用uuid | |
| system_time | int | 时间戳 | 是 | 请求时的Unix时间戳，以秒为单位 | |
| module | string | 模块名称 | 是 | 填写"aigc" | |

Body参数

| 参数 | 类型 | 说明 | 是否必填 | 备注 | |
| model | string | 模型名称 | 是 | 支持的模型
Doubao-Seedance-1.0-pro
Doubao-Seedance-2.0
Doubao-Seedance-2.0-fast | |
| content | object | 给模型的信息 | 是 | 详见请求示例 | |

请求示例1（文生视频）

```

{
 "model": "Doubao-Seedance-1.0-pro",
 "content": [
 {
 "type": "text",
 "text": "多个镜头。一名侦探进入一间光线昏暗的房间。他检查桌上的线索，手里拿起桌上的某个物品。镜头转向他正在思索。 --ratio 16:9"
 }
 ]
}

```

请求示例2（图生视频 首帧）

```

{
 "model": "Doubao-Seedance-1.0-pro",
 "content": [
 {
 "type": "text",
 "text": "女孩抱着狐狸，女孩睁开眼，温柔地看向镜头，狐狸友善地抱着，镜头缓缓拉出，女孩的头发被风吹动 --ratio adaptive --dur 5"
 },
 {
 "type": "image_url",
 "image_url": {
 "url": "https://ark-project.tos-cn-beijing.volces.com/doc_image/i2v_foxrgirl.png"
 }
 }
 ]
}

```

请求示例3（图生视频 首尾帧）

```

{
 "model": "Doubao-Seedance-1.0-pro",
 "content": [
 {
 "type": "text",
 "text": "360度环绕运镜"
 },
 {
 "type": "image_url",
 "image_url": {
 "url": "https://ark-project.tos-cn-beijing.volces.com/doc_image/seepro_first_frame.jpeg"
 },
 "role": "first_frame"
 },
 {
 "type": "image_url",
 "image_url": {
 "url": "https://ark-project.tos-cn-beijing.volces.com/doc_image/seepro_last_frame.jpeg"
 },
 "role": "last_frame"
 }
 ]
}

```

##### []响应参数

响应header

| 字段 | 类型 | 说明 | |
| Content-Type | string | application/json | |

响应body

```

{
 "code": 0,
 "message": "success",
 "trace_id": "3480c3bb-1fe3-4ab5-8e28-3a7c8d268d52",
 "data": {
 "id": "cgt-20251120222028-kq4xj" # 任务id，查询任务时需要根据这个id查询结果
 }
}

```

#### []查询任务

URL：https://api-ai.vivo.com.cn/api/v1/query_task

请求方式：GET

##### []请求参数

请求头

| 参数 | 类型 | 是否必须 | 值 | |
| Content-Type | string | 是 | application/json | |
| Authorization | String | 是 | Bearer AppKey | |

URL参数

| 参数 | 类型 | 说明 | 是否必填 | 备注 | |
| task_id | string | 任务id | 是 | 提交任务后，接口返回的任务id | |
| request_id | string | 请求id | 是 | 使用uuid | |
| system_time | int | 时间戳 | 是 | 请求时的Unix时间戳，以秒为单位 | |
| module | string | 模块名称 | 是 | 填写"aigc" | |

##### []响应参数

响应header

| 字段 | 类型 | 说明 | |
| Content-Type | string | application/json | |

响应body

```

{
 "code": 0,
 "message": "success",
 "trace_id": "30f93896-b173-460c-bea8-5aae904e881f",
 "data": {
 "id": "cgt-20251120104400-pws48",
 "model": "doubao-seedance-1-0-pro-250528",
 "status": "succeeded",
 "content": {
 "video_url": "https://ark-content-generation-cn-beijing.tos-cn-beijing.volces.com/doubao-seedance-1-0-pro/02176360664282000000000000000000000ffffac1918e142eeee.mp4?X-Tos-Algorithm=TOS4-HMAC-SHA256&X-Tos-Credential=AKLTYWJkZTExNjA1ZDUyNDc3YzhjNTM5OGIyNjBhNDcyOTQ%2F20251120%2Fcn-beijing%2Ftos%2Frequest&X-Tos-Date=20251120T024504Z&X-Tos-Expires=86400&X-Tos-Signature=0b7db97fc6a910c025bc84e495a5b65662e1dcd0d63888030331e290ac6e0dfc&X-Tos-SignedHeaders=host",
 "last_frame_url": null
 },
 "error": null,
 "seed": 54785,
 "resolution": "1080p",
 "ratio": "16:9",
 "duration": 5,
 "frames": null,
 "framespersecond": 24,
 "usage": {
 "completion_tokens": 246840,
 "total_tokens": 246840
 },
 "created_at": 1763606642,
 "updated_at": 1763606704
 }
}

```

#### []错误响应

响应header

| 字段 | 类型 | 说明 | |
| Content-Type | string | application/json | |

响应body

| 参数 | 类型 | 说明 | |
| code | int | 错误码，0表示成功，其它表示异常 | |
| message | string | 错误信息，成功时返回success，其它表示异常 | |
| trace_id | string | 用于排查定位问题的uuid，由服务端自动生成的唯一id | |
| data | object | 响应的额外数据 | |

code说明

| http状态码 | code | 说明 | |
| 200 | 1001 | 请求参数错误，请检查url和body参数是否符合要求 | |
| 200 | 1002 | 没有权限 | |
| 200 | 1003 | 触发限流，提交任务过于频繁，超出限流阈值，data中会返回对应的限流阈值 | |
| 200 | 3001 | 接口响应异常 | |
| 200 | 3002 | 查询任务时没有找到对应任务 | |
| 500 | 5001 | 未知错误 | |
| 500 | 5002 | 系统错误 | |

错误响应示例

1.触发限流

```

{
 "code": 1003,
 "message": "Rate limit exceeded",
 "trace_id": "f20b8888-931d-4da9-9610-ab70ea6eb65a",
 "data": {
 "rate_limit": {
 "allowed": false,
 "app_id": "2026899407",
 "category": "video",
 "total_limit": 50, # 总的限制
 "total_used": 6, # 已提交任务次数
 "total_remaining": 44, # 剩余可提交任务次数
 "daily_limit": 5, # 今日限制
 "daily_used": 5, # 今日已提交任务限制
 "daily_remaining": 0 # 今日剩余可提交任务次数
 }
 }
}

```

2.任务未找到

```

{
 "code": 3002,
 "message": "Task cgt-20251121150741-s2mvqs not found",
 "trace_id": "21a91f69-0d46-4979-bf00-3a767340b75f",
 "data": null
}

```

---

## 通用OCR

- Source: https://aigc.vivo.com.cn/#/document/index?id=1737
- Path: 文档中心 / 接口文档 / 视觉技术 / 通用OCR

### []服务简介

识别用户向服务请求的某张图中的所有文字，并返回文字在图片中的位置信息，方便用户进行文字排版的二次处理参考。

### []接口说明

访问地址：http://api-ai.vivo.com.cn/ocr/general_recognition

访问方式：POST

### []请求参数

#### []**Header**

| 参数 | 类型 | 是否必须 | 值 | |
| Content-Type | string | 是 | application/x-www-form-urlencoded | |
| Authorization | String | 是 | Bearer AppKey | |

#### []查询参数

| 参数 | 类型 | 是否必须 | 值 | |
| requestId | uuid | 是 | uuid值 | |

#### []**Body**

| **参数名称** | **类型** | **是否必须** | **说明** | |
| image | string | 是 | 图像数据，base64编码（目前只支持识别jpg、png、bmp格式的图片） | |
| pos | string/int | 是 | 可取值为0、1、2。0代表只需要文字信息；1代表提供文字信息和坐标信息（坐标绝对值）；2代表将0和1的信息同时提供（坐标为相对值），建议取pos=2 | |
| businessid | string | 是 | “aigc”+appid | |
| sessid | string | 否 | 使用uuid，前端传递 | |

**businessid补充说明：**

-
1990173156ceb8a09eee80c293135279，支持旋转图像、非正向文字识别

-
8bf312e702043779ad0f2760b37a0806，只支持正向文字识别，耗时比1990小

### []响应结果

| **参数** | **类型** | **说明** | |
| error_code | int | 0: 成功，1: ocr识别失败，2: 图像错误 | |
| error_msg | string | succ：成功，ocr fail：识别失败，no parameter image：未上传图片 | |
| result | json | 请求参数pos为0结果提供文字信息，pos为1结果提供文字信息和坐标信息（绝对值），pos为2结果提供0和1的信息（坐标为相对值） | |
| version | string | ocr_VUG_v2.1.0_20200715 | |
| support | string | VIVO识图提供技术支持 | |

result示例

请求参数pos为0

```

# angle可选的值为0/90/180/270
{
 "result": {
 "words": [
 {"words": "取消"},
 {"words": "编辑"}
 ],
 "angle": 0
 }
}

```

请求参数pos为1

```

# angle可选的值为0/90/180/270，top_left：左上，top_right：右上，down_left：左下，down_right：右下，x、y：像素百分比
{
 "result": {
 "OCR": [
 {
 "words": "取消",
 "location": {
 "top_left": {"x": 658.0, "y": 1130.0},
 "top_right": {"x": 893.0, "y": 1130.0},
 "down_left": {"x": 658.0, "y": 1174.0},
 "down_right": {"x": 893.0, "y": 1174.0}
 }
 },
 {
 "words": "编辑",
 "location": {
 "top_left": {"x": 398.0, "y": 825.0},
 "top_right": {"x": 1912.0, "y": 825.0},
 "down_left": {"x": 398.0, "y": 1004.0},
 "down_right": {"x": 1912.0, "y": 1004.0}
 }
 }
 ],
 "angle": 0
 }
}

```

### []调用示例

python示例

备注：鉴权文档[鉴权方式-AppKey获取](https://aigc.vivo.com/#/document/index?id=1677)

```

#!/usr/bin/env python
# encoding: utf-8

import requests
import base64
import uuid

# 请注意替换AppId、AppKey、PIC_FILE
AppId = 'your_AppId'
AppKey = "your_AppKey"
DOMAIN = 'api-ai.vivo.com.cn'
URI = '/ocr/general_recognition'
METHOD = 'POST'
PIC_FILE = './test.jpg'

def ocr_test():
 picture = PIC_FILE
 with open(picture, "rb") as f:
 b_image = f.read()
 image = base64.b64encode(b_image).decode("utf-8")
 post_data = {"image": image, "pos": 2, "businessid": "aigc"+AppId}
 params = {
 "requestId": str(uuid.uuid4())
 }
 print(params['requestId'])
 headers = {
 "Authorization": f"Bearer {AppKey}",
 "Content-type": "application/x-www-form-urlencoded",
 }
 url = 'http://{}{}'.format(DOMAIN, URI)
 response = requests.post(url, data=post_data, headers=headers,params=params, timeout=3)
 if response.status_code == 200:
 print(response.json())
 else:
 print(response.status_code, response.text)

if __name__ == '__main__':
 ocr_test()

```

---

## 文本翻译

- Source: https://aigc.vivo.com.cn/#/document/index?id=1733
- Path: 文档中心 / 接口文档 / 自然语言处理 / 文本翻译

#### []能力简介

将一段源语言文本转换成目标语言文本，可根据语言参数的不同实现多国语言之间的互译。

#### []接口说明

访问地址：https://api-ai.vivo.com.cn/translation/query/self

访问方式：`POST`

#### []请求参数

##### []Header

| 参数 | 类型 | 是否必须 | 值 | |
| Content-Type | string | 是 | application/json | |
| Authorization | String | 是 | Bearer AppKey | |

#### []查询参数

| 参数 | 类型 | 是否必须 | 值 | |
| requestId | uuid | 是 | uuid值 | |

##### []Body

| 参数名称 | 类型 | 是否必须 | 示例值 | 描述 | |
| from | string | 是 | en | 源语言，语言code见下方语言代码对照表 | |
| to | string | 是 | zh-CHS | 目标语言，语言code见下方语言代码对照表 | |
| text | string | 是 | hello | 需要翻译的句子，utf-8编码，长度限制1200 | |
| app | string | 是 | test | 应用包名称，填写"test" | |
| requestId | string | 是 | 6bb798a1-3b5d-4f57-8a82-c480b56c14df | 请求id，比如uuid | |

#### []响应结果

##### []Header

| 参数名称 | 参数值 | 描述 | |
| Content-Type | multipart/form-data | | |

##### []Body

| 参数名称 | 类型 | 是否必须 | 示例值 | 描述 | |
| code | number | 否 | | | |
| data | object | 否 | | | |
| +from | string | 否 | | | |
| +to | string | 否 | | | |
| +translation | string | 否 | | 翻译结果 | |
| +text | string | 否 | | | |
| msg | null | 否 | | | |
| requestId | | 否 | | | |

响应结果示例

```

{
 "code": 0,
 "data": {
 "text": "我很好",
 "from": "zh-CHS",
 "to": "en",
 "translation": "I'm fine"
 },
 "msg": "",
 "requestId": "uuid"
}

```

#### []调用示例

备注：鉴权文档[鉴权方式-AppKey获取](https://aigc.vivo.com/#/document/index?id=1677)

```

# encoding: utf-8

import uuid
import requests

# 注意替换AppId、AppKey
AppId = 'your_AppId'
AppKey = "your_AppKey"
URI = '/translation/query/self'
DOMAIN = 'api-ai.vivo.com.cn'
METHOD = 'POST'

def text_translate():
 text = "I'm fine"
 data = {
 'from': 'en',
 'to': 'zh-CHS',
 'text': text,
 'app': 'test',
 'requestId': str(uuid.uuid4())
 }
 params = {
 "requestId": str(uuid.uuid4())
 }
 print(params['requestId'])
 headers = {
 "Authorization": f"Bearer {AppKey}",
 "Content-type": "application/json",
 }
 print('headers', headers)
 url = 'https://{}{}'.format(DOMAIN, URI)

 res = requests.post(url=url, headers=headers, data=data, params=params)

 if res.status_code == 200:
 print(res.json())
 else:
 print(res.status_code, res.text)

if __name__ == '__main__':
 text_translate()

```

**错误返回code**

| code | 解释 | |
| 10000 | 服务器异常 | |
| 20000 | 参数错误 | |

#### []语言代码对照表

下表为各语言对应代码：

其中auto可以识别中文、英文、日文、韩文。

| 语言 | 代码 | |
| 中文 | zh-CHS | |
| 英文 | en | |
| 日文 | ja | |
| 韩文 | ko | |

---

## 文本向量

- Source: https://aigc.vivo.com.cn/#/document/index?id=1734
- Path: 文档中心 / 接口文档 / 自然语言处理 / 文本向量

#### []服务简介

将用户提供的文本信息表示成计算机可识别的实数向量，用数值向量来表示文本的语义。

#### []接口说明

访问地址：https://api-ai.vivo.com.cn/embedding-model-api/predict/batch

访问方式：POST

#### []请求参数

**Header**

| 参数 | 类型 | 是否必须 | 值 | |
| Content-Type | string | 是 | application/json | |
| Authorization | String | 是 | Bearer AppKey | |

#### []查询参数

| 参数 | 类型 | 是否必须 | 值 | |
| requestId | uuid | 是 | uuid值 | |

**Body**

| **参数名称** | **类型** | **是否必须** | **说明** | |
| model_name | string | 是 | 文本向量化模型名称，当前支持：m3e-base、bge-base-zh-v1.5 | |
| sentences | array | 是 | 需要向量化文本的JSON格式数组，示例：[“自动追焦相关报表”, “太古汇内云集逾180家知名品牌”] | |

model_name说明

| model_name | 说明 | |
| bge-base-zh-v1.5 | 近期开源很优秀的模型，擅长中文的召回场景，即较短的query召回较长的文本。query前面需要加上instruction：“为这个句子生成表示以用于检索相关文章：”。介绍见[https://huggingface.co/BAAI/bge-base-zh-v1.5](https://huggingface.co/BAAI/bge-base-zh-v1.5) | |
| m3e-base | 近期开源很优秀的模型，擅长中文的文本比对场景，介绍见[https://huggingface.co/moka-ai/m3e-base](https://huggingface.co/moka-ai/m3e-base) | |

我们重点优化了bge-base-zh-v1.5和m3e-base模型的推理性能，分别是我们调研的效果最好的中文模型和英文模型。

请求参数示例

```

# Content-Type设置为JSON格式，如"Content-Type: application/json"
{
 "model_name": "m3e-base",
 "sentences":["自动追焦相关报表","太古汇内云集逾180家知名品牌","其中逾70个品牌为第一次进驻广州","交通：商场M层连通地铁三号线石牌桥站；毗邻地铁一号线体育中心站。"]
}

```

如果是bge-base-zh模型，长文本的请求示例

```

# Content-Type设置为JSON格式，如"Content-Type: application/json"
{
 "model_name": "bge-base-zh-v1.5",
 "sentences":["自动追焦相关报表","太古汇内云集逾180家知名品牌","其中逾70个品牌为第一次进驻广州","交通：商场M层连通地铁三号线石牌桥站；毗邻地铁一号线体育中心站。"]
}

```

如果是bge-base-zh模型，短query的请求示例

```

# Content-Type设置为JSON格式，如"Content-Type: application/json"
{
 "model_name": "bge-base-zh-v1.5",
 "sentences":["为这个句子生成表示以用于检索相关文章：地铁交通","为这个句子生成表示以用于检索相关文章：太古汇"]
}

```

#### []响应结果

| **参数** | **类型** | **说明** | |
| data | array | 对应sentence的文本向量的实际值 | |

返回响应示例

```

# data主体是向量的二维数组，向量维度与模型相关
{"data":[[-0.006009635981172323,0.0320364348590374,-0.012086838483810425,0.04545353353023529,....],[-0.04749463126063347,0.03422294184565544,0.011880395002663136,...]]

```

#### []调用示例

备注：鉴权文档[鉴权方式-AppKey获取](https://aigc.vivo.com/#/document/index?id=1677)

```

#!/usr/bin/env python
# encoding: utf-8

import requests
import uuid

# 注意替换AppId、AppKey
AppId = 'your_AppId'
AppKey = "your_AppKey"
DOMAIN = 'api-ai.vivo.com.cn'
URI = '/embedding-model-api/predict/batch'
METHOD = 'POST'

def embedding():
 params = {}
 post_data = {
 "model_name": "m3e-base",
 "sentences": ["豫章故郡，洪都新府", "星分翼轸，地接衡庐"]
 }
 params = {
 "requestId": str(uuid.uuid4())
 }
 print(params['requestId'])
 headers = {
 "Authorization": f"Bearer {AppKey}",
 "Content-type": "application/json",
 }
 print('headers', headers)
 url = 'https://{}{}'.format(DOMAIN, URI)
 response = requests.post(url, json=post_data, headers=headers,params=params )
 if response.status_code == 200:
 print(response.json())
 else:
 print(response.status_code, response.text)

if __name__ == '__main__':
 embedding()

```

#### []常见问题

1.Q：文本向量化能力支持的语种有哪些？

A：中文、英文，暂不支持其他语种向量化的功能。

2.Q: 文本长度是否有限制？

A：文本长度控制在**500字**以内。

---

## 文本相似度

- Source: https://aigc.vivo.com.cn/#/document/index?id=2060
- Path: 文档中心 / 接口文档 / 自然语言处理 / 文本相似度

#### []服务简介

将用户提供的文本信息从语义的角度来判断两者相似度。

#### []接口说明

请求地址：https://api-ai.vivo.com.cn/rerank

访问方式：`POST`

#### []请求参数

**Header**

| 参数 | 是否必须 | 值 | |
| Content-Type | 是 | application/json | |
| Authorization | String | 是 | |

**查询参数**

| 参数 | 类型 | 是否必须 | 值 | |
| requestId | uuid | 是 | uuid值 | |

**Body**

| **参数名称** | **类型** | **是否必须** | **说明** | |
| model_name | string | 是 | 文本向量化模型名称，当前支持：bge-reranker-large | |
| query | string | 是 | 示例：“科技发展趋势” | |
| sentences | array | 是 | 需要向量化文本的JSON格式数组，示例：[“自动追焦相关报表”, “太古汇内云集逾180家知名品牌”] | |

model_name说明

| model_name | 说明 | |
| bge-reranker-large | 介绍见[https://huggingface.co/BAAI/bge-reranker-large](https://huggingface.co/BAAI/bge-reranker-large) | |

我们重点优化了bge-reranker-large模型的推理性能。

请求参数示例

```

# Content-Type设置为JSON格式，如"Content-Type: application/json"
{
 "model_name": "bge-reranker-large",
 "query": "科技品牌发展",
 "sentences":["自动追焦相关报表","太古汇内云集逾180家知名品牌","其中逾70个品牌为第一次进驻广州","交通：商场M层连通地铁三号线石牌桥站；毗邻地铁一号线体育中心站。"]
}

```

#### []响应结果

| **参数** | **类型** | **说明** | |
| data | array | 对应sentences中每条文本与query文本的相似度 | |

返回响应示例

```

# data主体是数组，长度与输入的sentences数组相同，代表query与sentences中每条文本的相似度
{"data":[-8.067169189453125,-5.946075439453125,-4.977325439453125,-8.957794189453125]}

```

#### []调用示例

备注：鉴权文档[鉴权方式-AppKey获取](https://aigc.vivo.com/#/document/index?id=1677)

```

#!/usr/bin/env python
# encoding: utf-8

import requests
import uuid

# 注意替换AppId、AppKey
AppId = 'your_AppId'
AppKey = "your_AppKey"
DOMAIN = 'api-ai.vivo.com.cn'
URI = '/rerank'
METHOD = 'POST'

def rerank():
 params = {}
 post_data = {
 "model_name": "bge-reranker-large",
 "query": "老夫聊发少年狂",
 "sentences": ["豫章故郡，洪都新府", "星分翼轸，地接衡庐"]
 }
 params = {
 "requestId": str(uuid.uuid4())
 }
 print(params['requestId'])
 headers = {
 "Authorization": f"Bearer {AppKey}",
 "Content-type": "application/json",
 }
 print('headers', headers)
 url = 'https://{}{}'.format(DOMAIN, URI)
 response = requests.post(url, json=post_data, headers=headers,params=params )
 if response.status_code == 200:
 print(response.json())
 else:
 print(response.status_code, response.text)

if __name__ == '__main__':
 rerank()

```

#### []常见问题

1.Q：文本相似度能力支持的语种有哪些？

A：中文、英文，暂不支持其他语种向量化的功能。

2.Q: 文本长度是否有限制？

A：文本 query + sentence 长度控制在**500字**以内。

---

## 查询改写

- Source: https://aigc.vivo.com.cn/#/document/index?id=2061
- Path: 文档中心 / 接口文档 / 自然语言处理 / 查询改写

#### []服务简介

查询改写是RAG/AI搜索链路中的重要环节，目的是使用模型对用户当前输入的问题（query）进行理解，并改写为适合搜索引擎检索的query。改写后的结果可根据情况融入历史对话的关键信息，可对复杂问题进行拆解，使得检索召回的知识更加全面、丰富，为最终生成回答提供有力支持。

#### []接口说明

外网请求地址：https://api-ai.vivo.com.cn/query_rewrite_base

请求方式：`POST`

#### []请求参数

##### []**Header**

| 参数名称 | 类型 | 是否必须 | 参数值 | |
| Content-Type | string | 是 | application/json | |
| Authorization | String | 是 | Bearer AppKey | |

##### []查询参数

| 参数 | 类型 | 是否必须 | 值 | |
| requestId | uuid | 是 | uuid值 | |

##### []**Body**

| **参数名称** | **类型** | **是否必须** | **说明** | |
| prompts | list | 是 | 历史问答与当前问题组成的数组，目前支持传入最多3轮历史信息 | |

prompts中参数说明

| **参数名称** | **类型** | **是否必须** | **说明** | |
| q3 | string | 是 | 上三轮问题，如没有则传空字符串 | |
| a3 | string | 是 | 上三轮回答，如没有则传空字符串 | |
| q2 | string | 是 | 上两轮问题，如没有则传空字符串 | |
| a2 | string | 是 | 上两轮回答，如没有则传空字符串 | |
| q1 | string | 是 | 上一轮问题，如没有则传空字符串 | |
| a1 | string | 是 | 上一轮回答，如没有则传空字符串 | |
| q | string | 是 | 当前轮问题 | |

Body示例

```

{
 "prompts": [
 [
 "",
 "",
 "",
 "",
 "战狼2是谁主演的",
 "《战狼2》是由吴京执导并主演的一部军事战争题材电影。影片中，吴京饰演了主角冷锋，他是一名退役的特种部队军人，在非洲执行任务时遭遇了一连串危机和战斗。因此，《战狼2》的主演是吴京。"
 ],
 [
 "第一部里有他吗"
 ]
 ]
}

```

示例说明

```

{
 "prompts": [
 [
 "", // q3, 上三轮问题
 "", // a3, 上三轮回答
 "", // q2, 上两轮问题
 "", // a2, 上两轮回答
 "战狼2是谁主演的", // q1, 上一轮问题
 "《战狼2》是由吴京执导并主演的一部军事战争题材电影。影片中，吴京饰演了主角冷锋，他是一名退役的特种部队军人，在非洲执行任务时遭遇了一连串危机和战斗。因此，《战狼2》的主演是吴京。" // a1, 上一轮回答
 ],
 [
 "第一部里有他吗" // q，当前轮问题
 ]
 ]
}

```

#### []响应结果

| **参数** | **类型** | **说明** | |
| code | int | 0: 成功，其它表示失败，详细见下方错误码说明 | |
| result | list | 改写后结果 | |

结果示例

```

{'result': ['《战狼》第一部里有吴京吗'], 'code': 0}

```

错误码说明

| 错误码（code） | 含义 | |
| 0 | 正常 | |
| -2 | 请求列表格式错误 | |
| -3 | 当前query长度大于50 | |
| -4 | 当前query含有特定词语（A类） | |
| -5 | 当前query含有特定词语（B类） | |
| -6 | 上轮历史只有query或只有answer | |
| -8 | 当前query含有特定模版不进行改写 | |
| -9 | 模型判定无需改写 | |
| -3002 | 服务运行异常 | |

#### []调用示例

备注：鉴权文档[鉴权方式-AppKey获取](https://aigc.vivo.com/#/document/index?id=1677)

```

#!/usr/bin/env python
# encoding: utf-8

import json
import uuid

import requests

# 注意替换AppId、AppKey
AppId = 'your_AppId'
AppKey = "your_AppKey"
URI = '/query_rewrite_base'
DOMAIN = 'api-ai.vivo.com.cn'
METHOD = 'POST'

def query_rewrite():
 params = {}
 post_data = {
 "prompts": [
 [
 "",
 "",
 "",
 "",
 "战狼2是谁主演的",
 "《战狼2》是由吴京执导并主演的一部军事战争题材电影。影片中，吴京饰演了主角冷锋，他是一名退役的特种部队军人，在非洲执行任务时遭遇了一连串危机和战斗。因此，《战狼2》的主演是吴京。"
 ],
 [
 "第一部里有他吗"
 ]
 ]
 }
 data = json.dumps(post_data)
 params = {
 "requestId": str(uuid.uuid4())
 }
 print(params['requestId'])
 headers = {
 "Authorization": f"Bearer {AppKey}",
 "Content-type": "application/json",
 }
 print('headers', headers)

 url = 'http://{}{}'.format(DOMAIN, URI)
 response = requests.post(url, data=data, headers=headers, params=params)
 if response.status_code == 200:
 print(response.json())
 else:
 print(response.status_code, response.text)

if __name__ == '__main__':
 query_rewrite()

```

---

## 实时短语音识别

- Source: https://aigc.vivo.com.cn/#/document/index?id=1738
- Path: 文档中心 / 接口文档 / ASR / 实时短语音识别

### []服务简介

本文主要描述基于websocket协议之上的实时ASR交互接口协议， 基于该接口协议，客户端可以选择合适的语言进行客户端的开发，短语音指单轮识别时长在60s之内。

### []接口说明

实时ASR服务是基于WebSocket协议实现数据的传输。 主要是包含两个阶段：握手阶段和实时通信阶段 。

#### []注意

说明：支持的音频格式为16k/16b 单声道的PCM编码格式音频

#### []API

WebSocket 握手阶段主要是用于客户端和服务端建立WebSocket通信通道

##### []请求地址

域名：api-ai.vivo.com.cn

##### []握手参数

Headers

| 参数 | 类型 | 是否必须 | 值 | |
| Authorization | string | 是 | Bearer AppKey | |

URL参数通过key1=val1&key2=val2…&keyn=valn 方式拼接 ， 并附加在url后面 ， 例如 ：

```

ws://api-ai.vivo.com.cn/asr/v2?key1=val1&key2=val2..&keyn=valn

```

| 字段 | 类型 | 说明 | 是否必选 | 是否要urlencode | 备注 | |
| model | string | 手机型号 | 否 | 是 | | |
| system_version | string | 手机系统版本号 | 否 | 是 | | |
| client_version | string | 应用版本号 | 是 | 是 | 可写默认值"unknown" | |
| package | string | 应用包名 | 是 | 是 | 可写默认值"unknown" | |
| sdk_version | string | sdk版本号 | 是 | 是 | 可写默认值"unknown" | |
| user_id | string | 用户id(32位字符串，包括数字和小写字母) | 是 | 是 | 唯一标志符 | |
| android_version | string | android版本号 | 是 | 是 | 可写默认值"unknown" | |
| system_time | string | 系统时间 | 是 | 是 | Unix timestamp, 单位:毫秒 | |
| net_type | string | 网络状态 | 是 | 是 | 0数据网络，1 wifi环境 | |
| engineid | string | 能力id，如shortasrinput | 是 | 是 | 短语音根据所需的模型类别选择能力id，一般选通用模型：shortasrinput | |
| requestId | uuid | 追踪链路 | 是 | | | |

#### []**发送语音请求**

###### []语音请求text参数

1） websocket连接建立成功之后，调用端首先向服务端发送一个opcode为text的报文
 2） 这个报文的payload是一个json字符串

| 参数名 | 类型 | 说明 | 是否必选 | 备注 | |
| type | string | text包的类型 | 是 | started | |
| request_id | string | uuid，标识一次请求，32字符 | 是 | | |
| asr_info.end_vad_time | int | 后端检测时间 | 是 | 单位：毫秒 | |
| asr_info.audio_type | string | 音频类型 | 是 | pcm/opus | |
| asr_info.chinese2digital | int | 是否打开汉字转数字 | 是 | 0关闭，1打开 | |
| asr_info.punctuation | int | 是否打开标点符号 | 是 | 0：无标点 1：带标点 | |
| business_info | string | 扩展字段，可用于透传信息 | 否 | | |

###### []语音请求binary数据

1） 调用端发送完opcode为text的报文之后，接着发送语音数据，opcode为binary, payload是语音数据
 2） 语音数据建议分帧发送，每帧包含的语音时长是40毫秒，单句不超过60s
 3） 语音数据发送完毕之后，再发送一个opcode为binary，payload是’ --end –- ‘，表示语音数据发送完毕
 4） 需要关闭时，发送一个opcode为binary，payload是’ --close-- '，服务端收到后退出连接

#### []**接收数据格式**

##### []握手返回包

**成功:**

```

{
 "action":"started",
 "code":0,
 "data":"",
 "desc":"success",
 "sid":"5e094340-31be-47e7-83ad-7c6f27cd4f74"
}

```

**失败:**

```

{
 "action":"error",
 "code":1001,
 "data":"",
 "desc":"time out",
 "sid":"5e094340-31be-47e7-83ad-7c6f27cd4f74"
}

```

**识别结果返回包:**

```

{
 "sid":"e831d141-34e0-4617-a1b9-4ba43811453c@91",
 "is_finish":false,
 "data":{
 "result_id":91,
 "reformation":1,
 "is_last":true,
 "text":"气场中的场的部首共是多少笔。"
 },
 "action":"result",
 "request_id":"req_id",
 "code":0,
 "desc":"success",
 "type":"asr"
}

```

##### []返回字段

| 参数 | 类型 | 说明 | |
| action | string | 返回类型(started-握手成功, result-结果, error-出错) | |
| type | string | 业务类型(asr-语音识别, nlu-语义理解，common-通用返回) | |
| code | int | 返回码， 成功为0， 详细见2.4 | |
| data | object | 结果数据 | |
| desc | string | 描述 | |
| sid | string | 会话id | |

data字段说明

| 参数 | 类型 | 说明 | |
| text | string | asr识别结果 | |
| result_id | int | 结果序列号 | |
| reformation | int | asr识别返回， 1代表修正 0代表追加 | |
| business_info | stirng | 透传，由业务方和应用决定 | |
| is_last | bool | 是否为本次会话最后一条结果 | |
| is_finish | bool | 是否为本次连接最后一条结果 | |

#### []识别错误码

| 错误码 | 描述 | |
| 10000 | 参数校验失败 | |
| 10002 | 引擎服务异常 | |
| 10003 | 获取中间识别结果失败 | |
| 10004 | 获取最终识别结果失败 | |
| 10005 | 解析引擎数据异常 | |
| 10006 | 引擎内部错误 | |
| 10007 | 请求nlu出错 | |
| 10008 | 音频超长 | |

#### []调用示例

python调用demo：[实时短语音识别demo](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20260313/2026031310474283974.rar)

使用说明见：[demo使用说明](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20240419/202404191042322196023.txt)

---

## 长语音听写

- Source: https://aigc.vivo.com.cn/#/document/index?id=1740
- Path: 文档中心 / 接口文档 / ASR / 长语音听写

### []服务简介

本文主要描述基于websocket协议之上的实时长语音转文本交互接口协议， 基于该接口协议，客户端可以选择合适的语言进行客户端的开发，长语句指单轮识别不限制时长。

### []更新说明：

- 2025/04/09：更新调用示例中的python调用demo，修复调用时出现小概率性异常的bug

### []接口说明

实时ASR服务是基于WebSocket协议实现数据的传输。 主要是包含两个阶段：握手阶段和实时通信阶段 。

#### []注意

说明：支持的音频为16k/16b 单声道的PCM编码格式音频

#### []**API**

WebSocket 握手阶段主要是用于客户端和服务端建立WebSocket通信通道

##### []请求地址

域名：api-ai.vivo.com.cn

##### []握手参数

Headers

| 参数 | 类型 | 是否必须 | 值 | |
| Authorization | String | 是 | Bearer AppKey | |

##### []

URL参数

握手参数通过key1=val1&key2=val2…&keyn=valn 方式拼接 ， 并附加在url后面，例如： ws://asr-test-v2.vivo.com.cn/asr/v2?key1=val1&key2=val2…&keyn=valn

| 字段 | 类型 | 说明 | 是否必选 | 是否要urlencode | 备注 | |
| model | string | 手机外部型号 | 否 | 是 | | |
| system_version | string | 手机系统版本号 | 否 | 是 | | |
| client_version | string | 应用版本号 | 是 | 是 | 可写默认值"unknown" | |
| product | string | 内部机型名 | 否 | 是 | | |
| package | string | 应用包名 | 是 | 是 | 可写默认值"unknown" | |
| sdk_version | string | sdk版本号 | 是 | 是 | 可写默认值"unknown" | |
| user_id | string | 用户id(32位字符串，包括数字和小写字母) | 是 | 是 | 唯一标志符 | |
| android_version | string | android版本号 | 是 | 是 | 可写默认值"unknown" | |
| system_time | string | 手机时间 | 是 | 是 | Unix timestamp, 单位:毫秒 | |
| net_type | string | 网络状态 | 是 | 是 | 0数据网络，1 wifi环境 | |
| engineid | string | 能力id，如longasrlisten | 是 | 是 | 根据所需的长语音模型类别选择能力id，一般选通用模型：longasrlisten； | |
| requestId | uuid | 追踪链路 | 是 | | | |

#### []发送语音请求

##### []语音请求text参数

1） websocket连接建立成功之后，调用端首先向服务端发送一个opcode为text的报文
 2） 这个报文的payload是一个json字符串

| **参数名** | **类型** | **说明** | **是否必选** | **备注** | |
| type | string | text包的类型 | 是 | started | |
| request_id | string | uuid，标识一次请求，32字符 | 是 | | |
| asr_info.audio_type | string | 音频类型 | 是 | pcm/opus | |
| asr_info.lang | string | 语言 | 否 | cn/en | |
| asr_info.punctuation | int | 是否开启标点 | 否 | 1：开启， 0：关闭 | |
| asr_info.eng_pgsnum | int | 控制中间结果长度(取值为正整数(大于 0))。一 般建议设置为 40 | 否 | 40 | |
| business_info | string | 扩展字段，可用于透传信息 | 否 | | |

##### []语音请求binary数据

1） 调用端发送完opcode为text的报文之后，接着发送语音数据，opcode为binary, payload是语音数据
 2） 语音数据建议分帧发送，每帧包含的语音时长是40毫秒，云端会对连续的音频流进行实时识别，内置断句功能
 3） 语音数据发送完毕之后，再发送一个opcode为binary，payload是’ --end–- ‘，表示语音数据发送完毕
 4） 需要关闭时，发送一个opcode为binary，payload是’ --close-- '，服务端收到后退出连接

#### []**接收听写结果**

##### []接收握手返回包

**成功:**

```

{
 "action":"started",
 "code":0,
 "data":"",
 "desc":"success",
 "sid":"5e094340-31be-47e7-83ad-7c6f27cd4f74"
}

```

**失败:**

```

{
 "action":"error",
 "code":1001,
 "data":"",
 "desc":"time out",
 "sid":"5e094340-31be-47e7-83ad-7c6f27cd4f74"
}

```

##### []接收听写结果

消息内容：

- 当action = result，code = 9时，表示为客户端发完语音数据后的最后一句，客户端可以断开链接。
- 当action = result，code = 8时，表示本次返回为识别中间var结果，即一句话的中间结果。
- 当action = result，code = 0时，表示本次返回为识别中间rec结果，即一句话的完整结果，整个过程就是一句话中间结果，一句话完整结果…结束

###### []获取中间var结果

```

{
 "sid":"b1998631-035d-403b-868f-bf68d32637ad@7380",
 "action":"result",
 "data":{
 "speaker":0,
 "bg":289820,
 "recvid":"103e721b63014ffd92b5669c6d2c1ae2",
 "var":"政协委员姚明凝视天空时的表情还有一位记者"
 },
 "code":8,
 "desc":"success",
 "type":"asr"
}

```

###### []获取中间rec结果

```

{
 "sid":"b1998631-035d-403b-868f-bf68d32637ad@7396",
 "action":"result",
 "data":{
 "bg":289820,
 "speaker":0,
 "onebest":"政协委员姚明凝视天空时的表情，还有一位记者的发型。",
 "recvid":"103e721b63014ffd92b5669c6d2c1ae2",
 "ed":295060
 },
 "code":0,
 "desc":"success",
 "type":"asr"
}

```

###### []获取最后一句结果

```

{
 "sid":"b1998631-035d-403b-868f-bf68d32637ad@8331",
 "action":"result",
 "data":{
 "bg":331400,
 "speaker":0,
 "onebest":"有一定的下降，",
 "recvid":"103e721b63014ffd92b5669c6d2c1ae2",
 "ed":333230
 },
 "code":9,
 "desc":"success",
 "type":"asr"
}

```

###### []返回字段

| **参数** | **类型** | **说明** | |
| action | string | 返回类型(started-握手成功, result-结果, error-出错) | |
| type | string | 业务类型(asr-语音识别) | |
| code | int | action为result 见2.3.2 | |
| data | object | 结果数据 | |
| desc | string | 描述 | |
| sid | string | 会话id | |

data字段说明:

| **参数** | **类型** | **说明** | |
| var | string | 识别中间var结果即一句话中间结果 | |
| onebest | string | 识别中间rec结果即完整一句话或者最后一句结果 | |
| bg | int | 开始时间，单位毫秒 | |
| ed | int | 结束时间，单位毫秒 | |
| speaker | int | 当有角色分离时返回0表示当前说话人， 非0表示角色id，有角色变化 | |

#### []**错误码**

| **错误码** | **描述** | |
| 10000 | 参数校验失败 | |
| 10001 | 签名校验失败 | |
| 10002 | 引擎服务异常 | |
| 10003 | 获取中间识别结果失败 | |
| 10004 | 获取最终识别结果失败 | |
| 10005 | 解析引擎数据异常 | |
| 10006 | 引擎内部错误 | |
| 50001 | 使用超量 | |

#### []调用示例

python调用demo：[长语音听写调用demo](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20260313/20260313104241534192.rar)

使用说明见：[demo使用说明](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20240419/202404191042322196023.txt)

---

## 长语音转写

- Source: https://aigc.vivo.com.cn/#/document/index?id=1739
- Path: 文档中心 / 接口文档 / ASR / 长语音转写

### []服务简介

本文主要描述基于http协议之上的录音文件长语音转写（单次转写文件限制5个小时且小于500M）交互接口协议， 基于该接口协议，客户端可以选择合适的语言进行客户端的开发

### []接口说明

#### []注意

 说明：支持的音频格式有wav，pcm，m4a，mp3，acc，ogg，ogg_opus。
 录音文件长语音转写，主要是包含以下5个阶段：

1.创建音频

2.文件分片上传

3.创建任务并开始转写

4.查询转写进度

5.查询转写结果

#### []**API**

##### []请求地址

域名：api-ai.vivo.com.cn

##### []公共参数

Header

请求头鉴权参数用于服务鉴权

| 参数名称 | 类型 | 是否必须 | 参数值 | |
| Authorization | String | 是 | Bearer AppKey | |

URL参数

url参数通过key1=val1&key2=val2…&keyn=valn 方式拼接 ， 并附加在url后面

例如：http://api-ai.vivo.com.cn/lasr/create?key1=val1&key2=val2…&keyn=valn

| **字段** | **类型** | **说明** | **是否必选** | **是否要urlencode** | **备注** | |
| client_version | string | 应用版本号 | 是 | 是 | | |
| package | string | 应用包名 | 是 | 是 | | |
| user_id | string | 用户id(32位字符串，包括数字和小写字母) | 是 | 是 | 唯一标志符 | |
| system_time | string | 请求时间 | 是 | 是 | Unix timestamp, 单位:毫秒 | |
| engineid | string | 能力id，如fileasrrecorder | 是 | 是 | 根据所需的长语音转写模型类别选择能力id，普通录音文件转写模型：fileasrrecorder | |
| requestId | uuid | 追踪链路 | 是 | 是 | | |

**【注意事项】**

1.header和url参数1-5阶段都需要带上

#### []创建音频

【地址】：/lasr/create

【方式】：POST

【头部】：“Content-Type”: “application/json; charset=UTF-8”

##### []请求body

| **参数名** | **类型** | **位置** | **说明** | **是否必选** | **备注** | |
| audio_type | string | body | 音频类型 | 是 | pcm格式传pcm
其他wav，ogg(speex)，ogg_opus，mp3，aac，m4a格式传auto | |
| x-sessionId | string | body | 请求端生成uuid，且必须保证创建音频和文件分片上传时使用相同的x-sessionId | 是 | | |
| slice_num | int | body | 音频分片总数，用于最后的分片上传数量检查 | 是 | slice_num = ceil((file_size)/(slice_size)),slice_size 为文件分片的大小， 目前为5Mfile_size 为录音文件的大小ceil() 表示向上取整，因单次转写限制500M，slice_num取值小于等于100 | |

##### []响应结果

```

{
	"sid": "81303be6-c015-4aa3-9191-f1234cdf0a6e",
	"action": "result",
	"data": {
		"audio_id": "5fb63a82bbb2a462d7bae7dd" // 音频ID，分片上传和创建任务的API都会用到
	},
	"code": 0,
	"desc": "success",
	"type": "asr"
}

```

#### []文件分片上传

【地址】：/lasr/upload

【方式】：POST

【头部】：“Content-Type”: "multipart/form-data“

##### []URL请求参数

| **参数名** | **类型** | **位置** | **说明** | **是否必选** | **备注** | |
| audio_id | string | query string | 创建任务时，服务器返回的audio_id，URL参数。 | 是 | | |
| x-sessionId | string | query string | 请求端生成uuid，且必须保证创建音频和文件分片上传时使用相同的x-sessionId，URL参数 | 是 | | |
| slice_index | int | query string | 本次上传的分片索引编号，从0开始，URL参数 | 是 | | |

**示例:**

```
curl -i -X POST -H "Content-Type: multipart/form-data" -F file=@slice_path /lasr/upload?{公参}&audio_id={audio_id}&slice_index={slice_index}&x-sessionId={x-sessionId}

```

##### []响应结果

分片未上传完：

```

{
 "sid":"6b5e969e-7a53-415c-8ce1-859043731982",
 "action":"result",
 "data":{
 "total":3,
 "slices":1, // 1 ～ slices_num, 服务器已成功保存的分片总数
 "audio_id":"5fb63a82bbb2a462d7bae7dd"
 },
 "code":0,
 "desc":"success",
 "type":"asr"
}

```

分片上传完：

```

{
 "sid":"f55e388d-f2fa-48b1-9f84-310d74bf4879",
 "action":"result",
 "data":{
 "url":"",
 "total":3,
 "slices":3,
 "audio_id":"5fb63a82bbb2a462d7bae7dd"
 },
 "code":0,
 "desc":"success",
 "type":"asr"
}

```

**【注意事项】**

1.为了更好的保障大文件的传输稳定性和效率，分片大小为5M， 5M之内的无需分片（slices_num = 1, slice_index = 0）

#### []**创建任务并开始转写**

【地址】：/lasr/run

【方式】：POST

【头部】：“Content-Type”: “application/json; charset=UTF-8”

##### []请求body

| **参数名** | **类型** | **位置** | **说明** | **是否必选** | **备注** | |
| audio_id | string | body | 创建任务时，服务器返回的audio_id | 是 | | |
| x-sessionId | string | body | 请求端生成uuid，且必须保证创建音频和文件分片上传时使用相同的x-sessionId | 是 | | |

##### []响应结果

```

{
 "sid":"64b26906-c491-4664-b6fd-68b3aa4e84b1",
 "action":"result",
 "data":{
 "task_id":"5fb621c3bb14f77daecb9224"
 },
 "code":0,
 "desc":"success",
 "type":"asr"
}

```

#### []**查询转写进度**

【地址】：/lasr/progress

【方式】：POST

【头部】：“Content-Type”: “application/json; charset=UTF-8”

##### []请求body

| **参数名** | **类型** | **位置** | **说明** | **是否必选** | **备注** | |
| task_id | string | body | 创建转写任务返回的任务ID | 是 | | |
| x-sessionId | string | body | 请求端生成uuid，且必须保证创建音频和文件分片上传时使用相同的x-sessionId | 是 | | |

##### []响应结果

```

{
 "sid":"13d8bfdb-7f2f-46c3-b854-dbf86df52361",
 "action":"result",
 "data":{
 "progress":100 //0 ～ 100，100表示转写完成
 },
 "code":0,
 "desc":"success",
 "type":"asr"
}

```

#### []**查询转写结果**

【地址】：/lasr/result

【方式】：POST

【头部】：“Content-Type”: “application/json; charset=UTF-8”

##### []请求body

| **参数名** | **类型** | **位置** | **说明** | **是否必选** | **备注** | |
| task_id | string | body | 创建转写任务返回的任务ID | 是 | | |
| x-sessionId | string | body | 请求端生成uuid，且必须保证创建音频和文件分片上传时使用相同的x-sessionId | 是 | | |

##### []响应结果

```

{
 "sid":"dbfeac3d-d931-4bde-99a1-dcff713fdb2b",
 "action":"result",
 "data":{
 "result":[
 {
 "onebest":"播放歌曲摇篮曲。 ",
 "bg":0,
 "ed":2190,
 "speaker":1
 }
 ]
 },
 "code":0,
 "desc":"success",
 "type":"asr"
}

```

#### []**错误码**

##### []创建音频

| 业务层错误码 | 错误原因 | |
| 10000 | 客户端传公共参数校验失败 | |
| 10001 | 客户端传创建音频相关参数校验失败 | |
| 10002 | 客户端请求body参数音频分片数slice_num大于100 | |
| 10003 | 服务端创建音频失败 | |

##### []文件上传

| 业务层错误码 | 错误原因 | |
| 10100 | 客户端传公共参数校验失败 | |
| 10101 | 客户端传音频上传相关参数校验失败 | |
| 10102 | 服务端创建读音频对象失败 | |
| 10103 | 服务端读取音频失败 | |
| 10104 | 服务端获取缓存的音频分片数量失败 | |
| 10105 | 服务端上传音频到数据库失败 | |
| 10106 | 最后一个分片上传完成时服务端状态流转失败 | |

##### []开始转写

| 业务层错误码 | 错误原因 | |
| 10200 | 客户端传公共参数校验失败 | |
| 10201 | 客户端传转写相关参数校验失败 | |
| 10202 | 服务端创建转写任务失败 | |
| 10203 | 开始转写时服务端状态流转失败 | |

####查询进度

| 业务层错误码 | 错误原因 | |
| 10300 | 客户端传公共参数校验失败 | |
| 10301 | 客户端传查询进度相关参数校验失败 | |
| 10302 | 服务端获取进度失败 | |

##### []查询结果

| 业务层错误码 | 错误原因 | |
| 10400 | 客户端传公共参数校验失败 | |
| 10401 | 客户端传查询结果相关参数校验失败 | |
| 10402 | 服务端获取结果失败 | |

#### []调用示例

python调用demo：[长语音转写调用demo](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20260313/202603131038263594744.rar)

使用说明见：[demo使用说明](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20240419/202404191042322196023.txt)

---

## 方言自由说

- Source: https://aigc.vivo.com.cn/#/document/index?id=2065
- Path: 文档中心 / 接口文档 / ASR / 方言自由说

#### []简介

本文主要描述基于websocket协议之上的实时短语音转文本交互接口协议， 基于该接口协议，客户端可以选择合适的语言进行客户端的开发

支持语种：济南话，河南话，四川话，武汉话

#### []接口说明

实时短语音转文本服务是基于WebSocket协议实现数据的传输。 主要是包含两个阶段：握手阶段和实时通信阶段 。

#### []注意

说明：支持的音频格式为16k/16b 单声道的PCM编码格式音频

#### []API

WebSocket 握手阶段主要是用于客户端和服务端建立WebSocket通信通道

##### []请求地址

**域名**： api-ai.vivo.com.cn

##### []握手参数

headers

| 参数 | 类型 | 是否必须 | 值 | |
| Authorization | String | 是 | Bearer AppKey | |

URL参数

URL参数通过key1=val1&key2=val2…&keyn=valn 方式拼接 ， 并附加在url后面 ， 例如 ：

```
ws://api-ai.vivo.com.cn/asr/v2?key1=val1&key2=val2..&keyn=valn

```

| 字段 | 类型 | 说明 | 是否必选 | 是否要urlencode | 备注 | |
| model | string | 手机型号 | 否 | 是 | | |
| system_version | string | 手机系统版本号 | 否 | 是 | | |
| client_version | string | 应用版本号 | 是 | 是 | 可写默认值"unknown" | |
| package | string | 应用包名 | 是 | 是 | 可写默认值"unknown" | |
| sdk_version | string | sdk版本号 | 是 | 是 | 可写默认值"unknown" | |
| user_id | string | 用户id(32位字符串，包括数字和小写字母) | 是 | 是 | 唯一标志符 | |
| android_version | string | android版本号 | 是 | 是 | 可写默认值"unknown" | |
| system_time | string | 系统时间 | 是 | 是 | Unix timestamp, 单位:毫秒 | |
| net_type | string | 网络状态 | 是 | 是 | 0数据网络，1 wifi环境 | |
| engineid | string | 能力id，如shortasrinput | 是 | 是 | shortasrinput | |
| user_info | string | 用户体验开关 | 是 | 是 | 0用户体验开关关闭，1用户体验开关打开 | |
| requestId | uuid | 追踪请求 | 是 | | | |

#### []发送语音请求

##### []语音请求text参数

1） websocket连接建立成功之后，调用端首先向服务端发送一个opcode为text的报文
 2） 这个报文的payload是一个json字符串

| 参数名 | 类型 | 说明 | 是否必选 | 备注 | |
| type | string | text包的类型 | 是 | started | |
| request_id | string | uuid，标识一次请求，32字符 | 是 | | |
| asr_info.end_vad_time | int | 静音检测时长，单位是ms，默认1440ms | 否 | 最小说话时长和静音检测时长共同决定断句 | |
| asr_info.mini_speech_time | int | 最小说话时长，单位是ms，默认300ms | 否 | | |
| asr_info.audio_type | string | 音频类型 | 是 | 起到后端vad的作用pcm/opus | |
| asr_info.chinese2digital | int | 是否打开汉字转数字 | 是 | 0关闭，1打开 | |
| asr_info.punctuation | int | 是否打开标点符号 | 是 | 0：无标点 1：带标点 | |
| business_info | string | 扩展字段，可用于透传信息 | 否 | | |
| asr_info.lang | string | 语种，默认是中文 | 否 | dialect：方言自由说 | |

##### []语音请求binary数据

1） 调用端发送完opcode为text的报文之后，接着发送语音数据，opcode为binary, payload是语音数据
 2） 语音数据建议分帧发送，每帧包含的语音时长是40毫秒，单句不超过60s
 3） 语音数据发送完毕之后，再发送一个opcode为binary，payload是’ --end–- ‘，表示语音数据发送完毕
 4） 需要关闭时，发送一个opcode为binary，payload是’ --close-- '，服务端收到后退出连接

#### []**接收数据格式**

##### []握手返回包

**成功:**

```

{
 "action":"started",
 "code":0,
 "data":"",
 "desc":"success",
 "sid":"5e094340-31be-47e7-83ad-7c6f27cd4f74"
}

```

**失败:**

```

{
 "action":"error",
 "code":1001,
 "data":"",
 "desc":"time out",
 "sid":"5e094340-31be-47e7-83ad-7c6f27cd4f74"
}

```

**识别结果返回包:**

```

{
 "sid":"e831d141-34e0-4617-a1b9-4ba43811453c@91",
 "is_finish":false,
 "data":{
 "result_id":91,
 "reformation":1,
 "is_last":true,
 "text":"气场中的场的部首共是多少笔。"
 },
 "action":"result",
 "request_id":"req_id",
 "code":0,
 "desc":"success",
 "type":"asr"

```

##### []返回字段

| 参数 | 类型 | 说明 | |
| action | string | 返回类型(started-握手成功, result-结果, error-出错) | |
| type | string | 业务类型(asr-语音识别, nlu-语义理解，common-通用返回) | |
| code | int | 返回码， 成功为0， 详细见2.4 | |
| data | object | 结果数据 | |
| desc | string | 描述 | |
| sid | string | 会话id | |

data字段说明

| 参数 | 类型 | 说明 | |
| text | string | asr识别结果 | |
| result_id | int | 结果序列号 | |
| reformation | int | asr识别返回， 1代表修正 0代表追加 | |
| business_info | stirng | 透传，由业务方和应用决定 | |
| is_last | bool | 是否为本次会话最后一条结果 | |
| is_finish | bool | 是否为本次连接最后一条结果 | |

#### []识别错误码

| 错误码 | 描述 | |
| 10000 | 参数校验失败 | |
| 10002 | 引擎服务异常 | |
| 10003 | 获取中间识别结果失败 | |
| 10004 | 获取最终识别结果失败 | |
| 10005 | 解析引擎数据异常 | |
| 10006 | 引擎内部错误 | |
| 10007 | 请求nlu出错 | |
| 10008 | 音频超长 | |

#### []调用示例

python调用demo：[方言自由说demo](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20260313/202603131030584807356.rar)

使用说明见：[demo使用说明](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20240419/202404191042322196023.txt) （同实时语音识别）

---

## 同声音传译

- Source: https://aigc.vivo.com.cn/#/document/index?id=2068
- Path: 文档中心 / 接口文档 / ASR / 同声音传译

#### []简介

本文主要描述基于websocket协议之上的实时ASR交互接口协议， 基于该接口协议，客户端可以选择合适的语言进行客户端的开发

#### []接口说明

实时ASR服务是基于WebSocket协议实现数据的传输。 主要是包含两个阶段：握手阶段和实时通信阶段 。

#### []API

WebSocket 握手阶段主要是用于客户端和服务端建立WebSocket通信通道

##### []请求地址

**域名**： api-ai.vivo.com.cn

##### []握手参数

headers

| 参数 | 类型 | 是否必须 | 值 | |
| Authorization | String | 是 | Bearer AppKey | |

URL参数

URL参数通过key1=val1&key2=val2…&keyn=valn 方式拼接 ， 并附加在url后面 ， 例如 ：

```
ws://api-ai.vivo.com.cn/asr/v2?key1=val1&key2=val2..&keyn=valn

```

| 字段 | 类型 | 说明 | 是否必选 | 是否要urlencode | 备注 | |
| user_id | string | 用户id(32位字符串，包括数字和小写字母) | 是 | 是 | 唯一标志符 | |
| product | string | 手机型号 | 否 | 是 | | |
| package | string | 应用包名 | 是 | 是 | 可写默认值"unknown" | |
| client_version | string | 应用版本号 | 是 | 是 | 可写默认值"unknown" | |
| system_version | string | 手机系统版本号 | 否 | 是 | | |
| sdk_version | string | sdk版本号 | 是 | 是 | 可写默认值"unknown" | |
| android_version | string | android版本号 | 是 | 是 | 可写默认值"unknown" | |
| system_time | string | 系统时间 | 是 | 是 | Unix timestamp, 单位:毫秒 | |
| net_type | string | 网络状态 | 是 | 是 | 0数据网络，1 wifi环境 | |
| engineid | string | 能力id，如longasrsubtitle | 是 | 是 | longasrsubtitle | |
| requestId | uuid | 用于问题追踪 | 是 | 是 | | |

#### []发送语音请求

##### []语音请求text参数

1） websocket连接建立成功之后，调用端首先向服务端发送一个opcode为text的报文
 2） 这个报文的payload是一个json字符串

| 参数名 | 类型 | 说明 | 是否必选 | 备注 | |
| type | string | text包的类型 | 是 | started | |
| request_id | string | uuid，标识一次请求，32字符 | 是 | | |
| asr_info.audio_type | string | 音频类型 | 是 | 起到后端vad的作用pcm/opus | |
| asr_info.lang | string | 语言 | 是 | 中英自识别：cn
 中文：cn
英文：en
日文：ja
韩文：ko | |
| asr_info.target_lang | string | 目标翻译语言，默认是""空字符串，如果开启翻译，必传参数 | 是 | 英译中：en_cn
日译中：ja_cn
韩译中：ko_cn | |
| asr_info.punctuation | int | 是否打开标点符号 | 否 | 0：无标点 1：带标点 | |
| asr_info.eng_pgsnum | int | 控制中间结果长度(取值为正整数(大于 0))。一 般建议设置为 40 | 否 | 40 | |
| asr_info.scene | string | 区分场景类型，如会议场景为meet | 否 | 适配会议助手新增，会议场景关闭语气词，其他场景开启语气词 | |
| asr_info.audio_source | int | 区分系统音和麦克风音 | 否 | 1：系统音，2：麦克风音 | |
| asr_info.roletype | int | 是否需要分角色 | 否 | 0：不需要，1：需要，默认是需要 | |
| asr_info.tc | int | **同声传译开关，默认是0：关闭** | 否 | 1：开启， 0：关闭
 | |
| asr_info.end_vad_time | int | 静音检测时长，单位是ms，默认1440ms | 是 | 单位：毫秒 | |
| tts_info.selftts | int | 同声纹复刻开关，默认是0：关闭 | 否 | 1：开启， 0：关闭 | |
| tts_info.speed | int | 语速 | 否 | 范围[0,100]，默认50 | |
| tts_info.speaker | string | 音色，开启同声纹复刻时，为同声纹复刻音色 | 否 | 参照下方发音人列表 | |
| tts_info.audio_code | string | 音频编码 | 否 | 音频的编码格式，支持raw/speex/speex-wb,默认raw | |
| tts_info.volume | string | 音量 | 否 | 可选值：[1-100]，默认50 | |
| tts_info.engineid | string | TTS能力id | 否 | tts_replica/short_audio_synthesis_customization，默认tts_replica | |
| business_info | string | 扩展字段，可用于透传信息 | 否 | | |

**上传会话级热词包**

| 参数名 | 类型 | 说明 | 是否必选 | 备注 | |
| type | string | text包的类型 | 是 | hotword | |
| hotword_info.business.hotWord | string | 多个热词以英文逗号","分隔，其总长度最大 10000 个字节。一次会话中支持热词个数最大上限 3000 个。 | 是 | { “business”: { “hotWord”: “示例热词一,示例热词二” } } | |

##### []语音请求binary数据

1） 调用端发送完opcode为text的报文之后，接着发送语音数据，opcode为binary, payload是语音数据
 2） 语音数据建议分帧发送，每帧包含的语音时长是40毫秒，单句不超过60s
 3） 语音数据发送完毕之后，再发送一个opcode为binary，payload是’ --end–- ‘，表示语音数据发送完毕
 4） 需要关闭时，发送一个opcode为binary，payload是’ --close-- '，服务端收到后退出连接

#### []**接收数据格式**

##### []握手返回包

**成功:**

```

{
 "action":"started",
 "code":0,
 "data":"",
 "desc":"success",
 "sid":"5e094340-31be-47e7-83ad-7c6f27cd4f74"
}

```

**失败:**

```

{
 "action":"error",
 "code":1001,
 "data":"",
 "desc":"time out",
 "sid":"5e094340-31be-47e7-83ad-7c6f27cd4f74"
}

```

##### []接收转写结果

```

【消息内容】：

当action = result，code = 9时，表示为客户端发完语音数据后的最后一句，客户端可以断开链接。
当action = result，code = 8时，表示本次返回为识别中间var结果，即一句话的中间结果。
当action = result，code = 0时，表示本次返回为识别中间rec结果，即一句话的完整结果，整个过程就是一句话中间结果，一句话完整结果...结束

```

##### []获取中间var结果

```

{
"sid": "b1998631-035d-403b-868f-bf68d32637ad@7380",
"action": "result",
"data": {
"speaker": 0,
"bg": 289820,
"recvid": "103e721b63014ffd92b5669c6d2c1ae2",
"var": "政协委员姚明凝视天空时的表情还有一位记者"
},
"code": 8,
"desc": "success",
"type": "asr"
}

```

##### []获取中间rec结果

```

{
"sid": "b1998631-035d-403b-868f-bf68d32637ad@7396",
"action": "result",
"data": {
"bg": 289820,
"speaker": 0,
"onebest": "政协委员姚明凝视天空时的表情，还有一位记者的发型。",
"recvid": "103e721b63014ffd92b5669c6d2c1ae2",
"ed": 295060
},
"code": 0,
"desc": "success",
"type": "asr"
}

```

##### []获取最后一句结果

```

{
"sid": "b1998631-035d-403b-868f-bf68d32637ad@8331",
"action": "result",
"data": {
"bg": 331400,
"speaker": 0,
"onebest": "有一定的下降，",
"recvid": "103e721b63014ffd92b5669c6d2c1ae2",
"ed": 333230
},
"code": 9,
"desc": "success",
"type": "asr"
}

```

##### []返回字段

| 参数 | 类型 | 说明 | |
| action | string | 返回类型(started-握手成功, result-结果, error-出错) | |
| type | string | 业务类型(asr-语音识别, nlu-语义理解，common-通用返回) | |
| code | int | 返回码， 成功为0， | |
| data | object | 结果数据 | |
| desc | string | 描述 | |
| sid | string | 会话id | |

data字段说明

| 参数 | 类型 | 说明 | |
| var | string | 识别中间var结果 | |
| onebest | string | 识别中间rec结果或者最后一句结果 | |
| bg | int | 开始时间，单位毫秒 | |
| ed | int | 结束时间，单位毫秒 | |
| recvid | string | 引擎为三方时填写三方的会话id | |
| segId | int | 标记返回的消息编号 | |
| isseg | int | 字幕3.0引入，为1表示分段展示，为0表示不分段，日韩转写不支持分段 | |
| speaker | int | 当有角色分离时返回，表示角色id，第一个角色id从1开始，返回-1表示该字段值失效 | |
| src | string | 当用户开启翻译时，该字段返回翻译的源语言，如用户选择英文翻译为中文，则该字段返回识别的英文 | |
| audio | string | 当用户开启同声传译时，返回同声传译的音频 | |

#### []错误码

| 错误码 | 描述 | |
| 10000 | 参数校验失败 | |
| 10002 | 引擎服务异常 | |
| 10003 | 获取中间识别结果失败 | |
| 10004 | 获取最终识别结果失败 | |
| 10005 | 解析引擎数据异常 | |
| 10006 | 引擎内部错误 | |
| 10007 | 请求nlu出错 | |
| 10008 | 音频超长 | |

#### []调用示例

python调用demo：[同声传译demo](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20260313/20260313095942167947.zip)

使用说明见：[demo使用说明](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20240419/202404191042322196023.txt)

发音人列表

语种 发音人
 中文 cn xiaopei,xiaoyan,yiyi,xiaofang,chaoge,yifei
 英文 en Lindsay,Catherine
 法语 fr Mariane
 俄语 ru Allabent
 日语 ja xiaolin
 韩语 ko zhimin
 西班牙语 es Gabriela
 德语 de Leonie
 阿拉伯语 ar Ahmed
 泰语 th suparut
 越南语 vi xiaoyun
 维语 cn_uyghur patiguli
 藏语 cn_tibetan sgron
 粤语 cn_cantonese xiaomei
 中英混合 cnen xiaopei

---

## 音频生成

- Source: https://aigc.vivo.com.cn/#/document/index?id=1735
- Path: 文档中心 / 接口文档 / TTS / 音频生成

#### []服务介绍

自动文本转语音（TTS）功能，可将上传的单句文本转成播报音频

#### []接口介绍

语音合成流式接口将文字信息转化为声音信息，该语音能力是通过Websocket API的方式提供一个通用的接口。Websocket API具备流式传输能力，适用于需要流式数据传输的API服务场景。相较于SDK，API具有轻量、跨语言的特点；相较于HTTP API，Websocket API协议有原生支持跨域的优势。

#### []接口要求

集成在线语音合成流式API时，需按照以下要求。

| **内容** | **说明** | |
| 请求协议 | wss | |
| 域名地址 | wss://api-ai.vivo.com.cn | |
| 请求行 | GET /tts HTTP/1.1 | |
| 接口鉴权 | 签名机制，详情请参照下方 | |
| 字符编码 | UTF8 | |
| 响应格式 | 统一采用JSON格式 | |
| 开发语言 | 任意，只要可以发起Websocket请求的均可 | |
| 操作系统 | 任意 | |
| 音频属性 | 采样率24KHz, 16bit,单通道 | |
| 音频格式 | pcm | |
| 文本长度 | 无限制 | |

#### []请求接口

接口地址：wss://api-ai.vivo.com.cn/tts

**合成流程简介**

- 客户端通过websocket与服务端建立连接
- 客户端发送合成文本相关信息
- 服务端每隔100ms左右会返回pcm相关数据
- 一次文本合成结束，如果客户端继续合成，流程跳转到
- 关闭websocket协议

**接口鉴权**

**接口协议字段**

Header

| 参数 | 类型 | 是否必须 | 值 | |
| Authorization | String | 是 | Bearer AppKey | |
| X-AI-GATEWAY-SIGNATURE | String | 是 | developers-aigc | |

URL参数

| **参数名称** | **类型** | **必须** | **是否需要urlencode** | **说明** | 默认值 | |
| engineid | string | 是 | 是 | 短音频合成：short_audio_synthesis_jovi
长音频合成：long_audio_synthesis_screen
超拟人音色：tts_humanoid_lam | | |
| system_time | int | 是 | 是 | 当前时间戳，精确到秒 | | |
| user_id | string | 是 | 是 | 用户id（32位字符串，包括数字和小写字母） | | |
| model | string | 是 | 是 | 手机外部型号 | 可写默认值“unknown” | |
| product | string | 是 | 是 | 内部机型名 | 可写默认值“unknown” | |
| package | string | 是 | 是 | 应用包名 | 可写默认值“unknown” | |
| client_version | string | 是 | 是 | 应用版本号 | 可写默认值“unknown” | |
| system_version | string | 是 | 是 | 手机系统版本号 | 可写默认值“unknown” | |
| sdk_version | string | 是 | 是 | sdk版本号 | 可写默认值“unknown” | |
| android_version | string | 是 | 是 | android系统版本号 | 可写默认值“unknown” | |
| requestId | uuid | 是 | 是 | uuid | | |

engineid：通过该值选择不同的语音合成能力，短音频合成适用于对话合成，比如语音助手的应用场景；长音频合成适用于长文本合成场音，比如小说阅读，屏幕朗读

URL示例：`wss://api-ai.vivo.com.cn/tts?engineid=short_audio_synthesis_jovi&system_time=1653908720&user_id=123&model=V1809A&product=PD1809&package=com.vivo.agent&client_version=47405&system_version=PD1809_A_7.6.22&sdk_version=1.1.2.1&android_version=9`

**握手结果**
 如果握手成功，表示协议升级成功；如果握手失败，则根据不同错误类型返回不同Code状态码，同时携带错误描述信息，详细错误说明如下

| **error code** | **说明** | **错误描述信息** | |
| 0 | 成功（ws返回数据,收到此消息后，就可以发送文本数据了） | {“error_code”:0, “error_msg”:“connect success”} | |
| 10000 | 缺少请求参数或者签名错误 （http协议返回，status=400） | {“error_code”:10000, “error_msg”:“package not exist”} | |
| 10001 | 升级到websocket协议失败（http协议返回，status=400） | {“error_code”:10001, “error_msg”:“failed to upgrade ws”} | |

**文本合成请求**

**请求参数说明，请求都为json字符串**

| **参数名** | **类型** | **是否必传** | **描述** | **示例** | |
| aue | int | 是 | 音频的格式：0：pcm 1: opus压缩 | “aue” : 0 | |
| auf | string | 是 | 音频采样率，audio/L16;rate=24000：合成24K 的音频 | “auf” : “audio/L16;rate=24000” | |
| vcn | string | 是 | 角色发音人，可选值：

当engineid为short_audio_synthesis_jovi时支持音色如下：
vivoHelper：奕雯
yunye ： 云野-温柔
wanqing：婉清-御姐
xiaofu：晓芙-少女
yige_child：小萌-女童
yige：依格
yiyi：依依
xiaoming：小茗

当engineid为long_audio_synthesis_screen时支持音色如下：
x2_vivoHelper：奕雯
x2_yige：依格-甜美
x2_yige_news：依格-稳重
x2_yunye：云野-温柔
x2_yunye_news：云野-稳重
x2_M02：怀斌-浑厚
x2_M05：兆坤-成熟
x2_M10：亚恒-磁性
x2_F163：晓云-稳重
x2_F25：倩倩-清甜
x2_F22：海蔚-大气
x2_F82：英文女声

当engineid为tts_humanoid_lam时支持大模型音色如下：
F245_natural：知性柔美
M24：俊朗男声
M193：理性男声
GAME_GIR_YG：游戏少女
GAME_GIR_MB：游戏萌宝
GAME_GIR_YJ：游戏御姐
GAME_GIR_LTY：电台主播
YIGEXIAOV：依格
FY_CANTONESE：粤语
FY_SICHUANHUA：四川话
FY_MIAOYU：苗语
 | “vcn” : “yige” | |
| speed | int | 否 | 语速，可选值：[0-100]，默认为50 | “speed”: 50 | |
| volume | int | 否 | 音量，可选值：[1-100]，默认为50 | “volume”: 50 | |
| text | string | 是 | 文本内容，需进行base64编码； base64编码前最大长度2048字节 | | |
| encoding | string | 是 | 文本的编码格式，一律采用utf8 | “encoding”:“utf8” | |
| reqId | long | 是 | 请求ID | “reqId”: 513722013 | |

**返回参数说明：**

| **参数名** | **类型** | **描述** | |
| error_code | int | 返回码，0表示成功，其它表示异常，详情请参考错误码。 | |
| error_msg | string | 描述信息 | |
| sid | string | 每段文本的id，只在第一帧请求时返回 | |
| ver | string | 引擎版本号，1(项目)21(年份)01(前端)02(后端)03(发音人个数)，如221010103 | |
| data | object | | |
| data.audio | string | 合成后的音频片段，采用base64编码 | |
| data.status | int | 当前音频流状态，0表示开始合成（返回的第一帧数据），1表示合成中，2表示合成结束(返回的最后一帧数据） | |
| data.progress | int | 合成进度，指当前合成文本的字节数-总的字节数 *注*：请注意合成是以句为单位切割的，若文本只有一句话，则每次返回结果的ced是相同的。 | |
| data.slice | int | 返回的第几帧数据 | |

返回参数示例

```

{
 "ver": "121101005",
 "error_msg": "success",
 "req_id": 0,
 "error_code": 0,
 "sid": "e2122ae692f9862e58ba065d3394bd9b",
 "data": {
 "status": 2,
 "progress": "2-2",
 "hit": 0,
 "audio": "DF3RDSF35SDA==",
 "slice": 1
 }
}

```

#### []错误码

| **错误码** | **错误描述说明** | **处理方式** | |
| 10010 | 发送数据不是json格式 | 以json格式发送数据 | |
| 10011 | 发送文本时，缺少必要的参数 | 确认参数 | |
| 10012 | 发送文本时，签名错误 | 签名算法是否正确 | |
| | 以下是逻辑层服务器错误 | | |
| 10030 | 发送文本到引擎时错误 | 发送文本时，和引擎服务器连接出错 | |
| 10031 | 获取audio数据发生错误 | 获取数据时，和引擎服务器连接出错 | |
| 10032 | 无可用的引擎服务器 | 检查配置文件，查看引擎服务器是否在运行 | |
| | 以下是引擎层服务器错误 | | |
| 11001 | 负载过大，拒绝新的请求 | | |
| 11002 | 请求头协议错误 | | |
| 11003 | 设置合成文本的请求参数错误 | | |
| 11004 | 获取andio数据的请求参数错误 | | |
| 11005 | session重复了 | | |
| 11006 | 获取数据时，找到不到session | | |
| 11007 | 创建引擎错误 | | |
| 11008 | 向算法引擎获取数据时出错 | | |
| 11009 | opus压缩出现问题 | | |
| 11010 | 输入的合成文本不合法 | | |

#### []运行示例

**1.安装环境**
 如果使用conda创建环境，则如下初始环境：

```
conda create -n tts_py38 python=3.8

conda activate tts_py38

pip --no-cache-dir install -i https://pypi.tuna.tsinghua.edu.cn/simple -r ./requirements.txt

```

如果在linux下有docker的环境，可以直接在build目录下通过makefile构建环境镜像,会自动从阿里云下载基础镜像:

```
cd build

make #构建基础镜像

make run #启动镜像实例,由于命令中加了--rm,实例退出导致实例会被删除

make stop #退出实例，退出后实例将被自动删除

make debug #进入实例

make clean #清除镜像，必须实例退出并删除才可清除镜像

```

**2.运行TTS合成**
 使用环境变量设置app_id与app_key
 linux:

```
export APP_ID=你的APPID
export APP_KEY=你的APPKEY

```

windows:

```
参考https://zhuanlan.zhihu.com/p/231668109设置

```

或直接tts_examples.py最开头加上如下代码指定环境

```
os.environ['APP_ID']=你的APPID
os.environ['APP_KEY']=你的APPKEY

```

运行代码

```
python audio_decode.py

```

#### []调用示例

**调用接口获取音频数据**

备注：鉴权文档[鉴权方式-AppKey获取](https://aigc.vivo.com/#/document/index?id=1677)

```

# -*- coding: utf-8 -*-
import uuid

from websocket import create_connection, ABNF
import time
import base64
import json
import os
from enum import IntEnum

# os.environ['APP_ID']=your_app_id
# os.environ['APP_KEY']=your_app_key

class AueType(IntEnum):
 PCM = 0
 OPUS = 1

class TTS(object):

 def __init__(self, app_id=None, app_key=None, engineid='short_audio_synthesis_jovi', *args, **argskw):
 self._appid = app_id or os.getenv('APP_ID')
 self._app_key = app_key or os.getenv('APP_KEY')
 if isinstance(self._app_key, str):
 self._app_key = self._app_key
 self._engineid = engineid
 self._ws = None

 def open(self, domain="wss://api-ai.vivo.com.cn"):
 uri = "/tts"
 system_time = str(int(time.time()))
 user_id = 'userX'
 model = 'modelX'
 product = 'productX'
 package = 'packageX'
 client_version = '0'
 system_version = '0'
 sdk_version = '0'
 android_version = '9'
 requestId = str(uuid.uuid4())
 params = {"engineid": self._engineid, "system_time": system_time, "user_id": user_id, "model": model,
 "product": product, "client_version": client_version, "system_version": system_version,
 "package": package, "sdk_version": sdk_version, "android_version": android_version,
 "requestId": requestId}
 headers = {
 "Authorization": f"Bearer {self._app_key}"
 }
 headers["vaid"] = "123456789"
 param_str = '?'
 seq = ''
 for key, value in params.items():
 param_str = param_str + seq + key + '=' + value
 seq = '&'
 url = domain + uri + param_str
 print(url)
 try:
 self._ws = create_connection(url, header=headers)
 except Exception as e:
 print("print err:", repr(e))
 return None
 # get first handshake data
 code, data = self._ws.recv_data(True)
 return self._ws

 def gen_radio(self, text='你好', vcn='xiaofu', aue=AueType.PCM, extra={}):
 if self._ws is None:
 return None
 obj = {}
 obj["speed"] = 60
 obj["text"] = base64.b64encode(text.encode('utf-8')).decode('utf-8')
 obj["auf"] = 'audio/L16;rate=24000'
 obj["vcn"] = vcn
 obj["volume"] = 30
 obj["aue"] = aue
 obj["sfl"] = 1
 obj["reqId"] = int(round(time.time() * 1000)) # int(t.ident)
 obj.update(extra)
 self._ws.send(json.dumps(obj))
 print("finish_send_text", json.dumps(obj))
 audio_buff = b''
 while True:
 code, data = self._ws.recv_data(True)
 if code == ABNF.OPCODE_PONG:
 # recv pong
 pass
 elif code == ABNF.OPCODE_CLOSE:
 # recv close
 print('close')
 return None
 elif code == ABNF.OPCODE_TEXT:
 # recv text
 jre = json.loads(data)
 if jre["error_code"] != 0:
 print(f"error_code is not zero. data:{data}")
 return None
 else:
 if 'data' not in jre:
 print(jre)
 continue
 audio = base64.b64decode(jre["data"]["audio"])
 audio_buff += audio
 if jre["data"]["status"] == 0:
 print('the first data')
 elif jre["data"]["status"] == 2:
 print("complete ~")
 break
 jre["data"]["audio"] = ''
 print(jre)
 else:
 print("error,recv type:", code)
 break
 return audio_buff

if __name__ == '__main__':
 input_params = {
 # 注意替换AppId、AppKey
 'app_id': 'your_AppId',
 'app_key': 'your_AppKey',
 'engineid': 'long_audio_synthesis_screen'
 }
 tts = TTS(**input_params)
 tts.open()
 audio_buffer = tts.gen_radio(vcn='x2_F82')
 print(len(audio_buffer))

```

**解码音频数据**

```

# -*- coding: utf-8 -*-
import wave
import io

class ShortTTS(object):
 vivoHelper = "vivoHelper"
 yunye = "yunye"
 wanqing = "wanqing"
 xiaofu = "xiaofu"
 yige_child = "yige_child"
 yige = "yige"
 yiyi = "yiyi"
 xiaoming = "xiaoming"

class LongTTS(object):
 x2_vivoHelper = "vivoHelper"
 x2_yige = "x2_yige"
 x2_yige_news = "x2_yige_news"
 x2_yunye = "x2_yunye"
 x2_yunye_news = "x2_yunye_news"
 x2_M02 = "x2_M02"
 x2_M05 = "x2_M05"
 x2_M10 = "x2_M10"
 x2_F163 = "x2_F163"
 x2_F25 = "x2_F25"
 x2_F22 = "x2_F22"
 x2_F82 = "x2_F82"

class Humanoid(object):
 F245_natural = "F245_natural" # 知性柔美
 M24 = "M24" # 俊朗男声
 M193 = "M193" # 理性男声
 GAME_GIR_YG = "GAME_GIR_YG" # 游戏少女
 GAME_GIR_MB = "GAME_GIR_MB" # 游戏萌宝
 GAME_GIR_YJ = "GAME_GIR_YJ" # 游戏御姐
 GAME_GIR_YJ = "GAME_GIR_LTY" # 电台主播
 YIGEXIAOV = "YIGEXIAOV" # 依格
 FY_CANTONESE = "FY_CANTONESE" # 粤语
 FY_SICHUANHUA = "FY_SICHUANHUA" # 四川话
 FY_MIAOYU = "FY_MIAOYU" # 苗语

'''
input:
 pcmdata: pcm audio data
output:
 wav file-like object
'''

def pcm2wav(pcmdata: bytes, channels=1, bits=16, sample_rate=24000):
 if bits % 8 != 0:
 raise ValueError("bits % 8 must == 0. now bits:" + str(bits))
 io_fd = io.BytesIO()
 wavfile = wave.open(io_fd, 'wb')
 wavfile.setnchannels(channels)
 wavfile.setsampwidth(bits // 8)
 wavfile.setframerate(sample_rate)
 wavfile.writeframes(pcmdata)
 wavfile.close()
 io_fd.seek(0)
 return io_fd

if __name__ == '__main__':
 from tts_examples import TTS, AueType

 for k, v in ShortTTS.__dict__.items():
 if k.find('__') != -1:
 continue
 print(k, v)
 input_params = {
 # 修改为你的app_id 和 app_key
 'app_id': 'your_app_id',
 'app_key': 'your_app_key',
 'engineid': 'short_audio_synthesis_jovi'
 }
 tts = TTS(**input_params)
 tts.open()
 # pcm
 pcm_buffer = tts.gen_radio(aue=AueType.PCM, vcn=k, text='你好呀')
 wav_io = pcm2wav(pcm_buffer)
 with open(f'{k}_pcm.wav', 'wb') as fd:
 fd.write(wav_io.read())
 break

 for k, v in LongTTS.__dict__.items():
 if k.find('__') != -1:
 continue
 print(k, v)
 input_params = {
 # 注意替换AppId、AppKey
 'app_id': 'your_AppId',
 'app_key': 'your_AppKey',
 'engineid': 'long_audio_synthesis_screen'
 }
 tts = TTS(**input_params)
 tts.open()
 # pcm
 pcm_buffer = tts.gen_radio(aue=AueType.PCM, vcn=k, text='你好呀')
 wav_io = pcm2wav(pcm_buffer)
 with open(f'{k}_pcm.wav', 'wb') as fd:
 fd.write(wav_io.read())
 break

 for k, v in Humanoid.__dict__.items():
 if k.find('__') != -1:
 continue
 print(k, v)
 input_params = {
 # 注意替换AppId、AppKey
 'app_id': 'your_AppId',
 'app_key': 'your_AppKey',
 'engineid': 'tts_humanoid_lam'
 }
 tts = TTS(**input_params)
 tts.open()
 # pcm
 pcm_buffer = tts.gen_radio(aue=AueType.PCM, vcn=k, text='你好呀')
 wav_io = pcm2wav(pcm_buffer)
 with open(f'{k}_pcm.wav', 'wb') as fd:
 fd.write(wav_io.read())
 break

```

---

## 声音复刻

- Source: https://aigc.vivo.com.cn/#/document/index?id=2062
- Path: 文档中心 / 接口文档 / TTS / 声音复刻

### []服务简介

该服务主要负责将用户上传的录音生成定制的音色（vcn），用户可根据生成的定制音色（`vcn`）和`engineid`结合[短音频生成](https://aigc.vivo.com.cn/#/document/index?id=1735)能力合成音频

### []接口说明

访问域名：http://api-ai.vivo.com.cn

### []音色对象基础结构

**vcn_obj ：**

| **参数名** | **类型** | **是否必传** | **描述** | |
| vcn | string | 是 | 提取的音色特征id，请求TTS合成api接口时所需要传的vcn | |
| status | int | 是 | 1:等待执行状态
2:音色提取中
3:完成状态
4:失败状态 | |
| create_time | string | 是 | 创建时间 | |
| update_time | string | 是 | 更新时间 | |
| complete_time | string | 是 | 完成时间 | |
| est_wait_time | int | 是 | 预估需要等待的时间，单位为秒 | |
| process | int | 是 | 当前进度:0-100 | |
| attribute | object | 否 | 自定义音色属性信息 | |
| engineid | string | 是 | 请求TTS合成api接口时所需要传的engineid | |

### []公共参数

###### []Headers

| 参数名称 | 类型 | 是否必须 | 参数值 | |
| Content-Type | string | 是 | application/json | |
| Authorization | String | 是 | Bearer AppKey | |
| X-AI-GATEWAY-SIGNATURE | String | 是 | developers-aigc | |

### []创建音色生成任务

功能：上传音频文件生成一个音色id

URI: /replica/create_vcn_task?req_id=xxxxx

Method: POST

#### []header参数

| 字段 | 值 | |
| Content-Type | multipart/form-data | |

#### []uri参数

| **参数名** | **类型** | **是否必传** | **描述** | |
| requestId | String | 是 | 便于问题跟踪 | |

#### []Body参数

| **参数名** | **类型** | **是否必传** | **描述** | |
| audio | file | 是 | 用户的音频文件，wav文件，24k采样率的wav格式音频数据，单通道，16bit | |
| text | string | 是 | 音频对应的文本 | |

#### []响应

响应头

| 字段 | 值 | |
| Content-Type | application/json | |

响应体

| **参数名** | **类型** | **是否必传** | **描述** | |
| error_code | int | 是 | 返回码，0表示成功，其它表示异常，详情请参考错误码。 | |
| error_msg | string | 是 | 描述信息 | |
| op_str | string | 否 | 编辑距离字符串,代表用户读错/读漏，比如"MDMMMRRIII"。这个字符串的长度与朗读文案的长度一致，端侧遍历该字符串，找到R和I的位置标红对应文字，提示用户重录。一共有四种字母:M (Match)、D (Delete)、R (Replace)、I (Insert) | |
| org_text | string | 否 | 朗读文案 | |
| asr_text | string | 否 | 识别文本 | |

### []获取单个音色信息

功能：查询某个音色的信息

URI: /replica/get_vcn_task?req_id=xxxxx

Method: POST

#### []header参数

| 字段 | 值 | |
| Content-Type | application/json | |

#### []uri参数

| **参数名** | **类型** | **是否必传** | **描述** | |
| requestId | String | 是 | 便于问题跟踪 | |

#### []Body参数

| **参数名** | **类型** | **是否必传** | **描述** | |
| vcn | string | 是 | 音色id | |

#### []响应

响应头

| 字段 | 值 | |
| Content-Type | application/json | |

响应体

| **参数名** | **类型** | **描述** | |
| error_code | int | 返回码，0表示成功，其它表示异常，详情请参考错误码。 | |
| error_msg | string | 描述信息 | |
| vcn_obj | vcn_obj | vcn_obj定义，参见:0. 1音色对像基础结构 | |

### []获取音色列表

功能：查询用户已创建音色的列表

URI: /replica/get_vcn_task_list?req_id=xxxxx

Method: GET,POST

#### []uri参数

| **参数名** | **类型** | **是否必传** | **描述** | |
| requestId | String | 是 | 便于问题跟踪 | |

#### []响应

响应头

| 字段 | 值 | |
| Content-Type | application/json | |

响应体

| **参数名** | **类型** | **描述** | |
| error_code | int | 返回码，0表示成功，其它表示异常，详情请参考错误码。 | |
| error_msg | string | 描述信息 | |
| vcn_obj_list | vcn_obj list | vcn_obj定义，参见:0. 音色对像基础结构 | |

### []删除音色接口

URI: /replica/del_task?req_id=xxxxx

Method: POST

#### []header参数

| 字段 | 值 | |
| Content-Type | application/json | |

#### []uri参数

| **参数名** | **类型** | **是否必传** | **描述** | |
| requestId | String | 是 | 便于问题跟踪 | |

Body:

| **参数名** | **类型** | **是否必传** | **描述** | |
| vcn | string | 是 | 需要删除的用户的音色id | |

#### []响应

响应头

| 字段 | 值 | |
| Content-Type | application/json | |

Body:

| **参数名** | **类型** | **描述** | |
| error_code | int | 返回码，0表示成功，其它表示异常，详情请参考错误码。 | |
| error_msg | string | 描述信息 | |

### []调用示例

python调用demo：[音色复刻demo](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20260313/202603130939108404567.zip)

### []错误码

| 错误名 | **错误码** | **错误描述说明** | **处理方式** | |
| ERR_OK | 0 | 正常 | | |
| ERR_UNKOWN_EXCEPTION | 40000 | 服务端捕获未处理的未知异常 | 服务端异常 | |
| ERR_PARAM_LOST | 40001 | 缺参或参数错误 | 客户端异常 | |
| ERR_ASR_FAILED | 40002 | ASR识别失败 | 服务端异常 | |
| ERR_NOT_FOUND_TASK | 40003 | 没有找到音色信息 | 客户端请求不存在的音色 | |
| ERR_UPLOAD_FS_FAILD | 40004 | 上传文件服务失败 | 服务端异常 | |
| ERR_GEN_VCN | 40006 | 生成音色失败 | 服务端异常 | |
| ERR_DEL_VCN | 40007 | 删除音色失败 | 服务端异常 | |
| ERR_BYTE_ASINE | 40008 | ASR识别文本与原始文本不对齐 | 客户端传的音频不合格或ASR识别有问题 | |
| ERR_MORE_BYTE | 40009 | ASR识别文本多于原始文本，简称多读 | 客户端传的音频不合格或ASR识别有问题 | |
| ERR_TASK_LIMIT | 40012 | 超过音色数量最大限制 | 客户端删除历史音色后再发起音色生成任务 | |

---

## 地理编码(POI搜索)

- Source: https://aigc.vivo.com.cn/#/document/index?id=1736
- Path: 文档中心 / 接口文档 / LBS / 地理编码(POI搜索)

#### []服务简介

输入关键字，查询对应城市的POI接口，输出相关联的地理名称、类别、经度纬度、附近的酒店饭店商铺等信息。

#### []接口说明

访问地址：https://api-ai.vivo.com.cn/search/geo

访问方式：GET

#### []请求参数

**Header**

| 参数 | 类型 | 是否必须 | 值 | |
| Content-Type | string | 是 | application/json | |
| Authorization | String | 是 | Bearer AppKey | |

**查询参数**

| 参数 | 类型 | 是否必填 | 描述 | 示例值 | |
| keywords | String | 是 | 关键字 | 卓悦汇 | |
| city | String | 是 | 行政区划编码或城市名称 | 深圳市或440300 | |
| page_num | int | 否 | 当前页数 | 2 （小于1按1处理，大于20按20处理） | |
| page_size | int | 否 | 每页条目数 | 10 （小于1按10处理，大于15按15处理） | |
| requestId | uuid | 是 | uuid值 | | |

#### []响应结果

Header

| 参数 | 类型 | 值 | |
| Content-Type | string | application/json | |

Body

| 参数 | 类型 | 是否必填 | 最大长度 | 描述 | 示例值 | |
| statusCode | int | 是 | | 状态码 | | |
| statusInfo | int | 是 | | 状态信息 | | |
| total | string | 是 | | poi总数 | | |
| pois | array[poi(object)] | 是 | | poi列表 | | |
| currentDistrict | object | 是 | | 当前行政区域 | | |

poi的格式如下：

| 参数 | 类型 | 是否必填 | 最大长度 | 描述 | 示例值 | |
| name | string | 是 | | 名称 | 卓悦汇 | |
| address | string | 是 | | 地址 | 中康路126 | |
| province | string | 是 | | 省 | 广东省 | |
| city | string | 是 | | 市 | 深圳市 | |
| district | string | 是 | | 区 | 福田区 | |
| nid | string | 是 | | id | 44010000880698 | |
| phone | string | 是 | | 电话 | | |
| location | string | 是 | | 经纬度坐标（02坐标）,经度和纬度用","分隔 | 114.060325,22.570432 | |
| distance | int | 是 | | 距离 | 0.0 | |

currentDistrict的格式如下：

| 参数 | 类型 | 是否必填 | 描述 | 示例值 | |
| name | string | 是 | 名称 | 深圳市 | |
| level | int | 是 | 行政区域级别，0：国家、1：省、2：市、3：县 | 2 | |
| centerPoint | string | 是 | 行政区域中心点（市级行政区的中心点是城区的中心点），经度和纬度用","分隔，备注：中心点数据可以人工配置 | 114.05369,22.54267 | |
| adcode | string | 是 | 区域编码 | 440300 | |

响应示例

```

{
 "isNearby": 0,
 "nearbyParam": null,
 "filter": null,
 "poiStyle": "normal",
 "topicName": null,
 "searchType": "normal",
 "totalCount": 52,
 "pois": [
 {
 "mid": "93377815",
 "province": "广东省",
 "district": "福田区",
 "tag": "",
 "brand": "",
 "alias": null,
 "confidenceLevel": "1",
 "direct": "",
 "hit": 119,
 "point": 1,
 "cityPoint": 1,
 "url": "",
 "photo": "",
 "border": null,
 "road": null,
 "score": 1.0,
 "parentId": "",
 "standbyTypeName": "",
 "standbyTypeCode": "",
 "standbyTag": "",
 "standbyBrand": "",
 "chaincode": "",
 "extds": null,
 "city": "深圳市",
 "nid": "44010000880698",
 "cpid": "",
 "src": "www.navinfo.com",
 "phone": "0755-82566588",
 "typeName": "百货商场零售",
 "typeCode": "130102,650100,650000",
 "location": "114.060325,22.570432",
 "side": "",
 "rank": "0",
 "adcode": "440304",
 "name": "卓悦汇",
 "address": "中康路126",
 "naviLocation": "114.060325,22.570562",
 "distance": 0.0
 },
 {
 "mid": "500047755",
 "province": "广东省",
 "district": "盐田区",
 "tag": "",
 "brand": "",
 "alias": null,
 "confidenceLevel": "1",
 "direct": "",
 "hit": 1,
 "point": 1,
 "cityPoint": 1,
 "url": "",
 "photo": "",
 "border": null,
 "road": null,
 "score": 1.0,
 "parentId": "",
 "standbyTypeName": "",
 "standbyTypeCode": "",
 "standbyTag": "",
 "standbyBrand": "",
 "chaincode": "",
 "extds": null,
 "city": "深圳市",
 "nid": "44010000233953",
 "cpid": "",
 "src": "www.navinfo.com",
 "phone": "18876146807",
 "typeName": "服装、箱包零售",
 "typeCode": "130301,650300,650000",
 "location": "114.232137,22.551464",
 "side": "",
 "rank": "0",
 "adcode": "440308",
 "name": "卓悦汇",
 "address": "官下路79",
 "naviLocation": "114.232247,22.551554",
 "distance": 0.0
 }
 ],
 "currentDistrict": {
 "level": 2,
 "centerPoint": "114.05369,22.54267",
 "citycode": "020_10",
 "name": "深圳市",
 "adcode": "440300"
 },
 "total": 52,
 "statusCode": 4,
 "statusInfo": "cookie is null",
 "dataType": 30
}

```

#### []调用示例

备注：鉴权文档[鉴权方式-AppKey获取](https://aigc.vivo.com/#/document/index?id=1677)

```

#!/usr/bin/env python
# encoding: utf-8
import uuid
import requests

# 注意替换AppId、AppKey
AppId = 'your_AppId'
AppKey = "your_AppKey"
DOMAIN = 'api-ai.vivo.com.cn'
URI = '/search/geo'
METHOD = 'GET'

def geocode_poi():
 """ 地理编码（poi搜索） """
 params = {
 'keywords': '卓悦汇',
 'city': '深圳',
 'page_num': 1,
 'page_size': 3,
 "requestId": str(uuid.uuid4())
 }
 print(params['requestId'])
 headers = {
 "Authorization": f"Bearer {AppKey}",
 "Content-type": "application/json",
 }
 print('headers', headers)
 url = 'http://{}{}'.format(DOMAIN, URI)
 response = requests.get(url, params=params, headers=headers)

 if response.status_code == 200:
 data = response.json()
 else:
 data = response.text
 print(data)

if __name__ == "__main__":
 geocode_poi()

```

#### []常见问题

-
Q：地理编码的只能转成高德坐标系吗？是否支持转成百度？

A：不支持，如果需要自己进行转换，请参考：https://github.com/wandergis/coordTransform_py

---

## 端侧3B模型

- Source: https://aigc.vivo.com.cn/#/document/index?id=1802
- Path: 文档中心 / 接口文档 / 端侧文本生成 / 端侧3B大模型

## []能力介绍

提供3B蓝心大模型BlueLM的移动端推理能力，支持纯文本对话与多模态（图文理解）两种模式。

## []SDK和模型下载

SDK以C++ so库和头文件的形式提供，涉及在android端native开发
 [端侧LLM 推理SDK](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20260514/202605141053194787070.zip)

在复赛阶段提供[BlueLM开源3B],
 [云真机](http://dev-cloud.vivo.com.cn/) （X300 Pro）机器 在/sdcard/1225/1.7.0.4_1225_mtk9500 路径下默认内置模型
 注意：禁止修改模型文件夹内各个文件的名字， 否则将无法读取模型，造成错误

## []接入和调用流程

建议使用Android Studio 进行开发，可以通过界面新建一个native工程 或者 建议直接基于[demo源码](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20260605/20260605171224152718.zip)进行二次开发

 若自建新的工程需要进行如下操作：
 1.添加aar文件
 将 `llm-sdk-release.aar`复制到项目的 `app/libs/` 目录下。
 在 `app/build.gradle` 中添加依赖：

```

android {
 defaultConfig {
 minSdk 28
 ndk { abiFilters 'arm64-v8a' } // 仅支持 arm64
 }
}
dependencies {
 implementation files('libs/llm-sdk-release.aar')
 implementation 'androidx.appcompat:appcompat:1.6.1'
}

```

2.在AndroidManifest.xml中添加权限

```
<!-- 存储权限：读取 /sdcard/ 下的模型文件 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
 android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
 android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
<uses-permission android:name="mediatek.permission.ACCESS_APU_SYS"/>
...
<uses-native-library android:name="libdmabufheap.so" android:required="false" />
<uses-native-library android:name="libvcap_npu_network_v1.so" android:required="false" />

```

即可使用SDK进行开发,也可以参考我们提供的demo源码

## []接口介绍

### []文本审核

为了避免暴力、涉黄、涉政、辱骂等非法文本的生成，我们要求参赛选手在使用端侧大语言模型推理时，接入系统文本审核能力。
 具体使用方式参考[文档](/#/preview/355?serviceCode=39817053a67c15886a9743e35f85cb5e)

### []LLM推理

LLM 推理能力通过 Java 封装类 `LlmManager` 提供，底层对接 `LLM_inference_manager` 原生库。

#### []LlmConfig 初始化参数

| 参数 | 类型 | 默认值 | 描述 | |
| modelPath | String | — | **必填**，模型目录路径 | |
| multimodal | boolean | false | 是否启用多模态模式（图文理解） | |
| nCtx | int | 2048 | 上下文长度(支持2048 4096 8192) | |
| nThreads | int | 4 | CPU 线程数 | |
| npuPower | int | 100 | NPU 档位，MTK 取值 10~100，越高性能越好 | |
| temperature | float | 0.0 | 越大输出越随机，0 为贪心解码 | |
| topP | float | 1.0 | 累计概率阈值，超出后不再考虑剩余 token | |
| topK | int | 1 | 单步最多考虑的 token 数量 | |

#### []LlmManager 接口

-
**`init(LlmConfig config) → int`**
 初始化模型，返回 0 表示成功，非 0 为错误码。耗时操作，需在子线程调用。
 当 `config.multimodal = true` 时，内部以 `BlueLM_V_3B` 多模态模型进行初始化，同时加载 VIT 模块。

-
**`callVit(byte[] rgbData, int width, int height) → int`**
 **多模态专用**。对图像进行 VIT 编码，返回 0 表示成功。必须在 `init()` 成功（多模态模式）之后调用。

- `rgbData`：图片的 RGB 原始字节数据（3 通道，长度 = width × height × 3）
- `width`：图片宽度（像素）
- `height`：图片高度（像素）

VIT 编码完成后，编码结果自动缓存在模型实例内部，下一次 `generate()` 调用时可直接引用。

-
**`generate(String prompt, TokenCallback callback)`**
 执行推理，流式回调每个 token。

- 纯文本模式 prompt 模板：`[|Human|]:用户输入\n[|AI|]:`
- 多模态模式 prompt 模板（VIT 编码完成后）：`[|Human|]:<im_start><image><im_end>用户输入\n[|AI|]:`

推理在内部子线程执行，回调方法在主线程被调用，可直接更新 UI。

-
**`interrupt()`**
 中断当前正在进行的推理。

-
**`release()`**
 释放原生资源，Activity 销毁时必须调用。

##### []TokenCallback 回调接口

```

public interface TokenCallback {
 void onToken(String token); // 每生成一个 token 回调一次
 void onComplete(); // 推理正常结束
 void onError(int code, String message); // 推理失败
}

```

##### []调用示例

###### []C++调用示例（纯文本）

```

 // 初始化
 llm_params params;
 params.model_path = const_cast<char*>(modelPath.c_str());
 params.context_suffix = ""; // 留空，SDK 自动从 config JSON 选择
 params.vocab_json_path = nullptr;
 params.merges_path = nullptr;
 params.runtime = DX3_APU;
 params.model_type = BlueLM_3B;
 params.tokenizer_type = 1; // 1 = bluelm tokenizer
 params.n_predict = 512; // 最大生成 token 数
 params.n_ctx = 2048;
 params.n_threads = 4;
 params.npu_power = 100;

 llm_instance_ = new LLM_inference_manager();
 llm_trace trace;
 LLM_CODE res = llm_instance_->init_base(params, trace);
 if (res != LLM_SUCCESS) {
 delete llm_instance_;
 llm_instance_ = nullptr;
 return res;
 }
 ...
 // 推理（prompt 需套用 chat 模板）
 std::string prompt = "[|Human|]:" + userInput + "\n[|AI|]:";
 res = llm_instance_->forward(prompt, true, eval_cb, handle);
 if (res != LLM_SUCCESS && res != LLM_INTERRUPTED) {
 return res;
 }
 // 每次推理结束后必须 reset
 llm_instance_->llm_reset();
 ...
 // 释放
 llm_instance_->release();
 delete llm_instance_;
 llm_instance_ = nullptr;

```

###### []C++调用示例（多模态）

```

 // 初始化（model_type 改为 BlueLM_V_3B）
 llm_params params;
 params.model_path = const_cast<char*>(modelPath.c_str());
 params.context_suffix = "";
 params.vocab_json_path = nullptr;
 params.merges_path = nullptr;
 params.runtime = DX3_APU;
 params.model_type = BlueLM_V_3B; // 多模态模型
 params.tokenizer_type = 1;
 params.n_predict = 512;
 params.n_ctx = 2048;
 params.n_threads = 4;
 params.npu_power = 100;

 LLM_inference_manager llm;
 llm_trace trace;
 LLM_CODE res = llm.init_base(params, trace);
 if (res != LLM_SUCCESS) return res;

 // 加载图片为 RGB 数据（可用 stb_image 等库）
 int w, h, c;
 uint8_t* img_buf = stbi_load("test.jpg", &w, &h, &c, STBI_rgb);

 // VIT 编码
 Image_Data img_data;
 img_data.input_width = w;
 img_data.input_height = h;
 img_data.image_buf = img_buf;
 res = llm.call_vit(img_data);
 if (res != LLM_SUCCESS) { /* VIT 编码失败 */ }

 // 多模态推理（prompt 中使用 <im_start><image><im_end> 标记图像位置）
 std::string prompt = "[|Human|]:<im_start><image><im_end>描述这张图片\n[|AI|]:";
 std::string answer;
 res = llm.forward(prompt, true, eval_cb, &answer);

 // 推理结束后 reset
 llm.llm_reset();

 // 释放
 stbi_image_free(img_buf);
 llm.release();

```

###### []JAVA调用示例（纯文本）

```

 // 1. 初始化（在子线程中调用，init_base 耗时较长）
 LlmManager llmManager = new LlmManager();

 LlmConfig config = new LlmConfig();
 config.modelPath = "/sdcard/1225/1.7.0.4_1225_mtk9500"; // 模型目录
 config.multimodal = false; // 纯文本模式
 config.nPredict = 512;
 config.nCtx = 2048;
 config.nThreads = 4;
 config.npuPower = 100;
 config.temperature = 0.95f;
 config.topP = 0.8f;
 config.topK = 50;

 new Thread(() -> {
 int ret = llmManager.init(config);
 runOnUiThread(() -> {
 if (ret == 0) {
 // 初始化成功，可以开始推理
 } else {
 // 初始化失败，错误码 ret
 }
 });
 }).start();

 // 2. 推理（在子线程中执行，通过回调流式返回结果）
 // prompt 必须套用 chat 模板，否则输出乱码
 String prompt = "[|Human|]:" + userInput + "\n[|AI|]:";

 llmManager.generate(prompt, new TokenCallback() {
 @Override
 public void onToken(String token) {
 // 每个 token 回调一次，在主线程更新 UI
 tvResponse.append(token);
 }

 @Override
 public void onComplete() {
 // 推理完成
 }

 @Override
 public void onError(int code, String message) {
 // 推理失败
 }
 });

 // 3. 中断推理（可选）
 llmManager.interrupt();

 // 4. 释放资源（Activity 销毁时调用）
 llmManager.release();

```

###### []JAVA调用示例（多模态）

```

 // 1. 多模态初始化
 LlmManager llmManager = new LlmManager();

 LlmConfig config = new LlmConfig();
 config.modelPath = "/sdcard/1225/1.7.0.4_1225_mtk9500"; // 模型目录（需包含 VIT 模型文件）
 config.multimodal = true; // 启用多模态
 config.nPredict = 512;
 config.nCtx = 2048;
 config.nThreads = 4;
 config.npuPower = 100;

 new Thread(() -> {
 int ret = llmManager.init(config);
 // ret == 0 表示成功
 }).start();

 // 2. VIT 图像编码（将图片转为 RGB byte[] 后调用）
 // 从 Bitmap 获取 RGB 数据的示例：
 Bitmap bmp = BitmapFactory.decodeFile("/sdcard/test.jpg");
 Bitmap rgbBmp = bmp.copy(Bitmap.Config.ARGB_8888, false);
 int w = rgbBmp.getWidth();
 int h = rgbBmp.getHeight();

 ByteBuffer buffer = ByteBuffer.allocate(w * h * 4);
 rgbBmp.copyPixelsToBuffer(buffer);
 byte[] argbBytes = buffer.array();

 // ARGB → RGB 转换
 byte[] rgbData = new byte[w * h * 3];
 for (int i = 0; i < w * h; i++) {
 rgbData[i * 3] = argbBytes[i * 4 + 1]; // R
 rgbData[i * 3 + 1] = argbBytes[i * 4 + 2]; // G
 rgbData[i * 3 + 2] = argbBytes[i * 4 + 3]; // B
 }

 int vitRet = llmManager.callVit(rgbData, w, h);
 // vitRet == 0 表示 VIT 编码成功

 // 3. 多模态推理（prompt 中需包含图像占位标记）
 String prompt = "[|Human|]:<im_start><image><im_end>" + userInput + "\n[|AI|]:";

 llmManager.generate(prompt, new TokenCallback() {
 @Override
 public void onToken(String token) {
 tvResponse.append(token);
 }

 @Override
 public void onComplete() {
 // 推理完成
 }

 @Override
 public void onError(int code, String message) {
 // 处理错误
 }
 });

 // 4. 释放
 llmManager.release();

```

### []多模态使用说明

#### []多模态与纯文本的区别

| 对比项 | 纯文本模式 | 多模态模式 | |
| LlmConfig | `multimodal = false` | `multimodal = true` | |
| 底层模型类型 | `BlueLM_3B` | `BlueLM_V_3B` | |
| VIT 编码 | 不需要 | 每张图片需调用 `callVit()` 进行编码 | |
| Prompt 模板 | `[\|Human\|]:文本\n[\|AI\|]:` | `[\|Human\|]:<im_start><image><im_end>文本\n[\|AI\|]:` | |

#### []多模态调用流程

```
init(multimodal=true) → callVit(图片RGB数据) → generate(带图像标记的prompt) → release()

```

- **初始化**：`config.multimodal = true`，调用 `init()` 加载基座模型 + VIT 模块
- **VIT 编码**：将图片解码为 RGB 字节数组，调用 `callVit(rgbData, width, height)`
- **推理**：Prompt 中使用 `<im_start><image><im_end>` 标记图像位置，调用 `generate()`
- **释放**：调用 `release()`

#### []注意事项

- `callVit()` 必须在 `init()` 成功后调用，且 `multimodal` 必须为 `true`
- VIT 编码结果缓存在模型实例中，每次 `callVit()` 会覆盖上一次编码结果
- 图片数据格式为 RGB 三通道，无 Alpha 通道，字节顺序为 R、G、B 逐像素排列
- 多模态模型文件夹下需包含 VIT 相关文件（如 `.dla` 和 `shared_weights_vit_*.bin`）
- 若在纯文本模式下调用 `callVit()` 将返回错误码

## []示例 Demo

-
已编译的APK demo
 [APK demo](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20260605/202606051707524452111.zip)

云真机已内置了端侧模型, 若使用[云真机](http://dev-cloud.vivo.com.cn/) 运行apk，
 可以使用adb connect 远程连接对应机器ip, 再执行 adb install即可开始体验。

 **MainActivity**：LLM 推理能力调用，界面布局从上到下：

- **模型路径输入框**（`etModelPath`）：填写模型文件所在目录，默认 `/sdcard/1225/1.7.0.4_1225_mtk9500`
- **"多模态"复选框**（`cbMultimodal`）：勾选后启用多模态模式（图文理解），默认开启
- **"初始化"按钮**（`btnInit`）：点击后在后台线程调用 `LlmManager.init()`，成功后按钮变为"已初始化"且置灰，输入框和发送按钮解锁
- **图片选择区**（多模态模式下可见）：

- **"选择图片"按钮**（`btnPickImage`）：从相册选取图片，自动进行 VIT 编码
- **图片预览**（`ivPreview`）：显示选中的图片缩略图
- **"清除"按钮**（`btnClearImage`）：清除已编码图片

- **响应展示区**（`tvResponse`，带 ScrollView）：流式显示模型逐 token 输出，自动滚动到底部
- **Prompt 输入框**（`etInput`）：输入用户消息（无需手动添加模板，发送时自动包装）
- **"发送"按钮**（`btnSend`）：触发推理，推理期间置灰防止重复提交
- **"中断"按钮**（`btnInterrupt`）：推理中可见，点击后调用 `LlmManager.interrupt()` 停止当前推理

**注意**：首次启动需授予「所有文件访问权限」（Android 13+），App 启动时会自动跳转权限设置页。

-
源代码
 [端侧LLM源代码](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20260605/20260605171224152718.zip)

### []已验证开发环境

| 条件 | 要求 | |
| Android 目标平台 | arm64-v8a | |
| 芯片 | MediaTek DX5（MT6993 等） | |
| Android SDK | API 28+ | |
| NDK | r23（交叉编译 llm_utils 时使用） | |
| CMake | 3.22.1+（Android Studio 自带） | |
| Gradle | 8.5 | |
| AGP | 8.2.2 | |

安装完Android Studio后，可以将adb所在路径添加至系统Path，方便后续用adb命令行执行操作

## []常见问题

-
demo APK安装失败，闪退
 APK运行依赖系统版本，需运行在比赛特定机型上面，并保证指定模型路径下存在完整的模型文件

-
初始化失败错误码说明

| 错误码 | 含义 | 排查方向 | |
| -1001 | config 文件不存在 | 检查模型路径下是否有 `bluelm_mtk_llm_config.json` | |
| -2101 | 基座模型加载失败 | DLA 文件版本与设备 Neuron Runtime 不匹配 | |
| -2104 | VIT 初始化失败 | 多模态模型文件缺失或损坏 | |
| -2105 | Tokenizer 加载失败 | 检查 `bluelm_3b_model_vocab.bin` 是否存在 | |

- Android 权限
 Android 13+ 读取 `/sdcard/` 需要 `MANAGE_EXTERNAL_STORAGE`，`READ_EXTERNAL_STORAGE` 带 `maxSdkVersion=32` 在 Android 13 上无效。
 `AndroidManifest.xml`：

```

<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />

```

运行时申请（MainActivity）：

```

if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
 if (!Environment.isExternalStorageManager()) {
 Intent intent = new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
 Uri.parse("package:" + getPackageName()));
 startActivity(intent);
 }
}

```

---

## 端侧文本审核

- Source: https://aigc.vivo.com.cn/#/document/index?id=1804
- Path: 文档中心 / 接口文档 / 端侧文本生成 / 端侧文本审核

## []服务简介

提供端侧文本审核服务，智能检测文本内容是否命中包括暴力、涉黄、涉政、辱骂等敏感内容，命中则审核不通过

## []接入准备

### []SDK下载

[AIGC文本审核aar](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20240528/202405281733531654358.zip)

#### []Android Studio接入

- 添加SDK依赖包：在工程项目下找到文件夹libs，如果没有请新建，将下载的aar包放入
- 添加依赖：打开应用级"build.gradle"文件，在"dependencies"中添加依赖

```
dependencies {
 implementation files('libs/aisdk-cms-local-1.0.0.0.aar')
}

```

在AndroidManifest.xml中申请权限

```
 <uses-permission android:name="vivo.aiservice.permission.AISERVICE_ACCESS"/>

```

- 混淆配置: 编译APK前需配置混淆配置文件，避免混淆导致功能异常
 在应用级根目录下打开混淆配置文件，如 proguard-rules.pro。添加如下配置

```
-keep class com.vivo.aisdk.**{*;}
-dontwarn com.vivo.aisdk.**
-keep class com.vivo.aiservice.cms.**{*;}

```

### []应用开发指南

#### []SDK初始化

应用开发之前，必须先完成SDK初始化流程，完成公共参数的设置和相关初始化设置

##### []接口函数

```
/**
 * 初始化sdk
 * @param context context上下文对象
 * @param listener 初始化回调结果
 */
public void init(final Context context, final IInitializeListener listener)

```

##### []输入输出

| 参数明细 | 类型 | 描述 | |
| context | Context | 上下文对象 | |
| listener | IInitializeListener | 初始化结果回调 | |

##### []调用示例

```
import com.vivo.aisdk.cms.local.CmsLocalFrame; // CMS服务总类
import com.vivo.aisdk.cms.local.IInitializeListener; // 初始化回调
import com.vivo.aisdk.cms.local.utils.LogUtils; // sdk内部日志工具类

// 在Application中初始化CMS本地化框架
@Override
public void onCreate() {
	super.onCreate();
	// 初始化CMS本地化框架，建议在Application中初始化
	CmsLocalFrame.getInstance().init(this, new IInitializeListener() {
		@Override
		public void onInitSuccess() {
			LogUtils.i("sdk 初始化成功!");
		}
		@Override
		public void onInitFailed(int code, String message) {
			LogUtils.e("sdk 初始化失败 code = " + code + ", message = " + message);
		}
	});
}

```

##### []初始化异常code

| code | 描述 | |
| 110010 | 初始化参数，缺少context | |

### []文本审核功能

初始化SDK完成之后即可开始具体功能-文本审核的开发工作

##### []接口函数

```
/**
 * 文本审核
 *
 * @param text 待审核文本
 * @param timeout 超时时间
 * @return ResponseResult 结果
 */
public void TextModeration(String text, CommApiCallBack<ResponseResult> callBack, int timeout)

```

##### []输入输出

| 参数明细 | 类型 | 描述 | |
| text | String | 待审核文本 | |
| callback | CommApiCallBack | callback 结果回调 | |
| timeout | long | 超时时间（ms） | |

ResponseResult 数据结构：

| 参数明细 | 类型 | 描述 | |
| code | int | 0:成功；其他: 异常，详见错误码说明 | |
| msg | String | 错误信息 | |
| data | String | 结果数据内容，json 字符串 | |
| respId | String | id | |
| ver | String | 协议版本 | |
| api | int | sdk接口 | |
| type | String | service 能力接口类型 | |
| extras | String | extral | |

ResponseResult.getData 数据结构:

| 参数明细 | 类型 | 描述 | |
| result | String | 0:审核通过， 1：嫌疑， 2：审核不通过 | |

结果示例

```
{"result":"0"}

```

##### []调用示例

```
1.导入必须类：在使用文本审核API时，将相关的类添加至工程

import com.vivo.aisdk.cms.local.CmsLocalFrame;   // CMS服务总类
import com.vivo.aisdk.cms.local.internal.CommApiCallBack; // 结果回调
import com.vivo.aisdk.cms.local.internal.ResponseResult; // 接口返回的结果类
import com.vivo.aisdk.cms.local.utils.LogUtils; // log工具类

2. 应用CmsLocalFrame进行接口调用， 异步获取审核结果
 String text = "待测试文本内容";
 long timeout = 5000;

 CmsLocalFrame.getInstance().TextModeration(text, new CommApiCallBack<ResponseResult>() {
	@Override
	public void onCallBack(ResponseResult responseResult) {
		if (responseResult.getCode() == CMSLocalConstants.ResultCode.SUCCESS) {
			//调用成功：解析结果
			String data = responseResult.getData();
			try {
				JSONObject json = new JSONObject(data);
				// 系统默认方法将 String转换为int 类型。
				int result = json.getInt("result");
				if (result == 0) {
					// 审核通过
					LogUtils.d("checked");
				} else if (result == 1) {
					// 存在嫌疑
					LogUtils.d("Under suspicion");
				} else if (result == 2) {
					// 未通过审核
					LogUtils.d("not checked");
				}
			} catch (JSONException e) {
				LogUtils.e("json error: " + e.getMessage());
			}
		} else {
			//返回错误码
			showMesage(responseResult.getMsg());
		}
	}
}, timeout);

```

##### []结果示例

| 测试文案 | 结果 | |
| 如果您想管理自己的数字货币，可以到数字人民币的官方服务平台，注册开通个人钱包，这样可以帮助您保护好自己的现金，不必担心跟踪失败或遗失问题，并有效地进行数字货币交易和转账。 | 2：审核不通过 | |
| 今天天气真不错 | 0：审核通过 | |

##### []错误码

| code | 错误描述 | |
| 0 | success：成功 | |
| 110001 | 未知错误 | |
| 110002 | 参数错误 | |
| 110003 | 远程服务不存在 | |
| 110004 | 远程服务未连接 | |
| 110005 | 能力不支持 | |
| 110006 | 请求超时 | |
| 110007 | 返回结果为空 | |
| 110008 | 鉴权失败 | |
| 110009 | 远程服务错误 | |
| 110010 | 初始化参数，缺少context | |

##### []文本审核Demo体验

Demo简介：

Application入口: DemoApplication，sdk初始化
 MainActivity：文本审核功能实现。

-
文本输入框：输入审核文本

-
"Submit"按钮：调用输入文本进行文本审核

-
结果展示: 展示审核结果

-
[Demo apk](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20260608/202606081535444318563.zip)

-
[Demo 源码](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20240528/202405281738277348462.rar)

## []常见问题

- 文本审核失败，toast提示错误信息 “unexception error, result is null”
 请确保审核能力在调用前已成功初始化，需要进一步分析可以抓取“_V_AiSdk”相关的LOG，并联系vivo的开发人员

---

## 端侧能力相关文件

- Source: https://aigc.vivo.com.cn/#/document/index?id=1803
- Path: 文档中心 / 接口文档 / 端侧文本生成 / 端侧能力相关文件

[llm-demo.zip](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20260605/202606051707524452111.zip)

[llm-android-sdk-source.zip](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20260605/20260605171224152718.zip)

[llm_3b_sdk.zip](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20260514/202605141053194787070.zip)

[文本审核demo.zip](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20260608/202606081535444318563.zip)

[文本审核SDK.zip](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20240528/202405281733531654358.zip)

[文本审核demo源码.rar](https://vstack-vivofs.vivo.com.cn/uAfNzbyGPR9eJshQ/v-stack/20240528/202405281738277348462.rar)
