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
echo -e "\n "
read -p "Enter email for standard Git repositories: " standardEmail
echo " "
read -p "Enter name for standard Git repositories: " standardName
echo  " "
read -p "Enter email for work Git repositories: " workEmail
echo  " "
read -p "Enter name for work Git repositories: " workName
echo  " "
read -p "Enter GPG key ID for the key associated with Git: " gpgKey
echo " "

read -p "Do you want to update and upgrade packages [y/n]? " updateAndUpgradeReply
if [[ $updateAndUpgradeReply =~ ^[Yy]$ ]]
then
	echo -e "\nUpdating and upgrading packages...\n"
	echo $sudoPassword | sudo -S apt update && sudo -S apt upgrade -y 
echo $sudoPassword | sudo -S apt update && sudo -S apt upgrade -y
	echo $sudoPassword | sudo -S apt update && sudo -S apt upgrade -y 
fi


echo  " "
read -p "Do you want to generate and set up SSH keys? [y/n] " sshReply
if [[ $sshReply =~ ^[Yy]$ ]]
then
	echo -e "\nGenerating SSH keys...\n"
	ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -C "${standardEmail}"
	ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519.work -C "${workEmail}"
	eval "$(ssh-agent -s)"
	ssh-add ~/.ssh/id_ed25519
	ssh-add ~/.ssh/id_ed25519.work
fi

echo  " "
read -p "Do you want to set up GPG keys reference and cache password for 3 hours after first prompt? [y/n] " gpgReply
if [[ $gpgReply =~ ^[Yy]$ ]]
then
	echo -e "\nSetting up GPG key reference..."
	touch ~/.bashrc_backup
	cat ~/.bashrc > ~/.bashrc_backup
	echo -e '\n# Enable reference to tty output for GPG environment variable\nexport GPG_TTY=$(tty)' >> ~/.bashrc

	echo -e "\nSetting GPG agent to not ask for the passphrase again in three hours...\n"
	touch ~/.gnupg/gpg-agent.conf
	tee ~/.gnupg/gpg-agent.conf <<-EOL
	default-cache-ttl 10800
	EOL
	echo "Done!"
fi

echo  " "
read -p "Do you want to set up repo folders? [y/n] " foldersReply
if [[ $foldersReply =~ ^[Yy]$ ]]
then
	echo -e "\nCreating repo folder on user home with work and standard repos...\n"
	cd ~
	mkdir -p repositories
	cd repositories
	mkdir -p work
	mkdir -p standard
	echo "Created!"
fi

echo  " "
read -p "Do you want to set up Git? [y/n] " gitReply
if [[ $gitReply =~ ^[Yy]$ ]]
then
	echo -e "\nSetting up Git...\n"
	cd ~
	touch .gitconfig
	touch .gitconfig.work

	tee .gitconfig <<-EOL
	# Common and fallback configurations
	[user]
		name = ${standardName}
		email = ${standardEmail}
		signingkey = ${gpgKey}
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

	echo " "
	tee .gitconfig.work <<-EOL
	[user]
		name = ${workName}
		email = ${workEmail}
	[core]
		sshCommand = ssh -i ~/.ssh/id_ed25519.work
	EOL
fi

# At this point, you should add the public keys to GitHub








echo -e "\nDone!"