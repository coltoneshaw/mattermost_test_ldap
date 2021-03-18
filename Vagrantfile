# -*- mode: ruby -*-
# vi: set ft=ruby :

MATTERMOST_VERSION = '5.32.1'
DATABASE_USER_PASS = 'really_secure_password'
DATABASE_ROOT_PASS = 'Password42!'


Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-20.04"
  config.vm.network "forwarded_port", guest: 8065, host: 8065
  config.vm.network "forwarded_port", guest: 5432, host: 15432
  config.vm.hostname = 'mattermost'

  setup_script = File.read('setup.sh')
 
  config.vm.provision :shell, inline: setup_script, args: [MATTERMOST_VERSION, DATABASE_USER_PASS, DATABASE_ROOT_PASS], run: 'once'
  
end
