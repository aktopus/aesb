---
name: convergence
description: Use when the user says /convergence, types 'convergence', 'converge these', 'pick between these answers', or has N independent candidate answers (N=2 or N=3) to a hard question and wants tournament-style synthesis ending in a simplicity-first final answer. Orchestrates parallel subagents via the Agent tool. Refuse N>=4.
---

# /convergence — Tournament synthesis of parallel answers

User has N independent candidate answers to a hard question (typically gathered from separate Claude windows or prior subagents). Drive them through parallel comparison → optional narrowing → one terminal simplicity picker. Present only the final answer.

## Inputs

Required:
- **The original question** (one clear statement of what's being decided)
- **N labelled answers** (`Answer 1`, `Answer 2`, ...)

If the user invokes `/convergence` without pasting answers, ask them to paste each one clearly labelled.

If `N >= 4`, refuse: *"Four is absurd — drop the weakest before invoking /convergence."* Do not proceed.

## Stage layout

**N=2:** Stage A (2 comparison subagents in parallel) → Stage C (1 simplicity picker).

**N=3:** Stage A (3 comparison subagents in parallel) → Stage B (2 narrowing subagents in parallel) → Stage C (1 simplicity picker).

All within-stage subagents run **in parallel** (single message, multiple Agent tool calls). Stages are sequential.

## Subagent prompts

Use these prompts verbatim. The constraints in each are load-bearing — relaxing them is how the pattern degrades into "pick the prettiest answer."

### Comparison subagent (Stage A)

Inputs: original question + all N answers (labelled).

Prompt:
> Pick the best answer to the question below. For each answer, first name what is **load-bearing** — the specific insight, mechanism, or framing that would be lost if that answer were discarded. Then pick. One paragraph total. No insight blocks. No headers.
>
> **Question:** {{question}}
>
> **Answer 1:** {{answer_1}}
>
> **Answer 2:** {{answer_2}}
>
> [...]

### Narrowing subagent (Stage B, N=3 only)

Inputs: original question + all 3 Stage-A verdicts (labelled `Verdict 1`, `Verdict 2`, `Verdict 3`).

Prompt:
> Pick the best verdict below. Two sentences. No insight blocks.
>
> **Question:** {{question}}
>
> **Verdict 1:** {{verdict_1}}
>
> [...]

### Simplicity picker (Stage C, terminal)

Inputs: original question + prior-stage outputs (Stage A for N=2, Stage B for N=3).

Prompt:
> Produce the **minimum spec to act on** the question. The smallest set of steps, commands, or code changes that does the thing. No insight blocks. No failure-mode lists. No "why" paragraphs. If the answer is two lines, the response is two lines.
>
> **Question:** {{question}}
>
> **Inputs:** {{prior_stage_outputs}}

## Output to user

Present **only** the simplicity picker's output. The tournament trail (Stage A, Stage B) stays hidden by default.

If the user explicitly asks ("show the trail", "show the tournament", "what did each stage say"), surface the full chain under a `## Tournament trail` header beneath the final answer.

## What this skill is for

This pattern catches the failure mode where one window's answer feels right but is structurally wrong, *and* the failure mode where two windows produce equivalent answers but one is shorter. Comparison subagents catch the first; the terminal simplicity picker catches the second.

When convergence is genuine (multiple comparison subagents land on the same verdict), the simplicity picker still earns its keep by stripping the prose that accumulated through the stages.
