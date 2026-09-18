---
name: eli5
description: Explain a topic like I'm a 5 year old. Use when the user types /eli5 <topic> or asks for a dead-simple picture explainer of how something works. Produces an HTML artifact with big pictures, few words, hover-to-reveal real terminology, and a glossary at the bottom.
---

# eli5

Explain like I'm someone who knows nothing about this topic, using an HTML artifact with big pictures and few words.

Topic: $ARGUMENTS

Forked from the `eli5@claude-community` plugin (2026-09-18) to make two things standard on every eli5 page: hover terms and a glossary. The plugin is disabled so `/eli5` lands here.

## The two standing rules

### 1. Every plain-word stand-in hides its real term on hover

The page talks in plain words ("our golf robot", "the front-door lock"). Each plain phrase that stands in for a real thing is marked up so hovering (desktop), tapping (phone), or tabbing to it (keyboard) shows the real thing.

- Mark every stand-in, not only the hard ones. If the plain phrase replaces a named system, a number, a date, a person's role, or a mechanism, it gets marked.
- The real text is specific: names, values, ids, dates. "the silo38_golf Airflow DAG, scheduled 16:00 UTC", not "a scheduled job".
- Mark the phrase, not the whole sentence. The marked text becomes the glossary term.
- One plain phrase means one real thing on a page. If the same phrase appears twice, both carry the same `data-real`.
- Put a one-line "how to read this" note under the title so readers know the underlined words do something.

### 2. A glossary closes every page

The last section is a **Glossary**. One entry per distinct marked term, in the order the terms first appear, each written as:

`<eli5 term>: <the real thing>`

For example: `our golf robot: the silo38_golf Airflow DAG, scheduled 16:00 UTC`.

Build the glossary from the same `b.t` elements the hovers use (the script below does this), so the two can never disagree. Do not hand-write a second copy of the definitions.

## Reference markup

Plain phrase with its real term:

```html
<p class="howto">Anything written like <b class="t" tabindex="0" data-real="the technical term behind the plain words">this</b> hides the real words. Hover on a computer, tap on a phone.</p>

<p class="say">Every day at noon, <b class="t" tabindex="0" data-real="the silo38_golf Airflow DAG, scheduled 16:00 UTC">our golf robot</b> walks to ...</p>
```

Styles (colors come from the page's `:root` tokens; rename to match):

```css
b.t { position: relative; font-weight: 700; color: var(--accent); border-bottom: 3px solid var(--underline); cursor: help; outline: none; border-radius: 2px; }
b.t:focus-visible { box-shadow: 0 0 0 3px var(--underline-soft); }
b.t::after {
  content: "real words: " attr(data-real);
  position: absolute; left: 0; bottom: calc(100% + 8px); z-index: 5;
  background: var(--tip-bg); color: var(--tip-ink);
  font-weight: 400; font-size: 14px; line-height: 1.35;
  padding: 8px 10px; border-radius: 8px; width: max-content; max-width: min(320px, 80vw);
  opacity: 0; transform: translateY(4px); pointer-events: none; transition: opacity .12s, transform .12s;
}
b.t:hover::after, b.t:focus::after, b.t.open::after { opacity: 1; transform: translateY(0); }
@media (prefers-reduced-motion: reduce) { b.t::after { transition: none; } }

.glossary { margin-top: 44px; border-top: 1px solid var(--rule); padding-top: 28px; }
.glossary ul { list-style: none; padding: 0; margin: 0; }
.glossary li { padding: 8px 0; border-bottom: 1px solid var(--rule); }
.glossary li b { color: var(--accent); }
```

Glossary container, as the last thing on the page:

```html
<section class="glossary">
  <h2>Glossary</h2>
  <ul id="glossary"></ul>
</section>
```

Script (tap-to-toggle for touch, plus the glossary build):

```html
<script>
  // Tap-to-toggle for touch screens; hover and keyboard focus already work through CSS.
  document.querySelectorAll('b.t').forEach(function (el) {
    el.addEventListener('click', function (e) {
      var open = el.classList.contains('open');
      document.querySelectorAll('b.t.open').forEach(function (o) { o.classList.remove('open'); });
      if (!open) el.classList.add('open');
      e.stopPropagation();
    });
  });
  document.addEventListener('click', function () {
    document.querySelectorAll('b.t.open').forEach(function (o) { o.classList.remove('open'); });
  });

  // Glossary: one entry per distinct term, first-appearance order, "<eli5 term>: <real thing>".
  (function () {
    var list = document.getElementById('glossary');
    if (!list) return;
    var seen = {};
    document.querySelectorAll('b.t').forEach(function (el) {
      if (el.closest('.howto')) return;
      var term = el.textContent.trim().replace(/[.,;:!?]+$/, '');
      var key = term.toLowerCase();
      if (!term || seen[key]) return;
      seen[key] = true;
      var li = document.createElement('li');
      var b = document.createElement('b');
      b.textContent = term;
      li.appendChild(b);
      li.appendChild(document.createTextNode(': ' + el.dataset.real));
      list.appendChild(li);
    });
  })();
</script>
```

## Before publishing

- Open the page and check that every marked term shows its tooltip, and that the glossary lists each term once, in reading order, in the `term: real thing` shape.
- Tooltips near the right edge must not cause horizontal scroll at phone width; the `max-width: min(320px, 80vw)` cap handles this when the term sits at the start of a line. Check once at 375px.
- Publish through `/publish-work` (work account), and record the artifact URL in the worklog's `**Artifacts:**` line.
