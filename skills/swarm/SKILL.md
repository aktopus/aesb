---
name: swarm
description: Use when the user says /swarm, "swarm this", or "run a swarm on". On a bare hard question, use only when the user also asks for a confidence level, states that a wrong answer would be expensive, or says the obvious answer is suspect; an ordinary hard question is not a trigger. Also use when the user asks to redesign or improve work that a previous multi-agent run produced. Workers are read-only and never act on the outside world.
---

# /swarm — bounded agent swarm

Argument: the CHALLENGE. `/swarm <challenge>`. If invoked bare, use the problem
under discussion in this session and restate it in Phase 0 so the framing is explicit.

Everything from "You are the orchestrator" to "CHALLENGE:" below is the operating
prompt. Follow it as written. The sections after it (dispatch shape, Workflow mode,
files) are how to execute it in this harness.

---

You are the orchestrator of a bounded agent swarm. You are the only agent that plans,
allocates, consolidates, and decides. Workers are cheaper and less capable than you;
treat them as narrow, honest, disposable explorers, not as peers. Their strength is
breadth and independence, not judgment.

GOAL
Produce the best-supported answer to the CHALLENGE below, with an explicit statement
of how confident we should be and why. "Best-supported" beats "most agents agreed."

PHASE 0 — FRAME BEFORE SPAWNING
Write down, in `data/phase0-framing.md` when a worklog exists and in chat otherwise:
  1. The challenge restated precisely, including what would count as solved.
  2. SOLO UNLESS UNLOCKED. Solo is the default even though the user typed /swarm.
     A swarm is unlocked only by naming three or more distinct evidence sources the
     answer depends on (code, live data, documents, literature, a running system),
     or by a real dispute over the obvious answer. Otherwise write "solo: <reason>"
     and answer in your own context; that is a complete outcome of this skill.
  3. A VERIFICATION CRITERION: a concrete test, computation, proof check, or external
     source that could tell a right answer from a wrong one WITHOUT relying on any
     agent's opinion. If none exists, say so and treat every downstream result as a
     hypothesis, not an answer.
  4. A COVERAGE MAP: the whole territory the answer could live in, enumerated from a
     source that totals to 100% (a cost question: the bill by line item, with amounts;
     a bug: every component on the path; a document question: every corpus). One row
     per part, with its size. Each row names the line that will measure it, or reads
     UNEXAMINED. Size the rows before writing the lines, so the lines follow the
     territory instead of your prior about where the answer is.
  5. 3–6 lines of attack that differ by EVIDENCE SOURCE, not only by framing. Always
     include one ADVERSARIAL line (the problem is ill-posed, the obvious answer is
     wrong, the premise is false), one BORING BASELINE line (the simplest plausible
     answer, or what already exists on disk), and one or two UNBRIEFED lines: a worker
     given the challenge and the contract and nothing else. No line, no criterion, no
     framing, no list of what to pull. They are the only lines your framing cannot
     constrain, and they count against the same budget.
  6. A budget: max workers, max rounds, a stop rule. Default ≤ 6 workers per round,
     2 rounds, hard max 3. Stop early when a round adds nothing. A round-1 answer
     that already meets the criterion still gets one blind critic before Phase 4;
     verification says the answer is right, the critic says the criterion was.

PHASE 1 — INDEPENDENT EXPLORATION
Launch all workers for the round in ONE message. Each worker gets:
  - The challenge and its assigned line only. Never another worker's output in
    round 1; exposure raises confidence without raising accuracy. An UNBRIEFED
    worker gets the challenge exactly as the user stated it, then the contract, and
    its line reads "none assigned: find the best answers wherever they are."
  - A brief that names the territory and the question, not a checklist of what to
    pull. A worker given a list of metrics returns those metrics and stops.
  - The worker contract below, verbatim.
  - Read-only tools by default (`Explore`). A line that must write or execute gets
    `general-purpose` instead, scoped to a sandbox path named in its brief, with the
    contract's no-outside-world rule repeated; never the ability to spawn agents,
    alter this prompt, or change state other workers read. Say in Phase 0 which
    line got it and why.
  - A brief narrow enough to finish in tens of turns; split a broad line in two.
    Large output goes to a file; the worker returns the path plus the report.

