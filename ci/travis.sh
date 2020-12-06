#!/bin/sh -eu
# The main script for building/testing while under travis ci.
# https://travis-ci.org/libgd/libgd

travis_fold() {
	case "${TRAVIS_OS_NAME}" in ?*)
		printf 'travis_fold:%s:%s\r\n' "$@" | tr ' ' '_'
	esac
}

case "${TRAVIS_OS_NAME}" in ?*)
	whitebg=$(tput setab 7)
	blackfg=$(tput setaf 0)
	normal=$(tput sgr0)
;;(*)
	whitebg=
	blackbg=
	normal=
esac
v() {
	local fold=""
	case $1 in
	--fold=*) fold=${1:7}; shift;;
	esac
	case "${fold}" in ?*)
		travis_fold start "${fold}"
		echo "\$ $*"
		"$@"
		travis_fold end "${fold}"
	;; *)
		echo "${whitebg}${blackfg}\$ $*${normal}"
		"$@"
	esac
}

ncpus=$(getconf _NPROCESSORS_ONLN)
m() {
	v make -j${ncpus} "$@"
}

main() {
	m
	m install DESTDIR="${PWD}/destdir"
}
main "$@"
