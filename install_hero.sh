#!/bin/bash -e

set -e

os_name="$(uname -s)"
arch_name="$(uname -m)"
version='1.0.36'

# Detect Linux distribution type
linux_type=""
if [[ "$os_name" == "Linux" ]]; then
    if [ -f /etc/os-release ]; then
        linux_type="$(. /etc/os-release && echo "$ID")"
    fi
fi

# Base URL for GitHub releases
base_url="https://github.com/incubaid/herolib/releases/download/v${version}"

# Select the URL based on the platform
if [[ "$os_name" == "Linux" && "$arch_name" == "x86_64" ]]; then
    if [[ "$linux_type" == "alpine" ]]; then
        url="$base_url/hero-x86_64-linux-musl"
    else
        url="$base_url/hero-x86_64-linux"
    fi
elif [[ "$os_name" == "Linux" && "$arch_name" == "aarch64" ]]; then
    if [[ "$linux_type" == "alpine" ]]; then
        url="$base_url/hero-aarch64-linux-musl"
    else
        url="$base_url/hero-aarch64-linux"
    fi
elif [[ "$os_name" == "Darwin" && "$arch_name" == "arm64" ]]; then
    url="$base_url/hero-aarch64-apple-darwin"
# elif [[ "$os_name" == "Darwin" && "$arch_name" == "x86_64" ]]; then
#     url="$base_url/hero-x86_64-apple-darwin"
else
    echo "Unsupported platform: $os_name $arch_name"
    exit 1
fi

# Check for existing hero installations
existing_hero=$(which hero 2>/dev/null || true)
if [ ! -z "$existing_hero" ]; then
    echo "Found existing hero installation at: $existing_hero"
    if [ -w "$(dirname "$existing_hero")" ]; then
        echo "Removing existing hero installation..."
        rm "$existing_hero" || { echo "Error: Failed to remove existing hero binary at $existing_hero"; exit 1; }
    else
        echo "Error: Cannot remove existing hero installation at $existing_hero (permission denied)"
        echo "Please remove it manually with sudo and run this script again"
        exit 1
    fi
fi

if [[ "${OSNAME}" == "darwin"* ]]; then
    # Check if /usr/local/bin/hero exists and remove it
    if [ -f /usr/local/bin/hero ]; then
        rm /usr/local/bin/hero || { echo "Error: Failed to remove existing hero binary"; exit 1; }
    fi

    # Check if brew is installed
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is required but not installed."
        read -p "Would you like to install Homebrew? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
                echo "Error: Failed to install Homebrew"
                exit 1
            }
        else
            echo "Homebrew is required to continue. Installation aborted."
            exit 1
        fi
    fi

    # Update Homebrew
    echo "Updating Homebrew..."
    if ! brew update; then
        echo "Error: Failed to update Homebrew. Please check your internet connection and try again."
        exit 1
    fi

    # Upgrade Homebrew packages
    echo "Upgrading Homebrew packages..."
    if ! brew upgrade; then
        echo "Error: Failed to upgrade Homebrew packages. Please check your internet connection and try again."
        exit 1
    fi
fi

if [ -z "$url" ]; then
    echo "Could not find url to download."
    echo $urls
    exit 1
fi
zprofile="${HOME}/.zprofile"
hero_bin_path="${HOME}/hero/bin"
temp_file="$(mktemp)"

# Check if ~/.zprofile exists
if [ -f "$zprofile" ]; then
    # Read each line and exclude any that modify the PATH with ~/hero/bin
    while IFS= read -r line; do
        if [[ ! "$line" =~ $hero_bin_path ]]; then
            echo "$line" >> "$temp_file"
        fi
    done < "$zprofile"
else
    touch "$zprofile"
fi
# Add ~/hero/bin to the PATH statement
echo "export PATH=\$PATH:$hero_bin_path" >> "$temp_file"
# Replace the original .zprofile with the modified version
mv "$temp_file" "$zprofile"
# Ensure the temporary file is removed (in case of script interruption before mv)
trap 'rm -f "$temp_file"' EXIT

# Output the selected URL
echo "Download URL for your platform: $url"

# Download the file
curl -o /tmp/downloaded_file -L "$url"

set -e

# Check if file size is greater than 2 MB
file_size=$(du -m  /tmp/downloaded_file | cut -f1)
if [ "$file_size" -ge 2 ]; then
    # Create the target directory if it doesn't exist
    mkdir -p ~/hero/bin
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Move and rename the file
        mv  /tmp/downloaded_file ~/hero/bin/hero
        chmod +x ~/hero/bin/hero
    else
        mv  /tmp/downloaded_file /usr/local/bin/hero
        chmod +x /usr/local/bin/hero
    fi

    echo "Hero installed properly"
    export PATH=$PATH:$hero_bin_path
    hero -version
else
    echo "Downloaded file is less than 2 MB. Process aborted."
    exit 1
fi
