# @summary Installs, configures, and manages the Node.js application service.
class nodeapp (
  String $version,
  Integer $port,
  String $node_env,
  String $db_host,
  String $db_name,
  String $log_level,
  String $session_secret_key_vault_ref,
  String $feature_flag_new_checkout,
) {
  contain nodeapp::install
  contain nodeapp::config
  contain nodeapp::service

  Class['nodeapp::install']
  -> Class['nodeapp::config']
  ~> Class['nodeapp::service']
}
