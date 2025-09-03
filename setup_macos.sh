#!/bin/zsh

# Install and enable macos developer tools
if xcode-select -p &> /dev/null; then
    echo "Xcode Command Line Tools are already installed"
else
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
fi

# Install Rosetta 2 (x86 Emulator)
if pkgutil --pkgs | grep -q "com.apple.pkg.RosettaUpdateAuto"; then
    echo "Rosetta 2 is already installed"
else
    echo "Installing Rosetta 2..."
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license
fi

# Install Homebrew (for arm64 and x86 Rosetta2 apps)
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Oh My ZSH
[ ! -d "$HOME/.oh-my-zsh" ] && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install essential brew packages & casks
is_brew_installed() {
    brew list "$1" &> /dev/null
}

is_cask_installed() {
    brew list --cask "$1" &> /dev/null
}

packages=(tmux tpm docker ollama)
for package in "${packages[@]}"; do
    if ! is_brew_installed "$package"; then
        echo "Installing $package..."
        brew install "$package"
    else
        echo "$package is already installed"
    fi
done

casks=(iterm2 tunnelblick microsoft-office claude-code font-powerline-symbols)
for cask in "${casks[@]}"; do
    if ! is_cask_installed "$cask"; then
        echo "Installing $cask..."
        brew install --cask "$cask"
    else
        echo "$cask is already installed"
    fi
done
echo "Installed essential packages via homebrew"


## Backup original files
cp ~/.zshrc ~/.zshrc.bak
cp ~/.tmux.conf ~/.tmux.conf.bak
echo "Created backups of .zshrc and .tmux.conf files (if exists)"

# Move custom files into their right place.
typeset -A existing_lines
ZSH_CONFIG_PATH="$HOME/.zshrc"
ZSH_SOURCE_CONFIG_PATH="zshrc"

# Read existing lines (assuming format like "key=value" or just unique lines)
if [[ -f "$ZSH_CONFIG_PATH" ]]; then
    while IFS= read -r line; do
        existing_lines[$line]=1
    done < "$ZSH_CONFIG_PATH"
fi

# Process source file
while IFS= read -r line; do
    if [[ -z "${existing_lines[$line]}" ]]; then
        # Line doesn't exist, append it
        echo "$line" >> "$ZSH_CONFIG_PATH"
        existing_lines[$line]=1
    fi
done < "$ZSH_SOURCE_CONFIG_PATH"
echo "Added custom config to .zshrc"

cp tmux.conf ~/.tmux.conf
echo "Initialized tmux config"

# Add Oh-my-zsh theme
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
THEME_FOLDER="$ZSH_CUSTOM/themes/powerlevel10k"
if [ ! -d "$THEME_FOLDER" ] ; then
    git clone https://github.com/romkatv/powerlevel10k.git "$THEME_FOLDER"
fi
echo "Added oh-my-zsh theme"

# Configure tmux plugin manager
TPM_LOCAL_PATH="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_LOCAL_PATH" ] ; then
    git clone git clone https://github.com/tmux-plugins/tpm "$TPM_LOCAL_PATH"
fi
echo "Added tmux plugin manager. When opening tmux for the first time hit prefix + I (typically: prefix=ctrl+b) to install everything."


# Move source command to end of file. Required to load plugins properly.
sed "/^source \$ZSH\/oh-my-zsh\.sh$/d" ~/.zshrc > temp && echo "source $ZSH/oh-my-zsh.sh" >> temp && mv temp ~/.zshrc
echo "Moved source statement to end of file"

# Create an SSH key if not exists
if [ ! -f ~/.ssh/id_ed25519 ] && [ ! -f ~/.ssh/id_rsa ] && [ ! -f ~/.ssh/id_ecdsa ]; then
    ssh-keygen -t ed25519 -C "$USER@$HOST" -f "$HOME""/.ssh/""$USER""_ed25519"
fi
echo "SSH key created and saved to ~/.ssh (ED-25519 key)"