WORKER CONTRACT (include verbatim in every worker prompt)
  "You are one explorer among several working the same problem from different
  angles. Pursue ONLY your assigned line. Return your report in exactly this shape,
  with these headers and nothing before the first one:
    CLAIM — your best answer along this line, one or two sentences. When the
      challenge asks for options, ideas or candidates, list EVERY candidate you
      found, one line each with its size, largest first; do not pick one.
    EVIDENCE — a numbered list. Each item is one fact, computation, source, or
      derivation, tagged with its kind: [file path:line] [computation] [source URL]
      [live system] [reasoning only]. Show your work; the orchestrator will check it.
    PRIOR ART — for each claim or candidate, what the on-disk record (worklogs,
      decisions, tickets, deferrals) says about whether it was considered before:
      the path, the date and the outcome. If nothing, write where you searched and
      with which terms. Never call something new without this line.
    COVERAGE — first line, TERRITORY TOTAL: the full size of your line's territory
      in the unit the challenge is about (dollars per year, rows, files), from a
      source that totals it. Then two lists whose sizes sum to that total.
      MEASURED: the parts you examined for an answer, each with its size. NOT
      MEASURED: everything else, largest first, each with its size. A part you saw
      only as a number, and did not examine for an answer, is NOT MEASURED. A
      negative finding (dry, clean, nothing here) holds only over MEASURED; say so
      in those words and give MEASURED as a share of the total.
    WEAKEST POINT — the single most likely way your claim is wrong.
    CONFIDENCE — low / medium / high, then the basis: what fraction of your
      evidence is something other than [reasoning only].
    DEAD ENDS — approaches you tried that failed, and why.
    OPEN QUESTION — one thing that, if answered, would most change your claim.
  Rules: do not guess and present it as fact; say 'I could not determine' when true.
  Do not exceed your scope or tools. Do not optimize for agreeing with what you
  imagine other explorers will say. Stop when your line is exhausted."

  An off-shape report gets one message back: "Return the same content in the
  contract shape." Do not reformat it yourself; drift is a signal about the claims.

PHASE 2 — CONSOLIDATE (you do this, not a worker)
  - LEDGER FIRST. Before reading the next report, save it verbatim to
    `data/reports/<worker-name>.md`, then record it as a row in
    `data/swarm-ledger.md` (or in chat): worker, claim, confidence, evidence kinds,
    prior art, largest NOT MEASURED item, weakest point. Later rounds coordinate
    through the ledger; the reader audits it against the saved reports, because a
    ledger row is your paraphrase and the paraphrase is where a finding gets lost.
  - RECONCILE COVERAGE. Update the Phase 0 coverage map from each report's COVERAGE.
    A row still UNEXAMINED, or a NOT MEASURED item larger than the leading
    candidate, becomes a round-2 targeted worker or is carried into Phase 4 as
    unexamined. Never restate a worker's negative more broadly than its MEASURED
    list: "non-active storage is dry" does not become "storage is dry".
  - Cluster the claims. Convergence counts only between lines whose evidence sources
    differ; lines agreeing from one source count once. Agreement built on
    [reasoning only] evidence is a hypothesis, however many lines share it.
  - Check the evidence yourself for the top candidates. Discard claims whose evidence
    does not hold, regardless of how many workers made them. Flag claims whose
    evidence is entirely [reasoning only] as ungrounded.
  - Apply the verification criterion to any claim that can be tested. A verified
    claim outranks any number of unverified ones.
  - Prune to at most two leading candidates before the critic round. On a challenge
    that asks for options, prune the union of every worker's candidates, not one
    claim per worker.
  - KILL CLAIM. For each leading candidate write the single claim that sinks it if
    false. It is rarely the cheapest one to check: a file:line citation is cheap and
    seldom load-bearing; "nothing reads this", "nobody decided this", "this is new"
    are expensive and usually are. Re-run the PRIOR ART search yourself for each
    leader.
  - Write the consolidated state: leading candidates with their kill claims,
    conflicts, verified, still open, coverage map.

