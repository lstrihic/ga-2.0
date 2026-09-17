You just joined the SRE rotation for **The Reef Shop**. Before any incident hits, an SRE learns the terrain: what runs where, what watches it, and where the data lives. In this challenge you'll survey all of it — and count how many different tools that survey takes.

---

<h2 style="color: #ff8d62;">Step 1: Browse the store</h2>

This is what your customers see. Open the storefront and place an order — it exercises the full request path: frontend → orders → payments.

<instruqt-button to="tab:shop" variant="outline">The Reef Shop</instruqt-button>

Pick a coral and click **Buy now**. A small confirmation message pops up in the top-right corner, the order lands in the **Recent orders** feed, and the status bar along the bottom shows all three services green — the whole chain is healthy.

---

<h2 style="color: #ff8d62;">Step 2: List the workloads</h2>

Now the operator view. Head to the terminal and ask Kubernetes what's running.

<instruqt-button to="tab:terminal" variant="outline">Terminal</instruqt-button>

```bash,run
kubectl get pods -o wide
```

Three shop services plus Prometheus, all `Running`. This is tool number one: `kubectl`, speaking Kubernetes API.

---

<h2 style="color: #ff8d62;">Step 3: Check the monitoring</h2>

Prometheus scrapes every service and evaluates alert rules. Open its Alerts page.

<instruqt-button to="tab:prometheus" variant="outline">Prometheus</instruqt-button>

Both rules — `PaymentsHighErrorRate` and `ShopTargetDown` — should be green (inactive). This is tool number two: PromQL and the Prometheus UI.

---

<h2 style="color: #ff8d62;">Step 4: Inspect the raw data</h2>

Logs and tickets don't live in either of those tools. Back in the terminal, look at the files directly.

<instruqt-button to="tab:terminal" variant="outline">Terminal</instruqt-button>

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
