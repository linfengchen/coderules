---
description: Example IM binding for Feishu (Lark) — API references, emoji_type mapping, block-type IDs. Universal patterns live in patterns/im-bot-integration.mdc.
globs: <AGENT_HOME>/extensions/im-feishu/**/*.ts
alwaysApply: false
---

# Feishu (Lark) SDK binding (sample)

The general IM-bot architecture — client init, WebSocket bridge, event dispatch, typing indicator, pagination — is in `../patterns/im-bot-integration.mdc`. This file is a **sample** for one vendor; copy and replace with Slack, Discord, etc.

## Concrete bindings (Feishu)

| Pattern slot | Value |
|---|---|
| SDK package | `@larksuiteoapi/node-sdk` |
| Domain enum | `Lark.Domain.Feishu` |
| Credentials env | `FEISHU_APP_ID`, `FEISHU_APP_SECRET` |
| Reference docs | https://open.feishu.cn (look up before adding a tool) |
| WebSocket event key (incoming) | `"im.message.receive_v1"` |
| Typing reaction | `messageReaction.create` with `emoji_type: "Typing"` |
| Receive-ID prefixes | `oc_` → `chat_id`, `ou_` → `open_id`, `@` → `email` |

## Client initialization

```typescript
import * as Lark from "@larksuiteoapi/node-sdk";
const client = new Lark.Client({
	appId: process.env.FEISHU_APP_ID,
	appSecret: process.env.FEISHU_APP_SECRET,
	domain: Lark.Domain.Feishu,
});
```

## WebSocket bridge

```typescript
const eventDispatcher = new Lark.EventDispatcher({}).register({
	"im.message.receive_v1": async (data) => {
		/* handle incoming message */
	},
});
const wsClient = new Lark.WSClient({
	appId: process.env.FEISHU_APP_ID,
	appSecret: process.env.FEISHU_APP_SECRET,
	loggerLevel: Lark.LoggerLevel.info,
});
await wsClient.start({ eventDispatcher });
```

## Message event shape

```typescript
{
	message: { chat_id, message_id, message_type, content: '{"text":"..."}' },
	sender: { sender_id: { open_id } }
}
```

- `content` is a JSON string — parse with try/catch fallback (per `../patterns/im-bot-integration.mdc#3-message-event-routing`).
- Only process `message_type === "text"` when that is your product policy; ignore or branch for others.

## Receive-ID detection

```typescript
function detectReceiveIdType(id: string) {
	if (id.startsWith("oc_")) return "chat_id";
	if (id.startsWith("ou_")) return "open_id";
	if (id.includes("@")) return "email";
	return "open_id";
}
```

## Feishu emoji — prefer built-in `emoji_type`

When using Feishu reactions, use built-in `emoji_type` instead of raw Unicode in product surfaces (per `../patterns/im-bot-integration.mdc#8-native-emoji--reaction-vocabularies`).

| Intent | emoji_type | Avoid raw |
|--------|------------|-----------|
| OK / agree | OK | ad-hoc Unicode |
| thumbs up | THUMBSUP | — |
| done / check | DONE | — |

Full vendor list: official Feishu “message reaction / emojis” docs.

## Document token extraction

```typescript
input.match(/\/(?:docx|wiki|doc|sheet|file|base|bitable)\/([a-zA-Z0-9_-]+)/)?.[1] || input;
```

## Block types for document writing

| Type | ID |
|------|-----|
| Text | 2 |
| Heading 1–6 | 3–8 |
| Bullet list | 12 |
| Ordered list | 13 |
| Code | 14 |

Batch `createChildren` in chunks (respect vendor limits, often ~20 blocks).

## See also

- `../patterns/im-bot-integration.mdc`
- `plugin-extension-sample.md` — if this bridge loads as an extension
- `monorepo-trunk-sample.md` — E2E / smoke commands for your repo
