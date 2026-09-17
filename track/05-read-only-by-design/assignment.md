---
slug: read-only-by-design
id: 5xyfrnopnbni
type: challenge
title: Read-Only by Design — and Extensible in One YAML File
teaser: Prove the governance model, then add your own API to the catalog with one
  short spec.
notes:
- type: text
  contents: |-
    <div style="background:#191919;border:1px solid rgba(255,255,255,0.1);border-radius:12px;padding:28px 32px;font-family:system-ui,sans-serif;color:rgba(255,255,255,0.69)">
    <h2 style="color:#ff8d62;font-weight:500;margin-top:0">The part your security team will love</h2>
    <p style="text-transform:uppercase;letter-spacing:1.5px;font-size:13px;color:rgba(255,255,255,0.39);margin-bottom:4px">Context</p>
    <p style="margin-top:0">The incident is fixed — payments is back on v1. Two questions remain before anyone lets an agent near production: <b style="color:rgba(255,255,255,0.93)">can it break anything?</b> and <b style="color:rgba(255,255,255,0.93)">can it reach our own systems?</b> Coral's answers: structurally no, and yes — in one short YAML spec.</p>
    <p style="text-transform:uppercase;letter-spacing:1.5px;font-size:13px;color:rgba(255,255,255,0.39);margin-bottom:4px">In this challenge</p>
    <p style="margin-top:0">Try to mutate production through Coral and watch it refuse — the engine has no write path at all. Then extend the catalog with a custom source spec that wraps the shop's own stats API.</p>
    <p style="text-transform:uppercase;letter-spacing:1.5px;font-size:13px;color:rgba(255,255,255,0.39);margin-bottom:4px">Why it matters</p>
    <p style="margin-top:0;margin-bottom:0">Read-only by design means governance is an architecture property, not a policy hope. And custom specs mean <i>your</i> product's API becomes agent-queryable the same afternoon.</p>
    </div>
tabs:
- id: tyi6k65eyvzx
  title: Terminal
  type: terminal
  hostname: k8s
- id: 21hq61cs0woy
  title: Spec Editor
  type: code
  hostname: k8s
  path: /root/specs
difficulty: intermediate
timelimit: 0
enhanced_loading: false
---

The fire is out — setup rolled payments back to v1 while you weren't looking. What's left is the conversation every platform team has before adopting agent tooling: blast radius and reach. Both answers live in this challenge.

---

<h2 style="color: #ff8d62;">Step 1: Try to break production</h2>

You have a connection that can see everything. Try to *change* something with it:

```bash,run
coral sql "DELETE FROM k8s.pods WHERE name LIKE 'payments%'" 2>&1 | tee /root/answers/mutation-attempt.txt
```

An error is exactly what you want here:

```nocopy
Error (invalid argument): invalid input: DML not supported: Delete
```

That's not a permission denying you — it's the query engine reporting it has no DELETE capability at all. We keep the refusal as `/root/answers/mutation-attempt.txt` — a receipt worth showing your security team.

And try an UPDATE for good measure:

```bash,run
coral sql "UPDATE shopdata.tickets SET status = 'closed'"
```

Same refusal, `DML not supported: Update`. Both fail — not because a permission said no, but because the engine has no write path to say yes with. That's the difference between *policy* and *architecture*. Hand this connection to any agent and the worst it can do is read.

---

<h2 style="color: #ff8d62;">Step 2: Read a source spec</h2>

Everything Coral queried today came from small YAML specs. Open the one that powered your incident logs.

[button label="Spec Editor" variant="outline"](tab-1)

Open `shopdata.yaml`. Location, glob, columns — that's the whole integration. No SDK, no code.

---

<h2 style="color: #ff8d62;">Step 3: Wrap your own API in one small spec</h2>

The shop's frontend exposes a stats endpoint (`/api/stats`) that isn't in Coral yet. Add it. You should still be in the **Spec Editor** from the last step — a file named `shopapi.yaml` is already waiting in the tree, containing only a placeholder comment. Click it to open it, select everything in it, and replace it with exactly this content (the editor saves automatically — watch for *"Changes saved"* in the top right):

```copy
name: shopapi
description: The Reef Shop's own stats API, exposed to agents as SQL
version: 0.1.0
dsl_version: 3
backend: http
base_url: http://localhost:30080
tables:
- name: service_stats
  description: Per-service request success and error counts
  request:
    method: GET
    path: /api/stats
  response:
    rows_path: [stats]
  columns:
  - {name: service, type: Utf8}
  - {name: ok_requests, type: Int64}
  - {name: error_requests, type: Int64}
```

Then lint and add it from the terminal:

[button label="Terminal" variant="outline"](tab-0)

```bash,run
coral source lint /root/specs/shopapi.yaml && coral source add --file /root/specs/shopapi.yaml
```

Lint validates the spec against Coral's schema; add installs it. Success looks like this:

```nocopy
Manifest is valid
Added source shopapi (secrets: none)
  ✓ shopapi connected successfully
    shopapi (1 table)
    └─ service_stats
```

If lint complains instead, the message names the exact line — fix it in the Spec Editor and re-run.

---

<h2 style="color: #ff8d62;">Step 4: Query your API like a database</h2>

Your internal API is now a SQL table an agent can reach:

```bash,run
coral sql "SELECT service, ok_requests, error_requests FROM shopapi.service_stats"
```

Two rows — `orders` and `payments`, with live request counts served by *your API* a moment ago. Don't be surprised that `orders` carries the incident's error count while `payments` shows zero: these counters live as long as the pod does, and the fix *redeployed* payments (fresh pod, fresh counters) while orders — the cascade victim — was never restarted. Metrics remember what deploys erase. And because it's in the same catalog, it JOINs against everything else — tickets included:

```bash,run
coral sql "SELECT s.service, s.error_requests, COUNT(t.ticket_id) AS open_tickets FROM shopapi.service_stats s LEFT JOIN shopdata.tickets t ON t.service = s.service AND t.status = 'open' GROUP BY s.service, s.error_requests"
```

`payments` pairs its request stats with its three open tickets — API metrics and business data in one result. That's the full loop: your product's API, in the agent's catalog, joined against business data — read-only, in a YAML file short enough to read in one breath.

---

✅ Governance proven, catalog extended. Click **Check** to finish the track — and imagine this demo wearing *your* product's API.
