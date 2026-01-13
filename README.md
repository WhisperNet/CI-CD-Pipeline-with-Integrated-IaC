# CI/CD Pipeline with Integrated Infrastructure as Code

A complete end-to-end CI/CD pipeline that demonstrates how to build, test, and deploy a Java application to AWS infrastructure that is provisioned on-demand using Terraform.

## Overview

This project showcases the integration of several DevOps practices:

- **Continuous Integration**: Automated testing and building with Jenkins
- **Continuous Deployment**: Automated deployment to cloud infrastructure
- **Infrastructure as Code (IaC)**: AWS resources provisioned via Terraform
- **Containerization**: Application packaged and deployed as Docker containers

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CI/CD PIPELINE FLOW                            │
└─────────────────────────────────────────────────────────────────────────────┘

  ┌──────────┐     ┌─────────────────────────────────────────────────────┐
  │  GitHub  │────▶│                    JENKINS                          │
  │   Repo   │     │  ┌──────┐  ┌─────────┐  ┌───────┐  ┌─────────────┐  │
  └──────────┘     │  │ Test │─▶│ Version │─▶│ Build │─▶│ Build Image │  │
                   │  └──────┘  │Increment│  │  JAR  │  └──────┬──────┘  │
                   │            └─────────┘  └───────┘         │         │
                   └───────────────────────────────────────────┼─────────┘
                                                               │
                   ┌───────────────────────────────────────────▼─────────┐
                   │                  DOCKER HUB                         │
                   │              (Image Registry)                       │
                   └───────────────────────────────────────────┬─────────┘
                                                               │
  ┌────────────────────────────────────────────────────────────▼─────────┐
  │                         AWS INFRASTRUCTURE                           │
  │  ┌─────────────────────────────────────────────────────────────────┐ │
  │  │                        VPC (10.0.0.0/16)                        │ │
  │  │  ┌───────────────────────────────────────────────────────────┐  │ │
  │  │  │                  Subnet (10.0.10.0/24)                     │  │ │
  │  │  │  ┌─────────────────────────────────────────────────────┐  │  │ │
  │  │  │  │              EC2 Instance (Amazon Linux)            │  │  │ │
  │  │  │  │  ┌─────────────────┐    ┌─────────────────────────┐ │  │  │ │
  │  │  │  │  │  Java App       │    │  PostgreSQL             │ │  │  │ │
  │  │  │  │  │  (Port 8080)    │    │  (Port 5432)            │ │  │  │ │
  │  │  │  │  └─────────────────┘    └─────────────────────────┘ │  │  │ │
  │  │  │  │              Docker Compose                         │  │  │ │
  │  │  │  └─────────────────────────────────────────────────────┘  │  │ │
  │  │  └───────────────────────────────────────────────────────────┘  │ │
  │  └─────────────────────────────────────────────────────────────────┘ │
  └──────────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Category         | Technology                    |
| ---------------- | ----------------------------- |
| Application      | Java 8, Spring Boot 2.3.x     |
| Build Tool       | Maven 3.9.x                   |
| CI/CD            | Jenkins (with Shared Library) |
| Containerization | Docker, Docker Compose        |
| Infrastructure   | Terraform, AWS (VPC, EC2)     |
| Image Registry   | Docker Hub                    |

---

## Project Structure

```
├── src/                          # Application source code
│   ├── main/
│   │   ├── java/com/example/     # Java application files
│   │   │   └── Application.java  # Spring Boot entry point
│   │   └── resources/static/     # Static web resources
│   │       └── index.html        # Simple frontend
│   └── test/java/                # Unit tests
│       └── AppTest.java          # JUnit test cases
├── terraform/                    # Infrastructure as Code
│   ├── main.tf                   # AWS resource definitions
│   ├── varibales.tf              # Terraform variables
│   └── entry-script.sh           # EC2 user data script
├── Jenkinsfile                   # CI/CD pipeline definition
├── Dockerfile                    # Container image definition
├── docker-compose.yaml           # Multi-container orchestration
├── server-cmds.sh                # Deployment commands for EC2
└── pom.xml                       # Maven build configuration
```

---

## Pipeline Stages Explained

The Jenkins pipeline executes the following stages sequentially:

```
┌────────┐   ┌───────────┐   ┌───────────┐   ┌────────────┐   ┌───────────┐   ┌────────┐
│  Test  │──▶│  Version  │──▶│  Build    │──▶│  Build &   │──▶│ Provision │──▶│ Deploy │
│        │   │ Increment │   │   JAR     │   │ Push Image │   │   Infra   │   │        │
└────────┘   └───────────┘   └───────────┘   └────────────┘   └───────────┘   └────────┘
```

### 1. Test

Runs Maven tests to ensure code quality before proceeding.

```bash
mvn test
```

### 2. Version Increment

Automatically increments the application version in `pom.xml` using a shared library function. This ensures each build produces a uniquely versioned artifact.

### 3. Build JAR

Compiles the Java application and packages it into an executable JAR file.

### 4. Build & Push Docker Image

- Builds a Docker image with the JAR file
- Tags it with the incremented version
- Pushes to Docker Hub registry

### 5. Provision Infrastructure

Uses Terraform to create AWS infrastructure on-demand:

- VPC with custom CIDR block
- Public subnet
- Internet Gateway
- Security Groups (SSH + Application ports)
- EC2 instance with Docker pre-installed

### 6. Deploy

- Waits for EC2 instance initialization (90 seconds)
- Copies deployment scripts via SSH
- Pulls Docker image and starts containers using Docker Compose

---

