# Perf backlog queue handoff

Source of truth: docs/perf-roadmap.md, section "Backlog (verified 2026-10-16)", items B1-B13.
Milestones: docs/perf-milestones.json.

Rules for each item agent:
- Branch `perf-<item>` from latest main. One item per branch. Never use git stash or git worktree.
- Offline proof only (`swift build -c release`, `.build/release/realityhd perf --budget|--breakdown <scene>`,
  `swift test --filter ...`, `realityhd render`, thumbnail pixel diff). No simulator runs.
- Append a status line under the item in docs/perf-roadmap.md with before -> after numbers, marked
  "offline; sim validation pending".
- Commit, push, open a DRAFT PR titled "Perf <item>: ...". Do not merge.
- Append one line to notes/QUEUE.md: `<item> | branch | PR url | offline result | sim bench to run`.
- Builds filtered: `2>&1 | grep -E "error:|warning:|BUILD" | head -40`.
- End by checking out main.
