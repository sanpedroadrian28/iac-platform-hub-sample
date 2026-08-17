# Role: what this node IS. Roles compose profiles; nodes are assigned exactly one role.
class role::nodeapp_server {
  include profile::nodeapp
  include profile::nodeapp_monitoring
  include profile::nodeapp_hardening
}
