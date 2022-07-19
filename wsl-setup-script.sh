#!/usr/bin/bash

# This script was tested with the Ubuntu 20.04. Before running it you should:
# - Generate a GPG key and add it to GitHub: https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key

# To do: 
# - Ask for permission before each section
# - Add color to echoes
# - Include installation of VS Code
# - Include installation of Docker engine
# - Include installation of K3s

echo -e "\nStarting script...\n"
read -s -p "Enter Password for sudo: " sudoPassword
echo -e "\nok"
read -p "Enter email for standard Git repositories: " standardEmail
echo "ok"
read -p "Enter name for standard Git repositories: " standardName
echo  "ok"
read -p "Enter email for work Git repositories: " workEmail
echo  "ok"
read -p "Enter name for work Git repositories: " workName
echo  "ok"

echo -e "\nUpdating and upgrading packages...\n"
echo $sudoPassword | sudo -S apt update && sudo -S apt upgrade -y

echo -e "\nGenerating SSH keys...\n"
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -C "${standardEmail}"
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519.work -C "${workEmail}"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
ssh-add ~/.ssh/id_ed25519.work

echo -e "\nSetting up GPG key reference for Git...\n"
touch ~/.bashrc_backup
cat ~/.bashrc > ~/.bashrc_backup
echo -e '\nexport GPG_TTY=$(tty)' >> ~/.bashrc
echo "Done!"

echo -e "\nCreating repo folder on user home with work and open repos...\n"
cd ~
mkdir repositories
cd repositories
mkdir work
mkdir standard
echo "Created!"

echo -e "\nSetting up Git and GitHub...\n"
cd ~
touch .gitconfig
touch .gitconfig.work

tee .gitconfig <<EOL
# Common and fallback configurations
[user]
    name = ${standardName}
    email = ${standardEmail}
[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519
[color]
    ui = auto
[init]
    defaultBranch = main
[commit]
    gpgSign = true
[gpg]
    program = /usr/bin/gpg
# Conditional configuration for work repositories
[includeIf "gitdir:~/repositories/work/"]
    path = .gitconfig.work
EOL

tee .gitconfig.work <<EOL
[user]
    name = ${workName}
    email = ${workEmail}
[core]
    sshCommand = ssh -i ~/.ssh/id_ed25519.work
EOL

# At this point, you should add the public keys to GitHub

echo -e "\nSetting GPG agent to not ask for the passphrase again in three hours...\n"
touch ~/.gnupg/gpg-agent.conf
tee ~/.gnupg/gpg-agent.conf <<EOL
default-cache-ttl 10800
EOL

echo "Done!"