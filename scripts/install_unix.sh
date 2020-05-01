#!/bin/sh

println() {
  echo "$@"
}

print_header() {
  if [ -z "$1" ]; then
    clear
    println
    println "============ Pandora installer for macOS and Linux ============"
    println
  fi
}

check_dependencies() {
  printf "Checking dependencies... "
  curl -v foo > /dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    println "FAILED [curl]"
    println
    println "Missing dependency: curl"
    println "Installation aborted."
    exit 1
  fi
  mktemp > /dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    println "FAILED [mktemp]"
    println
    println "Missing dependency: mktemp"
    println "Installation aborted."
    exit 1
  fi
#  nc -v > /dev/null 2>&1
#  # shellcheck disable=SC2181
#  if [ $? -ne 0 ]; then
#    println "FAILED [nc]"
#    println
#    println "Missing dependency: nc"
#    println "Installation aborted."
#    exit 1
#  fi
#  sed -v > /dev/null 2>&1
#  # shellcheck disable=SC2181
#  if [ $? -ne 0 ]; then
#    println "FAILED [sed]"
#    println
#    println "Missing dependency: sed"
#    println "Installation aborted."
#    exit 1
#  fi
  sudo -V > /dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    println "FAILED [sudo]"
    println
    println "Missing dependency: sudo"
    println "Installation aborted."
    exit 1
  fi
  uname -v > /dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    println "FAILED [uname]"
    println
    println "Missing dependency: uname"
    println "Installation aborted."
    exit 1
  fi
  unzip -v > /dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    println "FAILED [unzip]"
    println
    println "Missing dependency: unzip"
    println "Installation aborted."
    exit 1
  fi
  println "OK"
}

request_privilege() {
  # shellcheck disable=SC2039
  if [ "$UID" -ne 0 ]; then
    exec sudo "$0" "permission_flag" "$TEMP_FILE" "$LATEST_RELEASE"
    exit 1
  fi
}

get_latest_release() {
  printf "Checking latest Pandora version available... "
  #  printf "GET http://api.github.com HTTP/1.0\n\n" | nc api.github.com 80 > /dev/null 2>&1
  #  # shellcheck disable=SC2181
  #  if [ $? -ne 0 ]; then
  #    println "FAILED [offline]"
  #    println
  #    println "You are not connected to the Internet."
  #    println "Installation aborted."
  #    exit 1
  #  fi
  LATEST_RELEASE=$(curl --silent "https://api.github.com/repos/$GITHUB_ORG/$GITHUB_REPO/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/')
  println "OK [$LATEST_RELEASE]"
}

get_system_information() {
  printf "Checking system compatibility... "
  case "$(uname -s)" in
    Linux*)     OPERATING_SYSTEM="linux";;
    Darwin*)    OPERATING_SYSTEM="darwin";;
    *)          OPERATING_SYSTEM="0"
  esac
  case $(uname -m) in
    i386)       PROCESSOR_ARCHITECTURE="i386" ;;
    i686)       PROCESSOR_ARCHITECTURE="i386" ;;
    x86_64)     PROCESSOR_ARCHITECTURE="amd64" ;;
    *)          PROCESSOR_ARCHITECTURE="0"
  esac
  DISTRIBUTION="${OPERATING_SYSTEM}_${PROCESSOR_ARCHITECTURE}"
  if [ "$DISTRIBUTION" = "0_0" ]; then
    println "FAILED [$DISTRIBUTION]"
    println
    println "Your operating system is not supported by Pandora."
    println "Installation aborted."
    exit 1
  fi
  println "OK [$DISTRIBUTION]"
}

download_latest_release() {
  printf "Downloading Pandora package... "
  TEMP_FILE=$(mktemp)
  curl -L "$RELEASE_URL" 2>/dev/null > "$TEMP_FILE"
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    println "FAILED"
    println
    println "Download was interrupted. Please check your Internet connection."
    println "Installation aborted."
    exit 1
  fi
  PACKAGE_SIZE=$(wc -c < "$TEMP_FILE")
  println "OK [$PACKAGE_SIZE B]"
}

install_binary() {
  printf "Installing Pandora to %s... " "$INSTALL_DIR"
  TEMP_DIR=$(mktemp)
  rm -f "$TEMP_DIR" > /dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    println "FAILED [rm]"
    println
    println "Failed to remove temporary file."
    println "Installation aborted."
    exit 1
  fi
  mkdir "$TEMP_DIR" > /dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    println "FAILED [mkdir]"
    println
    println "Failed to make new temporary directory."
    println "Installation aborted."
    exit 1
  fi
  unzip "$TEMP_FILE" -d "$TEMP_DIR" > /dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    println "FAILED [unzip]"
    println
    println "Failed to extract Pandora package."
    println "Installation aborted."
    exit 1
  fi
  cp -r "$TEMP_DIR"/pandora "$INSTALL_DIR"/pandora > /dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    println "FAILED [cp]"
    println
    println "Failed to copy Pandora binary to $INSTALL_DIR."
    println "Installation aborted."
    exit 1
  fi
  println "OK"
}

clean_up() {
  printf "Cleaning up temporary files... "
  rm -f "$TEMP_FILE"
  println "OK"
}

cancel_install() {
    println
    println "Process cancelled by the user."
    println "Installation aborted."
    exit 1
}

main() {
  if [ -z "$1" ]; then
    print_header "$@"
    get_system_information
    get_latest_release
    RELEASE_URL="https://github.com/pandora-security/Pandora/releases/download/$LATEST_RELEASE/pandora-$DISTRIBUTION-$LATEST_RELEASE.zip"
    download_latest_release
    request_privilege
  else
    println "User permission request... GRANTED"
    check_dependencies
    install_binary
    clean_up
    println
    println "Pandora $LATEST_RELEASE is successfully installed."
  fi
}

GITHUB_ORG="pandora-security"
GITHUB_REPO="Pandora"
INSTALL_DIR="/usr/local/bin"

if [ -z "$1" ]; then
  check_dependencies
  println
  println "Pandora installer may needs your permission to proceed installing"
  println "Pandora. Please enter your password if asked."
  println

  while true; do
    printf "Proceed to installation? [Y/n]: "
    read -r yn
    case $yn in
      "" ) main; break;;
      [Yy]* ) main; break;;
      [Nn]* ) cancel_install;;
      * ) println "Please answer yes or no.";;
    esac
  done
else
  TEMP_FILE="$2"
  LATEST_RELEASE="$3"
  main "$1"
fi