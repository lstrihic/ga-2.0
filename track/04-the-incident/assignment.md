---
slug: the-incident
id: ufjclnsgousz
type: challenge
title: 'Incident: Checkout Is Down'
teaser: A bad deploy just shipped. Root-cause it with one cross-source JOIN.
notes:
- type: text
  contents: "<div style=\"background:#191919;border:1px solid rgba(255,255,255,0.1);border-radius:12px;padding:28px
    32px;font-family:system-ui,sans-serif;color:rgba(255,255,255,0.69)\">\n<h2 style=\"color:#e65fa9;font-weight:500;margin-top:0\">\U0001F525
    You're being paged</h2>\n<p style=\"text-transform:uppercase;letter-spacing:1.5px;font-size:13px;color:rgba(255,255,255,0.39);margin-bottom:4px\">Situation</p>\n<p
    style=\"margin-top:0\">A teammate just rolled out <code>v2</code> of one of the
    shop services. Moments later, checkouts started failing and a <b style=\"color:#e65fa9\">critical
    alert</b> began firing. Customers are bouncing.</p>\n<p style=\"text-transform:uppercase;letter-spacing:1.5px;font-size:13px;color:rgba(255,255,255,0.39);margin-bottom:4px\">Your
    job</p>\n<p style=\"margin-top:0\">One service is the <b style=\"color:rgba(255,255,255,0.93)\">root
    cause</b>; the cascade will make others look broken too. Your job: name the service
    whose own configuration failed. Use Coral — by hand or through Claude Code — to
    JOIN what Prometheus, Kubernetes, and the logs each know. When you're confident,
    record your answer with the <code>submit</code> command.</p>\n<p style=\"text-transform:uppercase;letter-spacing:1.5px;font-size:13px;color:rgba(255,255,255,0.39);margin-bottom:4px\">Remember</p>\n<p
    style=\"margin-top:0;margin-bottom:0\">Catalog first: <code style=\"color:#b2eaa5\">SELECT
    schema_name, table_name FROM coral.tables</code>. Alerts live in <code>prometheus.alerts</code>.</p>\n</div>"
tabs:
- id: k0uzbxfa9tpq
  title: Terminal
  type: terminal
  hostname: k8s
- id: 9hq5nh209tgk
  title: The Reef Shop
  type: service
  hostname: k8s
  path: /
  port: 30080
- id: b1sfrg3w2ixo
  title: Coral UI
  type: service
  hostname: k8s
  path: /
  port: 11457
difficulty: intermediate
timelimit: 0
enhanced_loading: false
---

The pager just went off. The storefront's checkout is failing, an alert is firing, and somewhere in this cluster a bad deploy is lying to you about being `Running`. This is the investigation you toured four tools for in Challenge 1 — now do it with one.

---

<h2 style="color: #ff8d62;">Step 1: Confirm the blast radius</h2>

See it like a customer first. Open the store:

[button label="The Reef Shop" variant="outline"](tab-1)

Before you click anything, look at the status bar along the bottom — the **orders and payments dots are already red**, with error counts climbing. This incident didn't wait for you; background traffic has been failing checkouts since the bad deploy landed. Now confirm it first-hand: try to buy any coral. The pop-up message in the top-right corner comes back pink — *"Checkout failed"* — and **Recent orders** logs `ERR`. It's real — time to find out *why*.

---

<h2 style="color: #ff8d62;">Step 2: What's alerting?</h2>

Back in the terminal, start where an SRE always starts: the alert stream. It's a SQL table now.

[button label="Terminal" variant="outline"](tab-0)

```bash,run
coral sql "SELECT alert_name, alert_state, severity, summary FROM prometheus.alerts" | tee /root/answers/alerts.txt
```

We save the output to `/root/answers/alerts.txt` — incident evidence for the postmortem (and for the Check button). A critical alert should be active. **If the table comes back empty, the rule is still evaluating — the error rate needs about 90 seconds to cross the threshold.** Re-run the query until the alert appears, then note which service it points at. An alert is a symptom, not a cause.

---

<h2 style="color: #ff8d62;">Step 3: The one-query investigation</h2>

Here's the Coral move: in a single JOIN, line up the firing alert, the live pod state, and the most recent error logs. Three systems, one answer. (This query filters on the alert being `firing` — make sure Step 2 showed it before running.)

```bash,run
coral sql "SELECT a.alert_name, a.severity, p.name AS pod, p.status, l.ts, l.message FROM prometheus.alerts a JOIN shopdata.logs l ON l.level = 'error' JOIN k8s.pods p ON p.name = l.pod WHERE a.alert_state = 'firing' ORDER BY l.ts DESC LIMIT 10"
```

Or — the better demo — let the agent write it. Start `claude` and paste this at its `❯` prompt:

```copy
We have a production incident. Use Coral to find which service is failing and why: check prometheus.alerts, join against k8s.pods and shopdata.logs, and tell me the root cause from the error messages.
```

Watch the transcript: same rhythm as challenge 3 — catalog, a JOIN it writes itself, then a diagnosis in plain English. Afterward, the whole investigation is sitting in the Coral UI's Traces stream:

[button label="Coral UI" variant="outline"](tab-2)

Then return to the terminal and **exit the agent** — type `/exit` at the `❯` prompt (or Ctrl+D twice). Steps 4 and 5 are shell commands and run at the `#` prompt:

[button label="Terminal" variant="outline"](tab-0)

Either way you investigated, the error messages name the exact misconfiguration the v2 deploy shipped with.

---

<h2 style="color: #ff8d62;">Step 4: Corroborate against the business</h2>

One more JOIN turns "technical incident" into "business impact" — check whether support tickets were already hinting at this service:

```bash,run
coral sql "SELECT t.ticket_id, t.priority, t.subject FROM shopdata.tickets t JOIN (SELECT service, COUNT(*) AS errs FROM shopdata.logs WHERE level = 'error' AND message NOT LIKE '%returned an error%' GROUP BY service) src ON t.service = src.service WHERE t.status = 'open'"
```

Three open tickets against the same service, filed *before* the deploy — the subquery finds the service whose errors are *self-originated* (its log lines name a broken config, rather than blaming a downstream call). The data was trying to tell someone.

---

<h2 style="color: #ff8d62;">Step 5: Submit your finding</h2>

Look at your investigation output again: *all three* services log errors — every root failure triggers one error in each service upstream of it. That's the cascade, and it's noise. The root cause is the one service whose error messages point at its **own broken configuration**, not at another service's failure. Submit that one — at the `#` shell prompt (not inside Claude):

```bash
submit "<root-cause-service>"
```

<details>
<summary>💡 <b>Stuck? Expand for a hint</b></summary>

<br>

Run this — it groups every error message by the service that logged it:

```bash,run
coral sql "SELECT service, message, COUNT(*) AS occurrences FROM shopdata.logs WHERE level = 'error' GROUP BY service, message ORDER BY occurrences DESC"
```

Now read the three messages carefully. Two of them say another service *"returned an error"* — they're pointing fingers downstream. One of them names a **missing configuration value in its own environment**. A service that blames someone else is a victim; the service that describes its *own* broken config is your root cause.

</details>

> [!TIP]
> The check grades against the live cluster, not a hardcoded answer — exactly how Coral's own checks would behave.

---

✅ Root cause found — with one connection instead of four tools. Click **Check**, then head to **Challenge 5** for the part your security team will love.
