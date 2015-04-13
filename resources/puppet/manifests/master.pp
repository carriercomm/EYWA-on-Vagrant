####################################################

include 'apt'

### Export Env: Global %PATH for "Exec"
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ] }

$oneadmin_home = "/var/lib/one"

package { "nfs-kernel-server":
    ensure   => installed,
}

package { "opennebula":
    ensure   => installed,
}

package { "virt-manager":
    ensure   => installed,
    require  => Package["opennebula"],
}

package { "opennebula-sunstone":
    ensure   => installed,
}

package { "mysql-server":
    ensure   => installed,
}

service { "nfs-kernel-server":
    ensure  => "running",
    enable  => "true",
    require => Package["nfs-kernel-server"],
}

service { "opennebula":
    ensure  => "running",
    enable  => "true",
    require => Package["opennebula"],
}

service { "opennebula-sunstone":
    ensure  => "running",
    enable  => "true",
    require => Package["opennebula-sunstone"],
}

service { "mysql":
    ensure  => "running",
    enable  => "true",
    require => Package["mysql-server"],
}

exec { "Set MySQL root Password":
    command  => "mysqladmin -uroot password ${oneadmin_pw}",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    onlyif   => "test ! -f /root/.installed.mysql",
    require  => [Package["opennebula"], Package["mysql-server"]],
}

exec { "Create opennebula Database":
    command  => "mysql -uroot -p${oneadmin_pw} -e 'create database opennebula' && touch /root/.installed.mysql",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    onlyif   => "test ! -f /root/.installed.mysql",
    notify   => Service["opennebula"],
    require  => Exec["Set MySQL root Password"],
}

file { "Config sunstone.conf":
    path    => "/etc/one/sunstone-server.conf",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    content => template("/vagrant/resources/puppet/templates/sunstone-server.conf.erb"),
    notify  => Service["opennebula-sunstone"],
    require => Package["opennebula-sunstone"],
}

file { "Export NFS":
    path    => "/etc/exports",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    source  => "/vagrant/resources/puppet/files/nfs-exports",
    notify  => Service["nfs-kernel-server"],
    require => Package["nfs-kernel-server"],
}

file { "Put .ssh DIR":
    path     => "${oneadmin_home}/.ssh",
    owner    => "oneadmin",
    group    => "oneadmin",
    mode     => 0644,
    source   => "/vagrant/resources/puppet/files/.ssh",
    ensure   => directory,
    replace  => true,
    recurse  => true,
    require  => File["Export NFS"],
}

exec { "Permission Private SSH-key":
    command  => "chown oneadmin:oneadmin ${oneadmin_home}/.ssh/* && chmod 644 ${oneadmin_home}/.ssh/* && chmod 600 ${oneadmin_home}/.ssh/id_rsa",
    cwd      => "${oneadmin_home}",
    user     => "oneadmin",
    timeout  => "0",
    logoutput => true,
    require  => File["Put .ssh DIR"],
}

file { "Config oned.conf":
    path    => "/etc/one/oned.conf",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0644,
    content => template("/vagrant/resources/puppet/templates/oned.conf.erb"),
    notify  => Service["opennebula"],
    require => [Exec["Create opennebula Database"], Exec["Permission Private SSH-key"]],
}

exec { "Restart OpenNebula Service":
    command  => "service opennebula restart",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => File["Config oned.conf"],
}

file { "Put set-oneadmin-pw.sh":
    path    => "/home/vagrant/set-oneadmin-pw.sh",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0744,
    content => template("/vagrant/resources/puppet/templates/set-oneadmin-pw.sh.erb"),
    require  => Exec["Restart OpenNebula Service"],
}

exec { "Run set-oneadmin-pw.sh":
    command  => "/home/vagrant/set-oneadmin-pw.sh",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => File["Put set-oneadmin-pw.sh"],
}

exec { "=== Starting Download Template-Image ===":
    command  => "echo '=== Starting... Download Template-Image... Waiting.... ==='",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => Exec["Run set-oneadmin-pw.sh"],
}

exec { "Download Ubuntu-14.04.qcow2.gz":
    command  => "wget 'https://onedrive.live.com/download?resid=28f8f701dc29e4b9%2110218' -O /usr/local/src/Ubuntu-14.04.qcow2.gz",
    creates  => "/usr/local/src/Ubuntu-14.04.qcow2.gz",
    user     => "root",
    timeout  => "0",
    #logoutput => true,
    require  => Exec["=== Starting Download Template-Image ==="],
}

file { "Put one-test-network.tmpl":
    path    => "/home/vagrant/one-test-network.tmpl",
    ensure  => present,
    owner   => "root",
    group   => "oneadmin",
    mode    => 0744,
    source => "/vagrant/resources/puppet/files/one-test-network.tmpl",
    require  => Exec["Download Ubuntu-14.04.qcow2.gz"],
}

file { "Put default.template":
    path    => "/home/vagrant/default.template",
    ensure  => present,
    owner   => "root",
    group   => "oneadmin",
    mode    => 0744,
    content => template("/vagrant/resources/puppet/templates/default.template.erb"),
    require  => File["Put one-test-network.tmpl"],
}

exec { "Set SSH_PUB_KEY in default.template":
    command  => "sed -i \"s|@@__SSH_PUB_KEY__@@|$(cat /var/lib/one/.ssh/id_rsa.pub)|g\" /home/vagrant/default.template",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => File["Put default.template"],
}

file { "Put config-one-env.sh":
    path    => "/home/vagrant/config-one-env.sh",
    ensure  => present,
    owner   => "root",
    group   => "root",
    mode    => 0744,
    content => template("/vagrant/resources/puppet/templates/config-one-env.sh.erb"),
    require  => Exec["Set SSH_PUB_KEY in default.template"],
}

exec { "Run config-one-env.sh":
    command  => "/home/vagrant/config-one-env.sh",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require  => File["Put config-one-env.sh"],
}

