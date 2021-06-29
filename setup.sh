#!/bin/bash
# -----------------------------------------------------------------------------
# Archive:    setup.sh
# Function:   Install and upgrade the AWX platform. This automation need internet
#             access to perform all tasks.
#
# Autor:      Lucas Afonso Kremer
#
#
# Review:     June/2020
# Reviwed by: Lucas Afonso Kremer
# -----------------------------------------------------------------------------
# Versions: 
#	      1.0 - Install docker, AWX and Operating System on localhost 
#	      2.0 - Profiling the operating system
#
# Examples:
#	      Run: sh setup.sh (this command will print all informations)
#
# -----------------------------------------------------------------------------
# Global vars
# -----------------------------------------------------------------------------
 CURRENTPATH=$(pwd)
 SCRIPTPATH=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
 CENTOSVERSION=$(cat /etc/redhat-release | awk '{printf "%d", $4}')
 ANSIBLELOCALVERSION=2.9.1.0
# -----------------------------------------------------------------------------
# Environment vars
# -----------------------------------------------------------------------------
export PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin
# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------
f_verifyexecutionpath() {
	if [ "$CURRENTPATH" != "$SCRIPTPATH" ]
	then 
		cd "$SCRIPTPATH"
	fi
}
f_installrequirements() {
	echo "----------------------------------------------------------------"
	echo "Requirements: Started"
	echo "----------------------------------------------------------------"
        yum clean all
	yum install epel-release -y
        yum install git -y
	if [ "$CENTOSVERSION" -eq "7" ]
	then
		yum install python-pip -y
                pip install --upgrade pip
		pip install ansible==$ANSIBLELOCALVERSION
	fi
        if [ "$CENTOSVERSION" -ge "8" ]
        then
                yum install python3-pip -y
                pip3 install ansible==$ANSIBLELOCALVERSION
        fi
}
f_setupso() {
	echo "----------------------------------------------------------------"
	echo "Operating System: Setup"
	echo "----------------------------------------------------------------"
	ansible-playbook playbooks/awx-so-setup.yml
}
f_systemprofile() {
        echo "----------------------------------------------------------------"
        echo "Operating System: System profile"
        echo "----------------------------------------------------------------"
	ansible-playbook playbooks/awx-tuned.yml
}
f_installdocker() {
	echo "----------------------------------------------------------------"
	echo "Docker: Setup"
	echo "----------------------------------------------------------------"
	ansible-playbook playbooks/awx-docker-setup.yml
}
f_cloneawxproject() {
	echo "----------------------------------------------------------------"
	echo "AWX: Download project"
	echo "----------------------------------------------------------------"
        if [ -d "$SCRIPTPATH"/awx ]
        then
		echo "----------------------------------------------------------------"
		echo "The awx project already exists"
		echo "----------------------------------------------------------------"
        else
                git clone https://github.com/ansible/awx.git
        fi
}
f_setupcentos8dockerinterface() {
if [ "$CENTOSVERSION" -ge "8" ]
then
	echo "----------------------------------------------------------------"
	echo "AWX: Setup dockerfile network"
	echo "----------------------------------------------------------------"
	ansible-playbook playbooks/awx-docker-composefile.yml
fi
}
f_installawxproject() {
	echo "----------------------------------------------------------------"
	echo "AWX: Install AWX"
	echo "----------------------------------------------------------------"
	if [ -f "$SCRIPTPATH"/variables/vars.yml ] && [ "$SCRIPTPATH"/vault/secret.yml ]
	then
		if [ "$CENTOSVERSION" -eq "7" ]
        	then
			echo "Please, provide your vault password before we start"
			ansible-playbook -i awx/installer/inventory awx/installer/install.yml --e "@variables/vars.yml" --e "@vault/secret.yml" --ask-vault-pass
		fi
		if [ "$CENTOSVERSION" -ge "8" ]
        	then
			echo "Please, provide your vault password before we start"
			ansible-playbook -i awx/installer/inventory --e "ansible_python_interpreter=python3" awx/installer/install.yml --e "@variables/vars.yml" --e "@vault/secret.yml" --ask-vault-pass
		fi
	else
		echo "Please, check that the following files exist:"
		echo "$SCRIPTPATH/variables/vars.yml"
		echo "$SCRIPTPATH/vault/secret.yml"
	fi
}
f_documentation() {
    cat << EOF
Usage: $0 --AWX Options

Options:
  --install             This command will set up your Operating System, the Docker environment and the AWX platform using local repo.
  --upgrade             This command will upgrade your the Docker environment and the AWX platform.
  --upgrade-awx-only	This command will upgrade only the AWX platform.
  --vars		This command will print all the environment variables storaged in variables/vars.yml.

EOF
    exit 64
}
f_printvars() {
	cat variables/vars.yml
}
f_printendprocess() {
	echo "----------------------------------------------------------------"
	echo "AWX SETUP: Process completed"
	echo "----------------------------------------------------------------"
}
# -----------------------------------------------------------------------------
# Start program
# -----------------------------------------------------------------------------
case "$1" in
# -----------------------------------------------------------------------------
# Starting routine
# -----------------------------------------------------------------------------
	--install)
		f_verifyexecutionpath	
		f_installrequirements
                f_setupso
		f_systemprofile
		f_installdocker
		f_cloneawxproject
		f_setupcentos8dockerinterface
		f_installawxproject
		f_printendprocess	
	;;
	--upgrade)
		f_verifyexecutionpath
		f_installrequirements
		f_installdocker
		f_cloneawxproject
		f_setupcentos8dockerinterface
		f_installawxproject
		f_printendprocess
	;;
	--upgrade-awx-only)
		f_verifyexecutionpath
		f_installrequirements
		f_cloneawxproject
		f_setupcentos8dockerinterface
		f_installawxproject
		f_printendprocess
	;;

	--vars)
		f_verifyexecutionpath
		f_printvars
	;;
	--help)
		f_documentation
	;;
	*)
		f_documentation
	;;
esac 
