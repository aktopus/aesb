export const meta = {
  name: 'swarm',
  description: 'Bounded agent swarm: independent Sonnet lines of attack, blind critics, schema-enforced worker contract',
  whenToUse: 'A hard open question the user wants attacked from several independent angles with a defensible confidence label. Phases 0, 2 and 4 stay with the orchestrator; this script runs Phases 1 and 3.',
  phases: [
    { title: 'Explore', detail: 'one read-only Sonnet worker per line of attack, no cross-talk', model: 'sonnet' },
    { title: 'Critique', detail: 'one blind critic per surviving candidate, plus one on the consolidation', model: 'sonnet' },
  ],
}

// args shape (pass as a JSON object, not a string):
// {
//   challenge:  "the challenge, restated as in Phase 0",
//   criterion:  "the verification criterion from Phase 0",
//   lines:      [{ key: "A-baseline", brief: "..." }, { key: "D-adversary", brief: "..." },
//                { key: "U1-unbriefed", unbriefed: true }, ...],  // unbriefed: challenge + contract only
//   candidates: [{ claim: "...", kill_claim: "...", evidence: ["..."] }, ...]  // OPTIONAL: skip Explore, run Critique only
//   consolidation: "the orchestrator's consolidated state"      // OPTIONAL: enables the consolidation critic
// }
// The orchestrator runs Explore first, consolidates in its own context (Phase 2), then
// re-invokes with `candidates` (and `consolidation`) for the critic round. Two invocations,
// two phases, and the journal of each is the ledger.

const CONTRACT = `You are one explorer among several working the same problem from different angles.
Pursue ONLY your assigned line. Rules: do not guess and present it as fact; say 'I could not
determine' when true. Do not exceed your scope or tools; you are read-only. Do not optimize for
agreeing with what you imagine other explorers will say. Stop when your line is exhausted.
Every evidence item must carry its kind: file (path:line), computation, source (URL), live
system, or reasoning_only. When the challenge asks for options or ideas, return EVERY candidate
you found in candidates, largest first; do not pick one. Never call something new without
prior_art: search the on-disk record (worklogs, decisions, tickets, deferrals) and report the
path, date and outcome, or where you searched and with which terms. coverage.territory_total is the full
size of your territory in the unit the challenge is about (dollars per year, rows, files);
measured plus not_measured must sum to it. A part you saw only as a number, and did not examine
for an answer, is not_measured. A negative finding (dry, clean, nothing here) holds only over
coverage.measured; give measured as a share of the total. Keep the report compact; write anything long to a file under the
scratchpad and cite the path.`

const REPORT = {
  type: 'object',
  properties: {
    claim: { type: 'string', description: 'best answer along this line, one or two sentences' },
    candidates: {
      type: 'array',
      description: 'every candidate found, largest first; empty when the challenge does not ask for options',
      items: {
        type: 'object',
        properties: { text: { type: 'string' }, size: { type: 'string' }, prior_art: { type: 'string' } },
        required: ['text', 'size', 'prior_art'],
      },
    },
    prior_art: { type: 'string', description: 'path, date and outcome of any earlier consideration of the claim; or where and how you searched' },
    coverage: {
      type: 'object',
      properties: {
        territory_total: { type: 'string', description: 'full size of the territory in the challenge unit, and the source that totals it' },
        measured: { type: 'array', items: { type: 'string' }, description: 'parts of the territory examined, each with its size' },
        not_measured: { type: 'array', items: { type: 'string' }, description: 'parts not examined, largest first, each with size or "size unknown"' },
      },
      required: ['territory_total', 'measured', 'not_measured'],
    },
    evidence: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          kind: { type: 'string', enum: ['file', 'computation', 'source', 'live_system', 'reasoning_only'] },
          text: { type: 'string' },
        },
        required: ['kind', 'text'],
      },
    },
    weakest_point: { type: 'string' },
    confidence: {
      type: 'object',
      properties: {
        level: { type: 'string', enum: ['low', 'medium', 'high'] },
        reason: { type: 'string' },
      },
      required: ['level', 'reason'],
    },
    dead_ends: { type: 'array', items: { type: 'string' } },
    open_question: { type: 'string' },
  },
  required: ['claim', 'candidates', 'evidence', 'prior_art', 'coverage', 'weakest_point', 'confidence', 'dead_ends', 'open_question'],
}

