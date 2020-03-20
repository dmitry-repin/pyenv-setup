#!/bin/bash


echoerr() {
  echo "$@" 1>&2
}


initial_check() {
  # root user checkout
  (( $UID != 0 )) && echoerr 'This script must be run as root!' && return 1

  # OS checkout
  local os_check
  os_check() {
    local id=$(lsb_release -is)
    local release=$(lsb_release -rs)
    [[ $id = Ubuntu && $release = 18.04 ]] && return 0 || return 1
  }
    
  if os_check; then
    return 0
  else
    echoerr 'Unsupported system!'
    return 1
  fi
}


main() {
  # pyenv setup
  local pyenv_path="/home/${USER}/.pyenv"
  if [ ! -d "${pyenv_path}" ]; then
    git clone https://github.com/pyenv/pyenv.git "${pyenv_path}"
    
    # build dependencies
    apt-get update
    apt-get install -y build-essential curl libbz2-dev libffi-dev \
    libfreetype6-dev libjpeg8-dev liblcms2-dev libmysqlclient-dev \
    libncurses5-dev libncursesw5-dev libreadline-dev libsqlite3-dev \
    libssl-dev libtiff5-dev libwebp-dev libxml2-dev libxslt1-dev llvm make \
    python3-dev tcl8.6-dev tk8.6-dev tk-dev wget xz-utils zlib1g-dev
  fi

  # pyenv-virtualenvwrapper setup
  local pyenv_vew_path="${pyenv_path}/plugins/pyenv-virtualenvwrapper"
  [ -d "${pyenv_vew_path}" ] || \
    git clone https://github.com/yyuu/pyenv-virtualenvwrapper.git \
    "${pyenv_vew_path}"

  # pyenv configuration
  local pyenvrc_path="/home/${USER}/.pyenvrc"
  if [ ! -f "${pyenvrc_path}" ]; then
    export pyenv_path
    envsubst '${pyenv_path}' < ./assets/.pyenvrc.tmpl > "${pyenvrc_path}"
  fi
  chown $USER:$GROUP "${pyenvrc_path}"
  local profile_line="source /home/${USER}/.pyenvrc"
  local conf_file
  for conf_file in .profile .bashrc; do
    local conf_path="/home/${USER}/${conf_file}"
    grep -q -F "${profile_line}" "${conf_path}" || \
    echo "${profile_line}" >> "${conf_path}"
  done
  source "${pyenvrc_path}"

  # Python setup
  local python_path="${pyenv_path}/versions/${PYTHON_VERSION}"
  if [ ! -d "${python_path}" ]; then
    pyenv install "${PYTHON_VERSION}"
  fi
  chown -R $USER:$GROUP "${pyenv_path}"

  # Virtual environment setup
  if [ ! -d "/home/${USER}/.virtualenvs/${VE_NAME}" ]; then
    sudo -i -u $USER bash -i -c "\
    pyenv shell ${PYTHON_VERSION};\
    pyenv virtualenvwrapper;\
    mkvirtualenv ${VE_NAME}\
    "
  fi
}


source ./settings.sh
initial_check || exit 1
main
