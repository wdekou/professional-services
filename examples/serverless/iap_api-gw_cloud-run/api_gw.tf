/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  api_gw_neg = "api-gw-neg"
}


resource "google_api_gateway_gateway" "api_gw" {
  provider   = google-beta
  api_config = google_api_gateway_api_config.api_gw.id
  gateway_id = "api-gw"
  region     = var.region
  project    = var.project_id

  provisioner "local-exec" {
    command = "gcloud beta compute network-endpoint-groups create ${local.api_gw_neg} --project=${var.project_id} --region=${var.region} --network-endpoint-type=serverless --serverless-deployment-platform=apigateway.googleapis.com  --serverless-deployment-resource=api-gw"
  }

  depends_on = [
    google_project_service.project
  ]
}

resource "google_api_gateway_api" "api_gw" {
  provider = google-beta
  api_id   = "api-gw"

  project = var.project_id
  depends_on = [
    google_project_service.project
  ]
}

resource "google_api_gateway_api_config" "api_gw" {
  provider      = google-beta
  api           = google_api_gateway_api.api_gw.api_id
  api_config_id = "config"
  project       = var.project_id

  openapi_documents {
    document {
      path = "spec.yaml"
      contents = base64encode(templatefile("openapi.yaml", {
        APP_URL = google_cloud_run_service.default.status[0].url
      }))
    }
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    google_project_service.project
  ]
}
