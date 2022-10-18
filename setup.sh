#!/bin/bash

# This script deploys a basic server for deploying CAPE using K3d on a single server

set -e
G="\e[32m"
Y="\e[33m"
R="\e[31m"
E="\e[0m"

FILE=.vars
if test -f "$FILE"; then
    echo -e ${G}"$FILE exists. Clear to proceed..."${E}
else
    echo -e ${R}"Whoops! $FILE does not exist. Please create the $FILE from $FILE.dist before proceeding. Details in the README.md"${E}
    exit 1
fi

source .vars

# Determine OS platform
UNAME=$(uname | tr "[:upper:]" "[:lower:]")
# If Linux, try to determine specific distribution
if [ "$UNAME" == "linux" ]; then
    # If available, use LSB to identify distribution
    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
        export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
    # Otherwise, use release info file
    else
        export DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
    fi
fi
# For everything else (or if above failed), just use generic identifier
[ "$DISTRO" == "" ] && export DISTRO=$UNAME

# Confirm OS is compatible with script
if [[ "$DISTRO" == *"Ubuntu"* ]] || [[ "$DISTRO" == *"debian"* ]]; then
  echo "This is Ubuntu or Debian. You have clearance Clarence to proceed..."
elif [[ "$DISTRO" == *"centos"* ]] || [[ "$DISTRO" == *"fedora"* ]] || [[ "$DISTRO" == *"rocky"* ]]; then
  echo "This is RHEL Based. You have clearance Clarence to proceed..."
else
  echo "Cannot be run on this systems. Needs to be Debian based (Ubuntu or Debian) or RHEL Based (RHEL, CentOS, Rocky, Fedora, Alma) to proceed. No install for you."
fi

## Install Docker

# Install Updates on Ubuntu/Debian
if [[ "$DISTRO" == *"Ubuntu"* ]] || [[ "$DISTRO" == *"debian"* ]]; then
  echo -e ${G}"Installing OS Updates..."${E}
  sudo DEBIAN_FRONTEND=noninteractive apt-get update #> /dev/null 2>&1
  sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y #> /dev/null 2>&1
else
  :
fi

if [[ "$DISTRO" == *"Ubuntu"* ]] || [[ "$DISTRO" == *"debian"* ]]; then
  echo -e ${G}"Installing packages..."${E}
  sudo DEBIAN_FRONTEND=noninteractive apt-get install ca-certificates curl gnupg lsb-release unzip haveged zsh jq nano git -y
else
  :
fi

#########################
# Install Updates and Packages
#########################

# Install Updates on Ubuntu/Debian
if [[ "$DISTRO" == *"Ubuntu"* ]] || [[ "$DISTRO" == *"debian"* ]]; then
  echo -e ${G}"Installing OS Updates..."${E}
  sudo DEBIAN_FRONTEND=noninteractive apt-get update #> /dev/null 2>&1
  sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y #> /dev/null 2>&1
else
  :
fi

if [[ "$DISTRO" == *"Ubuntu"* ]] || [[ "$DISTRO" == *"debian"* ]]; then
  echo -e ${G}"Installing packages..."${E}
  sudo DEBIAN_FRONTEND=noninteractive apt-get install ca-certificates curl gnupg lsb-release unzip haveged zsh jq nano git -y
else
  :
fi

# Install Updates on RHEL Based
if [[ "$DISTRO" == *"centos"* ]] || [[ "$DISTRO" == *"redhat"* ]] || [[ "$DISTRO" == *"rocky"* ]]; then
  echo -e ${G}"Installing OS Updates..."${E}
  sudo dnf upgrade --refresh -y
else
  :
fi

# Installing EPEL, yum-utils, dnf-plugins-core
if [[ "$DISTRO" == *"centos"* ]] || [[ "$DISTRO" == *"rocky"* ]]; then
  echo -e ${G}"Installing EPEL, yum-utils, dnf-plugins-core..."${E}
  sudo dnf install zsh epel-release yum-utils dnf-plugins-core -y
else
  :
fi

# Installing RPM Fusion, yum-utils, dnf-plugins-core on Fedora
if [[ "$DISTRO" == *"fedora"* ]]; then
  echo -e ${G}"Installing EPEL, yum-utils, dnf-plugins-core..."${E}
  sudo dnf upgrade --refresh -y
  sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm -y
  sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
  sudo dnf install yum-utils dnf-plugins-core -y
else
  :
fi

# Install prereq packages
if [[ "$DISTRO" == *"centos"* ]] || [[ "$DISTRO" == *"redhat"* ]] || [[ "$DISTRO" == *"rocky"* ]]; then
  echo -e ${G}"Installing prereq packages..."${E}
  sudo dnf update
  sudo dnf install ca-certificates curl gnupg unzip haveged zsh jq nano git util-linux-user -y
  update-ca-trust enable
  update-ca-trust extract
