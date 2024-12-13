# Despliegue de Jenkins y Docker-in-Docker con Terraform

Este documento proporciona una guía paso a paso para replicar el proceso de despliegue de Jenkins en un contenedor Docker, utilizando Terraform para la configuración de infraestructura y Docker-in-Docker (DinD) para ejecutar pipelines.

---

## Requisitos Previos

1. **Instalar las siguientes herramientas:**
   - [Docker Desktop](https://www.docker.com/products/docker-desktop)
   - [Git](https://git-scm.com/downloads)
   - [Terraform](choco install terraform)
   

## Crear la Imagen de Jenkins

1. **Crear un Dockerfile:**
   Crea un archivo llamado `Dockerfile` con el siguiente contenido:

   ```dockerfile
    FROM jenkins/jenkins:2.479.2-jdk17
    USER root
    RUN apt-get update && apt-get install -y lsb-release
    RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
        https://download.docker.com/linux/debian/gpg
    RUN echo "deb [arch=$(dpkg --print-architecture) \
        signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
        https://download.docker.com/linux/debian \
        $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
    RUN apt-get update && apt-get install -y docker-ce-cli
    USER jenkins
    RUN jenkins-plugin-cli --plugins "blueocean docker-workflow token-macro json-path-api"
   ```

2. **Construir la Imagen:**
   Ejecuta el siguiente comando en la terminal:

   ```bash
   docker build -t custom-jenkins:latest .
   ```

---

## Desplegar los Contenedores con Terraform

1. **Crear el Archivo de Configuración Terraform:**
   Crea un archivo llamado `main.tf` con el siguiente contenido:

   ```hcl
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

   ```

2. **Inicializar Terraform:**
   En la terminal, navega al directorio que contiene el archivo `main.tf` y ejecuta:

   ```bash
   terraform init
   ```

3. **Generar pla de Ejecución:**
   Ejecuta:

   ```bash
   terraform plan
   ```

4. **Desplegar la Infraestructura:**
   Ejecuta:

   ```bash
   terraform apply
   ```

   Confirma la aplicación escribiendo `yes` cuando se te solicite.

---

## Configuración de Jenkins

1. **Acceder a Jenkins:**
   - Abre un navegador y navega a `http://localhost:8080`.
   - Introduce la contraseña que puedes encontrar ejecutando

   ```bash
   docker logs <container-id>
   ```

2. **Instalar Plugins Requeridos:**

3. **Crear un Pipeline:**
   - Pulsa en **New Item**.
   - Introduce un nombre, selecciona la opcion **Pipeline** y pulsa **OK**
   - Dirígete al apartado **Pipeline** dentro de la configuración, en **Definition** selecciona la opción **Pipeline script from SMC**, selecciona **GIT** como SMC y copia la URL de tu repositorio en el apartado **Repository URL**.
   - Especifica */main* como rama a construir y pulsa en **GUARDAR**

4. **Contruir el Pipeline:**
    - Pulsa en **Construir ahora**.


---
