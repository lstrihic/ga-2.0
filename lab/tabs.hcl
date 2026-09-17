resource "terminal" "shell" {
  target            = resource.vm.k8s
  shell             = "/bin/bash"
  user              = "root"
  working_directory = "/root"
}
