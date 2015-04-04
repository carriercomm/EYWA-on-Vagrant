# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  #config.vm.boot_timeout = 600
  #config.vm.provider :virtualbox do |vb|
  #  vb.gui = true
  #end
  #config.ssh.forward_x11 = true

  master_ip = "192.168.33.11"

  oneadmin_pw = "passw0rd"
  sustone_listen_addr = "0.0.0.0"
  sustone_listen_port = "9869"

  config.vm.box = "trusty64"
  config.vm.box_url = "https://onedrive.live.com/download?resid=28F8F701DC29E4B9!247&authkey=!AC-zzAlAl6UhvGo&ithint=file%2cbox"

  config.vm.define "master" do |master|
    my_ip = "#{master_ip}"
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: "#{master_ip}", auto_config: false
    master.vm.network "forwarded_port", guest: "#{sustone_listen_port}", host: "#{sustone_listen_port}"
    #master.vm.network "forwarded_port", guest: 5050, host: 5050
    #master.vm.network "forwarded_port", guest: 4400, host: 4400
    master.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--cpus", "2"]
      vb.customize ["modifyvm", :id, "--memory", "2048"]
    end
    master.vm.provision "shell", path: "resources/puppet/scripts/upgrade-puppet.sh"
    master.vm.provision "shell", path: "resources/puppet/scripts/bootstrap.sh"
    master.vm.provision "puppet" do |puppet|
      puppet.working_directory = "/vagrant/resources/puppet"
      puppet.hiera_config_path = "resources/puppet/hiera.yaml"
      puppet.manifests_path = "resources/puppet/manifests"
      puppet.manifest_file  = "base.pp"
      puppet.options = "--verbose"
    end
    master.vm.provision "puppet" do |puppet|
      puppet.working_directory = "/vagrant/resources/puppet"
      puppet.hiera_config_path = "resources/puppet/hiera.yaml"
      puppet.manifests_path = "resources/puppet/manifests"
      puppet.manifest_file  = "common.pp"
      puppet.options = "--verbose"
    end
    master.vm.provision "puppet" do |puppet|
      puppet.working_directory = "/vagrant/resources/puppet"
      puppet.hiera_config_path = "resources/puppet/hiera.yaml"
      puppet.manifests_path = "resources/puppet/manifests"
      puppet.manifest_file  = "master.pp"
      puppet.facter = {
        "master_ip" => "#{master_ip}",
        "oneadmin_pw" => "#{oneadmin_pw}",
        "sustone_listen_addr" => "#{sustone_listen_addr}",
        "sustone_listen_port" => "#{sustone_listen_port}",
      }
      puppet.options = "--verbose"
    end
    master.vm.provision "puppet" do |puppet|
      puppet.working_directory = "/vagrant/resources/puppet"
      puppet.hiera_config_path = "resources/puppet/hiera.yaml"
      puppet.manifests_path = "resources/puppet/manifests"
      puppet.manifest_file  = "slave.pp"
      puppet.facter = {
        "master_ip" => "#{master_ip}",
        "my_ip" => "#{my_ip}",
      }
      puppet.options = "--verbose"
    end
  end

  #num_slave_nodes = 2 ## (WARNING) Sync with hiera file -> "resources/puppet/hieradata/hosts.json"
  num_slave_nodes = 1 ## (WARNING) Sync with hiera file -> "resources/puppet/hieradata/hosts.json"
  slave_ip_base = "192.168.33."
  slave_ips = num_slave_nodes.times.collect { |n| slave_ip_base + "#{n+12}" }
  
  num_slave_nodes.times do |n|
    config.vm.define "slave-#{n+1}" do |slave|
      slave_ip = slave_ips[n]
      my_ip = "#{slave_ip}"
      slave.vm.hostname = "slave-#{n+1}"
      slave.vm.network "private_network", ip: "#{slave_ip}"
      slave.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--cpus", "2"]
        vb.customize ["modifyvm", :id, "--memory", "2048"]
      end
      slave.vm.provision "shell", path: "resources/puppet/scripts/upgrade-puppet.sh"
      slave.vm.provision "shell", path: "resources/puppet/scripts/bootstrap.sh"
      slave.vm.provision "puppet" do |puppet|
        puppet.working_directory = "/vagrant/resources/puppet"
        puppet.hiera_config_path = "resources/puppet/hiera.yaml"
        puppet.manifests_path = "resources/puppet/manifests"
        puppet.manifest_file  = "base.pp"
        puppet.options = "--verbose"
      end
      slave.vm.provision "puppet" do |puppet|
        puppet.working_directory = "/vagrant/resources/puppet"
        puppet.hiera_config_path = "resources/puppet/hiera.yaml"
        puppet.manifests_path = "resources/puppet/manifests"
        puppet.manifest_file  = "common.pp"
        puppet.options = "--verbose"
      end
      slave.vm.provision "puppet" do |puppet|
        puppet.working_directory = "/vagrant/resources/puppet"
        puppet.hiera_config_path = "resources/puppet/hiera.yaml"
        puppet.manifests_path = "resources/puppet/manifests"
        puppet.manifest_file  = "slave.pp"
        puppet.facter = {
          "master_ip" => "#{master_ip}",
          "my_ip" => "#{my_ip}",
        }
        puppet.options = "--verbose"
      end
    end
  end
end