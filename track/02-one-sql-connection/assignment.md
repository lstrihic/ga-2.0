---
slug: one-sql-connection
id: yqlxpifqgyee
type: challenge
title: One SQL Connection
teaser: Discover the Coral catalog and JOIN Kubernetes, Prometheus, and files in one
  query.
notes:
- type: text
  contents: |-
    <div style="background:#191919;border:1px solid rgba(255,255,255,0.1);border-radius:12px;padding:28px 32px;font-family:system-ui,sans-serif;color:rgba(255,255,255,0.69)">
    <h2 style="color:#ff8d62;font-weight:500;margin-top:0">One SQL connection</h2>
    <p style="text-transform:uppercase;letter-spacing:1.5px;font-size:13px;color:rgba(255,255,255,0.39);margin-bottom:4px">Context</p>
    <p style="margin-top:0"><b style="color:#ff8d62">Coral</b> is already installed and connected to three sources: <code>k8s</code> (your cluster, read via the Kubernetes API), <code>prometheus</code> (alerts and scrape health), and <code>shopdata</code> (the JSONL logs and the ticket export). Each source's data appears as ordinary SQL tables — and tables from <i>different</i> sources JOIN like they live in one database.</p>
    <p style="text-transform:uppercase;letter-spacing:1.5px;font-size:13px;color:rgba(255,255,255,0.39);margin-bottom:4px">In this challenge</p>
    <p style="margin-top:0">Discover the catalog, query each source, then run your first cross-source JOIN.</p>
    <p style="text-transform:uppercase;letter-spacing:1.5px;font-size:13px;color:rgba(255,255,255,0.39);margin-bottom:4px">Reference</p>
    <p style="margin-top:0;margin-bottom:0">Start every investigation with: <code style="color:#b2eaa5">SELECT schema_name, table_name FROM coral.tables</code></p>
    </div>
tabs:
- id: l5i1bcpbqcvr
  title: Terminal
  type: terminal
  hostname: k8s
- id: tdglm8nkz3zi
  title: Coral UI
  type: service
  hostname: k8s
  path: /
  port: 11457
- id: 0vxqcrmrlxyh
  title: Data Files
  type: code
  hostname: k8s
  path: /root/data
difficulty: basic
timelimit: 0
enhanced_loading: false
---

In the last challenge you touched four different tools. Now meet the layer that makes them one. Coral is connected to your cluster, your Prometheus, and your data files — everything you toured is about to become SQL tables under a single connection.

---

<h2 style="color: #ff8d62;">Step 1: See what's connected</h2>

List Coral's sources. Each one was added from a small YAML spec — no code, no plugins.

```bash,run
coral source list
```

You should see three sources: `k8s`, `prometheus`, and `shopdata`.

---

<h2 style="color: #ff8d62;">Step 2: Discover the catalog</h2>

Every Coral workspace has a built-in catalog. This is the query to start any investigation with — it tells you every table you can reach.

```bash,run
coral sql "SELECT schema_name, table_name FROM coral.tables"
```

Pods, deployments, events, alerts, logs, tickets — one catalog, three very different systems behind it. Everything listed here is now queryable with plain SQL.

---

<h2 style="color: #ff8d62;">Step 3: Query each world</h2>

Prove each source speaks SQL. Kubernetes first:

```bash,run
coral sql "SELECT name, status, node_name FROM k8s.pods WHERE namespace = 'default'"
```

Four rows — your three shop services plus Prometheus, all `Running`. That's a live Kubernetes API call wearing a SQL costume. Then the log file — same syntax, no `jq` in sight:

```bash,run
coral sql "SELECT ts, service, level, message FROM shopdata.logs ORDER BY ts DESC LIMIT 5"
```

The same JSON lines you tailed in challenge 1, now sorted and filtered by a query engine. And the ticket export:

```bash,run
coral sql "SELECT ticket_id, service, priority, subject FROM shopdata.tickets WHERE status = 'open'"
```

Four open tickets — and notice that three of them already point at **payments**. File that away; it becomes relevant sooner than you'd like.

---

<h2 style="color: #ff8d62;">Step 4: The first cross-source JOIN</h2>

Here's the moment that separates Coral from a pile of connectors: JOIN live cluster state against the log file — one query, two systems.

```bash,run
coral sql "SELECT p.name AS pod, p.status, COUNT(l.request_id) AS log_lines FROM k8s.pods p LEFT JOIN shopdata.logs l ON l.pod = p.name WHERE p.namespace = 'default' GROUP BY p.name, p.status ORDER BY log_lines DESC" | tee /root/answers/first-join.txt
```

We save the output to `/root/answers/first-join.txt` — it's your evidence, and the Check button grades it. Every row pairs a *live* Kubernetes pod with how many log lines it has shipped to disk. No API pagination, no glue script — the JOIN happened inside Coral's engine.

---

<h2 style="color: #ff8d62;">Step 5: See it in the Coral UI</h2>

Coral also ships a local UI. Open it and look at the **Traces** view — it's a live query stream: every SQL statement you just ran, with execution timings. This is your query audit trail, and it matters more than it looks: when an *agent* is doing the querying, this stream is how you see exactly what it asked and how long each answer took.

[button label="Coral UI" variant="outline"](tab-1)

Then look at the raw files behind `shopdata` in the **Data Files** tab — this one's a two-part lesson:

[button label="Data Files" variant="outline"](tab-2)

Open `logs.jsonl` first: those are the exact lines your Step 3 query returned, one JSON object per line — readable, but imagine grepping a gigabyte of it. Now open `tickets.parquet`: the editor shows *nothing*. It isn't empty — it's columnar binary, and your four open tickets live inside it. That contrast is the lesson: one source has files a human can read but not query, the other has files SQL can query but a human can't read — and Coral gave both the same interface.

> [!WARNING]
> Look, don't type — these files are live data. The graders (and challenge 4's incident investigation) query them.

---

✅ Three systems, one connection, and your first cross-source JOIN. Click **Check**, then move on to **Challenge 3** to hand this power to an agent.
