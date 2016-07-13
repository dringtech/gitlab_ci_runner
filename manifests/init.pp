# == Class: gitlab_ci_runner
#
class gitlab_ci_runner (
  $manage_repo = true,
  $install_package = true,
  ){

    class { '::gitlab_ci_runner::install': } ->
    class { '::gitlab_ci_runner::service': } ->
    Class['::gitlab_ci_runner']
}
