# Design Craft (Full Gate 4)

Main SKILL: [`../SKILL.md`](../SKILL.md). This file expands Gate 4 "POLISH" — purpose-built to remove "AI-generated flavor".

References:
- addyosmani/agent-skills' `frontend-ui-engineering`
- WCAG 2.1 AA accessibility
- Refactoring UI principles for visual hierarchy
- Material / Tailwind / Radix design-system practices

---

## 1. Anti-AI Aesthetic (Most Important Section)

A senior reviewer can spot "AI-generated" UI at a glance. The signals below must all be eliminated.

### 1.1 Color

| ❌ AI default | Why it's a problem | ✅ Production approach |
|---|---|---|
| Purple / Indigo / Violet gradient | Model fallback palette; every AI app looks the same | Use the project's actual design tokens; **stop and ask if there are no tokens** |
| Heavy `bg-gradient-to-r from-purple-500 to-pink-500` | Visual noise + brand mismatch | Single color / extremely restrained gradient, **only** at hero / CTA / key focal points |
| `text-gray-500` everywhere | The "safe" gray in the model's memory | Use semantic colors from the design system (`text-secondary` / `text-muted`) |
| Black + electric blue ("cyberpunk") | Hard to read + harsh over time | Neutral dark background + high-contrast text |

**Principles**:
- Use **semantic color tokens**: `text-primary` / `bg-surface` / `border-default` / `text-error`
- No bare hex / RGB
- No design system → **stop and design tokens first**; don't sprinkle colors by intuition

### 1.2 Rounding

```
AI default:                 Production scale:
rounded-2xl everywhere →    button:    rounded-md  (4-6px)
                            input:     rounded-md  (4-6px)
                            card:      rounded-lg  (8-12px)
                            modal:     rounded-xl  (12-16px)
                            avatar:    rounded-full
                            container: rounded-none / rounded-lg
```

**Rounding has hierarchy**: small elements use small radii, large containers use larger radii — bigger isn't friendlier.

### 1.3 Shadows

```
❌ shadow-2xl + shadow-purple-500/50 everywhere
✅ Elevation scale defined by the design system:
   - elevation-0: flat (no shadow)
   - elevation-1: card (subtle shadow, blur radius 4-8)
   - elevation-2: popover / dropdown (medium shadow)
   - elevation-3: modal / drawer (strong shadow + backdrop)
```

Shadow = depth-hierarchy signal, not decoration. No hierarchy needed → no shadow.

### 1.4 Spacing

Use the spacing scale only — **no arbitrary pixels**:

```
✅ Standard scale (Tailwind):
0   1   2   3   4   5   6   8   10   12   16   20   24   32
0px 4px 8px 12px 16px 20px 24px 32px 40px 48px 64px 80px 96px 128px
```

```
❌ padding: 13px           // off-scale
❌ margin-top: 2.3rem      // off-scale
❌ p-12 everywhere         // huge padding wrecks hierarchy

✅ Consistent padding within a component: p-4 / px-6 py-4 / etc
✅ Hierarchy via spacing: section gap 8/12, item gap 3/4
```

**Density principle**:
- Information-dense (admin / dashboard) → tighter (gap 2–4)
- Marketing / landing → looser (gap 12–24)
- Don't mix wildly different densities within one component

### 1.5 Typography

```
✅ Type scale (no more than 6 levels):
display:   text-4xl / text-5xl  font-bold       (Hero / Landing)
h1:        text-3xl              font-semibold   (Page title, ONE per page)
h2:        text-2xl              font-semibold   (Section title)
h3:        text-xl               font-semibold   (Subsection)
body:      text-base             font-normal
small:     text-sm               font-normal     (Secondary)
caption:   text-xs               font-normal     (Helper / metadata)
```

