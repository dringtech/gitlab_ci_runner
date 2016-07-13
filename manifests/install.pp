# == Class: gitlab_ci_runner::install
#
class gitlab_ci_runner::install {

  case $::kernel {
    'Linux':  { include ::gitlab_ci_runner::install::linux }
    'windows': { include ::gitlab_ci_runner::install::windows }
    default: { error("Operatingsystem $::{'operatingsystem'} is not supported.") }
  }

}
