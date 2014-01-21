Vagrant.configure("2") do |config|

  config.vm.hostname = "docker-0.7.2"

  config.vm.box = "docker-0.7.2"
  config.vm.box_url = "https://dl.dropboxusercontent.com/s/oqz573nhj341l6o/docker-0.7.2-base.box"
  config.vm.network :private_network, ip: "192.168.33.10"

  (49000..49900).each do |port|
    config.vm.network :forwarded_port, :host => port, :guest => port
  end
end
