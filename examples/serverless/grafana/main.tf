locals {
  apis = ["iam.googleapis.com", "compute.googleapis.com", "run.googleapis.com", "apigateway.googleapis.com", "servicemanagement.googleapis.com", "servicecontrol.googleapis.com", "compute.googleapis.com", "iap.googleapis.com", "sql-component.googleapis.com", "cloudapis.googleapis.com", "containerregistry.googleapis.com", "sqladmin.googleapis.com", "secretmanager.googleapis.com", "artifactregistry.googleapis.com"]
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_artifact_registry_repository" "grafana" {
  provider = google-beta

  location = var.region
  project = data.google_project.project.project_id
  repository_id = "grafana"
  description = "Docker repository for Grafana"
  format = "DOCKER"

  depends_on = [
    google_project_service.project
  ]
}

resource "null_resource" docker_image {

  provisioner "local-exec" {
    command = <<EOT
docker pull grafana/grafana:${var.grafana_version}
docker tag grafana/grafana:${var.grafana_version} ${var.region}-docker.pkg.dev/${var.project_id}/grafana/grafana:${var.grafana_version}
docker push ${var.region}-docker.pkg.dev/${var.project_id}/grafana/grafana:${var.grafana_version}
EOT
  }
}

resource "google_project_service" "project" {
  for_each = toset(local.apis)
  project = data.google_project.project.project_id
  service = each.key

  //disable_dependent_services = true
  disable_on_destroy = false
}

resource "google_cloud_run_service" "default" {
  provider = google-beta
  name     = "grafana"
  location = var.region
  project = data.google_project.project.project_id

  metadata {
    annotations = {
      "run.googleapis.com/ingress" : "internal-and-cloud-load-balancing"
    }
  }
  
  template {
    spec {
      containers {
        image ="${var.region}-docker.pkg.dev/${data.google_project.project.project_id}/grafana/grafana:${var.grafana_version}"
        ports {
          name = "http1"
          container_port = 8080
        }
        env {
          name = "GF_SERVER_HTTP_PORT"
          value = "8080"
        }
        env {
          name = "GF_DATABASE_TYPE"
          value = "mysql"
        }
        env {
          name = "GF_DATABASE_USER"
          value = "${google_sql_user.user.name}"
        }
        env {
          name = "GF_DATABASE_NAME"
          value = google_sql_database.database.name
        }
        env {
          name = "GF_DATABASE_PASSWORD"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.secret.secret_id
              key = "1"
            }
          }
        }
        env {
          name = "GF_DATABASE_HOST"
          value = "/cloudsql/${google_sql_database_instance.instance.connection_name}"
        }
        env {
          name = "GF_DATABASE_HOST"
          value = "/cloudsql/${google_sql_database_instance.instance.connection_name}"
        }
        env {
          name = "GF_DATABASE_TYPE"
          value = "mysql"
        }
        env {
          name = "GF_AUTH_JWT_ENABLED"
          value = "true"
        }
        env {
          name = "GF_AUTH_JWT_HEADER_NAME"
          value = "X-Goog-Iap-Jwt-Assertion"
        }
        env {
          name = "GF_AUTH_JWT_USERNAME_CLAIM"
          value = "email"
        }
        env {
          name = "GF_AUTH_JWT_EMAIL_CLAIM"
          value = "email"
        }
        env {
          name = "GF_AUTH_JWT_JWK_SET_URL"
          value = "https://www.gstatic.com/iap/verify/public_key-jwk"
        }
        env {
          name = "GF_AUTH_JWT_EXPECTED_CLAIMS"
          value = "{\"iss\": \"https://cloud.google.com/iap\"}"
        }
        env {
          name = "GF_AUTH_PROXY_ENABLED"
          value = "true"
        }
        env {
          name = "GF_AUTH_PROXY_HEADER_NAME"
          value = "X-Goog-Authenticated-User-Email"
        }
        env {
          name = "GF_AUTH_PROXY_HEADER_PROPERTY"
          value = "email"
        }
        env {
          name = "GF_AUTH_PROXY_AUTO_SIGN_UP"
          value = "true"
        }
        env {
          name = "GF_USERS_AUTO_ASSIGN_ORG_ROLE"
          value = "Admin" //Viewer,Editor,Admin
        }
        env {
          name = "GF_USERS_VIEWERS_CAN_EDIT"
          value = "true" // default false
        }
        env {
          name = "GF_USERS_EDITORS_CAN_ADMIN"
          value = "true" // default false
        }
      }
    }
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"      = "100" 
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.instance.connection_name
        "run.googleapis.com/client-name"        = "grafana"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.project,
    null_resource.docker_image,
    google_sql_database.database,
    google_sql_user.user
  ]

}
