# Class varnish::repo
#
# This class installs aditional repos for varnish
#
class varnish::repo (
  $base_url = '',
  $enable = true,
  ) {

  $repo_base_url = 'https://packagecloud.io'

  $repo_distro = $::operatingsystem ? {
    'RedHat'    => 'el',
    'LinuxMint' => 'ubuntu',
    'centos'    => 'el',
    'amazon'    => 'el',
    default     => downcase($::operatingsystem),
  }

  $repo_arch = $::architecture
  $repo_version_first = regsubst($varnish::real_version, '^(\d+)\.(\d+)$', '\1\2')

  # Unless using 6.0.1, all 6.0.x versions should use the 60lts branch
  if $repo_version_first == '60' and $varnish::version != '6.0.1' {
    $repo_version = '60lts'
  } else {
    $repo_version = $repo_version_first
  }

  $osver_array = split($::operatingsystemrelease, '[.]')
  if downcase($::operatingsystem) == 'amazon' {
    $osver = $osver_array[0] ? {
      '2'     => '5',
      '3'     => '6',
      default => undef,
    }
  }
  else {
    $osver = $osver_array[0]
  }
  if str2bool($enable) {
    case $::osfamily {
      redhat: {
        yumrepo { 'varnish':
          descr         => 'varnish',
          enabled       => '1',
          gpgcheck      => '0',
          repo_gpgcheck => '1',
          gpgkey        => "${repo_base_url}/varnishcache/varnish${$repo_version}/gpgkey",
          priority      => '1',
          baseurl       => "${repo_base_url}/varnishcache/varnish${repo_version}/${repo_distro}/${osver}/\$basearch",
        }
      }

      debian: {
        case $repo_version {
            '30': {
              $key_id = '246BE381150865E2DC8C6B01FC1318ACEE2C594C'
            }
            '40': {
              $key_id = 'B7B16293AE0CC24216E9A83DD4E49AD8DE3FFEA4'
            }
            '41': {
              $key_id = '9C96F9CA0DC3F4EA78FF332834BF6E8ECBF5C49E'
            }
            '50': {
              $key_id = '1487779B0E6C440214F07945632B6ED0FF6A1C76'
            }
            '51': {
              $key_id = '54DC32329C37703D8B2819E6414C46826B880524'
            }
            '52': {
              $key_id = '91CFD5635A1A5FAC0662BEDD2E9BA3FE86BE909D'
            }
            '60': {
              $key_id = '7C5B46721AF00FD57E68E6E8D2605BF74E8B9DBA'
            }
            '60lts': {
              $key_id = '48D81A24CB0456F5D59431D94CFCFD6BA750EDCD'
            }
            '61': {
              $key_id = '4A066C99B76A0F55A40E3E1E387EF1F5742D76CC'
            }
            '62': {
              $key_id = 'B54813B54CA95257D3590B3F1B0096460868C7A9'
            }
            '63': {
              $key_id = '920A8A7AA7120A8604BCCD294A42CD6EB810E55D'
            }
            '64': {
              $key_id = 'A9897320C397E3A60C03E8BF821AD320F71BFF3D'
            }
            '65': {
              $key_id = 'A487F9BE81D9DF5121488CFE1C7B4E9FF149D65B'
            }
            '66': {
              $key_id = 'A0378A38E4EACA3660789E570BAC19E3F6C90CD5'
            }
            '70': {
              $key_id = 'A4FED748BC3C7FC82C34F108985A1C79B02B8211'
            }
            default: {
              fail("Repo version ${repo_version} not supported")
            }
          }

        apt::source { 'varnish':
          location => "${repo_base_url}/varnishcache/varnish${repo_version}/${repo_distro}",
          repos    => 'main',
          key      => {
            id     => $key_id,
            source => "${repo_base_url}/varnishcache/varnish${$repo_version}/gpgkey"
          },
        }
      }
      default: {
      }
    }
  }
}
