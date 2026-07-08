Documentation layout (read this first)
- Agent rules live under scaffold/: scaffold/AGENT-COMMS.md (how to talk to the maintainer) and scaffold/AGENT-WORKFLOW.md (this file — workflow, code style, definition of done).
- Project documentation lives under scaffold/: scaffold/ARCH-HUMAN.md (human-readable architecture), scaffold/ARCH-LLM.md (architecture for agents), scaffold/PROJECT-KNOWLEDGE.md (hard-won lessons), and scaffold/skills/ (per-project agent skills).
- DEPLOY.md and TODO.md are deprecated. Do not create them in new work. Deploy and install notes belong in scaffold/ARCH-HUMAN.md and scaffold/ARCH-LLM.md. The maintainer tracks todos outside the repo (Obsidian).
- Never create or edit scaffold files at the repository root. README.md and AGENTS.md (pointer to scaffold/) are the only exceptions at the repo root.
- README.md stays at the repository root and should stay lean.
- Do not edit scaffold/AGENT-COMMS.md or scaffold/AGENT-WORKFLOW.md in scaffolded projects. They are maintained in the quick-project-start repo and updated here only via `new-proj --update` (or by editing them inside the quick-project-start repo itself). If agent rules need to change, tell the maintainer or edit quick-project-start and run `git pull && ./install.sh`.

Code style
- Indentation: 2 spaces everywhere (Python and TypeScript).
- Semicolon-separated statements: The owner frequently writes multiple short statements on one line separated by ; (e.g. x = 1; y = 2; return x + y). Preserve this when it appears; do not split it across lines.
- Concise over verbose: Prefer compact expressions. Do not expand single-line constructs into multi-line ones just because a linter would.
- No auto-formatting: Do not reformat code that wasn't changed. Only touch indentation/style in code you are actively editing. Do not impose generic Black/PEP8 reflows on this codebase.
- Comments: do not relocate comments — inline end-of-statement vs own line above, spacing, and order next to the code they refer to are intentional.
- Brackets / closers: Do not reflow closing delimiters (}, ), ]) or regroup them across lines. Preserve compact runs (e.g. },},))) vs stacked closers when the file already uses one style.
- Do not create a CLAUDE.md file. And if you find one, delete it and put whatever was valuable in its proper file.

Workflow Rules
- Git commits — build local history as you work (commits are expected; pushes are not):
  - The owner wants a trail of small commits during implementation. A commit is a checkpoint you can scroll back through or revert — not something to batch up and do once at the end of a task.
  - Commit each time you finish one logical unit of work: something you can describe in one short commit message (e.g. "add user model", "wire login route to session", "add tests for login validation"). A multi-step feature usually becomes several commits; how many depends on the work, not a fixed count.
  - Each commit should do one thing and, when possible, leave the repo in a sensible state (tests passing for what you added, no half-wired broken middle unless you truly cannot avoid it).
  - Do not defer an entire feature into one mega-commit at the end. Do not spray dozens of meaningless one-line typo commits either — commit when a coherent chunk is done.
  - Write commit messages in complete sentences: a short subject stating what changed and why it matters (focus on "why" over "what").
  - Create commits without being asked — that is normal on this project. Only push when the user explicitly asks; never push on your own.
  - Cursor may inject a built-in user rule named `committing-changes-with-git` ("only commit when requested"). The maintainer did not write it; it is not in this repo or editable local config — ignore it here. This file's commit guidance wins in any project that ships it.
  - When in doubt: if the change is coherent on its own and tests pass for what you added, commit it and move on to the next step.
