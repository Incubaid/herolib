#!/bin/bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Help function
print_help() {
    echo "V & HeroLib Installer Script"
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --reset        Force reinstallation of V"
    echo "  --remove       Remove V installation and exit"
    echo "  --analyzer     Install/update v-analyzer"
    echo "  --herolib      Install our herolib"
    echo
    echo "Examples:"
    echo "  $0"
    echo "  $0 --reset           "
    echo "  $0 --remove          "
    echo "  $0 --analyzer        "
    echo "  $0 --herolib         "
    echo "  $0 --reset --analyzer # Fresh install of both"
    echo
}

# Parse arguments
RESET=false
REMOVE=false
INSTALL_ANALYZER=false
HEROLIB=false

for arg in "$@"; do
    case $arg in
        -h|--help)
            print_help
            exit 0
        ;;
        --reset)
            RESET=true
        ;;
        --remove)
            REMOVE=true
        ;;
        --herolib)
            HEROLIB=true
        ;;
        --analyzer)
            INSTALL_ANALYZER=true
        ;;
        *)
            echo "Unknown option: $arg"
            echo "Use -h or --help to see available options"
            exit 1
        ;;
    esac
done

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to run commands with sudo if needed
function run_sudo() {
    # Check if we're already root
    if [ "$(id -u)" -eq 0 ]; then
        # We are root, run the command directly
        "$@"
        # Check if sudo is installed
        elif command_exists sudo; then
        # Use sudo to run the command
        sudo "$@"
    else
        # No sudo available, try to run directly
        "$@"
    fi
}

export DIR_BASE="$HOME"
export DIR_BUILD="/tmp"
export DIR_CODE="$DIR_BASE/code"
export DIR_CODE_V="$DIR_BASE/_code"

check_release() {
    if ! command -v lsb_release >/dev/null 2>&1; then
        echo "❌ lsb_release command not found. Install 'lsb-release' package first."
        exit 1
    fi
    
    CODENAME=$(lsb_release -sc)
    RELEASE=$(lsb_release -rs)
    
    if dpkg --compare-versions "$RELEASE" lt "24.04"; then
        echo "ℹ️ Detected Ubuntu $RELEASE ($CODENAME). Skipping mirror fix (requires 24.04+)."
        return 1
    fi
    
    return 0
}

ubuntu_sources_fix() {
    # Check if we're on Ubuntu
    if [[ "${OSNAME}" != "ubuntu" ]]; then
        echo "ℹ️ Not running on Ubuntu. Skipping mirror fix."
        return 1
    fi
    
    if check_release; then
        local CODENAME
        CODENAME=$(lsb_release -sc)
        local TIMESTAMP
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        
        echo "🔎 Fixing apt mirror setup for Ubuntu $(lsb_release -rs) ($CODENAME)..."
        
        if [ -f /etc/apt/sources.list ]; then
            echo "📦 Backing up /etc/apt/sources.list -> /etc/apt/sources.list.backup.$TIMESTAMP"
            sudo mv /etc/apt/sources.list /etc/apt/sources.list.backup.$TIMESTAMP
        fi
        
        if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
            echo "📦 Backing up /etc/apt/sources.list.d/ubuntu.sources -> /etc/apt/sources.list.d/ubuntu.sources.backup.$TIMESTAMP"
            sudo mv /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.backup.$TIMESTAMP
        fi
        
        echo "📝 Writing new /etc/apt/sources.list.d/ubuntu.sources"
    sudo tee /etc/apt/sources.list.d/ubuntu.sources >/dev/null <<EOF
Types: deb
URIs: mirror://mirrors.ubuntu.com/mirrors.txt
Suites: $CODENAME $CODENAME-updates $CODENAME-backports $CODENAME-security
Components: main restricted universe multiverse
EOF
        
        echo "🔄 Running apt update..."
        sudo apt update -qq
        
        echo "✅ Done! Your system now uses the rotating Ubuntu mirror list."
    fi
}



