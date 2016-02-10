#!/bin/bash

create_dockerfile()
{
	local dockerdir=$(mktemp -d)
	cat >> ${dockerdir}/Dockerfile <<-EOF
		FROM openedge/chaperone-base
		MAINTAINER Tom Hite <thite@vmware.com>

		# get the base development and X11 stuff
		RUN DEBIAN_FRONTEND=noninteractive apt-get install -y curl git tig make sshpass vim

		# get the repo tool and other base development and X11 stuff
		RUN (\
			mkdir -p /usr/local/bin \
			&& curl -L -o /usr/local/bin/repo http://commondatastorage.googleapis.com/git-repo-downloads/repo \
			&& chmod a+x /usr/local/bin/repo \
		)

		# Setup ansible
		RUN pip install ansible
	EOF
	echo ${dockerdir}
}

login_user=vmware
# pick up any user/pass arguments
if [ -n "${1}" ]; then
	login_user="${1}"
fi

dockerdir=$(create_dockerfile "${login_user}")
pushd "${dockerdir}"
docker build -t openedge/chaperone-dev .
rm -rf "${dockerdir}"
popd
