---
description: MBTI Persona extension binding — 4-axis dichotomy templates, crate paths, splitter call site, channel preconditions. The universal bot-persona architecture lives in patterns/persona-architecture.mdc.
globs: crates/evox-ext-mbti-persona/**,crates/evox-ext-pure-lib/src/persona_profile.rs,crates/evox-ext-pure-lib/src/split.rs,crates/evox-channels/**
alwaysApply: false
---

# MBTI Persona Binding

Universal bot-persona architecture (single source of truth, pure splitter, mention gate decoupled, no 16-archetype switches) lives in `../patterns/persona-architecture.mdc`. This file is the EvoX-specific binding for the MBTI flavor.

## Concrete Bindings

| Pattern slot | EvoX/MBTI value |
|---|---|
| Personality framework | MBTI 4-axis dichotomy (E/I, S/N, T/F, J/P) |
| Bot persona file | `~/.evox/agent/persona.json` |
| Observer persona path | `<assets>/eavesdrop/persona/<kind>/<id>.json` (must NOT mix with bot persona) |
| Schema source of truth | `crates/evox-ext-pure-lib/src/persona_profile.rs` |
| Splitter pure function | `evox_ext_pure_lib::split::split_reply` |
| ContextSection source | `"mbti-persona"`, label `"MBTI 行为约束"`, priority `60` (recall is `70`) |
| Mention gate location | `crates/evox-channels/src/mention.rs` |
| Mention env var | `EVOX_REQUIRE_MENTION` (default `true`) |
| Splitter call sites | `crates/evox-channels/src/<platform>/streaming.rs` (one per platform; only at `final_status == Done`) |

## 4-Axis Templates (Single Source)

Only 4 axes, only at fixed paths:

```
crates/evox-ext-mbti-persona/assets/
  dim_E_I.md
  dim_S_N.md
  dim_T_F.md
  dim_J_P.md
```

Template constraints:

- Each covers exactly one axis's two ends (split with `## I` / `## E` style L2 headings)
- Behavioral observation style ("In a group, X won't Y"), not didactic ("INFPs like Y") — aligned with PR #141 conventions
- 40–80 chars per end (mixed-language counted by character)
- Avoid concrete business terms (feishu / slack / score), staying platform-agnostic

Per `../patterns/persona-architecture.mdc#7-the-16-archetype-anti-pattern`:

- No 5th axis (Big Five / Enneagram / DISC). To extend, decompose first per `../common/decision-hygiene.mdc#1-claim-decomposition-first` and submit a plan.
- No 16-type preset scripts (`if mbti == "INTP" { ... }`). Compose from 4 axes.
- No binding "is type X" with "does behavior X" inside templates — leave LLM flexibility.
- No second "MBTI knowledge / description / concept-definition" doc. Templates are the single source.

## Schema-Change Discipline

Per `../patterns/persona-architecture.mdc#2-persona-schema-lives-in-a-shared--pure-library`:

- New / modified fields must land in `crates/evox-ext-pure-lib/src/persona_profile.rs` — `Persona` / `ReplyEtiquette` / `parse_mbti`. **Do not** create a parallel definition in cdylib (`evox-ext-mbti-persona` or `evox-ext-persona`).
- Backward-compatible: `#[serde(default)]` + `Option<...>`
- Add `parse_*` validation function + unit tests
- Sync `merge_persona` behavior (new field overridden by patch if present, retained from current otherwise)
- Add no new runtime IO (`persona_profile` only reads / writes `~/.evox/agent/persona.json`)
- `Persona` and `ReplyEtiquette` cannot derive `Eq` (they contain `f32`).

## Prompt Injection — Single ContextSection

`context::build_section_for(&persona, &mood)` must:

- Return `Option<ContextSection>`; `None` lets the host skip this extension entirely (no degradation)
- `source = "mbti-persona"`, `label = "MBTI 行为约束"`, `priority = 60` (lower than learn's 70, ensuring recall hits sit closer to the user message)
- `content` is plain markdown — no XML / JSON tags
- Read no state outside evo-session. When `PersonalityState` is missing, the mood block is skipped and the section is still generated

Forbidden: pushing mbti content directly into `base_prompt` from any path other than `prompt_dispatch_run.rs`; second persona-injection section; `before_agent_start` hook for injection.

## Splitter Pure Function

`evox_ext_pure_lib::split::split_reply(full, mbti, etiquette)` constraints, per `../patterns/persona-architecture.mdc#4-reply-splitter-must-be-a-pure-function`:

- `mbti = None` or non-4-char → single chunk + `delay_ms = 0`
- jitter from a stable hash (same input → same chunks)
- `max_msgs` capped by `etiquette.max_messages_per_turn` (1..=12)
- No reading persona / files / env vars
- No RNG, no `unwrap()` / `expect()`, no `tokio::time::sleep` (host's job)

## Channels Splitter Call Site

Each IM platform calls `split_reply` exactly once, in the streaming module's "final reply phase" (currently feishu; same pattern for slack / qq / telegram).

Preconditions:

1. `final_status == Done`
2. `persona.reply_mode == Some("text_split")`
3. `parse_mbti(persona.mbti.as_deref())` returns `Some(_)`

Any precondition unmet → fall back to original streaming-card / single send_text path.

When sending chunks:

- Before each: `tokio::time::sleep(Duration::from_millis(chunk.delay_ms))`
- On `send_text_reply` error → break immediately (avoid duplicate sends)
- After all chunks sent → don't patch the streaming-card body (state already Done)

Forbidden: appending content beyond splitter output ("the above is split reply" notes); concatenating chunks back into one message; calling splitter from outside channels.

## Mention Gate

`crates/evox-channels/src/mention.rs` is the sole cross-platform mention gate. Each platform runtime normalizes its native event into `MentionGateInput`:

- `chat_type` → constants exposed by `mention.rs` (`CHAT_TYPE_GROUP`, etc.)
- `bot_id`: `Option<&str>`; missing → fail open (legacy deployments without bot-id)
- `mention_ids`: extracted from native mention (feishu mentions / slack `<@Uxxx>` / telegram `@username` / qqbot `[CQ:at,qq=xxx]`)
- `require_mention`: defaults from `EVOX_REQUIRE_MENTION`; missing means `true`

Gate fails → `return Ok(())` directly; never reaches the LLM. **Slash commands processed before the gate** (so `/gep_*` always responds).

Forbidden: a second gate outside `mention.rs`; secondary filtering after gate passes; mutual dependency between mention.rs and mbti-persona.

## Red Lines (EvoX-specific)

- Don't revive the `tools.ts` "persona MCP tool" path (deprecated; unified to ContextSection)
- Don't introduce "high-priority injection" for one platform that bypasses priority=60
- Don't patch the streaming card's main body again after splitter output (avoids text_split + dual display)
- Don't make channels depend on `evox-ext-mbti-persona` directly (resolved by sinking the splitter into `evox-ext-pure-lib`)

## See Also

- `../patterns/persona-architecture.mdc` — universal bot-persona pattern
- `../common/architecture.mdc#single-interface-definition` — schema / splitter / mention all "one definition per crate"
- `../common/decision-hygiene.mdc#5-temporal-layering` — 5th axis / 16 scripts / new IM platforms = post-v1
- `../common/clean-code-core.mdc#yagni` — 4 axes + 4 fields cap
- `gep-memory.mdc` — substantive persona changes → `gep_record_outcome` with `mbti_persona` / `reply_splitter` / platform signal
