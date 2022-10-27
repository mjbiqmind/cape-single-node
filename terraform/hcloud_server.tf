## Deploys servers on Hetzner Cloud

resource "hcloud_ssh_key" "cape_lab_key" {
  count       = var.hcloud_enabled ? 1 : 0
  name       = "${var.deployment_name}_cape_lab_key"
  public_key = tls_private_key.gen_ssh_key.public_key_openssh
}

data "template_file" "hcloud_init" {
  count       = var.hcloud_enabled ? 1 : 0
  template = "${file("./assets/templates/user_data.tmpl")}"
  vars = {
      user = var.user
      ssh-pub = tls_private_key.gen_ssh_key.public_key_openssh
  }
}

resource "hcloud_server" "cape_lab_server" {
  count       = var.hcloud_enabled ? var.hcloud_server_count : 0
  name        = "${var.deployment_name}-cape-hcloud-${count.index}"
  image       = var.hcloud_os_type
  server_type = var.hcloud_server_type
  location    = var.hcloud_location
  ssh_keys    = [hcloud_ssh_key.cape_lab_key[0].id]
  labels = {
    type = "cape"
  }
  user_data = "${data.template_file.hcloud_init[0].rendered}"

  connection {
    type     = "ssh"
    user     = var.user
    private_key = tls_private_key.gen_ssh_key.private_key_pem
    host     = hcloud_server.cape_lab_server[0].ipv4_address
  }

  provisioner "file" {
  source      = "./assets/files/cabundle"
  destination = "/home/${var.user}/cabundle"
  }

  provisioner "file" {
  source      = "./assets/files/pk"
  destination = "/home/${var.user}/pk"
  }

  provisioner "remote-exec" {
    inline = [
      "git clone https://github.com/mjbiqmind/cape-single-node.git",
      "cp ~/cape-single-node/.vars.dist ~/cape-single-node/.vars",
      "sed -i 's/Secure-GH-PAT1/${var.gh_pat1}/g' ~/cape-single-node/.vars",
      "sed -i 's/cape.demo.fqdn/${var.cape_demo_fqdn}/g' ~/cape-single-node/.vars",
    ]
  }
}