function sshknownkeysadd {
    mkdir -p ~/.ssh
    touch ~/.ssh/known_hosts
    if ! grep github.com ~/.ssh/known_hosts > /dev/null
    then
        ssh-keyscan github.com >> ~/.ssh/known_hosts
    fi
    if ! grep git.threefold.info ~/.ssh/known_hosts > /dev/null
    then
        ssh-keyscan git.threefold.info >> ~/.ssh/known_hosts
    fi
    git config --global pull.rebase false
    
}

function package_check_install {
    local command_name="$1"
    if command -v "$command_name" >/dev/null 2>&1; then
        echo "command '$command_name' is already installed."
    else
        package_install '$command_name'
    fi
}

function package_install {
    local command_name="$1"
    if [[ "${OSNAME}" == "ubuntu" ]]; then
        if is_github_actions; then
            run_sudo apt -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" install $1 -q -y --allow-downgrades --allow-remove-essential
        else
            apt -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" install $1 -q -y --allow-downgrades --allow-remove-essential
        fi
        
        elif [[ "${OSNAME}" == "darwin"* ]]; then
        brew install $command_name
        elif [[ "${OSNAME}" == "alpine"* ]]; then
        apk add $command_name
        elif [[ "${OSNAME}" == "arch"* ]]; then
        pacman --noconfirm -Su $command_name
    else
        echo "platform : ${OSNAME} not supported"
        exit 1
    fi
}

is_github_actions() {
    # echo "Checking GitHub Actions environment..."
    # echo "GITHUB_ACTIONS=${GITHUB_ACTIONS:-not set}"
    if [ -n "${GITHUB_ACTIONS:-}" ] && [ "$GITHUB_ACTIONS" = "true" ]; then
        echo "Running in GitHub Actions: true"
        return 0
    else
        echo "Running in GitHub Actions: false"
        return 1
    fi
}


function myplatform {
    if [[ "${OSTYPE}" == "darwin"* ]]; then
        export OSNAME='darwin'
        elif [ -e /etc/os-release ]; then
        # Read the ID field from the /etc/os-release file
        export OSNAME=$(grep '^ID=' /etc/os-release | cut -d= -f2)
        if [ "${OSNAME,,}" == "ubuntu" ]; then
            export OSNAME="ubuntu"
        fi
        if [ "${OSNAME}" == "archarm" ]; then
            export OSNAME="arch"
        fi
        if [ "${OSNAME}" == "debian" ]; then
            export OSNAME="ubuntu"
        fi
    else
        echo "Unable to determine the operating system."
        exit 1
    fi
    
    
    # if [ "$(uname -m)" == "x86_64" ]; then
    #     echo "This system is running a 64-bit processor."
    # else
    #     echo "This system is not running a 64-bit processor."
    #     exit 1
    # fi
    
}

myplatform

function os_update {
    if [[ "${OSNAME}" == "ubuntu" ]]; then
        ubuntu_sources_fix
    fi
    echo ' - os update'
    if [[ "${OSNAME}" == "ubuntu" ]]; then
        if is_github_actions; then
            echo "github actions"
        else
            rm -f /var/lib/apt/lists/lock
            rm -f /var/cache/apt/archives/lock
            rm -f /var/lib/dpkg/lock*
        fi
        export TERM=xterm
        export DEBIAN_FRONTEND=noninteractive
        run_sudo dpkg --configure -a
        run_sudo apt update -y
        if is_github_actions; then
            echo "** IN GITHUB ACTIONS, DON'T DO UPDATE"
        else
            set +e
            echo "** UPDATE"
            apt-mark hold grub-efi-amd64-signed
            set -e
            apt upgrade  -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --force-yes
            apt autoremove  -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --force-yes
        fi
        #apt install apt-transport-https ca-certificates curl software-properties-common  -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --force-yes
        package_install "apt-transport-https ca-certificates curl wget software-properties-common tmux make gcc"
        package_install "rclone rsync mc redis-server screen net-tools git dnsutils htop ca-certificates screen lsb-release binutils pkg-config libssl-dev iproute2"
        
        elif [[ "${OSNAME}" == "darwin"* ]]; then
        if command -v brew >/dev/null 2>&1; then
            echo ' - homebrew installed'
        else
            export NONINTERACTIVE=1
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            unset NONINTERACTIVE
        fi
        set +e
        brew install mc redis curl tmux screen htop wget rclone tcc
        set -e
        elif [[ "${OSNAME}" == "alpine"* ]]; then
        apk update screen git htop tmux
        apk add mc curl rsync htop redis bash bash-completion screen git rclone
        sed -i 's#/bin/ash#/bin/bash#g' /etc/passwd
        elif [[ "${OSNAME}" == "arch"* ]]; then
        pacman -Syy --noconfirm
        pacman -Syu --noconfirm
        pacman -Su --noconfirm arch-install-scripts gcc mc git tmux curl htop redis wget screen net-tools git sudo htop ca-certificates lsb-release screen rclone
        
        # Check if builduser exists, create if not
        if ! id -u builduser > /dev/null 2>&1; then
            useradd -m builduser
            echo "builduser:$(openssl rand -base64 32 | sha256sum | base64 | head -c 32)" | chpasswd
            echo 'builduser ALL=(ALL) NOPASSWD: ALL' | tee /etc/sudoers.d/builduser
        fi
        
        # if [[ -n "${DEBUG}" ]]; then
        #     execute_with_marker "paru_install" paru_install
        # fi
    fi
    echo ' - os update done'
}


