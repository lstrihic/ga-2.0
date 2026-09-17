---
slug: meet-the-stack
id: aykcptivjrpr
type: challenge
title: Meet the Stack You're On Call For
teaser: Tour the production shop, its metrics, and its logs — the old way.
notes:
- type: text
  contents: |-
    <div style="background:#191919;border:1px solid rgba(255,255,255,0.1);border-radius:12px;padding:28px 32px;font-family:system-ui,sans-serif;color:rgba(255,255,255,0.69)">
    <h2 style="color:#ff8d62;font-weight:500;margin-top:0">Welcome to the on-call seat</h2>
    <p style="text-transform:uppercase;letter-spacing:1.5px;font-size:13px;color:rgba(255,255,255,0.39);margin-bottom:4px">Context</p>
    <p style="margin-top:0">You run <b style="color:rgba(255,255,255,0.93)">The Reef Shop</b> — a three-service store (frontend, orders, payments) on Kubernetes. Prometheus watches it, every service streams JSON logs to disk, and support exports tickets to a columnar file. Four systems, and four different ways to ask them questions: <code>kubectl</code>, PromQL, <code>grep</code>-and-<code>jq</code>, and a columnar-file reader. That sprawl is exactly what <b style="color:#ff8d62">Coral</b> collapses into one SQL connection — but first, feel the sprawl.</p>
    <p style="text-transform:uppercase;letter-spacing:1.5px;font-size:13px;color:rgba(255,255,255,0.39);margin-bottom:4px">In this challenge</p>
    <p style="margin-top:0">Tour the stack the traditional way: browse the store, list the pods, peek at Prometheus, and inspect the raw data files.</p>
    <p style="text-transform:uppercase;letter-spacing:1.5px;font-size:13px;color:rgba(255,255,255,0.39);margin-bottom:4px">Tip</p>
    <p style="margin-top:0;margin-bottom:0">Nothing is broken yet. Enjoy it while it lasts.</p>
    </div>
tabs:
- id: r48qvhxxsmmo
  title: Terminal
  type: terminal
  hostname: k8s
- id: jybwfsyubqe2
  title: The Reef Shop
  type: service
  hostname: k8s
  path: /
  port: 30080
- id: qrtujnrhnfkz
  title: Prometheus
  type: service
  hostname: k8s
  path: /alerts
  port: 30990
difficulty: basic
timelimit: 0
enhanced_loading: null
---

You just joined the SRE rotation for **The Reef Shop**. Before any incident hits, an SRE learns the terrain: what runs where, what watches it, and where the data lives. In this challenge you'll survey all of it — and count how many different tools that survey takes.

---

<h2 style="color: #ff8d62;">Step 1: Browse the store</h2>

This is what your customers see. Open the storefront and place an order — it exercises the full request path: frontend → orders → payments.

[button label="The Reef Shop" variant="outline"](tab-1)

Pick a coral and click **Buy now**. A small confirmation message pops up in the top-right corner, the order lands in the **Recent orders** feed, and the status bar along the bottom shows all three services green — the whole chain is healthy.

---

<h2 style="color: #ff8d62;">Step 2: List the workloads</h2>

Now the operator view. Head to the terminal and ask Kubernetes what's running.

[button label="Terminal" variant="outline"](tab-0)

```bash,run
kubectl get pods -o wide
```

Three shop services plus Prometheus, all `Running`. This is tool number one: `kubectl`, speaking Kubernetes API.

---

<h2 style="color: #ff8d62;">Step 3: Check the monitoring</h2>

Prometheus scrapes every service and evaluates alert rules. Open its Alerts page.

[button label="Prometheus" variant="outline"](tab-2)

Both rules — `PaymentsHighErrorRate` and `ShopTargetDown` — should be green (inactive). This is tool number two: PromQL and the Prometheus UI.

---

<h2 style="color: #ff8d62;">Step 4: Inspect the raw data</h2>

Logs and tickets don't live in either of those tools. Back in the terminal, look at the files directly.

[button label="Terminal" variant="outline"](tab-0)

```bash,run
ls -lh /root/data/
```

Then peek at the last few log lines:

```bash,run
tail -3 /root/data/logs.jsonl
```

Two files: JSON log lines harvested from the pods every 30 seconds, and a support-ticket export sitting next to them. Tools three and four: raw JSON you'd normally attack with `grep` and `jq`, and a columnar ticket file that needs its own reader entirely.

> [!NOTE]
> Four systems, four interfaces — and during a real incident you'd be juggling all of them at once. Keep that number in mind; the next challenge replaces it with one.

---

✅ You know the terrain. Click **Check**, then move on to **Challenge 2** to give this stack one SQL connection.
