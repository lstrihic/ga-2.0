resource "page" "meet_the_stack" {
  title = "Meet the Stack You're On Call For"
  file  = "instructions/meet-the-stack.md"
}

resource "page" "meet_the_stack" {
  title = "Meet the Stack You're On Call For"
  file  = "instructions/meet-the-stack.md"

  activities = {
    check_stack = resource.task.meet_the_stack
  }
}


resource "page" "meet_the_stack" {
  title = "Meet the Stack You're On Call For"
  file  = "instructions/meet-the-stack.md"
}
