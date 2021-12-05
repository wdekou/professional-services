// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

terraform {
  required_providers {
    ipam = {
      version = "0.1"
      source = "ipam-pdk3svnohq-ew.a.run.app/ipam-autopilot/ipam"
    }
  }
}

provider "ipam" {
  url = "https://ipam-pdk3svnohq-ew.a.run.app"
}

resource "ipam_ip_range" "pod-ranges" {
  range_size = 22
  name = "gke services range"
}

output "range" {
  value = ipam_ip_range.pod-ranges.cidr
}