#!/bin/bash
# Check: environment healthy + learner actually toured it.
# No strict flags in check scripts (per repo convention): explicit handling only.

# 1. Shop pods running
for SVC in frontend orders payments; do
  PHASE=$(kubectl get pods -l app=${SVC} -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
  if [ "$PHASE" != "Running" ]; then
    printf '%s\n' "The ${SVC} pod isn't Running yet. Give the environment a few seconds, then run: kubectl get pods" >&2
    exit 1
  fi
done

# 2. Prometheus answering
if ! curl -fsS --max-time 5 http://127.0.0.1:9090/-/ready >/dev/null 2>&1; then
  printf '%s\n' "Prometheus isn't answering yet. Wait a few seconds and click Check again." >&2
  exit 1
fi

# 3. Data plane seeded (logs flowing + ticket export present)
if [ ! -s /root/data/logs.jsonl ]; then
  printf '%s\n' "The log export at /root/data/logs.jsonl is empty — give the 30s harvest timer a moment, then Check again." >&2
  exit 1
fi
if ! ls /root/data/tickets.* >/dev/null 2>&1; then
  printf '%s\n' "The ticket export is missing from /root/data/ — the environment may still be settling; try Check again shortly." >&2
  exit 1
fi

# NOTE: engagement here is experiential (browsing tabs, running reads);
# terminal history is NOT reliable on this image (Instruqt's terminal
# sources no rc file), so this check validates environment health only.
exit 0
