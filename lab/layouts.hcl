resource "layout" "single_panel" {
  column {
    width = "65"

    tab "terminal" {
      title  = "Terminal"
      target = resource.terminal.shell
    }
  }

  column {
    width = "35"

    instructions {}
  }
}
