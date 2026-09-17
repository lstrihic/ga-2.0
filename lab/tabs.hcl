resource "terminal" "shell" {
  target            = resource.vm.k8s
  shell             = "/bin/bash"
  user              = "root"
  working_directory = "/root"
}

resource "service" "shop" {
  target = resource.vm.k8s
  port   = 30080
  scheme = "http"
  path   = "/"
}

resource "service" "prometheus" {
  target = resource.vm.k8s
  port   = 30990
  scheme = "http"
  path   = "/alerts"
}
