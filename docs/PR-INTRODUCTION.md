# coderules：让 AI 编码从"能跑就行"升级为"团队规范"

> 一行话：把团队的代码品味、安全底线、设计纪律，沉淀成 AI agent 每次都遵守的可执行约束——而不是每次对话都重新解释。

---

## 0. TL;DR（30 秒版）

- **是什么**：一套分层的 Cursor / Claude-Code 规则包 + 一个名为 `aicoding` 的 agent skill。
- **干什么**：在每次 AI 编码对话中，自动注入"团队最在意的代码红线"——文件长度、嵌套深度、错误处理、安全、设计审美——并按场景触发更细的语言/架构/项目规则。
- **为什么不一样**：
  - 量化 + 可触发：500 行、6 个 always-on、≤9K token 注入 —— 都是数字，不是模糊建议。
  - 分层 + 渐进式加载：常驻规则 6 个，其它按 glob/desc 触发，**省 token 也省注意力**。
  - 项目无关 + 可共享：`common/ lang/ patterns/` 三层项目无关，团队共用一份；项目特异值放在自己的 `.cursor/rules/project/`。
- **怎么用**：
  ```bash
  curl -fsSL https://raw.githubusercontent.com/linfengchen/coderules/main/install.sh | bash -s cursor
  ```
- **跑一遍多久能感受到？**：写一个 200 行以上的功能 —— 第一次就能感觉到 AI 在拒绝单文件膨胀、在主动问决策维度、在拒绝紫色渐变 + 圆角 16 的默认审美。

---

## 1. 为什么需要这个工具

不是因为"AI 编码不好用"，而是因为它**太好用了**——好用到让我们忘了它在做什么取舍。下面三个真实场景：

### 场景 A — 失控的文件膨胀

> 你让 AI 在某个 service 下加一个新功能。它写得飞快，一个文件 800 行交付。你打开看："咦，这个函数怎么 200 行？为什么整个 controller 全揉在一个 .ts 里？"

这不是 AI 的错——它没拿到"我们团队认为单文件 ≤ 500 行、单函数 ≤ 120 行"这个约束。下次你换一个 prompt 又会重写一份巨石文件。

**`coderules` 怎么做**：`common/clean-code-core.mdc`（always-on）写明 500 / 120 / 3 行限制 + 每次任务结束后由 `common/quality-gates.mdc` 触发 "post-change review" 自检，如果 AI 自己写出 800 行单文件，它会自我否定并提议拆分。

### 场景 B — AI Aesthetic 污染

> PM 让你做个数据看板。你交给 AI："写个 React dashboard"。AI 输出一个 component，紫色渐变、圆角 2xl、阴影深、`p-12` 间距、配 emoji 图标、字体 `text-4xl font-bold`——一眼"AI 出品"。

设计师不接，PM 也不爱。你回头删紫色、改圆角、缩间距，又花 30 分钟。

**`coderules` 怎么做**：`aicoding/SKILL.md` 的 Gate 4 (POLISH) 明确禁了一组"AI 默认审美组合"：紫色 gradient + 大圆角 + 重阴影 + emoji 图标。还要求**四态完整**（loading / empty / error / success）+ WCAG 2.1 AA + 8/16/24 间距scale。AI 主动问你"这个项目有 design system 吗？没有要不要先建一套最小 token？"——而不是直接交付一个 AI flavor 浓缩液。

### 场景 C — 项目特异性丢失

> EvoX 项目里有个细节：feishu-bridge 跑在 TUI 环境，**不能用 `console.error`**——会污染 TUI 渲染——必须 `appendFileSync("/tmp/feishu-bridge.log", ...)`。每次新对话你要重新解释一遍。emoji 也是，必须用 `:THUMBSUP:` 这种 enum，不是 Unicode 表情。jiti cache 怎么重启？哪些路径属于 Phase 6b 双写区？

每次重新讲是浪费时间，更糟的是**讲漏了** —— AI 默认 console.error 出来，TUI 一团乱码。

**`coderules` 怎么做**：项目特异值放在你自己 repo 的 `.cursor/rules/project/`。`coderules` 提供 `examples/project-evox/` 作为模板——直接复制改值即可。glob 触发 `extensions/feishu-bridge/**` 时自动加载，不用每次解释。

---

## 2. 它到底怎么解决这些问题

四个机制，分别对应"约束输出 / 省 token / 标准化 / 沉淀经验"。

### 2.1 输出约束机制 — 4 Gates

`aicoding/SKILL.md` 把"vibe coding"切成 4 个有量化退出条件的 gate：

```
DECIDE  ──▶  BUILD  ──▶  VERIFY  ──▶  POLISH
拆维度       ≤100 LOC    5 轴 review   反 AI 审美
锚证据       结构限制    e2e 测试      四态完整
```

