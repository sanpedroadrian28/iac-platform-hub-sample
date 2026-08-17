class nodeapp::service {
  file { '/etc/systemd/system/nodeapp.service':
    ensure => file,
    source => 'puppet:///modules/nodeapp/nodeapp.service',
    notify => Service['nodeapp'],
  }

  service { 'nodeapp':
    ensure => running,
    enable => true,
  }
}
