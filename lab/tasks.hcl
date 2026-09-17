resource "task" "meet_the_stack" {
  description     = "Verify that the stack is healthy."
  success_message = "The shop, Prometheus, and data exports are ready."

  config {
    target            = resource.vm.k8s
    user              = "root"
    group             = "root"
    working_directory = "/root"
    timeout           = "30s"

    success_exit_codes = [0]
    failure_exit_codes = [1]
  }

  condition "stack_healthy" {
    description = "The shop pods, Prometheus, and data exports are available."

    check {
      script          = "scripts/meet-the-stack/check.sh"
      failure_message = "The stack is not ready. Check the shop pods, Prometheus, and exports in /root/data, then try again."
    }
  }
}
