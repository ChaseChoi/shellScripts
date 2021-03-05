#!/bin/bash

plistPath="Reactive-Smart-Reference/Info.plist"
versionNumberKey="CFBundleShortVersionString"
buildNumberKey="CFBundleVersion"
today=`date +%Y%m%d`

versionNumber=`/usr/libexec/PlistBuddy -c "print :${versionNumberKey}" $plistPath`
buildNumber=`/usr/libexec/PlistBuddy -c "print :${buildNumberKey}" $plistPath`

# bump version
major=${versionNumber%%.*}
minor=`echo ${versionNumber} | sed -E 's/[0-9]+\.([0-9]+)\.[0-9]+/\1/'`
patch=${versionNumber##*.}

bumpVersion() {
	expectedVersionNumber="${major}.${minor}.${patch}"
	/usr/libexec/PlistBuddy -c "set :${versionNumberKey} ${expectedVersionNumber}" $plistPath
	/usr/libexec/PlistBuddy -c "set :${buildNumberKey} ${today}" $plistPath

	updatedVersionNumber=`/usr/libexec/PlistBuddy -c "print :${versionNumberKey}" $plistPath`
	updatedBuildNumber=`/usr/libexec/PlistBuddy -c "print :${buildNumberKey}" $plistPath`
	echo -e "version: \033[1;31m${versionNumber}\033[0m -> \033[1;32m${updatedVersionNumber}\033[0m"
	echo -e "build: \033[1;31m${buildNumber}\033[0m -> \033[1;32m${updatedBuildNumber}\033[0m"
}

while getopts ":cmnph" opt; do
  case ${opt} in
 	c )
		commitMsg="Release ${versionNumber}(${buildNumber})"
		git add ${plistPath}
		git commit -m "${commitMsg}"
      	exit 0
      	;;
    m ) 
	  	let major++
	  	bumpVersion
      	exit 0
      	;;
    n )
		let minor++
		bumpVersion
      	exit 0
      	;;
 	p )
		let patch++
		bumpVersion
      	exit 0
      	;;
    h )
		echo "Usage:"
      	echo "The following options are available:"
      	echo "    -h   Display this help message."
      	echo "    -m   Bump major version number."
      	echo "    -n   Bump minor version number."
      	echo "    -p   Bump patch version number."
      	echo "    -c   Commit new version."
		echo "If no options are provided, patch number will be bumped by default."
      	exit 0
	    ;;
    \? )
	  	echo "Invalid option: -$OPTARG" 1>&2
      	exit 1
      	;;
  	: )
        echo "Invalid option: -$OPTARG requires an argument" 1>&2
        exit 1
        ;;
  esac
done
shift $((OPTIND -1))

# default
let patch++
bumpVersion
