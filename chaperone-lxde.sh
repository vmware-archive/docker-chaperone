#!/bin/bash

create_dockerfile()
{
	local dockerdir=''
	local vncserver=''
	if uname -a | grep -q Darwin; then
		dockerdir=$(mktemp -d)
		pushd "${dockerdir}" >/dev/null
		vncserver="${dockerdir}/$(mktemp XXXXXXXX)"
		popd >/dev/null
	else
		dockerdir=$(mktemp -d)
		vncserver=$(mktemp -p "${dockerdir}" -t XXXXXXXX)
	fi

	cat >> ${vncserver} <<-EOF
		#!/bin/bash
		echo "running 10-vncserver with args: " "$*"

		# fixup the vnc startup info
		rm -f /home/\${1}/.vnc/*.pid
		if [ ! -d /home/\${1}/.vnc ]; then
			 mkdir -p /home/\${1}/.vnc
			 echo "exec lxsession" > /home/\${1}/.vnc/xsession
			 echo "#!/bin/sh" > /home/\${1}/.vnc/xstartup
			 echo "export XKL_XMODMAP_DISABLE=1" >> /home/\${1}/.vnc/xstartup
			 echo "exec lxsession" >> /home/\${1}/.vnc/xstartup
			 chmod +x /home/\${1}/.vnc/xstartup
			 echo "" | vncpasswd -f > /home/\${1}/.vnc/passwd
			 chmod 600 /home/\${1}/.vnc/passwd
			 chown -R \${1}:\${1} /home/\${1}/.vnc
		fi

		# start the server
		su \${1} -c 'vncserver -geometry 1376x768 :0'
	EOF
	chmod +x ${vncserver}

	cat >> ${dockerdir}/Dockerfile <<-EOF
		FROM openedge/chaperone-dev
		MAINTAINER Tom Hite <thite@vmware.com>

		# get the lxde, chrome and a decent editor
		RUN DEBIAN_FRONTEND=noninteractive apt-get install -y lxde geany geany-plugins chromium-browser tightvncserver
		# Setup the vncserver at start
		ADD $(basename ${vncserver}) /etc/supervisord/init.d/10-vncserver
	EOF
	echo ${dockerdir}
}

dockerdir=$(create_dockerfile)
pushd "${dockerdir}"
docker build -t openedge/chaperone-lxde .
rm -rf "${dockerdir}"
popd
