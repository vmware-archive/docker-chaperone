#!/bin/bash

###
# Global Variables
###
CONTAINER_NAME="chaperone-base"
CONTAINER_USER='openedge'
CONTAINER_LOGIN='vmware'
KEY_ROOT="/${CONTAINER_USER}/${CONTAINER_NAME}"
SSH=""

###
# Functions
###
run_script() {
	chmod +x "${1}"

	if [ -n "${SSH}" ]; then
		${SSH} "$(cat "${1}")"
	else
		"${1}"
	fi

	rm -f "${1}"
}

run_command() {
	if [ -n "${SSH}" ]; then
		${SSH} "$@"
	else
		$@
	fi
}

generate_script_header() {
	cat >>${1} <<-EOF
		#!/bin/bash

		###
		# Global Variables
		###
		CONTAINER_NAME="${CONTAINER_NAME}"
		CONTAINER_USER='${CONTAINER_USER}'

	EOF
	cat ${CONTAINER_NAME}-functions.sh >>${1}
	cat >>${1} <<-EOF

		###
		# Main Line Code
		###
	EOF
}


###
# Main Line Code
###
login_user=vmware
login_pass=vmware
case "$1" in
	build)
		# shift the command out of the way
		shift

		# pick up any user/pass arguments
		if [ -n "${1}" ]; then
			login_user="${1}"
		fi

		if [ -n "${2}" ]; then
			login_pass="${2}"
		fi

		#echo "wiping prior etcd image ..."
		run_command "docker rmi ${CONTAINER_USER}/${CONTAINER_NAME}" || echo ""

		if uname -a | grep -q Darwin; then
			script="$(mktemp -t ${CONTAINER_NAME}.XXXXXXXX)"
		else
			script="$(mktemp --tmpdir ${CONTAINER_NAME}.XXXXXXXX)"
		fi
		generate_script_header ${script}
		cat >>${script} <<-EOF
			# generate the ${CONTAINER_NAME} container and set it up
			dockerdir=\$(create_startscript)
			create_dockerfile "\${dockerdir}" "${login_user}" "${login_pass}"
			pushd "\${dockerdir}"
			docker build -t \${CONTAINER_USER}/\${CONTAINER_NAME} .
			popd
			rm -f \${dockerdir}/*
			rmdir \${dockerdir}
		EOF
		run_script "${script}"
		;;
	*)
		echo "usage: ${0} build"
		;;
esac
