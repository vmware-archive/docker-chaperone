
###
# Functions
###

# creates the start.sh script
# returns: directory in which the Docker files should exist
create_startscript()
{
	local dockerdir=''
	if uname -a | grep -q Darwin; then
		dockerdir=$(mktemp -d -t dockerdir )
	else
		dockerdir=$(mktemp --tmpdir -d dockerdir.XXXX)
	fi

	cat >"${dockerdir}/start.sh" <<-EOS
		#!/bin/bash

		###
		# Functions
		###
		function supervisor_config_script()
		{
			 local file=''
			 if uname -a | grep -q Darwin; then
				 file=\$(mktemp -t supervisor.XXXX)
			 else
				 file=\$(mktemp --tmpdir supervisor.XXXX)
			 fi
			 cat >\${file} <<-EOC
				#!/bin/bash
				# start with a header
				supervisor_conf="/etc/supervisord.conf"

				echo "# ### WARNING -- CONFIGURED VIA BOOTSTRAP -- ALL CHANGES WILL GET OVERWRITTEN! ###" >\\\${supervisor_conf}
			 	cat >>\\\${supervisor_conf} <<-EOT
					[unix_http_server]
					file = /tmp/supervisor.sock

					[supervisord]
					logfile = /tmp/supervisord.log
					logfile_maxbytes = 10MB
					logfile_backups = 5
					loglevel = info
					pidfile = /tmp/supervisord.pid
					nodaemon = false
					minfds = 1024
					minprocs = 200

					[rpcinterface:supervisor]
					supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

					[supervisorctl]
					serverurl = unix:///tmp/supervisor.sock

					[program:sshd]
					command=/usr/sbin/sshd -D
					autorestart = true
					stdout_logfile = /var/log/supervisor/%(program_name)s.log
					stderr_logfile = /var/log/supervisor/%(program_name)s.log
				EOT
			EOC
			chmod 775 \${file}
			echo \${file}
		}

		create_user() {
			 grep "^\${1}" /etc/passwd >/dev/null 2>&1
			 if [ \$? -ne 0 ]; then
				 # create user "\${1}" to ssh into
				 useradd -G sudo -d /home/\${1} -s /bin/bash -m \${1}
				 echo "\${1}:\${2}" | chpasswd
				 echo ssh \${1} password: \${2}

				 # create chaperone source dir
				 mkdir -p /home/\${1}/chaperone
				 chown -R \${1}:\${1} /home/\${1}
			 fi
		}

		###
		# Main line code
		###
		# generate configurations
		config_gen=\$(supervisor_config_script)
		chmod +x \${config_gen}

		# create the supervisor.conf file
		\${config_gen}

		# create the desired user
		create_user "\${1}" "\${2}"

		# run any init.d scripts
		if [ -d /etc/supervisord/init.d ]; then
			run-parts /etc/supervisord/init.d \$(printf " --arg=%s" "\${@}")
		fi

		# start the supervisor daemon to stick around as this is a server
		supervisord -n
	EOS
	chmod +x "${dockerdir}/start.sh"

	echo "${dockerdir}"
}

create_dockerfile()
{
	local dockerdir="$1"
	local user="$2"
	local passwd="$3"
	local initfile=''
	if uname -a | grep -q Darwin; then
		pushd ${dockerdir}
		initfile="${dockerdir}/$(mktemp XXXXXXXX )"
		popd
	else
		initfile=$(mktemp -p "${dockerdir}" -t XXXXXXXX)
	fi

	cat >> ${initfile} <<-EOF
		#!/bin/bash
		echo "running 10-apache2 with args: " "$*"

		if [ -x /etc/init.d/apache2 ]; then
			rm -rf /var/run/apache2/*
			service apache2 start
		fi
	EOF
	chmod +x ${initfile}

	cat >> ${dockerdir}/Dockerfile <<-EOF
		FROM phusion/baseimage
		MAINTAINER Tom Hite <thite@vmware.com>

		# basic necessities
		RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server sudo
		RUN DEBIAN_FRONTEND=noninteractive apt-get update
		RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

		# python setup tools
		RUN DEBIAN_FRONTEND=noninteractive apt-get install -y curl python-dev make
		RUN curl https://bootstrap.pypa.io/ez_setup.py -o - | python
		RUN easy_install pip

		# install supervisord
		RUN (pip install supervisor && mkdir -p /var/log/supervisor)
		RUN (mkdir -p /etc/supervisord/init.d && chmod 775 /etc/supervisord/init.d)

		# clean up
		RUN (rm -rf /tmp/* && sudo apt-get clean all)

		# setup users and sudo so we can upgrade power as desired
		RUN echo %sudo ALL=NOPASSWD: ALL >> /etc/sudoers

		# start long running services at container start
		ADD ./start.sh /start.sh

		# Setup the vncserver at start
		ADD $(basename ${initfile}) /etc/supervisord/init.d/10-vncserver

		CMD /start.sh "${user}" "${passwd}"
	EOF
	echo ${dockerdir}
}