else
  :
fi

#########################
# Install ZSH
#########################

## Make ZSH Default Shell
echo -e ${G}"Making ZSH the default shell..."${E}
sudo chsh -s /bin/zsh $USER  > /dev/null 2>&1

## Install oh-my-zsh
echo -e ${G}"Installing oh-my-zsh..."${E}
DIR1=~/.oh-my-zsh
if [ -d "$DIR1" ]; then
    echo -e ${G} "$DIR1 exists. No need to install oh-my-zsh again."${E}
else 
    echo -e ${G} "$DIR1 does not exist. Installing oh-my-zsh."${E}
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended  > /dev/null 2>&1
fi

## Install ZSH things
echo -e ${G}"Installing ZSH things..."${E}
DIR2=~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
if [ -d "$DIR2" ]; then
    echo -e ${G} "$DIR2 exists. No need to install plugins again."${E}
else
    echo -e ${G} "$DIR2 does not exist. Installing plugins."${E}
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting  > /dev/null 2>&1
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions  > /dev/null 2>&1
fi

rm ~/.zshrc
cp assets/.zshrc ~/.zshrc

#########################
# Install Docker
#########################

## Install Docker on Ubuntu
if [[ "$DISTRO" == *"Ubuntu"* ]]; then
    echo -e ${G}"Installing Docker..."${E}
    sudo mkdir -p /etc/apt/keyrings  > /dev/null 2>&1
    sudo rm -f -- /etc/apt/keyrings/docker.gpg  > /dev/null 2>&1
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg  > /dev/null 2>&1
    echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update  > /dev/null 2>&1
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y  > /dev/null 2>&1
    sudo usermod -aG docker $USER  > /dev/null 2>&1
else
  :
fi

## Install Docker on Debian
if [[ "$DISTRO" == *"debian"* ]]; then
    echo -e ${G}"Installing Docker on Debian..."${E}
    sudo mkdir -p /etc/apt/keyrings  > /dev/null 2>&1
    sudo rm -f -- /etc/apt/keyrings/docker.gpg  > /dev/null 2>&1
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update  > /dev/null 2>&1
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y  > /dev/null 2>&1
    sudo usermod -aG docker $USER  > /dev/null 2>&1
else
  :
fi

#########################
# Install Kubectl
#########################

echo -e ${G}"Installing Kubectl..."${E}
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"  > /dev/null 2>&1
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl  > /dev/null 2>&1

#########################
# Install FZF
#########################
if [[ "$DISTRO" == *"Ubuntu"* ]] || [[ "$DISTRO" == *"debian"* ]]; then
    sudo apt-get install fzf
else [[ "$DISTRO" == *"fedora"* ]] || [[ "$DISTRO" == *"centos"* ]] || [[ "$DISTRO" == *"rocky"* ]];
    sudo dnf install fzf
fi

#########################
# Install Krew
#########################

KREWDIR=~/.krew
if [ -d "$KREWDIR" ]; then
    echo -e ${G} "$KREWDIR exists. No need to install Krew again."${E}
else
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)
fi

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

#########################
# Install kubectx & kubens
#########################

kubectl krew install ctx
kubectl krew install ns

#########################
# Install K3d
#########################

echo -e ${G}"Installing k3d..."${E}
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash



#########################
# Install VSCode Server
#########################

## Install VSCode Server on Debian Based
if [[ "$DISTRO" == *"Ubuntu"* ]] || [[ "$DISTRO" == *"debian"* ]]; then
    echo -e ${G}"Installing VSCode-Server..."${E}
    sudo mkdir -p $VSCODE_DIR_PATH
    mkdir -p /home/$USER/misc/code-server/User
    curl -fsSL -o /tmp/code-server_${VSCODE_VERSION}_amd64.deb https://github.com/coder/code-server/releases/download/v${VSCODE_VERSION}/code-server_${VSCODE_VERSION}_amd64.deb
    sudo dpkg -i /tmp/code-server_${VSCODE_VERSION}_amd64.deb
    sudo systemctl stop code-server@$USER
    sudo rm /lib/systemd/system/code-server@.service
    cat << EOF | sudo tee /lib/systemd/system/code-server@.service
    [Unit]
    Description=code-server
    After=network.target

    [Service]
    User=$USER
    Group=$USER
    Type=exec
    Environment=PASSWORD=$VSCODE_PASSWORD
    ExecStart=/usr/bin/code-server --bind-addr 0.0.0.0:8080 --user-data-dir /home/$USER/misc/code-server --auth password $VSCODE_DIR_PATH
    Restart=always

    [Install]
    WantedBy=default.target
