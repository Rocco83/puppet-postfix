# == Class: postfix
#
class postfix (
  Pattern[/^(absent|latest|present|purged)$/] $package_ensure    = 'present',
  String $package_name             = $::postfix::params::package_name,
  Optional[Array] $package_list             = $::postfix::params::package_list,

  $config_dir_path          = $::postfix::params::config_dir_path,
  Boolean $config_dir_purge         = false,
  Boolean $config_dir_recurse       = true,
  Optional[String] $config_dir_source        = undef,

  Stdlib::Absolutepath $config_file_path         = $::postfix::params::config_file_path,
  String $config_file_owner        = $::postfix::params::config_file_owner,
  String $config_file_group        = $::postfix::params::config_file_group,
  String $config_file_mode         = $::postfix::params::config_file_mode,
  Optional[String] $config_file_source       = undef,
  Optional[String] $config_file_string       = undef,
  Optional[String] $config_file_template     = undef,

  String $config_file_notify       = $::postfix::params::config_file_notify,
  String $config_file_require      = $::postfix::params::config_file_require,

  Hash $config_file_hash         = {},
  Hash $config_file_options_hash = {},

  $service_ensure           = 'running',
  String $service_name             = $::postfix::params::service_name,
  Boolean $service_enable           = true,

  $myhostname               = $::fqdn,
  $mydestination            = "${::fqdn}, localhost.${::domain}, localhost",
  $recipient                = "admin@${::domain}",
  $relayhost                = "smtp.${::domain}",
  $relayport                = 25,
  $sasl_user                = undef,
  $sasl_pass                = undef,
) inherits ::postfix::params {


  if $service_ensure !~ /^(running|stopped)$/ {
    fail("Invalid service_ensure: '${service_ensure}' must be 'running' or 'stopped'")
  }

  $config_file_content = default_content($config_file_string, $config_file_template)

  if $config_file_hash {
    create_resources('postfix::define', $config_file_hash)
  }

  if $package_ensure == 'absent' {
    $config_dir_ensure  = 'directory'
    $config_file_ensure = 'present'
    $_service_ensure    = 'stopped'
    $_service_enable    = false
  } elsif $package_ensure == 'purged' {
    $config_dir_ensure  = 'absent'
    $config_file_ensure = 'absent'
    $_service_ensure    = 'stopped'
    $_service_enable    = false
  } else {
    $config_dir_ensure  = 'directory'
    $config_file_ensure = 'present'
    $_service_ensure    = $service_ensure
    $_service_enable    = $service_enable
  }

  if $config_dir_ensure !~ /^(absent|directory)$/ {
    fail("Invalid config_dir_ensure: '${config_dir_ensure}' must be 'absent' or 'directory'")
  }
  
  if $config_file_ensure !~ /^(absent|present)$/ {
    fail("Invalid config_file_ensure: '${config_file_ensure}' must be 'absent' or 'present'")
  }

  anchor { 'postfix::begin': } ->
  class { '::postfix::install': } ->
  class { '::postfix::config': } ~>
  class { '::postfix::service': } ->
  anchor { 'postfix::end': }
}
