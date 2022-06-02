#!/bin/sh
# This is a reimplementation of the systemd tmpfiles.d code
# Control creation, deletion, and cleaning of volatile and temporary files
#
# Copyright (c) 2012 Gentoo Foundation
# Released under the 2-clause BSD license.
#
# This instance is a pure-POSIX sh version, written by Robin H Johnson
# <robbat2@gentoo.org>, based on the Arch Linux version as of 2012/01/01:
# http://projects.archlinux.org/initscripts.git/tree/arch-tmpfiles
#
# See the tmpfiles.d manpage as well:
# https://www.freedesktop.org/software/systemd/man/tmpfiles.d.html
# This script should match the old manpage
# http://0pointer.de/public/systemd-man/tmpfiles.d.html
# as of 2012/03/12 and also implements some more recent features
#

DRYRUN=0

checkprefix() {
	local x n="$1"
	shift
	for x in "$@"; do
		case ${n} in
			${x}*) return 0 ;;
		esac
	done
	return 1
}

owned_by_root() {
	local path="$1"
	if [ -z "${path}" ] ; then
		echo "Missing parameter" >&2
		return 404
	fi
	FOUND=$(find "${path}" -maxdepth 0 -uid 0 -gid 0)
	if [ -z $FOUND ] ; then
		echo "Not owned by root" >&2
		return 403
	fi
	return 0
}

warninvalid() {
	printf "tmpfiles: ignoring invalid entry on line %d of \`%s'\n" "${LINENUM}" "${FILE}"
	error=$(( error+1 ))
} >&2

invalid_option() {
	printf "tmpfiles: invalid option '%s'\n" "$1" >&2
	exit 1
}

dryrun_or_real() {
	local dryrun=
	if [ ${DRYRUN} -eq 1 ]; then
		dryrun="echo"
	fi
	${dryrun} "$@"
}

_chattr() {
	local attr="$2"
	case ${attr} in
		[+-=]*) : ;;
		'') return ;;
		*) attr="+${attr}" ;;
	esac
	local IFS=
	if ! owned_by_root $1 ; then
		echo "cowardly refusing to chattr" >&2
		return 107
	fi
	dryrun_or_real chattr "$1" "${attr}" -- "$3"
}

_setfacl() {
	dryrun_or_real setfacl -P "$1" "$2" "$3" -- "$4"
}

relabel() {
	local path
	local paths=$1 mode=$2 uid=$3 gid=$4
	local status

	status=0
	for path in ${paths}; do
		if [ -e "${path}" ]; then
			if ! owned_by_root $1 ; then
				echo "cowardly refusing to relabel" >&2
				return 108
			fi
			if [ -x /sbin/restorecon ]; then
				dryrun_or_real restorecon ${CHOPTS} "${path}" || status="$?"
				if [ $status -ne 0 ]; then
					echo "error on restorecon"  >&2
					exit $status
				fi
			fi
			if [ "${uid}" != '-' ]; then
				dryrun_or_real chown ${CHOPTS} "${uid}" "${path}" || status="$?"
			fi
			if [ "${gid}" != '-' ]; then
				dryrun_or_real chgrp ${CHOPTS} "${gid}" "${path}" || status="$?"
			fi
			if [ "${mode}" != '-' ]; then
				dryrun_or_real chmod ${CHOPTS} "${mode}" "${path}" || status="$?"
			fi
		fi
	done
	return ${status}
}