EOF
    cp assets/settings.json /home/$USER/misc/code-server/User/settings.json
    sudo systemctl enable --now code-server@$USER
else [[ "$DISTRO" == *"fedora"* ]] || [[ "$DISTRO" == *"centos"* ]] || [[ "$DISTRO" == *"rocky"* ]];
    echo -e ${G}"Installing VSCode-Server..."${E}
    sudo mkdir -p $VSCODE_DIR_PATH
    mkdir -p /home/$USER/misc/code-server/User
    sudo chown -R $USER:$USER /home/$USER/misc/code-server/User
    curl -fsSL -o /tmp/code-server_${VSCODE_VERSION}_amd64.rpm https://github.com/coder/code-server/releases/download/v${VSCODE_VERSION}/code-server-${VSCODE_VERSION}-amd64.rpm
    sudo rpm -iv --replacepkgs /tmp/code-server_${VSCODE_VERSION}_amd64.rpm
    sudo systemctl stop code-server@$USER
    sudo rm /lib/systemd/system/code-server@.service
    cat << EOF | sudo tee /lib/systemd/system/code-server@.service
    [Unit]
    Description=code-server
    After=network.target

    [Service]
    User=$USER
    Group=$USER
    Type=exec
    Environment=PASSWORD=$VSCODE_PASSWORD
    ExecStart=/usr/bin/code-server --bind-addr 0.0.0.0:8080 --user-data-dir /home/$USER/misc/code-server --auth password $VSCODE_DIR_PATH
    Restart=always

    [Install]
    WantedBy=default.target
EOF
    cp assets/settings.json /home/$USER/misc/code-server/User/settings.json
    sudo systemctl enable --now code-server@$USER

fi

#########################
# deploy K3d clusters
#########################
k3d registry create docker-io -p 5000 --proxy-remote-url https://registry-1.docker.io -v ~/.local/share/docker-io-registry:/var/lib/registry

k3d cluster create --k3s-arg "--tls-san=$SERVER_IP"@server:* saas -p "80:80@loadbalancer" --registry-use k3d-docker-io:5000 --registry-config assets/registry.yaml
k3d kubeconfig write saas
sed -i "s/0.0.0.0/$SERVER_IP/g" ~/.k3d/kubeconfig-saas.yaml
k3d kubeconfig merge saas

k3d cluster create --k3s-arg "--tls-san=$SERVER_IP"@server:* eks-demo -p "8010:80@loadbalancer" --registry-use k3d-docker-io:5000 --registry-config assets/registry.yaml
k3d kubeconfig write eks-demo
sed -i "s/0.0.0.0/$SERVER_IP/g" ~/.k3d/kubeconfig-eks-demo.yaml
k3d kubeconfig merge eks-demo

k3d cluster create --k3s-arg "--tls-san=$SERVER_IP"@server:* aks-demo -p "8020:80@loadbalancer" --registry-use k3d-docker-io:5000 --registry-config assets/registry.yaml
k3d kubeconfig write aks-demo
sed -i "s/0.0.0.0/$SERVER_IP/g" ~/.k3d/kubeconfig-aks-demo.yaml
k3d kubeconfig merge aks-demo

k3d cluster create --k3s-arg "--tls-san=$SERVER_IP"@server:* k3s-demo -p "8030:80@loadbalancer" --registry-use k3d-docker-io:5000 --registry-config assets/registry.yaml
k3d kubeconfig write k3s-demo
sed -i "s/0.0.0.0/$SERVER_IP/g" ~/.k3d/kubeconfig-k3s-demo.yaml
k3d kubeconfig merge k3s-demo

k3d cluster create --k3s-arg "--tls-san=$SERVER_IP"@server:* eks-smoketest -p "8040:80@loadbalancer" --registry-use k3d-docker-io:5000 --registry-config assets/registry.yaml
k3d kubeconfig write eks-smoketest
sed -i "s/0.0.0.0/$SERVER_IP/g" ~/.k3d/kubeconfig-eks-smoketest.yaml
k3d kubeconfig merge eks-smoketest

k3d cluster create --k3s-arg "--tls-san=$SERVER_IP"@server:* aks-smoketest -p "8050:80@loadbalancer" --registry-use k3d-docker-io:5000 --registry-config assets/registry.yaml
k3d kubeconfig write aks-smoketest
sed -i "s/0.0.0.0/$SERVER_IP/g" ~/.k3d/kubeconfig-aks-smoketest.yaml
k3d kubeconfig merge aks-smoketest

zsh