# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.hostname = 'pocketpaas'
  config.vm.box = "ubuntudocker"
  # config.vm.box_url = "http://domain.com/path/to/above.box"

  # ports
  (49000..49100).each do |port|
    config.vm.network :forwarded_port, :host => port, :guest => port
  end
  config.vm.network :forwarded_port, :host => 8080, :guest => 80

  config.vm.provider :virtualbox do |vb|
    # Don't boot with headless mode
    #vb.gui = true
  
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "768"]
  end
end