每个 gate 都包含：

- **Anti-rationalization 表**：列出 AI 最常用的"合理化跳过"借口（"用户没要求测试"、"先写出来再说"、"这只是 demo"）+ 反驳脚本。
- **Red flags**：触发哪些信号就停下问用户。
- **Verification checklist**：交付前 AI 自检的清单。

为什么 work：AI 默认会"勤奋地全速前进"。Gates 是给它一个**主动暂停的合法理由**——而且暂停标准是量化的，AI 自己能判断。

### 2.2 Token 消耗管控 — Always-on Tier ≤ 6 文件 / ~7K tokens

历史数据：

| 版本 | always-on 规则数 | 始终注入 token | 备注 |
|---|---|---|---|
| 早期手写 .cursorrules | 1 文件，无层级 | ~3K | 但能力贫乏 |
| coderules v2.2（未优化） | 13 | ~18K | 全量注入 |
| **coderules v2.4（当前）** | **6** | **~7K** | -60% |

每次 prompt 节省 ~11K input tokens。按 GPT-4 / Claude 价格，月千次对话能省下可观的费用——但更重要的是**模型注意力没被规则海稀释**：

- ≤ 7 文件 always-on：注意力留在用户任务上
- > 10 文件：AI 开始"过度引用规则"代替解决问题
- > 15 文件：instruction-following 明显下降

降权下来的规则没消失——按 `globs` / `description` 触发：编辑 `.rs` 才加载 Rust fmt 纪律，提到"重构"才加载 refactoring guidelines。**全部能力保留，注意力按需分配。**

### 2.3 代码标准化 — 量化阈值 + 强制清单

模糊的"代码要清晰"AI 没法 self-check；量化指标可以。`coderules` 把品味量化到 5 类约束：

| 类别 | 示例量化指标 |
|---|---|
| 结构 | 文件 ≤ 500 行 / 函数 ≤ 120 行 / 嵌套 ≤ 3 层 / 单 commit ≤ 100 行 |
| 错误 | 不空 catch、不裸 `unwrap()` / `panic!` 、边界 validate、log 带 module 前缀 |
| 命名 | 描述性名（拒 `data` `item` `handle`）、布尔 `is*/has*`、动名搭配 |
| 安全 | 凭证不入代码、log 脱敏、SQL/命令/路径/SSRF/prompt 注入防御 |
| 文档 | TODO 必带 owner + ticket、Deprecation 必带 alternative + removal version |

加上 `architecture.mdc` 的"接口单一定义 / wiring 完整 / 跨进程单胶水层"—— AI 在写第二个 service-to-service handler 时会主动问你"这个 dispatch 应该走 MCP 还是直连？项目里已经有一个 glue 层了"。

### 2.4 项目特异性沉淀 — 三层 + 一例

```
common/      团队/语言无关原则        always-on 6 个，触发 4 个
lang/        每语言语法/工具          按 .ts/.rs glob 触发
patterns/    跨项目可复用架构模式     按 desc/glob 触发
examples/    示例 binding（不加载）   .md 扩展名，给你抄
```

你自己的 repo 加一个 `.cursor/rules/project/` 写自己的 binding。当 AI 编辑 `extensions/feishu-bridge/**` 时，自动一起加载：
- `patterns/plugin-architecture.mdc`（通用 plugin 设计）
- `patterns/im-bot-integration.mdc`（IM 通用）
- 你的 `project/feishu-sdk.mdc`（emoji 表 + API endpoint + block-type IDs）
- `common/error-handling.mdc`（"TUI 不能 console.error"）

四层一起进 context，AI 输出符合**全部**约束。一次配置，长期受益。

### 2.5 Progressive Disclosure — 入口小、深度按需展开

```
aicoding/SKILL.md (~4K tokens)        ← 入口
└── references/
    ├── decision-hygiene.md (~6K)     ← 只在 Gate 1 深入时载入
    ├── code-craft.md (~8K)           ← 只在 Gate 2 深入时载入
    └── design-craft.md (~9K)         ← 只在 Gate 4 深入时载入
```

入口短而完整，详情按需打开。同 idea 在 patterns 层也成立——只有你真用 plugin / IM bot / memory MCP 时才装载对应规则。

---

## 3. 与市面常见做法对比（13 维度）