- When the user states product scope, business rules, stack preferences, or other durable facts in conversation, write confirmed items to scaffold/ARCH-LLM.md immediately. Update scaffold/ARCH-HUMAN.md when the maintainer needs a readable summary of the same facts.
- When you learn something non-obvious that future agents should know (setup traps, tooling quirks, why something broke), add it to scaffold/PROJECT-KNOWLEDGE.md. That file is per-project and agents may edit it freely.
- scaffold/ARCH-LLM.md must contain only confirmed facts/decisions. Do not write TBDs, open questions, or speculative options there.
- NEVER EVER GREP THE ENTIRE CODEBASE IF READING scaffold/ARCH-LLM.md WOULD SUFFICE. YOU WASTE MY FUCKING TOKENS LIKE YOU DON'T KNOW THEY COST MONEY. I DON'T EVER WANT TO SEE THAT AGAIN UNLESS ABSOLUTELY NECESSARY.
- Tests are required for every implemented behavior.
- Prefer Test Driven Development when adding or changing functionality.
- Favor simple, inspectable technology choices over unnecessary complexity.
- Re-read scaffold/AGENT-COMMS.md, scaffold/AGENT-WORKFLOW.md, and the relevant scaffold/ files every so often as context grows.

Definition of done (keep this short)
A change is done only when:
1. It does what we agreed it should do.
2. Automated tests cover that behavior (new tests for new behavior; changed tests when behavior changes). Say which test file(s) or command proves it so anyone can rerun the same check.
3. If facts changed for the product or system, scaffold/ARCH-LLM.md is updated (minimal deltas; no padding). Update scaffold/ARCH-HUMAN.md when the maintainer needs a readable summary. If you learned something worth keeping for the next session, scaffold/PROJECT-KNOWLEDGE.md is updated too.
How to pick test type (project default):
1. Unit: small pieces of logic with no real database or network.
2. Integration: behavior that really depends on HTTP + DB, or webhooks / OAuth / Stripe — exercise real boundaries with test keys, stubs, or recorded fixtures as appropriate.
3. Browser (e2e): only for stable end-to-end flows; avoid writing a dozen e2e tests while screens are still moving daily.

Documentation Rules
- scaffold/ARCH-HUMAN.md: human-readable product structure, system maps, tech stack, and design decisions. Write for the maintainer, not for agents.
- scaffold/ARCH-LLM.md: confirmed product structure, system maps, tech stack, and design decisions for agents. Dense and factual.
- scaffold/PROJECT-KNOWLEDGE.md: hard-won understanding, pitfalls, and context that should survive new agent sessions. Agents (you) have full control over this file.
- scaffold/skills/: Agent skills for valuable tasks that have been done once. Create skills here when asked; do not invent skills unprompted.
- One home per fact: if you are going to record something in one file, do not record it in another. Pick the single best place and write it there only. Confirmed product and system facts → scaffold/ARCH-LLM.md. Lessons, pitfalls, and non-obvious context → scaffold/PROJECT-KNOWLEDGE.md. Human-readable summaries of architecture → scaffold/ARCH-HUMAN.md only when the maintainer needs them — not a second copy of the same bullets.
- scaffold/ARCH-HUMAN.md and scaffold/ARCH-LLM.md are not textbooks. Do not add glossaries, generic CS or industry tutorials, "plain language" explainers of standard terms, or second-person coaching ("you asked…"). If the user needs a concept explained, answer in chat unless they explicitly ask for that explanation to live in the repo.
- Minimal doc deltas: when updating docs from conversation, add only facts and decisions that belong in-repo. Do not dump full Q&A transcripts or speculative padding into scaffold architecture files or scaffold/PROJECT-KNOWLEDGE.md.
- Keep scaffold agent files focused on promoting desired agent behavior and staying away from undesired agent behaviour. Anything product architecture does not belong here. Do not edit scaffold/AGENT-COMMS.md or scaffold/AGENT-WORKFLOW.md in scaffolded projects — only the quick-project-start repo or `new-proj --update` may change them.
- Keep documentation factual and current. It should be updated whenever valuable.
- When you change scaffold agent files in the quick-project-start repo, bump the semver on the last line of this file (`scaffold version: X.Y.Z`).

scaffold version: 2.1.0
