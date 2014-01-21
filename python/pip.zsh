# pip configuration
export PIP_REQUIRE_VIRTUALENV=true
# use `syspip` to install global python 2 packages
syspip() {
  PIP_REQUIRE_VIRTUALENV="" pip "$@"
}
# use `syspip3` to install global python 3 packages
syspip3() {
  PIP_REQUIRE_VIRTUALENV="" pip3 "$@"
}