function hero_lib_pull {
    pushd $DIR_CODE/github/incubaid/herolib 2>&1 >> /dev/null
    if [[ $(git status -s) ]]; then
        echo "There are uncommitted changes in the Git repository herolib."
        return 1
    fi
    git pull
    popd 2>&1 >> /dev/null
}

function hero_lib_get {
    
    mkdir -p $DIR_CODE/github/incubaid
    if [[ -d "$DIR_CODE/github/incubaid/herolib" ]]
    then
        hero_lib_pull
    else
        pushd $DIR_CODE/github/incubaid 2>&1 >> /dev/null
        git clone --depth 1 --no-single-branch https://github.com/incubaid/herolib.git
        popd 2>&1 >> /dev/null
    fi
}

# function install_secp256k1 {

#     echo "Installing secp256k1..."
#     if [[ "${OSNAME}" == "darwin"* ]]; then
#         # Attempt installation only if not already found
#         echo "Attempting secp256k1 installation via Homebrew..."
#         brew install secp256k1
#     elif [[ "${OSNAME}" == "ubuntu" ]]; then
#         # Install build dependencies
#         package_install "build-essential wget autoconf libtool"

#         # Download and extract secp256k1
#         cd "${DIR_BUILD}"
#         wget https://github.com/bitcoin-core/secp256k1/archive/refs/tags/v0.3.2.tar.gz
#         tar -xvf v0.3.2.tar.gz

#         # Build and install
#         cd secp256k1-0.3.2/
#         ./autogen.sh
#         ./configure
#         make -j 5
#         if is_github_actions; then
#             run_sudo make install
#         else
#             make install
#         fi

#         # Cleanup
#         cd ..
#         rm -rf secp256k1-0.3.2 v0.3.2.tar.gz
#     else
#         echo "secp256k1 installation not implemented for ${OSNAME}"
#         exit 1
#     fi
#     echo "secp256k1 installation complete!"
# }


remove_all() {
    echo "Removing V installation..."
    # Set reset to true to use existing reset functionality
    RESET=true
    # Call reset functionality
    run_sudo rm -rf ~/code/v
    run_sudo rm -rf ~/_code/v
    run_sudo rm -rf ~/.config/v-analyzer
    if command_exists v; then
        echo "Removing V from system..."
        run_sudo rm -f $(which v)
    fi
    if command_exists v-analyzer; then
        echo "Removing v-analyzer from system..."
        run_sudo rm -f $(which v-analyzer)
    fi
    
    # Remove v-analyzer path from rc files
    for RC_FILE in ~/.zshrc ~/.bashrc; do
        if [ -f "$RC_FILE" ]; then
            echo "Cleaning up $RC_FILE..."
            # Create a temporary file
            TMP_FILE=$(mktemp)
            # Remove lines containing v-analyzer/bin path
            sed '/v-analyzer\/bin/d' "$RC_FILE" > "$TMP_FILE"
            # Remove empty lines at the end of file
            sed -i.bak -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$TMP_FILE"
            # Replace original file
            mv "$TMP_FILE" "$RC_FILE"
            echo "Cleaned up $RC_FILE"
        fi
    done
    
    echo "V removal complete"
}