**Forbidden**:
- Skipping levels (don't go h1 directly to h3)
- Using heading styles as decorative text
- More than 3 sizes in one viewport
- More than 2 weights in one viewport
- Mixing serif + sans unless the design system explicitly requires it

### 1.6 Layout

| ❌ AI default | ✅ Alternative |
|---|---|
| Centered hero + giant padding | Content-driven layout; partition by user task |
| Generic 3-column card grid | Importance-driven: main + sidebar / list + detail |
| Everything centered | Long text left-aligned (more legible), numbers right-aligned, headings depending |
| Even grid with no visual anchor | Use size / whitespace / color as hierarchy anchors |
| Forcing whitespace when content is sparse | Content-driven sizing; introduce `EmptyState` when needed |

### 1.7 Decorative Elements

```
❌ Decorative emoji scattered ("🚀 Let's get started" / "💡 Tip")
❌ Decorative gradient blobs floating in the background
❌ Flicker / bounce / shake micro-motion (unless interaction-meaningful)
❌ "AI vibe" mysterious background images

✅ Use the design system's icon set (lucide / heroicons / radix-icons)
✅ Static / restrained visual anchors
✅ Micro-motion only for interaction feedback (hover / focus / state change)
```

---

## 2. Production-Grade UI: Four States

Any data-rendering component needs all four states. Drawing only success → not passing.

### 2.1 Loading

❌ Spinning indicator filling the page
❌ Blank waiting for data

✅ Skeleton loader (preserves layout, pulse animation)
✅ Add `aria-busy="true"` + `aria-label="Loading X"`

```tsx
function TaskListSkeleton() {
  return (
    <div className="space-y-3" aria-busy="true" aria-label="Loading tasks">
      {Array.from({ length: 3 }).map((_, i) => (
        <div key={i} className="h-12 bg-muted animate-pulse rounded-md" />
      ))}
    </div>
  );
}
```

### 2.2 Empty

❌ Render nothing when the array is empty
❌ A bare "No data"

✅ Provide: illustration / guidance copy / **next-step CTA**

```tsx
<div role="status" className="text-center py-12">
  <TasksEmptyIcon className="mx-auto h-12 w-12 text-muted" />
  <h3 className="mt-2 text-sm font-medium">No tasks yet</h3>
  <p className="mt-1 text-sm text-muted">
    Get started by creating your first task.
  </p>
  <Button className="mt-4" onClick={onCreateTask}>
    Create Task
  </Button>
</div>
```

### 2.3 Error

❌ Whole page crashed white
❌ "Something went wrong" with no reason / no remediation

✅ Error message + reason + **retry** or **contact** entry

```tsx
<div role="alert" className="rounded-lg border border-error bg-error-soft p-4">
  <h3 className="text-sm font-medium text-error">Failed to load tasks</h3>
  <p className="mt-1 text-sm text-error-muted">{error.message}</p>
  <Button variant="outline" size="sm" className="mt-3" onClick={retry}>
    Try again
  </Button>
</div>
```

### 2.4 Success

The actual content render. Notes:
- Long lists → virtualization / pagination
- Long text → fold / truncate
- Async operations → optimistic update + failure rollback

---

## 3. Accessibility (WCAG 2.1 AA Floor)

### 3.1 Keyboard Navigation

```tsx
✅ <button onClick={fn}>Click</button>          // focusable by default
❌ <div onClick={fn}>Click</div>                // mouse-only

✅ <a href="/x">Go</a>                          // Enter + browser navigation
❌ <span onClick={() => navigate('/x')}>Go</span>

// Forced to use a div as a button (not recommended):
<div role="button" tabIndex={0}
     onClick={fn}
     onKeyDown={(e) => { if (e.key === 'Enter') fn(); }}>
  Click
</div>
```

Test: **Tab through the whole page**; every interactive must be keyboard-reachable + activatable + show a focus ring.

### 3.2 ARIA & Semantics

```tsx
✅ Icon button: <button aria-label="Close dialog"><XIcon /></button>
✅ Form: <label htmlFor="email">Email</label> + <input id="email" />
✅ State change: <div role="status" aria-live="polite">Saved</div>
✅ Error: <div role="alert">{errorMessage}</div>
✅ List: <ul role="list"> ... <li>...</li>
```

**Always use semantic HTML first** (`button` / `nav` / `main` / `aside` / `section`); ARIA is a backstop, not a substitute.

### 3.3 Focus Management

- When a modal / dialog opens, move focus in; on close, restore focus to the trigger
- Focus must not be trapped in invisible DOM
- Focus ring must not be `outline: none` without a replacement (use `focus-visible:ring`)

### 3.4 Color Contrast

- Body text / background: ≥ **4.5:1**
- Large text (≥ 18pt or 14pt bold): ≥ **3:1**
- Decorative-only: no requirement
- **Color is not the sole information carrier**: errors must include icon / text; status dots paired with labels

Tools: built-in browser devtools contrast checker / axe DevTools.

### 3.5 Responsive

Test breakpoints: 320 / 768 / 1024 / 1440.

```tsx
<div className="
  grid grid-cols-1   /* mobile */
  sm:grid-cols-2     /* tablet */
  lg:grid-cols-3     /* desktop */
  gap-4
">
```

Mobile-first; layer in `sm:` / `md:` / `lg:` / `xl:`.

---

## 4. Micro-Interactions / Motion

### 4.1 Worth Doing

- **Hover / Focus**: subtle color or shadow shift, 150–250ms
- **State transitions**: selection / tab change, 200–300ms
- **Entrance**: toast / dropdown / popover, 200ms
- **Optimistic update**: instant feedback on action, rollback on failure

### 4.2 Don't Do

- Entrance animations on every element (perf + annoying)
- Duration > 500ms (unless meaningful, e.g., complex modal)
- Bounce / spring overuse (causes vertigo)
- Auto-playing video / auto-scrolling carousel

### 4.3 Reduced-Motion Preference

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## 5. Component Architecture

### 5.1 Separation of Concerns

```tsx
// ✅ Container: handles data
function TaskListContainer() {
  const { tasks, isLoading, error, refetch } = useTasks();

  if (isLoading) return <TaskListSkeleton />;
  if (error) return <TaskListError error={error} retry={refetch} />;
  if (tasks.length === 0) return <TaskListEmpty />;

  return <TaskList tasks={tasks} />;
}

// ✅ Presentation: pure render
function TaskList({ tasks }: { tasks: Task[] }) {
  return (
    <ul role="list" className="divide-y">
      {tasks.map(task => <TaskItem key={task.id} task={task} />)}
    </ul>
  );
}
```

### 5.2 Composition Over Configuration

```tsx
✅ Composition
<Card>
  <CardHeader>
    <CardTitle>Tasks</CardTitle>
    <CardActions><Button>Add</Button></CardActions>
  </CardHeader>
  <CardBody><TaskList tasks={tasks} /></CardBody>
</Card>

❌ Over-configuration (props explosion)
<Card
  title="Tasks"
  headerVariant="large"
  headerActions={[{ label: 'Add', onClick: ... }]}
  bodyPadding="md"
  bodyContent={<TaskList tasks={tasks} />}
/>
```

### 5.3 Component Size

- **Single component ≤ 200 lines** (including props + JSX)
- > 200 lines → split into container / sub-components / custom hook
- Prop drill ≥ 3 levels → switch to context / lift composition

---

## 6. State-Management Selection

By "simplest sufficient":

| Scenario | Pick |
|---|---|
| In-component UI state | `useState` |
| Sibling components share state | Lift state / parent component |
| Global read-only (theme / auth / locale) | `useContext` |
| URL-shareable state (filter / page) | URL searchParams |
| Server data + caching | React Query / SWR / TanStack Query |
| Complex client global state | Zustand / Redux Toolkit / Jotai |

**Start at the leftmost / simplest**; upgrade only when proven insufficient.

---

## 7. Design-System Integration

### 7.1 Project Has No Design System

- First confirm with the user if there's a Figma / Storybook / token JSON
- **None → stop and design a minimum token set**: 4–6 semantic colors + 8 spacings + 4 type sizes + 3 rounding levels + 2 elevation levels
- Don't sprinkle colors / radii / shadows out of thin air without tokens

### 7.2 Project Has a Design System

- Stick strictly to tokens; don't invent new values
- See design contradicting tokens → return to Gate 1 to decompose and ask the user

---

## 8. Frontend Performance Floor

Not the main focus of this gate, but worth a glance during polish:

- Lists ≥ 100 items → virtual scroll
- Images must be lazy-loaded + `width/height` to prevent CLS
- Third-party scripts `defer` / on-demand import
- Bundle monitoring: a single chunk < 250 kB gzipped is a good gate
- React: `memo` / `useMemo` / `useCallback` are **not defaults**; add only when profiling shows they help

---

## 9. Design Verification (Full Gate 4 Checklist)

```markdown
## Visual
- [ ] No purple gradient / no `rounded-2xl` everywhere / no `p-12` overuse
- [ ] All colors via semantic tokens; no bare hex
- [ ] Rounding / shadows / spacing all on the design scale
- [ ] Type scale ≤ 6 levels; ≤ 3 sizes per viewport

## States
- [ ] Loading: skeleton, not spinner
- [ ] Empty: illustration + copy + CTA
- [ ] Error: reason + retry entry
- [ ] Success: content complete

## a11y
- [ ] Tab through reaches every interaction
- [ ] Focus ring visible
- [ ] Icon buttons have aria-label
- [ ] Form labels associated
- [ ] Color is not the sole information
- [ ] Text contrast ≥ 4.5:1
- [ ] 320 / 768 / 1024 / 1440 all tested

## Interaction
- [ ] hover / focus has feedback
- [ ] Async ops have optimistic update or loading feedback
- [ ] No meaningless motion

## Architecture
- [ ] Single component ≤ 200 lines
- [ ] container / presentation separation
- [ ] Simplest-sufficient state choice
- [ ] No values invented outside design tokens
```

Any unchecked → return to Gate 4.
