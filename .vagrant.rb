Vagrant.configure(2) do |config|
  config.vm.provision "shell", inline: <<-SHELL
     sudo yum install -y gcc
     sudo yum install -y openssl-devel
  SHELL
end
