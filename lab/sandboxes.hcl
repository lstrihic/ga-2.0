resource "network" "main" {
  subnet = "10.50.0.0/24"
}

resource "aws_account" "bedrock" {
  services = ["bedrock"]
  regions  = ["us-east-1", "us-east-2", "us-west-2"]

  user "student" {
    managed_policies = [
      "arn:aws:iam::aws:policy/AmazonBedrockLimitedAccess"
    ]
  }
}

resource "vm" "k8s" {
  config {
    arch = "x86_64"
  }

  image {
    name = "ubuntu:24.04"
  }

  resources {
    cpu    = 4
    memory = 16384
  }

  network {
    id = resource.network.main.meta.id
  }
}
