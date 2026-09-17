resource "lab" "main" {
  title       = "AI SRE: Root-Cause an Incident with One SQL Query"
  description = <<-EOF
  Coral is the data engine for enterprise AI — one SQL connection that lets agents query APIs, databases, and files as if they were a single dataset.

  In this hands-on lab you step into the on-call seat. A three-service shop runs in Kubernetes with Prometheus watching it, logs streaming to disk, and a support-ticket export sitting in a Parquet file. When a bad deploy takes payments down, you will root-cause it the Coral way: one SQL JOIN across alerts, pod state, and error logs — first by hand, then hands-free through Claude Code over MCP.

  You will finish by proving the governance story: Coral is read-only by design, and extending the catalog to your own API takes fifteen lines of YAML.
EOF

  icon = "assets/icon.png"

  settings {
    theme = "modern-dark"

    controls {
      show_stop = true
    }

    timelimit {
      duration   = "1h"
      show_timer = true
    }

    idle {
      enabled = true
      timeout = "10m"
    }
  }

  layout = resource.layout.single_panel
}
