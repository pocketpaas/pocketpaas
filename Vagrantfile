# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

PROVISION_MODE = ENV['PPS_MODE'] || "use"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.hostname = 'pocketpaas'
  config.vm.box = "ubuntudocker"
  # config.vm.box_url = "http://domain.com/path/to/above.box"

  # ports
  config.vm.network :forwarded_port, :host => 8080, :guest => 80, auto_correct: true

  config.vm.provider :virtualbox do |vb|
    # Don't boot with headless mode
    #vb.gui = true
  
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "768"]
  end

  if PROVISION_MODE == 'use'
    config.vm.provision :shell, :inline => <<USE_PROVISION
#!/bin/bash

sudo -H -u vagrant /bin/bash - << EOF
# TODO fill in for regular use
EOF
USE_PROVISION
  elsif PROVISION_MODE == 'dev'
    config.vm.provision :shell, :inline => <<DEV_PROVISION
#!/bin/bash

sudo -H -u vagrant /bin/bash - << EOF

# setup local::lib first
if [[ ! -d perl5 ]]; then

    echo "setting up local::lib"
    wget http://search.cpan.org/CPAN/authors/id/E/ET/ETHER/local-lib-1.008011.tar.gz
    tar -xzvf local-lib-1.008011.tar.gz

    cd local-lib-1.008011/
    perl Makefile.PL --bootstrap
    make test && make install
    echo 'eval \\$(perl -I\\$HOME/perl5/lib/perl5 -Mlocal::lib)' >>~/.bashrc
    cd -

    rm -rf local-lib-1.008011*
fi

eval \\$(perl -I\\$HOME/perl5/lib/perl5 -Mlocal::lib)

## then install cpanm
[[ \\$(type -P cpanm) ]] || curl -L http://cpanmin.us | perl - App::cpanminus || exit

## finally, carton
[[ \\$(type -P carton) ]] || cpanm Carton || exit

EOF
DEV_PROVISION
  end
end
