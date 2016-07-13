# == Class: gitlab_ci_runner::install::linux
#
class gitlab_ci_runner::install::linux (
  $baseurl = "https://packages.gitlab.com/runner/gitlab-ci-multi-runner/el/${::os['release']['major']}/${::os['architecture']}",
  $gpgkey = 'https://packages.gitlab.com/runner/gitlab-ci-multi-runner/gpgkey',
  $sslcacert = '/etc/pki/tls/certs/ca-bundle.crt',
  $version = 'latest',
){

  if $::os['family'] == 'RedHat' {

    if $::gitlab_ci_runner::manage_repo == true {
      yumrepo { 'runner_gitlab-ci-multi-runner':
        baseurl   => $baseurl,
        descr     => 'Gitlab CI Multirunner repo',
        enabled   => '1',
        gpgcheck  => '0',
        gpgkey    => $gpgkey,
        sslverify => 1,
        sslcacert => $sslcacert,
      }
    }

    if $::gitlab_ci_runner::install_package == true {
      package { 'gitlab-ci-multi-runner':
        ensure  => $version,
        require => Yumrepo['runner_gitlab-ci-multi-runner'],
      }
    }
  }
  else {

    error('This module is only supported on RedHat flavoured linux')

  }
}
