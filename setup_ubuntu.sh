#!/bin/bash

# Ubuntu 24.04 Development Environment Setup Script
set -e  # Exit on any error

echo "Starting Ubuntu 24.04 development environment setup..."

# Update package lists
sudo apt update

# Install essential system packages
echo "Installing essential system packages..."
essential_packages=(
    build-essential
    libncursesw5-dev
    libssl-dev
    libgdbm-dev
    libc6-dev
    libsqlite3-dev
    libbz2-dev
    libffi-dev
    zlib1g-dev
    liblzma-dev
    libncurses5-dev
    libgdbm-dev
    libnss3-dev
    libreadline-dev
    libffi-dev
    wget
    curl
    git
    tmux
    apt-transport-https
    ca-certificates
    gnupg
    lsb-release
    software-properties-common
    zsh
)

for package in "${essential_packages[@]}"; do
    if ! dpkg -l | grep -q "^ii  $package "; then
        echo "Installing $package..."
        sudo apt install -y "$package"
    else
        echo "$package is already installed"
    fi
done

# Add Python PPA for latest Python versions
echo "Adding Python PPA repository..."
if ! grep -q "deadsnakes/ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
    sudo add-apt-repository ppa:deadsnakes/ppa -y
    sudo apt update
fi

# Install Python and related packages
echo "Installing Python packages..."
python_packages=(
    python3.12
    python3.12-dev
    python3.12-venv
    python3-pip
)

for package in "${python_packages[@]}"; do
    if ! dpkg -l | grep -q "^ii  $package "; then
        echo "Installing $package..."
        sudo apt install -y "$package"
    else
        echo "$package is already installed"
    fi
done

# Set Python 3.12 as default python3
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# Install GitHub CLI
echo "Installing GitHub CLI..."
if ! command -v gh &> /dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install -y gh
else
    echo "GitHub CLI is already installed"
fi

# Install Docker
echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Remove old versions
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Set up the stable repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add user to docker group
    sudo usermod -aG docker $USER
else
    echo "Docker is already installed"
fi

# Install Ollama
echo "Installing Ollama..."
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.ai/install.sh | sh
else
    echo "Ollama is already installed"
fi

# Install uv package manager
echo "Installing uv package manager..."
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # Add uv to PATH for current session
    export PATH="$HOME/.cargo/bin:$PATH"
else
    echo "uv is already installed"
fi

# Change default shell to zsh if not already
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Changing default shell to zsh..."
    chsh -s $(which zsh)
fi

# Install Oh My ZSH
echo "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh is already installed"
fi

# Backup original files
echo "Creating backups of existing config files..."
[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.bak
[ -f ~/.tmux.conf ] && cp ~/.tmux.conf ~/.tmux.conf.bak
echo "Created backups of .zshrc and .tmux.conf files (if they exist)"

# Move custom files into their right place
ZSH_CONFIG_PATH="$HOME/.zshrc"
ZSH_SOURCE_CONFIG_PATH="zshrc"

if [ -f "$ZSH_SOURCE_CONFIG_PATH" ]; then
    echo "Processing custom zshrc configuration..."

    # Create a temporary file to store existing lines
    TEMP_EXISTING=$(mktemp)

    # Read existing lines into temp file
    if [ -f "$ZSH_CONFIG_PATH" ]; then
        cat "$ZSH_CONFIG_PATH" > "$TEMP_EXISTING"
    fi

    # Process source file and append only new lines
    while IFS= read -r line; do
        # Check if line already exists in the file
        if ! grep -Fxq "$line" "$TEMP_EXISTING" 2>/dev/null; then
            # Line doesn't exist, append it
            echo "$line" >> "$ZSH_CONFIG_PATH"
            echo "$line" >> "$TEMP_EXISTING"
        fi
    done < "$ZSH_SOURCE_CONFIG_PATH"

    # Clean up temp file
    rm -f "$TEMP_EXISTING"
    echo "Added custom config to .zshrc"
else
    echo "Warning: zshrc source file not found, skipping custom zsh configuration"
fi

# Copy tmux config
if [ -f "tmux.conf" ]; then
    cp tmux.conf ~/.tmux.conf
    echo "Initialized tmux config"
else
    echo "Warning: tmux.conf source file not found, skipping tmux configuration"
fi

# Add Oh-my-zsh theme (Powerlevel10k)
echo "Installing Powerlevel10k theme..."
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
THEME_FOLDER="$ZSH_CUSTOM/themes/powerlevel10k"
if [ ! -d "$THEME_FOLDER" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$THEME_FOLDER"
    echo "Added oh-my-zsh theme"
else
    echo "Powerlevel10k theme is already installed"
fi

# Configure tmux plugin manager
echo "Installing tmux plugin manager..."
TPM_LOCAL_PATH="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_LOCAL_PATH" ]; then
    git clone https://github.com/tmux-plugins/tpm "$TPM_LOCAL_PATH"
    echo "Added tmux plugin manager. When opening tmux for the first time hit prefix + I (typically: prefix=ctrl+b) to install everything."
else
    echo "Tmux plugin manager is already installed"
fi

# Move source command to end of file. Required to load plugins properly.
if [ -f ~/.zshrc ]; then
    echo "Moving Oh My Zsh source statement to end of file..."
    sed "/^source \$ZSH\/oh-my-zsh\.sh$/d" ~/.zshrc > temp && echo "source \$ZSH/oh-my-zsh.sh" >> temp && mv temp ~/.zshrc
    echo "Moved source statement to end of file"
fi

# Create an SSH key if not exists
echo "Checking for SSH keys..."
if [ ! -f ~/.ssh/id_ed25519 ] && [ ! -f ~/.ssh/id_rsa ] && [ ! -f ~/.ssh/id_ecdsa ]; then
    echo "Creating SSH key..."
    mkdir -p ~/.ssh
    ssh-keygen -t ed25519 -C "$USER@$(hostname)" -f "$HOME/.ssh/${USER}_ed25519" -N ""
    echo "SSH key created and saved to ~/.ssh (ED-25519 key)"
else
    echo "SSH key already exists"
fi

# Add uv to PATH in zshrc if not already there
if [ -f ~/.zshrc ] && ! grep -q 'export PATH="$HOME/.cargo/bin:$PATH"' ~/.zshrc; then
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.zshrc
    echo "Added uv to PATH in .zshrc"
fi

# Final message
echo ""
echo "✅ Ubuntu 24.04 development environment setup complete!"
echo ""
echo "🔄 Please run the following to reload your shell:"
echo "   source ~/.zshrc"
echo ""
echo "📦 Installed packages and tools:"
echo "   • Essential build tools and libraries"
echo "   • Python 3.12 with development packages"
echo "   • uv package manager (fast Python package manager)"
echo "   • GitHub CLI"
echo "   • Docker with Docker Compose"
echo "   • Ollama"
echo "   • Oh My Zsh with Powerlevel10k theme"
echo "   • tmux with plugin manager"
echo ""
echo "🔑 SSH key created at ~/.ssh/${USER}_ed25519"
echo "   Add the public key to your Git hosting service:"
echo "   cat ~/.ssh/${USER}_ed25519.pub"
echo ""
echo "🐳 Note: You may need to log out and log back in for Docker group permissions to take effect"
echo ""
echo "🎨 To configure Powerlevel10k theme, run: p10k configure"
