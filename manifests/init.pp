# == Class: varnish
#
# Installs and configures Varnish.
# Tested on Ubuntu and CentOS.
#
#
# === Parameters
# All parameters are just a low case replica of actual parameters passed to
# the Varnish conf file, $class_parameter -> VARNISH_PARAMETER, i.e.
# $memlock             -> MEMLOCK
# $varnish_vcl_conf    -> VARNISH_VCL_CONF
# $varnish_listen_port -> VARNISH_LISTEN_PORT
#
# Exceptions are:
# ensure        - passed to puppet type 'package', attribute 'ensure'
# shmlog_dir    - location for shmlog
# shmlog_tempfs - mounts shmlog directory as tmpfs
#                 default value: true
# version       - the Varnish version to be installed (valid values are '3.0',
#                 '4.0' and '4.1')
# add_repo      - if set to false (defaults to true), the yum/apt repo is not added
#
# package_name  - the name of the package that should be installed
#                 default value: varnish
#
# === Default values
# Set to Varnish default values
# With an exception to
# - $storage_type, which is set to 'malloc' in this module
# - $varnish_storage_file, path to which is changed to /var/lib/varnish-storage
#                          this is done to avoid clash with $shmlog_dir
#
# === Examples
#
# - installs Varnish
# - enabled Varnish service
# - uses default VCL '/etc/varnish/default.vcl'
# class {'varnish': }
#
# same as above, plus
# - sets Varnish to listen on port 80
# - storage size is set to 2 GB
# - vcl file is '/etc/varnish/my-vcl.vcl'
# class {'varnish':
#   varnish_listen_port  => '80',
#   varnish_storage_size => '2G',
#   varnish_vcl_conf     => '/etc/varnish/my-vcl.vcl',
# }
#

class varnish (
  $ensure                       = 'present',
  $start                        = 'yes',
  $reload_vcl                   = true,
  $nfiles                       = '131072',
  $memlock                      = '82000',
  $storage_type                 = 'malloc',
  $varnish_vcl_conf             = '/etc/varnish/default.vcl',
  $varnish_user                 = 'varnish',
  $varnish_group                = 'varnish',
  $varnish_listen_address       = '',
  $varnish_listen_port          = '6081',
  $varnish_admin_listen_address = 'localhost',
  $varnish_admin_listen_port    = '6082',
  $varnish_min_threads          = '5',
  $varnish_max_threads          = '500',
  $varnish_thread_timeout       = '300',
  $varnish_storage_size         = '1G',
  $varnish_secret_file          = '/etc/varnish/secret',
  $varnish_storage_file         = '/var/lib/varnish-storage/varnish_storage.bin',
  $varnish_ttl                  = '120',
  $vcl_dir                      = undef,
  $shmlog_dir                   = '/var/lib/varnish',
  $shmlog_tempfs                = true,
  $version                      = '7.0',
  $add_repo                     = true,
  $manage_firewall              = false,
  $varnish_conf_template        = 'varnish/varnish-conf.erb',
  $varnish_identity             = undef,
  $varnish_name                 = undef,
  $package_name                 = 'varnish',
  $additional_parameters        = {},
  $additional_storages          = {},
  $conf_file_path               = $varnish::params::conf_file_path,
) inherits varnish::params {

  # read parameters
  include varnish::params

  if ! ($version =~ /^\d+\.\d+$/) {
    warning('$version should consist only of major and minor version numbers.')

    # Extract major and minor version from the value, otherwise default to 7.0.
    if $version =~ /^\d+\.\d+\./ {
      $real_version = regsubst($version, '^(\d+\.\d+).*$', '\1')
    } elsif $version == 'present' {
      $real_version = '7.0'
    } else {
      fail('Invalid value for $version.')
    }
  } else {
    $real_version = $version
  }

  case $varnish_storage_size {
    /%$/: {
      case $storage_type {
        'malloc': {
          $varnish_storage_size_percentage = scanf($varnish_storage_size, '%f%%')
          $varnish_actual_storage_size = sprintf('%dM', floor($::memorysize_mb * $varnish_storage_size_percentage[0] / 100))
        }

        default: {
          fail("A percentage-based storage size can only be specified if using 'malloc' storage")
        }
      }
    }

    default: {
      $varnish_actual_storage_size = $varnish_storage_size
    }
  }

  # install Varnish
  class {'varnish::install':
    add_repo            => $add_repo,
    manage_firewall     => $manage_firewall,
    varnish_listen_port => $varnish_listen_port,
  }

  # enable Varnish service
  class {'varnish::service':
    start => $start,
  }

  # mount shared memory log dir as tempfs
  if $shmlog_tempfs {
    class { 'varnish::shmlog':
      shmlog_dir => $shmlog_dir,
      require    => Package['varnish'],
    }
  }

  # varnish config file
  file { 'varnish-conf':
    ensure  => 'file',
    path    => $conf_file_path,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template($varnish_conf_template),
    require => Package['varnish'],
    notify  => Exec['restart-varnish'],
  }

  # storage dir
  $varnish_storage_dir = regsubst($varnish_storage_file, '(^/.*)(/.*$)', '\1')
  file { 'storage-dir':
    ensure  => directory,
    path    => $varnish_storage_dir,
    owner   => $varnish_user,
    group   => $varnish_group,
    mode    => '0755',
    require => Package['varnish'],
  }
}
