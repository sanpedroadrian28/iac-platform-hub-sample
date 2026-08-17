class nodeapp::install (
  String $version = $nodeapp::version,
) {
  archive { '/tmp/nodeapp.tar.gz':
    source       => "https://storageacct.blob.core.windows.net/releases/nodeapp-v${version}.tar.gz",
    extract      => true,
    extract_path => '/opt/nodeapp',
    creates      => "/opt/nodeapp/nodeapp-${version}",
    cleanup      => true,
  }

  package { ['nodejs', 'unattended-upgrades', 'auditd']:
    ensure => installed,
  }
}
