resource "tls_private_key" "key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "request" {
  private_key_pem = tls_private_key.key.private_key_pem

  subject {
    common_name  = var.mongodb_server.domain
    organization = var.server_certificate.organization
  }

  ip_addresses = ["127.0.0.1"]
  dns_names = [var.mongodb_server.domain]
}

resource "tls_locally_signed_cert" "certificate" {
  cert_request_pem   = tls_cert_request.request.cert_request_pem
  ca_private_key_pem = var.ca.key
  ca_cert_pem        = var.ca.certificate

  validity_period_hours = var.server_certificate.validity_period
  early_renewal_hours = var.server_certificate.early_renewal_period

  allowed_uses = [
    "server_auth",
    "client_auth",
  ]

  is_ca_certificate = false
}