# Function to check if a service is running and start it if needed
check_and_start_redis() {
    
    # Normal service management for non-container environments
    if [[ "${OSNAME}" == "ubuntu" ]] || [[ "${OSNAME}" == "debian" ]]; then
        
        # Handle Redis installation for GitHub Actions environment
        if is_github_actions; then
            
            # Import Redis GPG key
            curl -fsSL https://packages.redis.io/gpg | run_sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
            # Add Redis repository
            echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | run_sudo tee /etc/apt/sources.list.d/redis.list
            # Install Redis
            run_sudo apt-get update
            run_sudo apt-get install -y redis
            
            # Start Redis
            redis-server --daemonize yes
            
            # Print versions
            redis-cli --version
            redis-server --version
            
            return
        fi
        
        # Check if running inside a container
        if grep -q "/docker/" /proc/1/cgroup || [ ! -d "/run/systemd/system" ]; then
            echo "Running inside a container. Starting redis directly."
            
            if pgrep redis-server > /dev/null; then
                echo "redis is already running."
            else
                echo "redis is not running. Starting it in the background..."
                redis-server --daemonize yes
                if pgrep redis-server > /dev/null; then
                    echo "redis started successfully."
                else
                    echo "Failed to start redis. Please check logs for details."
                    exit 1
                fi
            fi
            return
        fi
        
        if systemctl is-active --quiet "redis"; then
            echo "redis is already running."
        else
            echo "redis is not running. Starting it..."
            run_sudo systemctl start "redis"
            if systemctl is-active --quiet "redis"; then
                echo "redis started successfully."
            else
                echo "Failed to start redis. Please check logs for details."
                exit 1
            fi
        fi
        elif [[ "${OSNAME}" == "darwin"* ]]; then
        # Check if we're in GitHub Actions
        if is_github_actions; then
            echo "Running in GitHub Actions on macOS. Starting redis directly..."
            if pgrep redis-server > /dev/null; then
                echo "redis is already running."
            else
                echo "redis is not running. Starting it in the background..."
                redis-server --daemonize yes
                if pgrep redis-server > /dev/null; then
                    echo "redis started successfully."
                else
                    echo "Failed to start redis. Please check logs for details."
                    exit 1
                fi
            fi
        else
            # For regular macOS environments, use brew services
            if brew services list | grep -q "^redis.*started"; then
                echo "redis is already running."
            else
                echo "redis is not running. Starting it..."
                brew services start redis
            fi
        fi
        elif [[ "${OSNAME}" == "alpine"* ]]; then
        if rc-service "redis" status | grep -q "running"; then
            echo "redis is already running."
        else
            echo "redis is not running. Starting it..."
            rc-service "redis" start
        fi
        elif [[ "${OSNAME}" == "arch"* ]]; then
        if systemctl is-active --quiet "redis"; then
            echo "redis is already running."
        else
            echo "redis is not running. Starting it..."
            run_sudo systemctl start "redis"
        fi
    else
        echo "Service management for redis is not implemented for platform: $OSNAME"
        exit 1
    fi
}

