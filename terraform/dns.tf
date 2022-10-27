resource "cloudflare_record" "cloudflare_demo_dns" {
  count  = "${var.dns_service == "cloudflare" && var.hcloud_server_count > 0 ? var.hcloud_server_count:0}"
  zone_id = var.cloudflare_zone_id
  name   = var.deployment_name
  value  = hcloud_server.cape_lab_server[0].ipv4_address
  type   = "A"
  ttl = 600
  depends_on = [hcloud_server.cape_lab_server]
}