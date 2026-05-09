---
description: GEP (Genome Evolution Protocol) memory MCP binding — server name, tool prefix, signal dictionary. The universal recall/record discipline lives in patterns/memory-mcp-discipline.mdc. Triggered when an EvoX agent is starting / ending a substantive task and the `user-evomap` MCP is available.
alwaysApply: false
---

# GEP Memory Binding

Universal memory-MCP discipline — when to recall, when to record, how to write `summary` / `signals` / `score` — lives in `../patterns/memory-mcp-discipline.mdc`. This file is the EvoX-specific binding (server name, tool prefix, signal vocabulary).

## Concrete Bindings

| Pattern slot | GEP value |
|---|---|
| MCP server name | `user-evomap` |
| Tool prefix | `gep_*` |
| Tools | `gep_recall`, `gep_search_community`, `gep_evolve`, `gep_install_gene`, `gep_record_outcome`, `gep_export`, `gep_status`, `gep_list_genes` |
| Resources | `Gene_Pool`, `Evolution_Capsules`, `GEP_Protocol_Specification` |
| Credit costs | recall=2, evolve=1, record=1, search_community=1; local ops (list / install / export / status) = free |

## EvoX Signals Dictionary

Use the project-domain signals below (mixed with the generic categories from `../patterns/memory-mcp-discipline.mdc`) when calling `gep_recall` / `gep_record_outcome`.

### Generic (task nature, pick at least 1)

`log_error`, `exception_raised`, `perf_bottleneck`, `slow_response`, `test_failure`, `ci_red`, `deployment_issue`, `build_failure`, `type_error`, `compile_error`, `capability_gap`, `user_feature_request`, `refactor_large`, `api_breaking_change`, `integration_issue`, `race_condition`, `memory_leak`, `config_mismatch`, `env_misconfigured`, `data_corruption`, `schema_mismatch`

### EvoX domain (always add 1–2)

| Signal | When |
|---|---|
| `feishu_bridge` / `feishu_streaming` / `lark_card` / `feishu_webhook` / `feishu_sdk` | Feishu integration work |
| `evox_extension` / `jiti_cache` / `mcp_server` / `mcp_handshake` | Extension / MCP infrastructure |
| `rust_port` / `ts_to_rust` / `worktree_conflict` / `parity_matrix` | Phase 6b dual-write / port work |
| `evolution_hook` / `evo_session` / `agent_session` | Session / lifecycle changes |
| `provider_anthropic` / `provider_gemini` / `provider_openai` | LLM provider integration |
| `tui_render` / `web_ui` / `session_manager` | UI / session-mgmt work |
| `mbti_persona` / `reply_splitter` / `mention_gate` | Persona / chat-style work (see `mbti-persona.mdc`) |

## EvoX-Specific Workflow Examples

### Scenario A — Fixing Feishu Streaming Render

1. `gep_recall` query=`"feishu streaming message renders as plain text"` signals=`["feishu_streaming","render_mode"]`
2. Local miss → `gep_search_community` same query, type=`Capsule`, outcome=`success`
3. Hit `capsule_feishu_streaming_fix` (similarity 0.78, signature present); read payload
4. Apply approach + run E2E per `evox-monorepo.mdc#7-feishu-bridge-e2e-testing`
5. `gep_record_outcome` signals=`["feishu_streaming","render_mode","openclaw_config"]` summary=`"Fixed feishu streaming plain-text bug by setting renderMode=card in openclaw.json (verified via E2E card render)"` score=0.95

### Scenario B — Porting a TS File to Rust, Stuck on Trait Design

1. Pre-flight scan per `../patterns/multi-worktree.mdc`
2. `gep_recall` query=`"port evolution-lifecycle.ts to rust"` signals=`["rust_port","evo_session"]`
3. Local + community both miss → try standard impl, stuck on hook trait design
4. `gep_evolve` context=`"Porting EvolutionLifecycle class with async hooks from TS to Rust. TS uses duck typing for hook interface, Rust needs explicit trait but hook set is open-ended."` intent=`"innovate"`
5. Implement per returned plan + run tests
6. `gep_record_outcome` signals=`["rust_port","evo_session","trait_design","async_hooks"]` summary=`"Ported EvolutionLifecycle to Rust using Box<dyn EvolutionHooks + Send + Sync>, erased generics at storage boundary to avoid explosion"` score=0.85

### Scenario C — E2E Wrap-Up

1. (Already doing small recall/record cycles during the fix)
2. After E2E green, `gep_status` to see node accumulation
3. If the lesson is broadly reusable → `gep_export` for a `.gepx` backup

### Scenario D — Reusable Community Gene Discovered

1. `gep_search_community` hits a Gene; signature present, gdi_score > 40, domain match
2. `gep_install_gene` to load it into the local pool
3. Future `gep_recall` hits the local version directly — no community-search credit needed

## See Also

- `../patterns/memory-mcp-discipline.mdc` — universal recall / record discipline (the 80%)
- `../common/quality-gates.mdc#post-change-review--e2e-gate` — `gep_record_outcome` only after E2E passes
- `../patterns/multi-worktree.mdc` — cross-worktree conflicts → `worktree_conflict` signal
- `evox-extension.mdc` / `feishu-sdk.mdc` / `mbti-persona.mdc` — domain-specific signals