splitpath() {
    local path=$1
    while [ -n "${path}" ]; do
        printf '%s\n' "${path}"
        path=${path%/*}
    done
}

_restorecon() {
    local path=$1
	if ! owned_by_root $1 ; then
		echo "cowardly refusing to restorecon" >&2
		return 103
	fi
    if [ -x /sbin/restorecon ]; then
        dryrun_or_real restorecon -F "$(splitpath "${path}")"
    fi
}

_chmod() {
    local path=$2 mode=$1
	if ! owned_by_root "${path}" ; then
		echo "cowardly refusing to chmod" >&2
		return 106
	fi
	dryrun_or_real chmod ${mode} "${path}"
	x=$?
	if [ $x -ne 0 ]; then
		echo "error on chmod"  >&2
		exit $x
	fi
}

_chown() {
    local path=$2 uid=$1
	if ! owned_by_root "${path}" ; then
		echo "cowardly refusing to chmod" >&2
		return 107
	fi
	dryrun_or_real chown ${uid} "${path}"
	x=$?
	if [ $x -ne 0 ]; then
		echo "error on chown"  >&2
		exit $x
	fi
}

_chgrp() {
    local path=$2 gid=$1
	if ! owned_by_root "${path}" ; then
		echo "cowardly refusing to chgrp" >&2
		return 108
	fi
	dryrun_or_real chgrp ${gid} "${path}"
	x=$?
	if [ $x -ne 0 ]; then
		echo "error on chgrp"  >&2
		exit $x
	fi
}

_rm_f() {
    	local path=$1 
	if [ ! -e "${path}" ] ; then
		echo "file does not exist" >&2
		return 112
	fi
	if owned_by_root "${path}" ; then
		echo "cowardly refusing to rm" >&2
		return 113
	fi
	rm -f "${path}"
}

createdirectory() {
	local mode="$1" uid="$2" gid="$3" path="$4" x
	# Do nothing if existing directory
	# avoids race condition
	if [ -e "${path}" ] ; then
		echo "Directory already exists" >&2
		return 101
	fi
	dryrun_or_real mkdir "${path}"
	# only continue on successful created directory 
	# avoids rrace condition
	x=$?
	if [ $x -ne 0 ] ; then
		echo "Could not create directory" >&2
		exit $x
	fi
	if [ "${uid}" = - ]; then
		uid=root
	fi
	if [ "${gid}" = - ]; then
		gid=root
	fi
	if [ "${mode}" = - ]; then
		mode=0755
	fi
	dryrun_or_real _chown ${uid} "${path}"
	dryrun_or_real _chgrp ${gid} "${path}"
	dryrun_or_real _chmod ${mode} "${path}"
}

createfile() {
	local mode="$1" uid="$2" gid="$3" path="$4"
	if [ -e "${path}" ] ; then
		echo "File already exists" >&2
		return 105
	fi
	dryrun_or_real touch "${path}"
	if ! owned_by_root "${path}" ; then
		echo "cowardly refusing to chown/chgrp/chmod" >&2
		return 106
	fi
	if [ "${uid}" = - ]; then
		uid=root
	fi
	if [ "${gid}" = - ]; then
		gid=root
	fi
	if [ "${mode}" = - ]; then
		mode=0644
	fi
	dryrun_or_real _chown ${uid} "${path}"
	dryrun_or_real _chgrp ${gid} "${path}"
	dryrun_or_real _chmod ${mode} "${path}"

}

createpipe() {
	local mode="$1" uid="$2" gid="$3" path="$4" x
	# Do nothing if existing pipe
	# avoids race condition
	if [ -e "${path}" ] ; then
		echo "Pipe already exists" >&2
		return 104
	fi
	dryrun_or_real mkfifo "${path}"
	# only continue on successful created pipe 
	# avoids rrace condition
	x=$?
	if [ $x -ne 0 ] ; then
		echo "Could not create pipe" >&2
		exit $x
	fi
	if [ "${uid}" = - ]; then
		uid=root
	fi
	if [ "${gid}" = - ]; then
		gid=root
	fi
	if [ "${mode}" = - ]; then
		mode=0644
	fi
	dryrun_or_real _chown ${uid} "${path}"
	dryrun_or_real _chgrp ${gid} "${path}"
	dryrun_or_real _chmod ${mode} "${path}"
}

_b() {
	# Create a block device node if it doesn't exist yet
	local path=$1 mode=$2 uid=$3 gid=$4 age=$5 arg=$6 x
	if [ "${uid}" = - ]; then
		uid=root
	fi
	if [ "${gid}" = - ]; then
		gid=root
	fi
	if [ "${mode}" = - ]; then
		mode=0644
	fi
	if [ ! -e "${path}" ]; then
		dryrun_or_real mknod -m ${mode} "${path}" b "${arg%:*}" "${arg#*:}"
		x=$?
		if [ $x -ne 0 ]; then
			echo "error on mknod"  >&2
			exit $x
		fi
		_restorecon "${path}"
		dryrun_or_real _chown ${uid} "${path}"
		dryrun_or_real _chgrp ${gid} "${path}"
	fi
}

_c() {
	# Create a character device node if it doesn't exist yet
	local path=$1 mode=$2 uid=$3 gid=$4 age=$5 arg=$6 x
	if [ "${uid}" = - ]; then
		uid=root
	fi
	if [ "${gid}" = - ]; then
		gid=root
	fi
	if [ "${mode}" = - ]; then
		mode=0644
	fi
	if [ ! -e "${path}" ]; then
		dryrun_or_real mknod -m ${mode} "${path}" c "${arg%:*}" "${arg#*:}"
		x=$?
		if [ $x -ne 0 ]; then
			echo "error on mknod"  >&2
			exit $x
		fi
		_restorecon "${path}"
		dryrun_or_real _chown ${uid} "${path}"
		dryrun_or_real _chgrp ${gid} "${path}"
	fi
}

_C() {
	# recursively copy a file or directory
	local path=$1 mode=$2 uid=$3 gid=$4 age=$5 arg=$6
	if owned_by_root "${arg}" ; then
		echo "cowardly refusing to copy root-owned dir" >&2
		return 114
	fi
	if [ ! -e "${path}" ]; then
		dryrun_or_real mkdir "$path"
		# only continue on successful created directory 
		# avoids race condition
		x=$?
		if [ $x -ne 0 ] ; then
			echo "Could not create directory" >&2
			exit $x
		fi
		# Ignore .hidden files should be OK
		dryrun_or_real cp -r "${arg}/*" "${path}/"
		_restorecon "${path}"
		if [ "${uid}" != '-' ]; then
			dryrun_or_real _chown "${uid}" "${path}"
		fi
		if [ "${gid}" != '-' ]; then
			dryrun_or_real _chgrp "${gid}" "${path}"
		fi
		if [ "${mode}" != '-' ]; then
			dryrun_or_real _chmod "${mode}" "${path}"
		fi
	fi
}

_f() {
	# Create a file if it doesn't exist yet
	local path=$1 mode=$2 uid=$3 gid=$4 age=$5 arg=$6

	[ "${CREATE}" -gt 0 ] || return 0

	if [ ! -e "${path}" ]; then
		createfile "${mode}" "${uid}" "${gid}" "${path}"
		if [ -n "${arg}" ]; then
			_w "$@"
		fi
	fi
}

_F() {
	# Create or truncate a file
	local path=$1 mode=$2 uid=$3 gid=$4 age=$5 arg=$6 x

	[ "${CREATE}" -gt 0 ] || return 0

	dryrun_or_real rm -f "${path}"
	x=$?
	if [ $x -ne 0 ]; then
		echo "error on rm"  >&2
		exit $x
	fi
	createfile "${mode}" "${uid}" "${gid}" "${path}"
	if [ -n "${arg}" ]; then
		_w "$@"
	fi
}

_d() {
	# Create a directory if it doesn't exist yet
	local path=$1 mode=$2 uid=$3 gid=$4

	if [ "${CREATE}" -gt 0 ]; then
		createdirectory "${mode}" "${uid}" "${gid}" "${path}"
		_restorecon "${path}"
	fi
}

_D() {
	# Create or empty a directory
	local path=$1 mode=$2 uid=$3 gid=$4

	if [ -d "${path}" ] && [ "${REMOVE}" -gt 0 ]; then
		if owned_by_root "${path}" ; then
			echo "Cowardly refusing to remove directory" >&2
			return 102
		fi
		dryrun_or_real rm -rf "${path}"
		createdirectory "${mode}" "${uid}" "${gid}" "${path}"
		_restorecon "${path}"
	fi

	if [ "${CREATE}" -gt 0 ]; then
		createdirectory "${mode}" "${uid}" "${gid}" "${path}"
		_restorecon "${path}"
	fi
}

_v() {
	# Create a subvolume if the path does not exist yet and the file system
	# supports this (btrfs). Otherwise create a normal directory.
	# TODO: Implement btrfs subvol creation.
	_d "$@"
}

_q() {
	# Similar to _v. However, make sure that the subvolume will be assigned
	# to the same higher-level quota groups as the subvolume it has
	# been created in.
	# TODO: Implement btrfs subvol creation.
	_d "$@"
}

_Q() {
	# Similar to q. However, instead of copying the higher-level quota
	# group assignments from the parent as-is, the lowest quota group
	# of the parent subvolume is determined that is not the
	# leaf quota group.
	# TODO: Implement btrfs subvol creation.
	_d "$@"
}

_a() {
	# Set/add file/directory ACL. Lines of this type accept
	# shell-style globs in place of normal path names.
	# The format of the argument field matches setfacl
	local ACTION='--remove-all --set'
	[ "${FORCE}" -gt 0 ] && ACTION='--modify'
	_setfacl '' "${ACTION}" "$6" "$1"
}

_A() {
	# Recursively set/add file/directory ACL. Lines of this type accept
	# shell-syle globs in place of normal path names.
	# Does not follow symlinks
	local ACTION='--remove-all --set'
	[ "${FORCE}" -gt 0 ] && ACTION='--modify'
	_setfacl -R "${ACTION}" "$6" "$1"
}

_h() {
	# Set file/directory attributes. Lines of this type accept
	# shell-style globs in place of normal path names.
	# The format of the argument field matches chattr
	_chattr '' "$6" "$1"
}

_H() {
	# Recursively set file/directory attributes. Lines of this type accept
	# shell-syle globs in place of normal path names.
	# Does not follow symlinks
	_chattr -R "$6" "$1"
}

_L() {
	# Create a symlink if it doesn't exist yet
	local path=$1 mode=$2 uid=$3 gid=$4 age=$5 arg=$6 x
	if [ ! -e "${path}" ]; then
		dryrun_or_real ln -s "${arg}" "${path}"
		x=$?
		if [ $x -ne 0 ]; then
			echo "error on ln"  >&2
			exit $x
		fi
	fi
	_restorecon "${path}"
}

_p() {
	# Create a named pipe (FIFO) if it doesn't exist yet
	local path=$1 mode=$2 uid=$3 gid=$4

	[ "${CREATE}" -gt 0 ] || return 0

	if [ ! -p "${path}" ]; then
		createpipe "${mode}" "${uid}" "${gid}" "${path}"
	fi
}

_x() {
	# Ignore a path during cleaning. Use this type to exclude paths from clean-up as
	# controlled with the Age parameter. Note that lines of this type do not
	# influence the effect of r or R lines. Lines of this type accept shell-style
	# globs in place of of normal path names.
	:
	# XXX: we don't implement this
}

_X() {
	# Ignore a path during cleanup. Use this type to prevent path
	# removal as controled with the age parameter. Note that if path is
	# a directory, the content of the directory is not excluded from
	# clean-up, only the directory itself.
	# Lines of this type accept shell-style globs in place of normal path names.
	:
	# XXX: we don't implement this
}

_r() {
	# Remove a file or directory if it exists. This may not be used to remove
	# non-empty directories, use R for that. Lines of this type accept shell-style
	# globs in place of normal path names.
	local path
	local paths=$1
	local status

	[ "${REMOVE}" -gt 0 ] || return 0

	status=0
	for path in ${paths}; do
		if owned_by_root "${path}" ; then
			echo "cowardly refusing to remove root-owned path" >&2
			return 113
		fi
		if [ -f "${path}" ]; then
			dryrun_or_real rm -f "${path}" || status="$?"
		elif [ -d "${path}" ]; then
			dryrun_or_real rmdir "${path}" || status="$?"
		fi
		# Return on first fail
		if [ $status -ne 0 ]; then
			exit $status
		fi
	done
	return ${status}
}

_R() {
	# Recursively remove a path and all its subdirectories (if it is a directory).
	# Lines of this type accept shell-style globs in place of normal path names.
	local path
	local paths=$1
	local status

	[ "${REMOVE}" -gt 0 ] || return 0

	status=0
	for path in ${paths}; do
		if [ -d "${path}" ]; then
			if owned_by_root "${path}" ; then
				echo "cowardly refusing to remove directory" >&2
				return 109
			fi
			dryrun_or_real rm -rf --one-file-system "${path}" || status="$?"
		fi
		# Return on first fail
		if [ $status -ne 0 ]; then
			exit $status
		fi
	done
	return ${status}
}

_w() {
	# Write the argument parameter to a file, if it exists.
	local path=$1 mode=$2 uid=$3 gid=$4 age=$5 arg=$6
	if [ -f "${path}" ]; then
		if owned_by_root "${path}" ; then
			echo "cowardly refusing to write file" >&2
			return 110
		fi
		if [ ${DRYRUN} -eq 1 ]; then
			echo "echo \"${arg}\" >>\"${path}\""
		else
			echo "${arg}" >>"${path}"
		fi
	fi
}

_z() {
	echo "Ignoring recursively *"
	return 111
}

_Z() {
	echo "Ignoring recursively *"
	return 111
}

usage() {
	printf 'usage: %s [--exclude-prefix=path] [--prefix=path] [--boot] [--create] [--remove] [--clean] [--verbose] [--dry-run]\n' "${0##*/}"
	exit "${1:-0}"
}

