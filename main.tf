terraform { 
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {
  host = "npipe:////.//pipe//docker_engine"
}

resource "docker_image" "dind" {
  name         = "docker:24.0-dind"
  keep_locally = false
}

resource "docker_container" "dind" {
  image = docker_image.dind.image_id
  name  = "practicas-dind"

  ports {
    internal = 80
    external = 8000
  }

  privileged = true
}

resource "docker_image" "jenkins" {
  name = "custom-jenkins:latest"
  build {
    context = "./" # Contexto del Dockerfile
  }
}

resource "docker_container" "jenkins" {
  image = docker_image.jenkins.image_id
  name  = "practicas-jenkins"

  ports {
    internal = 8080
    external = 8080
  }

  ports {
    internal = 50000
    external = 50000
  }

  env = [
    "JENKINS_ADMIN_ID=admin",
    "JENKINS_ADMIN_PASSWORD=admin"
  ]
}
