# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.hostname = 'pocketpaas'
  config.vm.box = "ppsdev_docker072"
  config.vm.box_url = "http://back.pckt.me/vagrant/ppsdev_docker072.box"

  # ports
  config.vm.network :forwarded_port, :host => 8080, :guest => 80, auto_correct: true

  config.vm.provider :virtualbox do |vb|
    # Don't boot with headless mode
    #vb.gui = true
  
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "768"]
  end
end
