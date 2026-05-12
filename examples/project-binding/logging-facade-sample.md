---
description: Sample binding pattern — structured logger facade so every line carries [module-name] prefix (closes the loop with ../common/error-handling.mdc). Copy into .cursor/rules/project/<your-logging>.mdc.
alwaysApply: false
---

# Logging facade binding (sample)

Replace `<...>` with your stack. Goal: **`error-handling.mdc`** requires module-prefixed log lines; **`common/`** does **not** pick a vendor — that choice lives **here**.

## Contract

Every error / warning line must render with a **`[module-name]`** prefix (or structured `module` field with the same value) so ops can grep by owner.

## TypeScript — thin wrapper around `console` (dev) or `pino` / `winston`

```typescript
export function logError(moduleSlug: string, message: string, err?: unknown) {
  const detail = err instanceof Error ? err.message : String(err);
  console.error(`[${moduleSlug}] ${message}${detail ? `: ${detail}` : ""}`);
}
```

For production structured logs, expose `logger.child({ module: moduleSlug })` and document that **`module`** is mandatory on `error` / `warn` levels.

## Rust — `tracing` subscriber field

Configure a default `tracing` formatter that emits `target` or an explicit **`module`** field aligned with `[module-name]`. Crate-local convention:

```rust
tracing::error!(target = "task-service", "persist failed");
```

Mirror the same **`target`** naming as your `[module-name]` grep keys.

## Go — `log/slog` with `Group` / attributes

Attach `slog.String("module", "payment-gateway")` (or wrapped helper) on every Error call path.

---

## Paste into onboarding

List the façade import path(s) developers must use **instead** of raw `console.log` / `println!` / `log.Print` on error paths:

- Preferred import: `<PKG_OR_PATH>`
- Forbidden on error paths: bare `println!` without module context (except tests)

See also `../common/error-handling.mdc`.
