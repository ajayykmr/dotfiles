---
name: fact-check
description: >
  Verify documents for factual accuracy, ambiguity, and unsupported claims.
  ONLY trigger this skill when the user explicitly uses the phrase "fact check"
  or "fact-check" (e.g. "fact check this", "can you fact-check my report",
  "run a fact check", "fact check against the codebase"). Do NOT trigger for
  generic review requests like "check this doc", "review this", or "proofread".
  The trigger phrase must contain the words "fact check" or "fact-check".
---

# Document Reviewer Skill

Verify all claims in a document and produce a structured markdown report with
flagged issues and copy-paste-ready corrections. The goal is to give the user
full confidence that a document is objectively correct before it is finalised.

---

## When to Use Which Verification Method

| Claim Type | Method |
|---|---|
| External facts (statistics, dates, product specs, org names, standards) | Web search |
| Code behaviour, API contracts, system behaviour | Documentation + Codebase (if available) |
| Subjective or opinion statements | Reason from context -- flag if unclear or unsupported |
| Internal consistency (e.g. numbers that contradict each other) | Reason within the doc itself |

---

## Step-by-Step Workflow

### 1. Identify the Target Document

Before doing anything else, determine which file to fact-check. Follow this order:

**a. User named specific files** (e.g. "fact check proposal.docx") -- use those, one report each.

**b. Active file in context** -- if the current conversation already references a file (e.g. Claude was just reading, editing, or discussing it), use that file automatically. State which file you picked before proceeding:
> "Fact-checking `proposal.docx` -- the file we were just working on."

**c. Multiple files in context, none active or named** -- list them and ask:
> "I can see multiple files. Which ones should I fact-check? I'll produce a separate report for each."
> - `proposal.docx`
> - `technical-spec.pdf`

Wait for the user to reply before proceeding.

**d. Single file in context** -- proceed automatically.

**e. Pasted content in the prompt** -- if the user wrote `"fact check: <content>"` or pasted text directly alongside the command, treat that text as the document. No file needed. Use `pasted-content` as the filename in the report header (e.g. `pasted-content-review.md`), saved to the current working directory.

**f. No file and no pasted content** -- ask the user to either attach a file or paste the content directly.

Once the target is confirmed, ingest it:

- `.docx` / `.pdf` -- use the appropriate file-reading skill or tool to extract full text
- `.md` / `.txt` -- read directly
- Pasted text -- use as-is from the prompt
- Note the filename (or `pasted-content`) -- it appears in the report header
- If the user mentions a codebase, confirm the repo path before proceeding

### 2. Extract All Claims

Read the document and produce an internal list of every checkable statement.
Do not output this list -- it is working memory only.

**Hard facts to always extract and verify:**
- Numerical claims (percentages, counts, dates, durations, version numbers)
- Named entities with attributed properties ("Company X has 500 employees")
- Standards or specifications ("REST requires stateless communication")
- Causal or comparative claims ("X is faster than Y by 30%")
- Technical assertions ("This function runs in O(n log n)")

**Subjective / opinion statements -- flag only if:**
- The claim is presented as objective fact but is actually contested or opinion
- The claim contradicts itself or the surrounding context
- The claim is vague to the point of being meaningless ("best-in-class", "highly scalable" with no qualifier)
- Leave well-reasoned opinions that are clearly framed as such

**Do not flag:**
- Clearly framed opinions ("We believe...", "Our view is...")
- Standard hedged language ("approximately", "roughly", "tends to")
- Internal process descriptions that are not externally verifiable

### 3. Verify Each Claim

For each extracted claim, determine the right verification method (see table above) and verify:

**Web search:**
- Search for the specific claim
- Note the source URL and date if found
- If conflicting sources exist, note the conflict

**Codebase:**
- Only if the user has explicitly asked or provided a repo path
- Look for relevant files, functions, or configs that confirm or contradict the claim
- Note the file and line reference

**Internal reasoning:**
- Cross-check numbers within the document (e.g. totals that don't add up)
- Flag circular or self-referential justifications

### 4. Classify Each Issue

Assign one of three labels:

| Label | Meaning |
|---|---|
| `❌ False` | Claim is contradicted by a reliable source or by the codebase |
| `⚠️ Unverifiable` | Claim could not be confirmed or denied -- no source found |
| `🔶 Ambiguous` | Claim is subjective, vague, or contested -- not clearly wrong but not clearly right |

### 5. Write the Correction

For every flagged issue, write a **Suggested Correction** that:
- Is a direct drop-in replacement for the original text (complete sentence or phrase)
- Is clearly bounded so the user or Claude Code can find and replace it precisely
- Includes a note if the correction requires the user to fill in a specific value (e.g. the real number)

Format the correction as a fenced block so it can be copied directly:

```
Suggested correction:

> [exact replacement text here]
```

If the claim should simply be removed rather than replaced, say so explicitly.

### 6. Produce the Markdown Report

Save the report to the same directory as the original document, as `<original-filename>-review.md`.
For example, if the file is at `/projects/docs/proposal.docx`, the report goes to `/projects/docs/proposal-review.md`.
Never save to the current working directory unless the original file itself is in the cwd.

Use this exact structure:

---

```markdown
# Document Review Report

**File:** `<filename>`
**Reviewed:** <date>
**Total claims checked:** <N>
**Issues found:** <N> (<N> false, <N> unverifiable, <N> ambiguous)

---

## Summary

<2-4 sentence plain-English summary of the overall confidence level and
the most important issues found.>

---

## Issues

### 1. [Short label for the claim]

**Original text:**
> <exact quote from the document>

**Verdict:** ❌ False / ⚠️ Unverifiable / 🔶 Ambiguous

**Finding:**
<Explanation of why this is flagged. Include source URL and date for web-verified
findings. Include file:line for codebase findings.>

**Suggested correction:**
> <drop-in replacement text>

---

### 2. ...

---

## No Issues Found

<If a section or the whole doc is clean, say so explicitly here.>
```

---

## Codebase Verification (Claude Code Only)

If the user says to verify against a codebase:

1. Ask for the repo path if not already known
2. Use grep, file reads, or symbol search to locate the relevant code
3. Quote the specific file and line(s) in the finding
4. Do not assume -- if you cannot find the relevant code, mark the claim as `⚠️ Unverifiable` with a note that the codebase search was inconclusive

---

## Tone and Precision

- Be direct. Do not soften findings with excessive hedging.
- Distinguish clearly between "this is wrong" and "this could not be verified" -- they are different problems.
- Corrections must be usable as-is. Do not write corrections that themselves contain vague or unverified claims.
- If you are unsure whether something qualifies as a claim worth checking, err on the side of checking it.
