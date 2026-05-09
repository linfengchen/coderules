---
description: Feishu (Lark) SDK integration — API endpoint references, emoji_type mapping, block-type IDs, document URL parsing. The general IM-bot patterns (WebSocket bridge, typing indicator, paginated SDK calls, tool file organization) live in patterns/im-bot-integration.mdc.
globs: .evox/agent/extensions/feishu-bridge/**/*.ts
alwaysApply: false
---

# Feishu SDK Binding

The general IM-bot architecture — client init, WebSocket bridge, event dispatch, typing indicator, pagination, tool grouping — is in `../patterns/im-bot-integration.mdc`. This file is the Feishu-specific binding.

## Concrete Bindings

| Pattern slot | Feishu value |
|---|---|
| SDK package | `@larksuiteoapi/node-sdk` |
| Domain enum | `Lark.Domain.Feishu` |
| Credentials env | `FEISHU_APP_ID`, `FEISHU_APP_SECRET` |
| Reference docs | https://feishu.apifox.cn (always look up before adding a tool) |
| WebSocket event key (incoming) | `"im.message.receive_v1"` |
| Typing reaction | `messageReaction.create` with `emoji_type: "Typing"` |
| Receive-ID prefixes | `oc_` → `chat_id`, `ou_` → `open_id`, `@` → `email` |

## Client Initialization

```typescript
import * as Lark from "@larksuiteoapi/node-sdk";
const client = new Lark.Client({
  appId: process.env.FEISHU_APP_ID,
  appSecret: process.env.FEISHU_APP_SECRET,
  domain: Lark.Domain.Feishu,
});
```

## WebSocket Bridge

```typescript
const eventDispatcher = new Lark.EventDispatcher({}).register({
  "im.message.receive_v1": async (data) => { /* handle incoming message */ },
});
const wsClient = new Lark.WSClient({
  appId: process.env.FEISHU_APP_ID,
  appSecret: process.env.FEISHU_APP_SECRET,
  loggerLevel: Lark.LoggerLevel.info,
});
await wsClient.start({ eventDispatcher });
```

## Message Event Shape

```typescript
{
  message: { chat_id, message_id, message_type, content: '{"text":"..."}' },
  sender: { sender_id: { open_id } }
}
```

- `content` is a JSON string — always parse with try/catch fallback (per `../patterns/im-bot-integration.mdc#3-message-event-routing`)
- Only process `message_type === "text"`; ignore others

## Receive-ID Detection

```typescript
function detectReceiveIdType(id: string) {
  if (id.startsWith("oc_")) return "chat_id";
  if (id.startsWith("ou_")) return "open_id";
  if (id.includes("@")) return "email";
  return "open_id";
}
```

## Feishu Emoji — Prefer Built-in Over Unicode

When feishu-bridge is active, always use Feishu's built-in `emoji_type` instead of Unicode emoji (per `../patterns/im-bot-integration.mdc#8-native-emoji--reaction-vocabularies`).
In message-card markdown, use `:emoji_type:` syntax (e.g., `:THUMBSUP:`, not `U+1F44D`).
In code and comments, never use any emoji at all.

| Intent          | emoji_type     | DO NOT use |
|-----------------|----------------|------------|
| OK / agree      | OK             | `U+1F44C`  |
| thumbs up       | THUMBSUP       | `U+1F44D`  |
| thanks          | THANKS         | --         |
| clap            | APPLAUSE       | `U+1F44F`  |
| done / check    | DONE           | `U+2705`   |
| heart / love    | HEART          | `U+2764`   |
| fire            | Fire           | `U+1F525`  |
| party           | PARTY          | `U+1F389`  |
| thinking        | THINKING       | `U+1F914`  |
| smile           | SMILE          | `U+1F604`  |
| laugh           | LAUGH          | `U+1F602`  |
| cry             | CRY            | `U+1F622`  |
| wow             | WOW            | `U+1F62E`  |
| error / cross   | CrossMark      | `U+274C`   |
| check mark      | CheckMark      | `U+2705`   |
| warning         | Alarm          | `U+26A0`   |
| pin             | Pin            | `U+1F4CC`  |
| trophy          | Trophy         | `U+1F3C6`  |
| loudspeaker     | Loudspeaker    | `U+1F4E2`  |
| coffee          | Coffee         | `U+2615`   |
| LGTM            | LGTM           | --         |
| 100             | Hundred        | `U+1F4AF`  |
| yes             | Yes            | --         |
| no              | No             | --         |
| muscle          | MUSCLE         | `U+1F4AA`  |

Full list: https://open.feishu.cn/document/server-docs/im-v1/message-reaction/emojis-introduce

## Document Token Extraction

Feishu URLs contain tokens in paths like `/docx/AbCdEf123`. Use `extractToken()` from `lib.ts`:

```typescript
input.match(/\/(?:docx|wiki|doc|sheet|file|base|bitable)\/([a-zA-Z0-9_-]+)/)?.[1] || input;
```

## Block Types for Document Writing

| Type | ID | Property |
|------|-----|----------|
| Text | 2 | `text` |
| Heading 1-6 | 3-8 | `heading1`-`heading6` |
| Bullet List | 12 | `bullet` |
| Ordered List | 13 | `ordered` |
| Code | 14 | `code` |
| Quote | 15 | `quote` |
| Todo | 17 | `todo` |
| Divider | 22 | `divider` |

Batch `createChildren` calls in chunks of 20 blocks max.

## Shared Utilities (lib.ts)

- `collectPaginated(fn, maxPages)` — auto-collect paginated results (per `../patterns/im-bot-integration.mdc#6-paginated-sdk-calls`)
- `toTimestamp(isoOrUnix)` — convert ISO string or unix seconds to a string timestamp
- `extractToken(input)` — extract a token from Feishu URLs or pass through raw tokens
- `callFeishu(fn)` — wrap API calls with error handling

## Tool File Organization (17 tools)

| File | Tools |
|------|-------|
| `tools/message.ts` | feishu_send_message, feishu_get_message, feishu_reaction, feishu_group, feishu_message_ops, feishu_image |
| `tools/doc.ts` | feishu_doc, feishu_search |
| `tools/workspace.ts` | feishu_wiki, feishu_drive, feishu_task, feishu_calendar |
| `tools/contacts.ts` | feishu_contacts |
| `tools/spreadsheet.ts` | feishu_spreadsheet |
| `tools/bitable.ts` | feishu_bitable |
| `tools/approval.ts` | feishu_approval |
| `tools/meeting.ts` | feishu_meeting |

## See Also

- `../patterns/im-bot-integration.mdc` — universal IM bot patterns
- `evox-extension.mdc` — feishu-bridge runs as an EvoX extension
- `evox-monorepo.mdc#7-feishu-bridge-e2e-testing` — Feishu E2E test flow
