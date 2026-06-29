# Function calling

- Source: https://aigc.vivo.com.cn/#/document/index?id=1805
- Path: 文档中心 / 接口文档 / 文本生成 / Function calling
- Doc ID: 1805
- Updated at(raw): 1773661955000

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
