#!/bin/bash -e
# The main script for building/testing while under travis ci.
# https://travis-ci.org/libgd/libgd

travis_fold() {
	if [[ -n ${TRAVIS_OS_NAME} ]] ; then
		printf 'travis_fold:%s:%s\r\n' "$@" | sed 's: :_:g'
	fi
}

if [[ -n ${TRAVIS_OS_NAME} ]] ; then
	whitebg=$(tput setab 7)
	blackfg=$(tput setaf 0)
	normal=$(tput sgr0)
else
	whitebg=
	blackbg=
	normal=
fi
v() {
	local fold=""
	case $1 in
	--fold=*) fold=${1:7}; shift;;
	esac
	if [[ -n ${fold} ]] ; then
		travis_fold start "${fold}"
		echo "\$ $*"
		"$@"
		travis_fold end "${fold}"
	else
		echo "${whitebg}${blackfg}\$ $*${normal}"
		"$@"
	fi
}

ncpus=$(getconf _NPROCESSORS_ONLN)
m() {
	v make -j${ncpus} "$@"
}

main() {
	m
	# The CI doesn't include a usable gtest install, so bootstrap it.
	m gtest
	m check
	m install DESTDIR="${PWD}/destdir"
}
main "$@"
