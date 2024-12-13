provider "google" {
  credentials = file("${path.module}/gcp_project.json")
  project     = "deep-thought-440807-g3"
  region      = "asia-northeast3"
}

resource "tls_private_key" "gcp_private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "gcp_json_key" {
  content  = jsonencode({
    type                        = "service_account",
    project_id                  = "deep-thought-440807-g3",
    private_key_id              = tls_private_key.gcp_private_key.private_key_pem_sha1,
    private_key                 = tls_private_key.gcp_private_key.private_key_pem,
    client_email                = "635009463326-compute@developer.gserviceaccount.com",
    client_id                   = "107386325958695760709",
    auth_uri                    = "https://accounts.google.com/o/oauth2/auth",
    token_uri                   = "https://oauth2.googleapis.com/token",
    auth_provider_x509_cert_url = "https://www.googleapis.com/oauth2/v1/certs",
    client_x509_cert_url        = "https://www.googleapis.com/robot/v1/metadata/x509/635009463326-compute%40developer.gserviceaccount.com",
    universe_domain             = "googleapis.com"
  })
  filename = "${path.module}/gcp_project.json"
}

resource "google_compute_instance" "bastion_host" {
  name         = "bastion-host"
  machine_type = "e2-small"
  zone         = "asia-northeast3-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-2004-focal-v20230929"
      size  = 10
      type  = "pd-standard"
    }
  }

  metadata_startup_script = templatefile("${path.module}/user_data_gcp_bastion.sh", {
    private_key = file("${path.module}/gcp_project.json")
  })

  network_interface {
    network    = "default"
    access_config {}
  }

  tags = ["bastion"]

  service_account {
    email  = "635009463326-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
