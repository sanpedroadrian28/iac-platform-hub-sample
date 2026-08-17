# Profile: how the Node.js app is configured on this class of node.
class profile::nodeapp {
  class { 'nodeapp':
    version                     => lookup('nodeapp::install::version'),
    port                        => lookup('nodeapp::config::port'),
    node_env                    => lookup('nodeapp::config::node_env'),
    db_host                     => lookup('nodeapp::config::db_host'),
    db_name                     => lookup('nodeapp::config::db_name'),
    log_level                   => lookup('nodeapp::config::log_level'),
    session_secret_key_vault_ref => lookup('nodeapp::config::session_secret_key_vault_ref'),
    feature_flag_new_checkout   => lookup('nodeapp::config::feature_flag_new_checkout'),
  }
}
