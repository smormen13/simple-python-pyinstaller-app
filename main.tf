terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {
  host = "npipe:////.//pipe//docker_engine" # Para sistemas Windows
}

# Docker in Docker (DinD)
resource "docker_image" "dind" {
  name         = "docker:24.0-dind"
  keep_locally = false
}

resource "docker_container" "dind" {
  image       = docker_image.dind.image_id
  name        = "practicas-dind"
  privileged  = true
  ports {
    internal = 2375
    external = 2375
  }
}

# Jenkins
resource "docker_image" "jenkins" {
  name = "custom-jenkins:latest"
}

resource "docker_container" "jenkins" {
  image = docker_image.jenkins.image_id
  name  = "practicas-jenkins"

  ports {
    internal = 8080
    external = 8080
  }

  env = [
    "JENKINS_ADMIN_ID=admin",
    "JENKINS_ADMIN_PASSWORD=admin"
  ]

  depends_on = [docker_container.dind]
}