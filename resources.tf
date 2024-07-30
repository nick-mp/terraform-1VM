resource "yandex_compute_instance" "default" {
  name        = "test"
  platform_id = "standard-v1"
  zone        = var.zone
  boot_disk {
    initialize_params {
      image_id = "fd8k2vlv3b3duv812ama"
      type     = "network-hdd"
      size     = 10
    }
  }
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 5
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
  }

  metadata = {
    user-data = file("./cloud-init.yaml")
  }
  scheduling_policy {
    preemptible = true
  }

  connection {
    type = "ssh"
    user = "nick"
    host = self.network_interface[0].nat_ip_address
  }

  # установка doker
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y ca-certificates curl",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc",
      "sudo chmod a+r /etc/apt/keyrings/docker.asc",
      "sudo echo \"deb [arch=$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "sudo groupadd docker",
      "sudo usermod -aG docker $USER",
      "sudo docker run --name my-mysql -e MYSQL_ROOT_PASSWORD=${random_password.mysql_root_password.result} -e MYSQL_PASSWORD=${random_password.mysql_name.result} -e MYSQL_USER=wordpress -e MYSQL_DATABASE=wordpress -d mysql:8.0"
    ]
  }

}

resource "random_password" "mysql_name" {
  length = 12
}

resource "random_password" "mysql_root_password" {
  length = 24
}

resource "yandex_vpc_network" "network" {}

resource "yandex_vpc_subnet" "subnet" {
  zone           = var.zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.1.0/24"]
}

