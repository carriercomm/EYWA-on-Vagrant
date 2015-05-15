####################################################

include 'apt'

### Export Env: Global %PATH for "Exec"
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin" ] }

package { "arping":
    ensure   => installed,
}

exec { "Add apt-key":
    command  => "wget -q -O- http://downloads.opennebula.org/repo/Ubuntu/repo.key | apt-key add -",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    #require => File[""],
}

if $opennebula_version == "4.6" {
    $one_repo = "deb http://downloads.opennebula.org/repo/Ubuntu/14.04 stable opennebula"
} else {
    $one_repo = "deb http://downloads.opennebula.org/repo/4.10/Ubuntu/14.04/ stable opennebula"
}

file { "Add sources.list":
    path    => "/etc/apt/sources.list.d/opennebula.list",
    ensure  => present,
    owner    => "root",
    group    => "root",
    #content => "deb http://downloads.opennebula.org/repo/Ubuntu/14.04 stable opennebula", ## OpenNebula 4.6.x
    #content => "deb http://downloads.opennebula.org/repo/4.10/Ubuntu/14.04/ stable opennebula",	## OpenNebula 4.10.x
    content => "$one_repo",
    require => Exec["Add apt-key"],
}

exec { "Apt-get Update":
    command  => "apt-get update",
    user     => "root",
    timeout  => "0",
    logoutput => true,
    require => File["Add sources.list"],
}

#exec { "Disable/Remove apparmor":
#    command  => "service apparmor stop && update-rc.d -f apparmor remove && apt-get remove -y apparmor apparmor-utils",
#    user     => "root",
#    timeout  => "0",
#    logoutput => true,
#    onlyif   => "service apparmor status",
#    require  => Exec["Apt-get Update"],
#}

