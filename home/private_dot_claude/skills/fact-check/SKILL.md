---
name: fact-check
description: Verify a document's claims for factual accuracy, ambiguity and unsupported statements, with drop-in corrections. Use only when the user's request contains "fact check" or "fact-check" (for example "fact check this", "can you fact-check my report", "fact check against the codebase"). Generic requests such as "check this doc", "review this" or "proofread" are not fact checks.
---

# Fact check

Check every claim in a document and report what is false, unverifiable or misleading, each with a correction ready to paste. The goal is a document the user can trust before it goes out.

If a `doc-reviewer` subagent is available and you are not it, hand the check to it. Pass the document as a file path it can read, or as text (convert `.docx`, PDF or Google Docs to text first), any codebase or reference material the user named, and, for a re-check, the earlier report. Relay its report. Otherwise, do the check yourself as below.

## 1. Pick the document

- Use the files the user named. Several files get one report each.
- Otherwise use text pasted with the request, or the one document the conversation is working on, and say which you picked.
- If several documents are in play and none is clearly meant, list them and ask. If there is none, ask for a file or pasted text.

Read the full text, with a document-reading skill or tool for formats like `.docx`, PDF or Google Docs. Check against the codebase the user names; if they ask for a codebase check without naming one, use the current repository and say so.

## 2. List the claims

Make an internal list of every checkable statement. It is working memory; don't output it.

Always check:

- numbers: percentages, counts, dates, durations, versions
- named things with attributed properties ("Company X has 500 employees", "the default timeout is 30s")
- standards and specifications ("REST requires stateless communication")
- causal or comparative claims ("X is faster than Y by 30%")
- technical assertions: commands, flags, paths, config keys, API behaviour, complexity

Check a subjective statement only when it is presented as objective fact but is contested, contradicts itself or its context, or is too vague to mean anything ("best-in-class", "highly scalable" with no qualifier).

These are not issues: clearly framed opinions ("we believe"), standard hedges ("approximately", "tends to"), internal process descriptions nobody outside can verify, and correct simplifications such as illustrative examples or rounded figures.

## 3. Verify each claim

| Claim type | Check against |
|---|---|
| External facts: statistics, dates, product specs, organisations, standards | Web search, primary sources first: official docs, specs, source code, the organisation's own pages. Note each source and its date. If reliable sources conflict, report the conflict |
| Code, API or system behaviour | The codebase when the user asked for it or named one, then official docs. Cite `file:line` |
| Internal consistency | The document itself: totals that don't add up, numbers or names that contradict each other |
| Subjective statements | The context, flagged only under the rule in step 2 |

If the relevant code can't be found, mark the claim unverifiable and say the codebase search was inconclusive.

## 4. Classify each issue

| Label | Meaning |
|---|---|
| ❌ False | Contradicted by a reliable source or by the codebase |
| ⚠️ Unverifiable | No source found that confirms or refutes it |
| 🔶 Ambiguous | Vague, contested or misleading as written: not clearly wrong, not clearly right |

## 5. Write the corrections

For each issue, write a drop-in replacement for the original text: a complete sentence or phrase, bounded so it can be found and replaced exactly. If the user has to supply a value (the real number), say so in the correction. If the claim should be removed rather than replaced, say that. A correction never introduces a new unverified claim.

## 6. Report

Give the report in the conversation. Write it to a file only when the user asks for one, and then name it `<original-name>-fact-check.md` next to the original.

```markdown
# Fact check: <document name>

**Claims checked:** <N>. **Issues:** <N> (<N> false, <N> unverifiable, <N> ambiguous)

<A short summary: overall confidence, and the most important issues.>

## Issues

### 1. <short label>

> <exact quote from the document>

**Verdict:** ❌ False / ⚠️ Unverifiable / 🔶 Ambiguous

**Finding:** <why, with the source URL and date, or `file:line`>

**Correction:**

> <drop-in replacement text>
```

If nothing is wrong, say so plainly and name the sections checked.

### Re-checks

When the conversation already has a fact check of the same document, check the current version in full again, then report in two parts:

1. **Earlier issues:** each one as fixed, still open, or changed (with its new state).
2. **New issues:** anything the earlier check didn't report.

## Tone

- Be direct; don't soften findings.
- When unsure whether a statement is a claim worth checking, check it.