version() {
	# We don't record the version info anywhere currently.
	echo "opentmpfiles"
	exit 0
}

BOOT=0 CREATE=0 REMOVE=0 CLEAN=0 VERBOSE=0 DRYRUN=0 error=0 LINENO=0
EXCLUDE=
PREFIX=
FILES=

while [ $# -gt 0 ]; do
	case $1 in
		--boot) BOOT=1 ;;
		--create) CREATE=1 ;;
		--remove) REMOVE=1 ;;
		--clean) CLEAN=1 ;; # TODO: Not implemented
		--verbose) VERBOSE=1 ;;
		--dryrun|--dry-run) DRYRUN=1 ;;
		--exclude-prefix=*) EXCLUDE="${EXCLUDE}${1##--exclude-prefix=} " ;;
		--prefix=*) PREFIX="${PREFIX}${1##--prefix=} " ;;
		-h|--help) usage ;;
		--version) version ;;
		-*) invalid_option "$1" ;;
		*) FILES="${FILES} $1"
	esac
	shift
done

if [ $(( CLEAN )) -eq 1 ] ; then
	printf '%s clean mode is not implemented\n' "${0##*/}"
	exit 1
fi

if [ "${CREATE}${REMOVE}" = '00' ]; then
	usage 1 >&2
fi

