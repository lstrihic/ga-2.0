resource "layout" "single_panel" {
  column {
    width = "65"

    tab "terminal" {
      title  = "Terminal"
      target = resource.terminal.shell
    }

    tab "shop" {
      title  = "The Reef Shop"
      target = resource.service.shop
    }

    tab "prometheus" {
      title  = "Prometheus"
      target = resource.service.prometheus
    }
  }

  column {
    width = "35"

    instructions {}
  }
}
