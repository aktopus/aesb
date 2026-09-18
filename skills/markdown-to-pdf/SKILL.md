---
name: markdown-to-pdf
description: Use when converting a Markdown file to a polished PDF for a client deliverable, brief, or signed handoff on macOS — especially when the output must paginate cleanly (no headings stranded at a page bottom, no table rows or code blocks split across pages). Triggers include "make this a PDF", "render to PDF", "PDF for the client", orphan heading, page break, pandoc, Chrome print-to-pdf.
---

# markdown-to-pdf

## Overview

Convert Markdown → professional PDF via one command that bundles the toolchain
(pandoc → self-contained HTML → Chrome headless `--print-to-pdf`) with a
canonical break-control stylesheet. The stylesheet defends against the whole
class of pagination bugs — most importantly an `<h2>`/`<h3>` heading left alone
at the bottom of a page with its content on the next (the "orphan heading"
bug). Without this, every PDF re-derives the verbose command and silently risks
that bug.

## When to use

- Any Markdown → PDF for an external/client-facing deliverable on macOS.
- When clean pagination matters: headings welded to their content, table rows
  intact, code blocks not fragmented.

**When NOT to use:** non-macOS hosts (the script hard-codes the macOS Chrome
path — override `CHROME_BIN` or adapt), or when the deliverable needs running
headers/footers + page numbers (Chrome `--print-to-pdf` omits these by design;
that's a separate need).

## Quick reference

```bash
# Simplest — layout-safe PDF, no visual theme:
markdown-to-pdf input.md output.pdf

# With a title and a per-document visual stylesheet layered on top:
markdown-to-pdf input.md output.pdf --title "Client Brief" --css brand.css
```

Script: `/Users/akpanoluo/code/scripts/markdown-to-pdf` (run `--help` for all flags).
Canonical layout CSS: `/Users/akpanoluo/code/vault/context/pdf-layout.css`.

| Flag | Purpose |
|------|---------|
| `--title "…"` | Sets the document `<title>` (overrides YAML front matter). |
| `--css <file>` | Layers a per-doc VISUAL sheet (fonts/colors/borders) ON TOP of the layout sheet. Repeatable; last wins. |
| `--keep-html` | Keep the intermediate HTML next to the PDF for debugging. |

## Layout vs. visual identity — the key separation

`pdf-layout.css` is **layout-only**: page geometry + break-control, NO fonts or
colors. Per-document visual identity goes in a SECOND `--css` sheet, which
pandoc emits after the layout sheet so it wins on equal specificity. Never bake
visual styling into the layout sheet — that's what makes it reusable across
every deliverable.

## What the layout CSS guarantees

- Headings never stranded: `break-after: avoid` + the next block `break-before: avoid`.
- Code blocks + blockquotes stay intact (`pre, blockquote, div.sourceCode` — the
  `div.sourceCode` wrapper is pandoc's; targeting `pre` alone can still let the
  wrapper fragment).
- Tables break BETWEEN rows, never within one; header row repeats on each page
  (`thead { display: table-header-group }`) and is never stranded.
- Figures welded to captions; no single dangling text line (`orphans/widows: 3`).

## Verifying section integrity (recommended for client docs)

macOS system Python ships PyMuPDF (`fitz`). Deterministic orphan check: a
heading-sized span must never be the LAST text on a page.

```python
import fitz
doc = fitz.open("output.pdf")
# compare each page's last span size against the body (modal) size;
# a heading-sized span as the last element = a stranded heading.
```

A copy of the full verifier lives with the worklog that created this skill:
`…/work-logs/2026/05-may/2026-05-28-pdf-orphan-headings-fix/verification/pdf-verify.py`.

## Common mistakes

- **Re-deriving the pipeline from scratch.** A capable agent will reinvent
  pandoc+Chrome+CSS (≈3 min, ~75k tokens) and then throw the CSS away. Use this
  script — the solution is captured and tested.
- **`pandoc --section-divs` + `section { break-inside: avoid }`.** Tried and
  REJECTED: too aggressive — Chrome isolates the title block on its own page,
  wasting page 1. The lighter break-after/before rules fix orphans without it.
- **Styling the layout sheet.** Keep `pdf-layout.css` layout-only; theme via `--css`.
- **A single element taller than a page** (e.g. a code block > 1 page) WILL
  break — no CSS can prevent that. Expected, not a bug.
