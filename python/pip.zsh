# use this instead of 'pip install' to keep things local and not require root
alias pinstall="pip install --user"
# pip configuration
export PIP_REQUIRE_VIRTUALENV=false
# use `gpip` to use global pip
gpip() {
  PIP_REQUIRE_VIRTUALENV="" pip "$@"
}
# use `gpip3` to use global pip3
gpip3() {
  PIP_REQUIRE_VIRTUALENV="" pip3 "$@"
}
# use `gpinstall` to install global python 2 packages
gpinstall() {
  PIP_REQUIRE_VIRTUALENV="" pip install --user "$@"
}
# use `gpinstall3` to install global python 3 packages
gpinstall3() {
  PIP_REQUIRE_VIRTUALENV="" pip3 install --user "$@"
}
