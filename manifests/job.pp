#
define bacula::job (
  $options,
  $runscripts = [],
  $client = $trusted['certname'],
) {
  validate_hash($options)
  validate_array($runscripts)
  @@bacula::job::director { "${client}-${name}":
    cluster     => $bacula::client::cluster,
    client      => $client,
    options     => $options,
    runscripts_ => $runscripts,
  }
}
