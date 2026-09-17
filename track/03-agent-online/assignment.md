---
slug: agent-online
id: yxgaodwoupmt
type: challenge
title: Agent Online
teaser: Wire Coral into Claude Code over MCP and let the agent query for you.
notes:
- type: text
  contents: |-
    <div style="background:#191919;border:1px solid rgba(255,255,255,0.1);border-radius:12px;padding:28px 32px;font-family:system-ui,sans-serif;color:rgba(255,255,255,0.69)">
    <h2 style="color:#ff8d62;font-weight:500;margin-top:0">Give your agent the keys (read-only ones)</h2>
    <p style="text-transform:uppercase;letter-spacing:1.5px;font-size:13px;color:rgba(255,255,255,0.39);margin-bottom:4px">Context</p>
    <p style="margin-top:0">Coral ships a built-in <b style="color:rgba(255,255,255,0.93)">MCP server</b> (<code>coral mcp-stdio</code>) that presents the whole workspace to any agent as a read-only SQL database with catalog discovery. Instead of an agent juggling one MCP server per provider — each with its own auth and its own pagination — it gets one tool that can JOIN.</p>
    <p style="text-transform:uppercase;letter-spacing:1.5px;font-size:13px;color:rgba(255,255,255,0.39);margin-bottom:4px">In this challenge</p>
    <p style="margin-top:0">Register Coral with Claude Code yourself — it's one command — then watch the agent discover the catalog and answer a cross-source question hands-free.</p>
    <p style="text-transform:uppercase;letter-spacing:1.5px;font-size:13px;color:rgba(255,255,255,0.39);margin-bottom:4px">Tip</p>
    <p style="margin-top:0;margin-bottom:0">Naming Coral explicitly in your prompt ("use Coral to...") helps the agent pick the right tool — that's Coral's own documented best practice.</p>
    </div>
tabs:
- id: 9nnxhchgjntc
  title: Terminal
  type: terminal
  hostname: k8s
- id: xdsyiknb0rii
  title: Coral UI
  type: service
  hostname: k8s
  path: /
  port: 11457
difficulty: intermediate
timelimit: 0
enhanced_loading: false
---

Everything you did in the last challenge, an agent can do for you — if you hand it the connection. Claude Code is pre-installed on this machine; your job is to introduce it to Coral. This is the exact workflow from Coral's MCP guide, unchanged.

---

<h2 style="color: #ff8d62;">Step 1: Register Coral with Claude Code</h2>

One command tells Claude Code that a tool called `coral` exists and how to launch it. This is the same registration you'd run on your own laptop.

```bash,run
claude mcp add --scope user coral -- coral mcp-stdio
```

Confirm the wiring took:

```bash,run
claude mcp list
```

You should see `coral` in the list, pointing at `coral mcp-stdio`.

---

<h2 style="color: #ff8d62;">Step 2: Ask the agent a cross-source question</h2>

Now put the agent to work. Start Claude Code — it's pre-configured to run against Amazon Bedrock through this sandbox's AWS account, so there is no login and nothing to sign up for:

```bash,run
claude
```

You'll land directly in the Claude Code REPL: a dark input box with a `❯` prompt (no login screen — if you ever see one, this sandbox is misconfigured; skip the challenge and flag it). The `coral` MCP tools you registered in Step 1 are pre-approved, so the agent can query without asking you for permission each time.

At the prompt, paste this question — it deliberately spans two systems:

```copy
Use Coral to find out which pods are running in the default namespace and how many error-level log lines each service has produced. Query the catalog first.
```

Now watch the transcript — this is the demo. You'll see the agent make a small number of `coral` tool calls: first the catalog (`coral.tables`), then one or two SQL queries it wrote itself, ending in a JOIN across `k8s.pods` and `shopdata.logs`. Then it answers in plain English: four pods running, error counts per service (all zero right now — the shop is healthy). No pagination loops, no per-provider tools, no tool-call spam — that's the point.

Then catch the agent in the act — open the Coral UI's **Traces** view:

[button label="Coral UI" variant="outline"](tab-1)

Every query the agent just ran is sitting in the stream with its execution time. Your agent's data access is fully auditable — that line lands hard with security teams. Then head back to the terminal for the last step:

[button label="Terminal" variant="outline"](tab-0)

> [!NOTE]
> This is the benchmark story made visible: in Coral's published testing, agents using one SQL surface were 20% more accurate and 2x cheaper than agents juggling per-provider MCP servers — and the gap widens on complex, multi-source questions.

---

<h2 style="color: #ff8d62;">Step 3: Leave a marker</h2>

**First, leave the agent.** Type `/exit` at Claude's `❯` prompt (or press Ctrl+D twice). You're back in the plain shell when the prompt is `#` again — the next command is a *shell* command, and pasting it into Claude's `❯` prompt will just confuse the agent.

From the `#` prompt, record the current error count:

```bash,run
coral sql "SELECT COUNT(*) AS error_lines FROM shopdata.logs WHERE level = 'error'" | tee /root/answers/agent-warmup.txt
```

Right now that count should be **0** — the shop is healthy, and the agent told you the same thing a minute ago. Remember this number; challenge 4 exists to change it.

---

✅ Your agent has one read-only SQL connection to everything. Click **Check**, then brace yourself — **Challenge 4** pages you.