# XXX: The harcoding of /usr/lib/ is an explicit choice by upstream
tmpfiles_dirs='/usr/lib/tmpfiles.d /run/tmpfiles.d /etc/tmpfiles.d'
tmpfiles_basenames=''

if [ -z "${FILES}" ]; then
	# Build a list of sorted unique basenames
	# directories declared later in the tmpfiles_d array will override earlier
	# directories, on a per file basename basis.
	# `/etc/tmpfiles.d/foo.conf' supersedes `/usr/lib/tmpfiles.d/foo.conf'.
	# `/run/tmpfiles/foo.conf' will always be read after `/etc/tmpfiles.d/bar.conf'
	for d in ${tmpfiles_dirs} ; do
		[ -d "${d}" ] && for f in "${d}"/*.conf ; do
			case "${f##*/}" in
				systemd.conf|systemd-*.conf) continue;;
			esac
			[ -f "${f}" ] && tmpfiles_basenames="${tmpfiles_basenames}\n${f##*/}"
		done # for f in ${d}
	done # for d in ${tmpfiles_dirs}
	# shellcheck disable=SC2059
	FILES="$(printf "${tmpfiles_basenames}" | sort -u )"
fi

tmpfiles_d=''

for b in ${FILES} ; do
	if [ "${b##*/}" != "${b}" ]; then
		# The user specified a path on the command line
		# Just pass it through unaltered
		tmpfiles_d="${tmpfiles_d} ${b}"
	else
		real_f=''
		for d in ${tmpfiles_dirs} ; do
			f=${d}/${b}
			[ -f "${f}" ] && real_f=${f}
		done
		[ -f "${real_f}" ] && tmpfiles_d="${tmpfiles_d} ${real_f}"
	fi
