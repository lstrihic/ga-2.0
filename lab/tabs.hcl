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
