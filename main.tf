variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "The Google Cloud Region"
  type        = string
}

variable "function_name" {
  description = "A unique name for the cloud function and related resources"
  type        = string
}

variable "spread_sheet_url" {
  description = "url of Google sheet"
  type        = string
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "cloudfunctions_api" {
  service = "cloudfunctions.googleapis.com"
}

resource "google_project_service" "secretmanager_api" {
  service = "secretmanager.googleapis.com"
}

resource "google_project_service" "sheets_api" {
  service = "sheets.googleapis.com"
}

resource "google_service_account" "cloud_function_account" {
  account_id   = "${var.function_name}-account"
  display_name = "${var.function_name} Service Account"
}

resource "google_secret_manager_secret" "service_account_key_secret" {
  secret_id   = "${var.function_name}-service-account-key"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
  depends_on = [google_project_service.secretmanager_api]
}

resource "google_service_account_key" "cloud_function_account_key" {
  service_account_id = google_service_account.cloud_function_account.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_secret_manager_secret_version" "service_account_key_secret_version" {
  secret      = google_secret_manager_secret.service_account_key_secret.id
  secret_data = base64decode(
    google_service_account_key.cloud_function_account_key.private_key
  )
}

// give default compute engine service account access to this secret
resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  secret_id = google_secret_manager_secret.service_account_key_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.project_id}@appspot.gserviceaccount.com"
}

resource "google_storage_bucket" "bucket" {
  name     = "${var.function_name}-bucket"
  location = var.region
  lifecycle_rule {
    condition {
      age = 1
      matches_prefix = ["cloudfunction-source-"] // Only apply the rule to objects with this prefix
    }
    action {
      type = "Delete"
    }
  }
}
data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/function_source.zip"
}

resource "google_storage_bucket_object" "archive" {
  name   = "cloudfunction-source-${data.archive_file.function_source.output_md5}.zip"
  bucket = google_storage_bucket.bucket.name
  source = data.archive_file.function_source.output_path
  depends_on = [
    data.archive_file.function_source
  ]
}

resource "google_cloudfunctions_function" "cloud_function" {
  name        = var.function_name
  description = "Appends data to a Google Sheet"
  runtime     = "python39"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  trigger_http          = true
  entry_point           = "sheets_append"

  environment_variables = {
    SPREADSHEET_URL = var.spread_sheet_url
  }

  secret_environment_variables {
    secret = google_secret_manager_secret.service_account_key_secret.secret_id
    key    = "SERVICE_ACCOUNT_JSON"
    #project_id = var.project_id
    version = "latest"
  }

  depends_on = [
    google_project_service.cloudfunctions_api,
    google_secret_manager_secret_version.service_account_key_secret_version
  ]
}

# IAM entry for all users to invoke the function (public access); terraform does not support     --allow-unauthenticated  as gcloud command does
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.cloud_function.project
  region         = google_cloudfunctions_function.cloud_function.region
  cloud_function = google_cloudfunctions_function.cloud_function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

output "service_account_email" {
  value = google_service_account.cloud_function_account.email
}