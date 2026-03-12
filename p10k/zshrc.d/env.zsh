# environment variables and PATH configuration

export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# if you are not english speaker, set LANG to your locale
export LANG=en_US.UTF-8



# nvm lazy load
lazy_load_nvm() {
  unset -f nvm node npm npx
  export NVM_DIR="$HOME/.nvm"
  # load nvm
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
  fi
  # load nvm bash_completion
  if [ -s "$NVM_DIR/bash_completion" ]; then
    . "$NVM_DIR/bash_completion"
  fi
  # default to nvm default version
  nvm use default >/dev/null 2>&1
}

# lazy load nvm when any of these commands is called
# Don’t manually export a version path anymore
# NVM will automatically manage PATH, no fixed version is required
nvm() { lazy_load_nvm; nvm "$@"; }
node() { lazy_load_nvm; node "$@"; }
npm() { lazy_load_nvm; npm "$@"; }
npx() { lazy_load_nvm; npx "$@"; }


export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"

# Go env
export GOPATH="$HOME/go"
# GOROOT Usually there is no need to export manually unless you have multiple Go versions installed
# export GOROOT="$(go env GOROOT)" 