const VERDICT = {
  type: 'object',
  properties: {
    kill_claim_result: { type: 'string', description: 'what you found when you tested the kill claim at its source: holds / fails / could not determine, with the evidence and its kind' },
    broken: { type: 'boolean', description: 'true if the claim does not survive your attack' },
    attack: { type: 'string', description: 'the strongest objection, with evidence and its kind' },
    rival: { type: 'string', description: 'the rival explanation you would back instead, and why' },
    confidence: { type: 'string', enum: ['low', 'medium', 'high'] },
  },
  required: ['kill_claim_result', 'broken', 'attack', 'rival', 'confidence'],
}

const grounded = r => r.evidence.filter(e => e.kind !== 'reasoning_only').length / Math.max(1, r.evidence.length)

const out = { explore: null, critique: null }

if (!args.candidates) {
  phase('Explore')
  const reports = await parallel(args.lines.map(l => () =>
    agent(
      l.unbriefed
        ? `CHALLENGE: ${args.challenge}\n\nYOUR ASSIGNED LINE: none assigned: find the best answers wherever they are.\n\n${CONTRACT}`
        : `CHALLENGE: ${args.challenge}\n\nVERIFICATION CRITERION (for your awareness; the orchestrator applies it): ${args.criterion}\n\nYOUR ASSIGNED LINE (${l.key}): ${l.brief}\n\n${CONTRACT}`,
      { label: `worker-${l.key}`, phase: 'Explore', schema: REPORT, model: 'sonnet', agentType: 'Explore' },
    ).then(r => r && { line: l.key, ...r, grounded_fraction: grounded(r) }),
  ))
  out.explore = reports.filter(Boolean)
  const dropped = args.lines.length - out.explore.length
  if (dropped) log(`${dropped} worker(s) returned nothing; budget spent on them is not recoverable`)
  return out
}

phase('Critique')
// Blind by construction: each critic sees one candidate and nothing else.
const verdicts = await parallel(args.candidates.map((c, i) => () =>
  agent(
    `CHALLENGE: ${args.challenge}\n\nA candidate answer and its evidence follow. Your only job is to break it. You do not know how many workers proposed it or how it was ranked; do not speculate about that. Test the KILL CLAIM at its source first and report that result on its own; confirming citations without reaching the kill claim is not a review. Then break whatever else you can, and name the rival explanation you would back instead.\n\nCLAIM: ${c.claim}\nKILL CLAIM (the one claim that sinks it if false): ${c.kill_claim || 'not supplied: name it yourself, then test it'}\nEVIDENCE:\n${c.evidence.map((e, j) => `${j + 1}. ${e}`).join('\n')}\n\n${CONTRACT}`,
    { label: `critic-${i + 1}`, phase: 'Critique', schema: VERDICT, model: 'sonnet', agentType: 'Explore' },
  ).then(v => v && { candidate: i, ...v }),
))
out.critique = verdicts.filter(Boolean)

if (args.consolidation) {
  out.consolidation_critique = await agent(
    `CHALLENGE: ${args.challenge}\n\nThe orchestrator's consolidated ranking follows. Attack the consolidation itself, not the candidates: which evidence was overweighted, which line's claim was discounted without cause, and does the ranking follow the orchestrator's stated prior too closely or abandon it without a stated reason?\n\n${args.consolidation}\n\n${CONTRACT}`,
    { label: 'critic-consolidation', phase: 'Critique', schema: VERDICT, model: 'sonnet', agentType: 'Explore' },
  )
}
return out
