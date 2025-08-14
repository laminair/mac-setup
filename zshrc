

# Setup plugins for faster access and better command line support
plugins=( git bundler dotenv macos rake rbenv ruby uv brew conda dotenv gh tmux virtualenv xcode vscode )

# Configure ZSH theme
ZSH_THEME="powerlevel10k/powerlevel10k"


# Brew config
export xbrew='arch -x86_64 /usr/local/bin/brew'
export mbrew='arch -arm64e /opt/homebrew/bin/brew'

source $ZSH/oh-my-zsh.sh
