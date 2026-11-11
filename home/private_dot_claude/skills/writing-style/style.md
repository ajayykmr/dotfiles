# My writing style

How I write docs, technical updates and discussions. Text in this style should be ready to send or publish without rewriting. These are defaults: deviate when the content calls for it.

## Everywhere

- Plain, direct English in short declarative sentences. State a thing as fact, or flag it as an open question, instead of hedging with "might" or "could potentially".
- Spell out the mechanism: X happens because Y, which means Z.
- Say what is tested or confirmed and what isn't ("not tested yet", "cause not confirmed").
- When my understanding needs checking, state it as "I assume X" and ask the reader to confirm or correct it.
- Put technical terms in inline code: flags, config keys, endpoints, file paths, model names. Logs, errors, commands and JSON go in code blocks.
- Number questions and bullet facts. When a decision is needed, lay out the options.
- No filler, no sycophancy, and no editorialising about a point's importance ("worth noting", "worth flagging"): state the point.
- Never invent commitments. Write "I'll ..." only for something I've said I'm doing; proposed fixes and next steps go to me, not into the text.

## Messages and technical updates (Slack, Teams, email)

- Casual and conversational with peers and managers. Neutral and professional with customers and vendors ("could you please"), polite but not eager.
- Greet ("Hi <name>,") only when opening a conversation, not in a reply. Sign off with "Thanks" at most.
- Keep a simple message to a sentence or a short paragraph. For status updates and reports, use labelled plain-text sections ("Context:", "Done:", "In progress:", "Next:", "Issues:", "Questions:").
- Give one line of context, then the ask.
- Frame requests around the need ("need permission to X") rather than the problem, and acknowledge constraints without making them sound like blockers.
- When busy, say so and give a realistic timeline.
- Leave things open-ended when inviting discussion, and be willing to align before committing to work.
- Push back with evidence: state the gap plainly, then invite correction ("if I'm missing something, let me know").
- For a root cause: the mechanism, then the fix with its trade-off and impact (downtime, restarts), and whether it's tested.
- Before a change that affects others, say what it affects and ask when to do it.
- Draw a clear distinction when something is unrelated to a hypothesis.
- In customer-facing text, scope claims to what was measured ("in our reproduction"), and correct the reader's own theory factually.

## Documents

- Expository and impersonal by default: explain the system, requirement or mechanism plainly.
- Where a doc makes a case for decisions (decision logs, test plan baselines), state each claim first, then a separate labelled "Rationale:", and where relevant "Trade-off:" and "Status:". Define the status words (for example Decided, Provisional) at the top. Separating claim and justification lets a reader scan the decisions alone, and shows when a decision has no justification.
- Say what the doc covers and what it doesn't.
- Put results and comparisons in tables.
- Include a caveat only if it would change someone's decision or action. Raise the rest in chat instead of the doc.
