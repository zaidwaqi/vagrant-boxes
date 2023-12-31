variable "iso_url" {
  default = "C:\\ISO\\CentOS-Stream-8-x86_64-latest-dvd1.iso"
}

variable "iso_checksum" {
  # Get-FileHash <iso_url> -Algorithm SHA256
  default = "5ea6d875f8ba256f4eac48957c075fcc8fee2b200fd69e3a03000c741306d756"
}

source "virtualbox-iso" "centos8s" {
  # default command is
  # linuxefi /images/pxeboot/vmlinuz inst.stage2=hd:LABEL=CentOS-Stream-8-BaseOS-x86_64 rd.live.check quiet
  # <end> will go to the end of line
  # <bs> x5 will backspace 5 times, removing "quiet" at the end
  # <bs> x19 will backspace 19 times, removing "rd.live.check quiet"
  # remove rd.live.check i.e. <bs> x19 to skip media check, making installation faster 
  boot_command = ["e<down><down><end><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<leftCtrlOn>x<leftCtrlOff>"]
  boot_wait             = "10s"
  disk_size             = "10000"
  guest_os_type         = "RedHat_64"
  headless              = false
  http_directory        = "http"
  iso_url               = var.iso_url
  iso_checksum          = var.iso_checksum
  output_directory      = "output-centos8s"
  shutdown_command      = "echo 'vagrant'|sudo -S /sbin/halt -h -p"
  ssh_username          = "vagrant"
  ssh_password          = "vagrant"
  ssh_wait_timeout      = "10000s"
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--firmware", "efi"],
    ["modifyvm", "{{.Name}}", "--memory", "4096"],
    ["modifyvm", "{{.Name}}", "--cpus", "2"],
    ["modifyvm", "{{.Name}}", "--nat-localhostreachable1", "on"]
  ]
}

build {
  sources = ["virtualbox-iso.centos8s"]

  provisioner "shell" {
    execute_command = "echo 'vagrant'|{{.Vars}} sudo -S -E bash '{{.Path}}'"

    # insecure public key at https://github.com/hashicorp/vagrant/blob/master/keys/vagrant.pub
    inline = [
      "mkdir -p /home/vagrant/.ssh",
      "chmod 700 /home/vagrant/.ssh",
      "echo \"ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key\" > /home/vagrant/.ssh/authorized_keys",
      "chmod 600 /home/vagrant/.ssh/authorized_keys",
      "chown -R vagrant:vagrant /home/vagrant"
    ]
  }

  post-processor "vagrant" {
    output = "centos8s-virtualbox.box"
  }

  post-processor "shell-local" {
    inline = [
      "pwsh .\\upload.ps1",
      "pwsh .\\publish.ps1"
    ]
  }
}
