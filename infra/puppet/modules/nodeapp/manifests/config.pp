# @summary Renders app config and asserts no required key is missing for this environment.
class nodeapp::config (
  String $node_env                     = $nodeapp::node_env,
  Integer $port                        = $nodeapp::port,
  String $db_host                      = $nodeapp::db_host,
  String $db_name                      = $nodeapp::db_name,
  String $log_level                    = $nodeapp::log_level,
  String $session_secret_key_vault_ref = $nodeapp::session_secret_key_vault_ref,
  String $feature_flag_new_checkout    = $nodeapp::feature_flag_new_checkout,
  Array[String] $required_keys         = lookup('nodeapp::config::required_keys'),
) {

  $rendered_config = {
    'node_env'                      => $node_env,
    'port'                          => $port,
    'db_host'                       => $db_host,
    'db_name'                       => $db_name,
    'log_level'                     => $log_level,
    'session_secret_key_vault_ref'  => $session_secret_key_vault_ref,
    'feature_flag_new_checkout'     => $feature_flag_new_checkout,
  }

  # Fail loudly at compile time if any required key resolves to undef —
  # this is what prevents "missing in dev" from ever reaching a deployed node.
  $required_keys.each |String $key| {
    if !($key in $rendered_config) or $rendered_config[$key] == undef {
      fail("nodeapp::config: required key '${key}' is undefined for environment '${server_facts['environment']}' on ${trusted['certname']}")
    }
  }

  file { '/opt/nodeapp/.env':
    ensure  => file,
    owner   => 'nodeapp',
    group   => 'nodeapp',
    mode    => '0640',
    content => epp('nodeapp/nodeapp.env.epp', { 'config' => $rendered_config }),
    require => Class['nodeapp::install'],
    notify  => Class['nodeapp::service'],
  }
}
