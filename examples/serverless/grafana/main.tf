locals {
  apis = ["iam.googleapis.com", "compute.googleapis.com", "run.googleapis.com", "apigateway.googleapis.com", "servicemanagement.googleapis.com", "servicecontrol.googleapis.com", "compute.googleapis.com", "iap.googleapis.com", "sql-component.googleapis.com", "cloudapis.googleapis.com", "containerregistry.googleapis.com", "sqladmin.googleapis.com"]
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_project_service" "project" {
  for_each = toset(local.apis)
  project = data.google_project.project.project_id
  service = each.key

  //disable_dependent_services = true
  disable_on_destroy = false
}

resource "null_resource" docker_image {

  provisioner "local-exec" {
    command = <<EOT
docker pull grafana/grafana:${var.grafana_version}
docker tag grafana/grafana:${var.grafana_version} gcr.io/${var.project_id}/grafana:${var.grafana_version}
docker push gcr.io/${var.project_id}/grafana:${var.grafana_version}
EOT
  }
}

resource "google_cloud_run_service" "default" {
  name     = "grafana"
  location = var.region
  project = var.project_id

  metadata {
    annotations = {
      "run.googleapis.com/ingress" : "internal-and-cloud-load-balancing"
    }
  }
  
  template {
    spec {
      containers {
        image ="gcr.io/${var.project_id}/grafana:${var.grafana_version}"
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
          value = "grafana"
        }
        env {
          name = "GF_DATABASE_PASSWORD"
          value = "${google_sql_user.user.password}"
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
      }
    }
    metadata {
      annotations ={
        "autoscaling.knative.dev/maxScale"         = "100" 
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

resource "google_sql_database_instance" "instance" {
  name   = "grafana-mysql"
  database_version = "MYSQL_8_0"
  region = var.region
  project = var.project_id

  settings {
    tier = "db-f1-micro"
  }

  deletion_protection  = "true"
}

resource "google_sql_database" "database" {
  name     = "grafana"
  project = var.project_id
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "user" {
  name     = "grafana"
  project = var.project_id
  instance = google_sql_database_instance.instance.name
  password = "changeme"
}