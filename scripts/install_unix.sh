#!/bin/sh

GITHUB_ORG="pandora-security"
GITHUB_REPO="Pandora"
INSTALL_DIR="/usr/local/bin"
INSTALL_METHOD=0

println() {
  echo "$@"
}

print_header() {
  if [ -z "$1" ]; then
    clear
    println
    if [ "$INSTALL_METHOD" -eq 0 ]; then
      println "============ Pandora installer for macOS and Linux ============"
    else
      println "============= Pandora updater for macOS and Linux ============="
    fi
    println
  fi
}

check_dependencies() {
  printf "Checking dependencies... "
  curl -h > /dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    println "FAILED [curl]"
    println
    println "Missing dependency: curl"
    if [ "$INSTALL_METHOD" -eq 0 ]; then
      println "Installation aborted."
    else
      println "Update aborted."
    fi
    exit 1
  fi
  mktemp > /dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    println "FAILED [mktemp]"
    println
    println "Missing dependency: mktemp"
    if [ "$INSTALL_METHOD" -eq 0 ]; then
      println "Installation aborted."
    else
      println "Update aborted."
    fi
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
    if [ "$INSTALL_METHOD" -eq 0 ]; then
      println "Installation aborted."
    else
      println "Update aborted."
    fi
    exit 1
  fi
  uname -v > /dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    println "FAILED [uname]"
    println
    println "Missing dependency: uname"
    if [ "$INSTALL_METHOD" -eq 0 ]; then
      println "Installation aborted."
    else
      println "Update aborted."
    fi
    exit 1
  fi
  unzip -v > /dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    println "FAILED [unzip]"
    println
    println "Missing dependency: unzip"
    if [ "$INSTALL_METHOD" -eq 0 ]; then
      println "Installation aborted."
    else
      println "Update aborted."
    fi
    exit 1
  fi
  println "OK"
}

check_existing_pandora() {
  printf "Checking if Pandora has already been installed... "
  pandora > /dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -eq 0 ]; then
    INSTALL_METHOD=1
    PANDORA_EXIST="exist"
  else
    INSTALL_METHOD=0
    PANDORA_EXIST="not exist"
  fi
  println "OK [$PANDORA_EXIST]"
}

request_privilege() {
  exec sudo "$0" "$INSTALL_METHOD" "$LATEST_RELEASE" "$TEMP_FILE" 
  exit 1
}

check_privilege() {
  # shellcheck disable=SC2039
  if [ -z "$UID" ] && [ "$UID" != "" ]; then
    if [ "$UID" -ne 0 ]; then
      request_privilege
    fi
  else
    if [ "$(id -u)" -ne 0 ]; then
      request_privilege
    fi
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
    if [ "$INSTALL_METHOD" -eq 0 ]; then
      println "Installation aborted."
    else
      println "Update aborted."
    fi
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
    if [ "$INSTALL_METHOD" -eq 0 ]; then
      println "Installation aborted."
    else
      println "Update aborted."
    fi
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
    if [ "$INSTALL_METHOD" -eq 0 ]; then
      println "Installation aborted."
    else
      println "Update aborted."
    fi
    exit 1
  fi
  mkdir "$TEMP_DIR" > /dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    println "FAILED [mkdir]"
    println
    println "Failed to make new temporary directory."
    if [ "$INSTALL_METHOD" -eq 0 ]; then
      println "Installation aborted."
    else
      println "Update aborted."
    fi
    exit 1
  fi
  unzip "$TEMP_FILE" -d "$TEMP_DIR" > /dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    println "FAILED [unzip]"
    println
    println "Failed to extract Pandora package."
    if [ "$INSTALL_METHOD" -eq 0 ]; then
      println "Installation aborted."
    else
      println "Update aborted."
    fi
    exit 1
  fi
  cp -r "$TEMP_DIR"/pandora "$INSTALL_DIR"/pandora > /dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    println "FAILED [cp]"
    println
    println "Failed to copy Pandora binary to $INSTALL_DIR."
    if [ "$INSTALL_METHOD" -eq 0 ]; then
      println "Installation aborted."
    else
      println "Update aborted."
    fi
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
    if [ "$INSTALL_METHOD" -eq 0 ]; then
      println "Installation aborted."
    else
      println "Update aborted."
    fi
    exit 1
}

main() {
  if [ -z "$1" ]; then
    print_header "$@"
    get_system_information
    get_latest_release
    RELEASE_URL="https://github.com/pandora-security/Pandora/releases/download/$LATEST_RELEASE/pandora-$DISTRIBUTION-$LATEST_RELEASE.zip"
    download_latest_release
    check_privilege
  else
    println "User permission request... GRANTED"
    check_dependencies
    install_binary
    clean_up
    println
    if [ "$INSTALL_METHOD" -eq 0 ]; then
      println "Pandora $LATEST_RELEASE is successfully installed."
    else
      println "Pandora is successfully updated to $LATEST_RELEASE."
    fi
  fi
}

if [ -z "$1" ]; then
  check_existing_pandora
  check_dependencies
  println
  if [ "$INSTALL_METHOD" -eq 0 ]; then
    println "Pandora installer may needs your permission to proceed installing"
  else
    println "Pandora updater may needs your permission to proceed update"
  fi
  println "Pandora. Please enter your password if asked."
  println

  while true; do
    if [ "$INSTALL_METHOD" -eq 0 ]; then
      printf "Proceed installation? [Y/n]: "
    else
      printf "Proceed update? [Y/n]: "
    fi
    read -r yn
    case $yn in
      "" ) main; break;;
      [Yy]* ) main; break;;
      [Nn]* ) cancel_install;;
      * ) println "Please answer yes or no.";;
    esac
  done
else
  INSTALL_METHOD="$1"
  LATEST_RELEASE="$2"
  TEMP_FILE="$3"
  main "$1"
fi
