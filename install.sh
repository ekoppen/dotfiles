#install script 

#SYS
echo "installing ssh config..."
cp ./ssh/config ~/.ssh/config

echo "installing fonts"
unzip -o ./fonts/\*.zip -d ~/Library/Fonts

#TOOLS
echo "installing homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "installing zsh en voorkeuren..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

cp ./zsh/.zshrc ~

echo "installing iTerm"
brew install iterm2