v-install() {
    
    # Check if v is already installed and in PATH
    if command_exists v; then
        echo "V is already installed and in PATH."
        # Optionally, verify the installation location or version if needed
        # For now, just exit the function assuming it's okay
        return 0
    fi
    
    
    # Only clone and install if directory doesn't exist
    # Note: The original check was for ~/code/v, but the installation happens in ~/_code/v.
    if [ ! -d ~/_code/v ]; then
        echo "Cloning V..."
        mkdir -p ~/_code
        cd ~/_code
        if ! git clone --depth=1 https://github.com/vlang/v; then
            echo "❌ Failed to clone V. Cleaning up..."
            rm -rf "$V_DIR"
            exit 1
        fi
    fi
    
    
    # Only clone and install if directory doesn't exist
    # Note: The original check was for ~/code/v, but the installation happens in ~/_code/v.
    # Adjusting the check to the actual installation directory.
    echo "Building V..."
    cd ~/_code/v
    make
    # Verify the build produced the executable
    if [ ! -x ~/_code/v/v ]; then
        echo "Error: V build failed, executable ~/_code/v/v not found or not executable."
        exit 1
    fi
    # Check if the built executable can report its version
    if ! ~/_code/v/v -version > /dev/null 2>&1; then
        echo "Error: Built V executable (~/_code/v/v) failed to report version."
        exit 1
    fi
    echo "V built successfully. Creating symlink..."
    run_sudo ./v symlink
    
    # Verify v is in path
    if ! command_exists v; then
        echo "Error: V installation failed or not in PATH"
        echo "Please ensure ~/code/v is in your PATH"
        exit 1
    fi
    
    echo "V installation successful!"
    
}


v-analyzer() {
    
    set -ex
    
    # Install v-analyzer if requested
    if [ "$INSTALL_ANALYZER" = true ]; then
        echo "Installing v-analyzer..."
        cd /tmp
        v download -RD https://raw.githubusercontent.com/vlang/v-analyzer/main/install.vsh
        
        # Check if v-analyzer bin directory exists
        if [ ! -d "$HOME/.config/v-analyzer/bin" ]; then
            echo "Error: v-analyzer bin directory not found at $HOME/.config/v-analyzer/bin"
            echo "Please ensure v-analyzer was installed correctly"
            exit 1
        fi
        
        echo "v-analyzer installation successful!"
    fi
    
    # Add v-analyzer to PATH if installed
    if [ -d "$HOME/.config/v-analyzer/bin" ]; then
        V_ANALYZER_PATH='export PATH="$PATH:$HOME/.config/v-analyzer/bin"'
        
        # Function to add path to rc file if not present
        add_to_rc() {
            local RC_FILE="$1"
            if [ -f "$RC_FILE" ]; then
                if ! grep -q "v-analyzer/bin" "$RC_FILE"; then
                    echo "" >> "$RC_FILE"
                    echo "$V_ANALYZER_PATH" >> "$RC_FILE"
                    echo "Added v-analyzer to $RC_FILE"
                else
                    echo "v-analyzer path already exists in $RC_FILE"
                fi
            fi
        }
        
        # Add to both .zshrc and .bashrc if they exist
        add_to_rc ~/.zshrc
        if [ "$(uname)" = "Darwin" ] && [ -f ~/.bashrc ]; then
            add_to_rc ~/.bashrc
        fi
    fi
}



# Handle remove if requested
if [ "$REMOVE" = true ]; then
    remove_all
    exit 0
fi

# Create code directory if it doesn't exist
mkdir -p ~/code


# Check if v needs to be installed
if [ "$RESET" = true ] || ! command_exists v; then
    
    os_update
    
    sshknownkeysadd
    
    # Install secp256k1
    
    v-install
    
    
    
fi


check_and_start_redis

if [ "$HEROLIB" = true ]; then
    # Check if we're in GitHub Actions and already in the herolib directory
    if is_github_actions && [ -f "./install_herolib.vsh" ]; then
        echo "Running in GitHub Actions, using current directory for herolib installation"
        HEROLIB_DIR="$(pwd)"
    else
        hero_lib_get
        HEROLIB_DIR="$HOME/code/github/incubaid/herolib"
    fi

    echo "Installing herolib from: $HEROLIB_DIR"
    "$HEROLIB_DIR/install_herolib.vsh"
fi


if [ "$INSTALL_ANALYZER" = true ]; then
    # Only install v-analyzer if not in GitHub Actions environment
    if ! is_github_actions; then
        v-analyzer
    fi
    echo "Run 'source ~/.bashrc' or 'source ~/.zshrc' to update PATH for v-analyzer"
fi


echo "Installation complete!"