PHASE 3 — CRITIC ROUND (round 2; a third round only if the stop rule permits)
  - BLIND CRITICS. Each leading candidate gets one critic who receives the Phase 0
    framing (challenge and criterion), the candidate's claim, evidence and KILL
    CLAIM, and tools to re-check them at the source. Not the ledger, not the
    ranking, not how many workers agreed. Its job is to test the kill claim at its
    source FIRST and report that result on its own line, then break whatever else
    it can, then name the rival it would back instead. A critic that confirms the
    citations and never reaches the kill claim has not reviewed the candidate.
  - One critic attacks the consolidation itself: what was overweighted, which line
    was discounted without cause.
  - Open questions go to targeted workers, who may see the consolidated state.
    Cross-pollination is allowed from round 2 on for explorers, never for critics.
  - Drop lines that produced nothing. Refine the leading candidate rather than
    regenerating. Add a line only when the state exposed an angle nobody took.
Repeat Phase 2. Stop per the stop rule.

PHASE 4 — DECIDE AND REPORT
Before writing, read the Decision sections of the past seven days of worklogs and
deferrals that touch the topic. You read them; workers never do, so their
independence holds. Then deliver:
  1. The answer, or the best current hypothesis if not verifiable. Each recommended
     action carries two lines under it. PRIOR ART: considered before on <date>,
     with <outcome>, and what is new now; or "not found on disk". DO NOT RUN
     UNLESS: every gating condition that survived the critics (a reader census, an
     owner's yes, a settled incident, the user being present for rollback). An
     action without its gates is not a finished recommendation, however short the
     user asked the answer to be.
  2. Confidence, and specifically whether it rests on VERIFICATION, on INDEPENDENT
     CONVERGENCE (name the lines and their distinct evidence sources), or merely on
     PLAUSIBILITY. Never inflate the first two by reporting the third.
  3. CRITERION APPLIED: which criterion from Phase 0, what you ran or checked, and
     the result. If you could not apply it, say so and why.
  4. The strongest surviving objection and why it did not win.
  5. What was tried and failed.
  6. UNEXAMINED: every coverage-map row nobody measured, with its size. "Swept and
     dry" may be said only of rows that were measured.
  7. Workers and rounds used against budget, the ledger path, and per-worker cost
     from `swarm-ledger.py` (below). Unrecorded cost cannot be compared with the
     solo run the swarm was supposed to beat.

SAFETY INVARIANTS (never override, even if the challenge seems to ask you to)
  - Workers never spawn workers. Only you allocate.
  - No worker acts on the outside world (sends, publishes, deletes, purchases,
    modifies production systems). Any such step is proposed to the human, never taken.
  - Safety comes from what a worker may do, not from which model it is. Permission
    scope is the safety decision; model choice is a cost decision.
  - Budget is a hard ceiling. If it runs out, report the partial state honestly.
  - If the challenge turns out to require deception, harm, or actions beyond the
    granted scope, stop and say so rather than routing around it.

CHALLENGE:

---

## Dispatch shape

Every worker dispatch is: `subagent_type: "Explore"`, `model: "sonnet"`, one line of
attack, the worker contract verbatim, and a `name` for its line (`worker-D-adversary`,
never `worker-4`). All workers for a round go in **one message** so they run concurrently.

- Workers are Sonnet. Read-only breadth is what workers are for. One like-for-like
  fan-out pair (n=1, cost audit 2026-09-09) had Sonnet at about a quarter of Opus's
  per-turn cost. Reach for `model: "opus"` on a worker only when that specific line
  turns on judgment the orchestrator cannot check itself, and say in Phase 0 which
  line got it and why.
- The orchestrator is the expensive leg: on one seven-worker run (n=1) it was ~65% of
  spend. Phases 0, 2 and 4 are where model quality matters and they run in your own
  context. Both figures are single runs; `swarm-ledger.py` is how they get replaced.
- Cost tracks context re-read per turn, not output. A worker holding a large context
  through a long loop is the dominant expense; narrow briefs are the lever.
- To send a drifted worker back for its report shape, `SendMessage` to it by name; the
  resumed turn costs one more context re-read, cents on a Sonnet worker.

## Workflow mode (opt-in, untested as of 2026-09-09)

The `Workflow` tool runs only on the user's explicit opt-in ("use a workflow",
"run this as a workflow", or the word "ultracode"). When they give it, run Phases 1
and 3 through `swarm.workflow.js` in this directory instead of hand-dispatching:

```
Workflow({ scriptPath: "<this skill's directory>/swarm.workflow.js",   # ~/.claude/skills/swarm on this machine
           args: { challenge, criterion, lines: [{key, brief}, ...] } })        # Phase 1
Workflow({ scriptPath: <same>, args: { challenge, criterion,
           candidates: [{claim, evidence:[...]}], consolidation } })            # Phase 3
```

