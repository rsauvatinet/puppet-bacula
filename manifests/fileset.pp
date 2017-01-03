define bacula::fileset (
  $includes,
  $excludes = [],
  $client = $trusted['certname'],
) {
  validate_array($includes)
  validate_array($excludes)
  @@bacula::fileset::director { "${client}-fs-${name}":
    cluster   => $bacula::client::cluster,
    includes_ => $includes,
    excludes_ => $excludes,
  }
}
