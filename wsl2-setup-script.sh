#!/usr/bin/bash -i

# To do: 
# - Add color to echoes
# - Include setup for Javascript and Typescript 
# - Implement restrictions for coupled steps if a previous one was skipped
# - Improve command and output printing
# - Make it idempotent

# This script was tested with the Ubuntu 20.04. Before running it you should:
# - Have an Ubuntu 20.04 WSL2 instance ready. As of today, that's a way of doing this:
#	1 - Start an elevated Powershell session.
#	2 - wsl --list --online (To check what are the available distros. Choose Ubuntu for this one.)
# 	3 - wsl --install -d <the Ubuntu distro name given by the previous command>
# - (Optional) Set up the Windows Terminal app
# - Generate a GPG key (and add it to GitHub while you're at it): https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key

echo -e "\nStarting script...\n"
read -s -p "Enter Password for sudo: " sudoPassword
echo -e "\n "
read -p "Enter email (for the Git related steps): " gitEmail
echo " "
read -p "Enter name (for the Git related steps): " gitName
echo  " "
read -p "Enter GPG key ID for the key associated with Git (if it applies): " gpgKey
echo " "

read -p "Do you want to update, upgrade and install relevant packages [y/n]? " updateAndUpgradeReply
if [[ $updateAndUpgradeReply =~ ^[Yy]$ ]]
then
	echo -e "\nUpdating and upgrading packages...\n"
	echo $sudoPassword | sudo -S apt update && sudo -S apt upgrade -y

	echo -e "\nInstalling other tools...\n"
	echo $sudoPassword | sudo -S apt install net-tools -y
fi

# (Reference) To exit the script execution otherwise:
# if [[ ! $updateAndUpgradeReply =~ ^[Yy]$ ]]
# then
#     [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
# fi

echo  " "
read -p "Do you want to generate and set up SSH keys? [y/n] " sshReply
if [[ $sshReply =~ ^[Yy]$ ]]
then
	echo -e "\nGenerating SSH keys...\n"
	ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -C "${gitEmail}"
	eval "$(ssh-agent -s)"
	ssh-add ~/.ssh/id_ed25519
fi

echo  " "
read -p "Do you want to set up GPG keys reference and cache password for 3 hours after first prompt? [y/n] " gpgReply
if [[ $gpgReply =~ ^[Yy]$ ]]
then
	echo -e "\nSetting up GPG key reference..."
	echo -e '\n# Enable reference to tty output for GPG environment variable\nexport GPG_TTY=$(tty)' >> ~/.bashrc

	echo -e "\nSetting GPG agent to not ask for the passphrase again in three hours...\n"
	touch ~/.gnupg/gpg-agent.conf
	tee ~/.gnupg/gpg-agent.conf <<-EOL
	default-cache-ttl 10800
	EOL
	echo "Done!"
fi

echo  " "
read -p "Do you want to set up Git repositories folder? [y/n] " folderReply
if [[ $folderReply =~ ^[Yy]$ ]]
then
	echo -e "\nCreating repositories folder on user home...\n"
	cd ~
	mkdir -p repositories
	echo "Created!"
fi

echo  " "
read -p "Do you want to set up Git? [y/n] " gitReply
if [[ $gitReply =~ ^[Yy]$ ]]
then
	echo -e "\nSetting up Git...\n"
	cd ~
	touch .gitconfig

	tee .gitconfig <<-EOL
	# Common and fallback configurations
	[user]
		name = ${gitName}
		email = ${gitEmail}
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
	EOL

	echo " "
fi

# At this point, you should add the public keys to GitHub:
# https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account

echo  " "
read -p "Do you want to set up Docker engine? [y/n] " dockerReply
if [[ $dockerReply =~ ^[Yy]$ ]]
then
	echo $sudoPassword | sudo -S apt install apt-transport-https ca-certificates curl gnupg lsb-release -y
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg 

	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list

	echo $sudoPassword | sudo -S apt update && sudo -S apt install  docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

	echo $sudoPassword | sudo -S groupadd docker 
	echo $sudoPassword | sudo -S usermod -aG docker $USER 
	newgrp docker

	echo -e "\nTesting Docker with the hello-world image...\n"
	echo $sudoPassword | sudo -S service docker start
	echo $sudoPassword | sudo -S docker run hello-world

	echo -e '\n# Start Docker automatically\nsudo service docker start > /dev/null 2>&1' >> ~/.bashrc
fi

echo  " "
read -p "Do you want to set up kubectl? [y/n] " kubectlReply
if [[ $kubectlReply =~ ^[Yy]$ ]]
then

	echo $sudoPassword | sudo -S curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
	echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] \
	https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

	echo $sudoPassword | sudo -S apt update && sudo -S apt install kubectl -y
	
fi

echo  " "
read -p "Do you want to configure bash-completion? [y/n] " bashReply
if [[ $bashReply =~ ^[Yy]$ ]]
then
	echo $sudoPassword | sudo -S apt install bash-completion -y
	echo -e '\n# Enable kubectl completion using bash\nsource <(kubectl completion bash)' >> ~/.bashrc
fi

echo  " "
read -p "Do you want to set up Minikube? [y/n] " minikubeReply
if [[ $minikubeReply =~ ^[Yy]$ ]]
then
	cd ~
	mkdir downloads
	cd downloads

	curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

	echo $sudoPassword | sudo -S install minikube-linux-amd64 /usr/local/bin/minikube
	minikube start
fi

echo  " "
read -p "Do you want to install Helm? [y/n] " helmReply
if [[ $helmReply =~ ^[Yy]$ ]]
then
	curl -fsSL https://baltocdn.com/helm/signing.asc | sudo gpg --dearmor -o /usr/share/keyrings/helm.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] \
	https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

	echo $sudoPassword | sudo -S apt update && sudo -S apt install helm -y
fi

echo  " "
read -p "Do you want to set up Terraform? [y/n] " terraformReply
if [[ $terraformReply =~ ^[Yy]$ ]]
then
	curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
	
	echo -e "\nHashicorp GPG key fingerprint:\n"
	gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
	echo  " "
	echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
	https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
	echo $sudoPassword | sudo -S apt update && sudo -S apt install terraform -y
	echo -e "\nVerifying terraform installation:\n"
	terraform -version
fi

echo  " "
read -p "Do you want to set up Pip and Pipenv? [y/n] " pipReply
if [[ $pipReply =~ ^[Yy]$ ]]
then
	echo $sudoPassword | sudo -S apt install python3-pip -y
	pip3 --version
	pip install pipenv
fi

echo -e "\nLoading .bashrc and .profile..."
source ~/.bashrc
source ~/.profile

echo -e "\nDone!"