## Component Deep Dive

### Application (`src/main/java`)

A minimal Spring Boot application that serves a simple web page:

```java
@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

**Why Spring Boot?** It provides a production-ready framework with minimal configuration, making it ideal for demonstrating DevOps pipelines without complex application setup.

---

### Dockerfile

```dockerfile
FROM amazoncorretto:8-alpine3.17-jre
EXPOSE 8080
COPY ./target/java-maven-app-*.jar /usr/app/
WORKDIR /usr/app
CMD java -jar java-maven-app-*.jar
```

**Key Points:**

- Uses Amazon Corretto (AWS-optimized JRE) for compatibility with AWS deployments
- Alpine-based image for smaller footprint
- Copies the built JAR from Maven's target directory
- Exposes port 8080 for the web application

---

### Docker Compose (`docker-compose.yaml`)

```yaml
services:
  java-maven-app:
    image: ${IMAGE} # Dynamically set via environment variable
    ports:
      - 8080:8080
  postgres:
    image: postgres:16
    ports:
      - 5432:5432
```

**Why Docker Compose?** It allows defining multi-container applications. Here it runs:

1. The Java application
2. A PostgreSQL database (for potential future use)

---

### Terraform Configuration (`terraform/`)

#### `main.tf` - Infrastructure Resources

| Resource                     | Purpose                             |
| ---------------------------- | ----------------------------------- |
| `aws_vpc`                    | Isolated network environment        |
| `aws_subnet`                 | Network segment within VPC          |
| `aws_internet_gateway`       | Enables internet access             |
| `aws_default_route_table`    | Routes traffic to internet gateway  |
| `aws_default_security_group` | Firewall rules (SSH: 22, App: 8000) |
| `aws_instance`               | EC2 server running the application  |

#### `entry-script.sh` - EC2 Bootstrap

```bash
#!/bin/bash
sudo yum update -y && sudo yum install -y docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
# Install docker-compose
sudo curl -SL "...docker-compose..." -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

This script runs automatically when the EC2 instance launches, installing Docker and Docker Compose.

---

### Jenkinsfile

The pipeline leverages a **Jenkins Shared Library** for reusable functions:

```groovy
library identifier: 'jenkins-shared-library-master@main', retriever: modernSCM([...])
```

**Shared Library Functions Used:**
| Function | Purpose |
|----------|---------|
| `incrementVersionMvn()` | Bumps version in pom.xml |
| `buildJar()` | Runs Maven build |
| `buildImage()` | Creates Docker image |
| `dockerLogin()` | Authenticates with Docker Hub |
| `dockerPush()` | Pushes image to registry |

**Why Shared Libraries?** They promote code reuse across multiple Jenkins pipelines and keep the Jenkinsfile clean and maintainable.

---

### Deployment Script (`server-cmds.sh`)

```bash
#!/usr/bin/env bash
export IMAGE=${IMAGE:-$1}
export DOCKER_USER=${DOCKER_USER:-$2}
export DOCKER_PWD=${DOCKER_PWD:-$3}

echo "$DOCKER_PWD" | docker login -u "$DOCKER_USER" --password-stdin
docker-compose -f docker-compose.yaml up --detach
```

This script runs on the EC2 instance to:

1. Authenticate with Docker Hub
2. Pull and start the containers in detached mode

---

## Prerequisites

Before using this pipeline, ensure you have:

### Jenkins Setup

- [ ] Jenkins server with Maven tool configured (`maven-3.9.11`)
- [ ] Jenkins Shared Library configured
- [ ] Credentials configured:
  - `docker-hub` - Docker Hub username/password
  - `aws_access_key_id` - AWS access key
  - `aws_secret_access_key` - AWS secret key
  - `server-ssh-key` - SSH key for EC2 access

### AWS Setup

- [ ] AWS account with appropriate IAM permissions
- [ ] S3 bucket for Terraform state (`tf-practice-remote-backend`)
- [ ] EC2 key pair created (`tf-cicd-key`)

### Local Development

- [ ] Java 8 JDK
- [ ] Maven 3.x
- [ ] Docker
- [ ] Terraform

---

## How to Run Locally

### Build the application

```bash
mvn clean package
```

### Run tests

```bash
mvn test
```

### Build Docker image

```bash
docker build -t java-maven-app .
```

### Run with Docker Compose

```bash
export IMAGE=java-maven-app
docker-compose up
```

Access the application at `http://localhost:8080`

---

## Key DevOps Concepts Demonstrated

| Concept                      | Implementation                               |
| ---------------------------- | -------------------------------------------- |
| **CI/CD Pipeline**           | Jenkins multi-stage pipeline                 |
| **Infrastructure as Code**   | Terraform managing AWS resources             |
| **Immutable Infrastructure** | New EC2 instance per deployment              |
| **Configuration Management** | Terraform variables & environment variables  |
| **Containerization**         | Docker packaging of application              |
| **Container Orchestration**  | Docker Compose for multi-container setup     |
| **Version Control**          | Git-based workflow with automated versioning |
| **Secrets Management**       | Jenkins credentials store                    |
| **Remote State**             | Terraform S3 backend for state management    |

---

## Security Considerations

⚠️ **Note:** This is a learning/demo project. For production use, consider:

- Use private subnets with NAT gateway
- Implement HTTPS with SSL certificates
- Use AWS Secrets Manager for sensitive data
- Enable VPC flow logs
- Implement proper IAM roles instead of access keys
- Add application load balancer for high availability

---

## Learning Resources

- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Spring Boot Documentation](https://spring.io/projects/spring-boot)

---