| 维度 | 裸 prompt | `.cursorrules` 单文件 | 内部 AGENTS.md | Claude /skills（如 addyosmani） | ESLint/Clippy 等 linter | **coderules** |
|---|---|---|---|---|---|---|
| 1. 触发机制 | 全靠用户提 | 全文件常驻 | 同左 | 描述匹配 | 静态扫描 | **always-on + glob + desc 三档** |
| 2. always-on token 量 | 0 | ~5–10K | ~5–10K | ~3K | n/a | **~7K（封顶 6 个文件）** |
| 3. 注意力分散风险 | 高（用户每次说） | 中-高（全量） | 中-高 | 低 | n/a | **低（≤6 常驻）** |
| 4. 量化阈值 | 偶尔 | 偶尔 | 看作者 | 100 行限制 | 部分（圈复杂度等） | **结构/错误/命名/安全/文档全量化** |
| 5. 决策卫生 | 无 | 无 | 偶尔 | 有（Gate 1）但浅 | 无 | **完整 Gate 1：claim decomposition + evidence anchors + temporal layering + commitment boundary** |
| 6. 反 AI 审美 | 无 | 偶尔 | 看作者 | 部分 | 无 | **Gate 4 反默认审美 + 4 态完整 + a11y + 设计 token** |
| 7. 多项目复用 | 无 | 复制 | 复制 | 全局 skill | 配置 | **三层项目无关 + 项目自带 binding 层** |
| 8. 项目特异性 | 用户每次提 | 同左 | 写到 AGENTS.md | 不擅长 | 配置 | **`patterns/` + `examples/` + 用户 `project/` 三件套** |
| 9. 维护成本 | 每对话一遍 | 改一处不影响其他 | 同左 | 一处更新全局 | 配置即生效 | **一处更新 + symlink 即时生效** |
| 10. 跨工具兼容 | 全部 | Cursor 专属 | Cursor / Claude | Claude | IDE plugin | **Cursor + Claude + 任何能加载 .md 的 agent** |
| 11. 学习曲线 | 低 | 低 | 低 | 中 | 中 | **入口短、深度按需展开** |
| 12. 回归测试 | 无 | 通常无 | 无 | 部分 | 工具内置 | **`REGRESSION-TEST-PLAN.md` 6 测试场景** |
| 13. 经验沉淀回路 | 无 | 手动改 | 手动改 | 手动改 | 无 | **配合 Memory MCP（GEP）/ EvoMap 形成闭环** |

> 说实话不擅长什么：**linter 是字符级强校验**，coderules 是 prompt 级**软约束**——两者互补。先用 coderules 让 AI 写得规范，再用 linter 兜底。

---

## 4. 与 EvoMap 项目协同的价值

EvoMap 是 agent economy 平台，agent 之间通过 Gene/Capsule 共享经验、做 bounty 任务、累积 credits。`coderules` 在这套平台里扮演**底层质量协议**：

### 4.1 每个 agent 输出的统一基线

EvoMap 的 agent 进化 (`evolver --review`) 需要一个**起点 baseline**。如果 baseline 本身就不规范——文件巨石、错误吞掉、没有决策追踪——后续 evolve 出的能力也是建在沙上。`coderules` 给所有 agent 一个团队认可的 quality bar。

### 4.2 Gene / Capsule 的载体

EvoMap 的 Gene/Capsule 是可复用经验单元。`coderules` 的两个特性正好契合：

- **量化阈值**：Gene 描述可以引用具体数字（"file ≤ 500 lines"），跨 agent 解码无歧义
- **决策卫生痕迹**：Gate 1 产生的 decomposition + anchors，本质上就是 Gene 的 metadata 候选

### 4.3 Bounty 任务的交付门槛

agent 接 bounty 任务，交付时需要一个客观验收标准。`coderules/REGRESSION-TEST-PLAN.md` 提供了 6 个可执行测试 + 量化 quality gate。bounty 发布方可以指定"必须通过 T1+T2+T3"，验收成本骤降。

### 4.4 Memory-MCP 协议的现成 pattern

`patterns/memory-mcp-discipline.mdc` 是通用 recall + record + community-search 协议，EvoMap 的 GEP 服务直接 bind 这个 pattern 即可——不用从零写"什么时候记什么时候不记"。

### 4.5 跨 agent 知识 lingua franca

agent A 用 `common/clean-code-core.mdc`、agent B 也用，它们生成的代码可以**直接互评**——同一套量化标准。EvoMap 跨 agent 协作不再需要"先沟通规则"。

---

## 5. 上手 30 秒

```bash
# 1. 装到当前项目
curl -fsSL https://raw.githubusercontent.com/linfengchen/coderules/main/install.sh | bash -s cursor

# 2. 在 Cursor 打开项目，问 AI 一个 200 行以上的功能
#    AI 会主动问决策维度、按 500 行限制拆文件、按四态完整画 UI

# 3. （可选）EvoX 项目特定 binding
mkdir -p .cursor/rules/project
cp ~/.coderules/examples/project-evox/*.md .cursor/rules/project/
# 把 .md 都改名为 .mdc 即激活；按需删掉用不到的
```

