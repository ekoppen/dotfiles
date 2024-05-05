#install script 

#SYS
echo "installing ssh config..."
cp ./ssh/config ~/.ssh/config

#TOOLS
echo "installing homebrew..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "installing zsh en voorkeuren..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
brew install zsh-autosuggestions zsh-syntax-highlighting
cp ./zsh/.zshrc ~

echo "installing iTerm"
brew install iterm2
