terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {
  host = "tcp://localhost:2375" # Conexión a través de TCP
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
  entrypoint  = ["dockerd-entrypoint.sh", "--host=tcp://0.0.0.0:2375"]
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
    "JENKINS_ADMIN_PASSWORD=admin",
    "JAVA_OPTS=-Djenkins.install.runSetupWizard=false -Dhudson.security.csrf.GlobalCrumbIssuerConfiguration=false",
    "DOCKER_HOST=tcp://practicas-dind:2375" # Configuración para que Jenkins se conecte a DinD
  ]

  volumes {
    host_path      = "C:/jenkins_home"
    container_path = "/var/jenkins_home"
  }

  depends_on = [docker_container.dind]
}