完整 docs：[`README.md`](../README.md) · [`INDEX.md`](../INDEX.md) · [`REGRESSION-TEST-PLAN.md`](../REGRESSION-TEST-PLAN.md)

---

## 6. 总结

| 团队痛点 | `coderules` 怎么治 |
|---|---|
| AI 写出 800 行巨石文件 | 量化阈值 500 / 120 / 3 + Gate 3 自检 |
| AI 默认紫色 gradient + 圆角 16 | Gate 4 反默认审美 + 四态完整 + a11y |
| 项目特异性每次重讲 | `examples/` 模板 + 用户 `project/` binding |
| Token 浪费在规则海里 | always-on 封顶 6 / ~7K + 三档触发 |
| AI 跳过决策直接撸代码 | Gate 1 强制 decomposition + anchors |
| 安全漏洞反复犯 | always-on `security-secrets.mdc` 不可绕过 |
| 团队规范没法跨项目 | 三层项目无关 + binding 层 |
| 单工具锁定 | 同时支持 Cursor / Claude / Codex / Gemini |

### 我们的赌注

这个工具的核心赌注是：**AI 编码的下一个瓶颈不是模型能力，是协议层**。

- 模型已经够强（GPT-5/Claude 4 写代码超过中级工程师）
- 但**没有约束**的强模型 = 用更快的速度写出更多需要返工的代码
- 团队需要的不是更牛的 AI，而是**让 AI 知道我们团队在意什么**

`coderules` 把"团队在意什么"沉淀成可执行的、可量化的、可分发的规则——一次写好，每个 prompt 受益。

### 下一步

如果你愿意做试点：

1. 在你最熟悉的一个项目装上 `coderules`，跑一周
2. 记录至少 3 个让你"哎这个 AI 居然主动停下来问我了"的瞬间
3. 把感受贴到团队群里

如果有"这个规则不适合我们项目"的反馈，就提个 issue / PR——`coderules` 的目的是**承载团队共识**，不是把作者的偏好塞给所有人。

---

## 附录 A — 当前规则清单

详见 [`INDEX.md`](../INDEX.md)。简表：

```
common/      (10) clean-code-core, architecture, decision-hygiene, error-handling,
                  quality-gates, security-secrets   ← 6 个 always-on
                  comments-docs, imports, refactoring-guidelines, testing-principles  ← desc/glob 触发

lang/        (4)  clean-code-typescript, clean-code-rust, rust-fmt-discipline, typescript-testing

patterns/    (5)  multi-worktree, plugin-architecture, im-bot-integration,
                  memory-mcp-discipline, persona-architecture

aicoding/         SKILL.md + 3 references (decision-hygiene / code-craft / design-craft)

examples/         project-evox/ (5 templates, .md, 不加载)
```

## 附录 B — 真实数据

| 指标 | 值 |
|---|---|
| 始终注入 token（v2.4） | ~7K |
| 较未优化版本节省 | ~11K / prompt（-60%） |
| 加载文件数（always-on） | 6 |
| 总规则文件数 | 19 .mdc + 5 .md 模板 |
| 文件长度上限（项目自身要求） | 500 行 |
| 函数长度上限 | 120 行 |
| 嵌套深度上限 | 3 |
| 安装命令数 | 1（curl 一行） |

## 附录 C — FAQ

**Q: 我们项目已经有 ESLint / Clippy / 内部规范文档，还需要这个吗？**
A: ESLint 是字符级强校验；`coderules` 是 prompt 级软约束——两者互补。AI 写之前规范，linter 写之后兜底。内部文档 AI 看不到（除非塞 system prompt），`coderules` 让规范变成 AI 可执行的格式。

**Q: 装了这个，AI 会不会变得很慢？啥都要问？**
A: Gate 1 只在大任务（≥100 行 / 涉及架构 / 涉及 UI）时触发；小修小改照常快速。"问决策维度"是设计意图——比改 3 次省得多。

**Q: 能不能只用一部分？**
A: 可以。`install.sh` 支持 `cursor` / `claude` / `all` 三档；想更细，直接挑 `common/` 单个文件复制。

**Q: 团队成员品味不一致怎么办？**
A: `common/` 是团队最低共识（量化阈值 + 安全），不会有人反对。`lang/` 是社区规范（Google Style 等）。`patterns/` 是可选项。真有分歧的，PR 进来讨论。

**Q: 跟 addyosmani/agent-skills 是什么关系？**
A: `aicoding` skill 学了它的 process-first 范式（DECIDE → BUILD → VERIFY → POLISH），但补了 Gate 1（决策卫生）+ 量化阈值。两者可共存。
