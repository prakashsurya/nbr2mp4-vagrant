# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty32"

  config.vm.provider "virtualbox" do |vb|
    #
    # Quoting: http://www.virtualbox.org/manual/ch03.html#settings-processor
    #
    #     Enabling the I/O APIC is required for 64-bit guest operating
    #     systems, especially Windows Vista; it is also required if you
    #     want to use more than one virtual CPU in a virtual machine.
    #
    vb.customize ["modifyvm", :id, "--ioapic", "on"]

    #
    # The conversion utility appears to use a lot of CPU, so lets give
    # it some more resources to work with.
    #
    vb.memory = "2048"
    vb.cpus = "2"
  end

  config.vm.provision "shell", path: "scripts/update-pkgs.sh"
  config.vm.provision "shell", path: "scripts/vagrant-autologin.bash"
  config.vm.provision "shell", path: "scripts/nbr2mp4.bash", privileged: false

end
