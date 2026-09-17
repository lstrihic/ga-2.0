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
  }

  column {
    width = "35"

    instructions {}
  }
}