done

error=0

# loop through the gathered fragments, sorted globally by filename.
# `/run/tmpfiles/foo.conf' will always be read after `/etc/tmpfiles.d/bar.conf'
FILE=
for FILE in ${tmpfiles_d} ; do
	LINENUM=0

	### FILE FORMAT ###
	# XXX: We ignore the 'Age' parameter
	# 1    2              3    4    5    6   7
	# Cmd  Path           Mode UID  GID  Age Argument
	# d    /run/user      0755 root root 10d -
	# Mode, UID, GID, Age, Argument may be omitted!
	# If Cmd ends with !, the line is only processed if --boot is passed

	# XXX: Upstream says whitespace is NOT permitted in the Path argument.
	# But IS allowed when globs are expanded for the x/r/R/z/Z types.
	while read -r cmd path mode uid gid age arg rest; do
		LINENUM=$(( LINENUM+1 ))
		FORCE=0

		# Unless we have both command and path, skip this line.
		if [ -z "${cmd}" ] || [ -z "${path}" ]; then
			continue
		fi

		case ${cmd} in
			\#*) continue ;;
		esac

		while [ ${#cmd} -gt 1 ]; do
			case ${cmd} in
				*!) cmd=${cmd%!}; [ "${BOOT}" -eq "1" ] || continue 2 ;;
				*+) cmd=${cmd%+}; FORCE=1; ;;
				*) warninvalid ; continue 2 ;;
			esac
		done

		# whine about invalid entries
		case ${cmd} in
			f|F|w|d|D|v|p|L|c|C|b|x|X|r|R|z|Z|q|Q|h|H|a|A) ;;
			*) warninvalid ; continue ;;
		esac

		# fall back on defaults when parameters are passed as '-'
		if [ "${mode}" = '-' ] || [ "${mode}" = '' ]; then
			case "${cmd}" in
				p|f|F) mode=0644 ;;
				d|D|v) mode=0755 ;;
				C|z|Z|x|r|R|L) ;;
			esac
		fi

		[ "${uid}" = '-' ] || [ "${uid}" = '' ] && uid=0
		[ "${gid}" = '-' ] || [ "${gid}" = '' ] && gid=0
		[ "${age}" = '-' ] || [ "${age}" = '' ] && age=0
		[ "${arg}" = '-' ] || [ "${arg}" = '' ] && arg=''
		set -- "${path}" "${mode}" "${uid}" "${gid}" "${age}" "${arg}"

		[ -n "${EXCLUDE}" ] && checkprefix "${path}" "${EXCLUDE}" && continue
		[ -n "${PREFIX}" ] && ! checkprefix "${path}" "${PREFIX}" && continue

		if [ "${FORCE}" -gt 0 ]; then
			case ${cmd} in
				p|L|c|b) [ -f "${path}" ] && dryrun_or_real _rm_f "${path}"
			esac
		fi

		[ "${VERBOSE}" -eq "1" ] && echo "_${cmd}" "$@"
		"_${cmd}" "$@"
		rc=$?
		if [ "${DRYRUN}" -eq "0" ]; then
			[ ${rc} -ne 0 ] && error=$((error + 1))
		fi
	done <"${FILE}"
done

exit ${error}

# vim: set ts=2 sw=2 sts=2 noet ft=sh:
