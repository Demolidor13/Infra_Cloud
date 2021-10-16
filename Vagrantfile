$script_mysql = <<-SCRIPT
  apt-get update && \
  apt-get install -y mysql-server-5.7 && \
  mysql < /vagrant/mysql/script/user.sql && \
  mysql < /vagrant/mysql/script/schema.sql && \
  mysql < /vagrant/mysql/script/data.sql && \
  cat /vagrant/mysql/mysqld.cnf > /etc/mysql/mysql.conf.d/mysqld.cnf && \
  service mysql restart
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"

  config.vm.define "mysql" do |mysql|
    mysql.vm.network "private_network", ip: "10.80.2.12"
    mysql.vm.network "forwarded_port", guest: 3036, host: 3036

    mysql.vm.provider "virtualbox" do |vb|
      vb.name = "mysql"
    end

    mysql.vm.provision "shell", inline: $script_mysql
  end

end