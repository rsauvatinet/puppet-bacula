class bacula::client (
  $package = $bacula::params::client_package,
  $configdir = $bacula::params::configdir,
  $config = $bacula::params::client_config,
  $group = $bacula::params::group,
  $service = $bacula::params::client_service,
  $port = $bacula::params::client_port,
  $working_directory = $bacula::params::working_directory,
  $pid_directory = $bacula::params::pid_directory,
  $password = $bacula::params::client_password,
  $max_concurrent_jobs = 2,
  $heartbeat_interval = '1 minute',
  $catalog = 'MainCatalog',
  $file_retention = '2 months',
  $job_retention = '6 months',
  $pki_enabled = false,
  $pki_master_key_content = undef,
) inherits bacula::params {
  include bacula::tls
  $cluster = $bacula::params::cluster

  package { 'bacula-client':
    ensure => present,
    name   => $package,
  }
  service { 'bacula-client':
    ensure  => running,
    enable  => true,
    name    => $service,
    require => Package['bacula-client'],
  }

  if $pki_enabled {
    $pki_file = "${configdir}/ssl/${::fqdn}_pki.pem"
    $pki_master_file = "${configdir}/ssl/pki_master.pem"
    concat { $pki_file:
      mode    => '0400',
      owner   => 'root',
      group   => 'root',
      require => Package['bacula-client'],
      notify  => Service['bacula-client'],
    }

    concat::fragment { "${pki_file}_cert":
      target => $pki_file,
      source => $::bacula::tls::cert,
      order  => '10',
    }
    concat::fragment { "${pki_file}_key":
      target => $pki_file,
      source => $::bacula::tls::key,
      order  => '20',
    }

    file { $pki_master_file:
      ensure  => file,
      mode    => '0400',
      owner   => 'root',
      group   => 'root',
      content => $pki_master_key_content,
      require => Package['bacula-client'],
      notify  => Service['bacula-client'],
    }
  }

  concat { $config:
    mode    => '0640',
    owner   => 'root',
    group   => $group,
    require => Package['bacula-client'],
    notify  => Service['bacula-client'],
  }
  concat::fragment { 'bacula_fd':
    target  => $config,
    content => template('bacula/fd.erb'),
    order   => $bacula::params::order_client,
  }
  @@bacula::client::director { $trusted['certname']:
    cluster        => $cluster,
    port           => $port,
    password       => $password,
    catalog        => $catalog,
    file_retention => $file_retention,
    job_retention  => $job_retention,
  }
  Bacula::Director::Client <<| cluster == $cluster |>>
  Bacula::Messages::Client <<| cluster == $cluster |>>

  # Postgres backup
  $scriptdir = "${configdir}/scripts"
  file { $scriptdir:
    ensure  => directory,
    require => Package['bacula-client'],
  }

  case $::osfamily {
    default: { fail("Unsupported platform ${::osfamily}") }
    'Debian': {
      ensure_resource("package", "xdelta3", { ensure => present })
    }
    'RedHat': {
      ensure_resource("package", "xdelta", { ensure => present })
    }
  }
  file { "${scriptdir}/delta.sh":
    source => 'puppet:///modules/bacula/delta.sh',
    mode   => '755',
  }
}