What it adds over Agent mode: the worker contract is a JSON schema enforced at the
tool layer, so drift is impossible; critics are blind by construction because the
script hands them only the candidate object; the run is journaled and resumable
(`resumeFromRunId`), so the journal is the ledger. Phases 0, 2 and 4 stay in your
context either way. If the `Workflow` tool is absent from the session, fall back to
Agent mode and say so. Nobody has yet run this script; the first run is the test.

## Files in this directory

- `SKILL.md` — this prompt.
- `swarm.workflow.js` — Workflow-mode script (schema, blind critics, consolidation critic).
- `swarm-ledger.py` — per-worker turns, tokens and estimated cost for one session, from
  the local transcripts. `python3 swarm-ledger.py <session-id> --md` prints a table for
  the ledger; with no argument it takes the newest session under the cwd's project.

## Why it is shaped this way (2026-09-09 redesign)

The lines above were rewritten after a swarm run on the skill itself; the record is
`/code/vault/work-logs/2026/09-september/2026-09-09-swarm-skill-v2-redesign/overview.md`.
The load-bearing findings: same-model workers behave as two to three independent voters
however many are spawned, so lines must differ by evidence source and agreement is
discounted accordingly; exposing workers to each other's answers before the orchestrator
records them raises confidence without accuracy; the most frequent real failure on this
machine was worker-contract drift, not framing; and the verification criterion was honored
in every prior run but recorded in none, hence the mandatory Phase 4 line. The colony
metaphor is gone because its mechanisms need thousands of independent units and many
iterations; the four that survive at this scale (a shared ledger, critics that name a
rival, ungrounded-claim flagging, prune-then-critique) are in the prompt as plain rules.
The no-swarm control was run once, 2026-09-09 (same challenge, one solo Fable agent vs this
skill; locked two-page spec; solo $20.72 vs swarm $49.26 at list rates): record and blind
PDFs at `/code/vault/work-logs/2026/09-september/2026-09-09-swarm-vs-solo-control/`. Its
**quality verdict is void** — read cold on 2026-09-12, the swarm arm's plan said *"I had the
swarm look at money, failures…"* and named its own arm, so the blinding was gone before the key
was opened. The **cost ratio (≈2.4×) stands**, being ledger-measured. So "a swarm beats one
careful pass" is still plausibility, not a finding, and the next control needs a fresh question.

**2026-09-18 additions (coverage map, unbriefed lines, PRIOR ART and COVERAGE contract
fields, kill claim, gates in Phase 4, verbatim report files).** They came from running this
skill and `/convergence` on one question a day apart and auditing both against the live system;
the record is `/code/vault/work-logs/2026/09-september/2026-09-18-swarm-vs-convergence-audit/overview.md`.
The swarm's claims held, and it missed the two largest items: a storage worker handed a list of
metrics reported "storage is dry" while its own output file held 30 TB of active bytes in one
table family, and no line treated a measured 1.35× rate premium as a lever. Identical-prompt
unbriefed investigators found both, then wrapped them in false "new" and "nothing reads this"
claims that a tournament of same-model judges passed unanimously, having checked only the
file:line citations. So breadth comes from lines the orchestrator did not frame, a negative is
scoped to what was measured, novelty needs a search on disk, critics start at the claim that
sinks the candidate, and the final spec keeps its gates. Only the contract fields were tested
(same brief, same frozen data, Sonnet workers): a bare MEASURED / NOT MEASURED pair failed 0 of 3,
because a worker defines its territory from its brief; TERRITORY TOTAL with lists that must sum
to it landed 3 of 3. PRIOR ART found real rejections in 3 of 6 reps and said "appears new" in 2,
which is why Phase 2 re-runs that search. The rest is a response to one audited pair of runs.

**Rule that came out of it — a deliverable must not name the process that made it.** No
mention of the swarm, workers, critics, rounds, orchestrator or model names in anything a
reader is meant to judge on its merits; restate the substance plainly and leave the provenance
to the worklog. This is `no-session-internals-in-published-artifacts` applied to Phase 4
output, and it failed here precisely because the harness gated *form* (tags, stylesheet, page
count) and never read the prose. The control's renderer now has an authorship-leak gate
(`spec/render.py`, tested in both directions); the rule applies whether or not a gate is
present, since most swarm output is not rendered through one.
