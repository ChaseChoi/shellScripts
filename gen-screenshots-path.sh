#!/bin/bash

# specify default value
desktopPath="$HOME/Desktop"
targetInfoFile="currentImgFolder.info"

# Auxiliary Functions
# Screenshot not found warning
screenshotNotFound () {
  echo -e "\033[1;31m --Screenshot Not Found!-- \033[0m"
}

successInfo() {
  if [[ -z $1 ]]; then
    echo -e "\033[1;31m --Parameter Lost!-- \033[0m"
  else
    echo $1
    echo -e "\033[1;32m --Copied to clipboard successfully!-- \033[0m"
  fi
}
# Check existence of targetInfoFile
checkTargetInfoFile() {
  if [[ ! -e ${targetInfoFile} ]]; then
    echo -e "\033[1;31m --Please define working directory first!--\033[0m"
    exit 1
  fi
}

displayWorkingDir() {
  checkTargetInfoFile
  workingDir=`cat ${targetInfoFile}`
  echo -e "\033[1;36;40m Current image folder: $workingDir \033[0m"
}

openWorkingDir() {
  checkTargetInfoFile
  workingDir=`cat ${targetInfoFile}`
  open ${workingDir}
}

helpInfo() {
  echo "Usage:"
  echo -e "    cmd -d working-directory \t Define working directory."
  echo -e "    cmd -h \t Display this help message."
  echo -e "    cmd -c \t Check working directory."
  echo -e "    cmd -o \t Open working directory."
  echo
}


# Handle options and arguments
while getopts ":d:hco" opt; do
  case ${opt} in
    d ) 
	  	  imageFolderPath=$OPTARG
        # store info
		    echo $imageFolderPath > $targetInfoFile
      	displayWorkingDir
      	exit 0
      	;;
    h )
      	helpInfo
      	exit 0
      	;;
    c )
      	displayWorkingDir
      	exit 0
      	;;
    o )
      	openWorkingDir
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

displayWorkingDir

imageList=`find ${desktopPath} \( -name "*.png" -o -name "*.jpg" -o -name "*.gif" \) -atime -1h`
# Screenshot not found
if [[ -z $imageList ]]; then
  screenshotNotFound
else
  # Find the latest image file
  image=`ls -t $desktopPath | egrep '\.png$|\.jpg$|\.gif$' | head -n 1`
  # Move to the target directory
  mv "$desktopPath/${image}" "${workingDir}"

  # Construct markdown image path
  imageName=`basename ${image}`
  parentDirectory=${workingDir##*/}
  relativePath=${parentDirectory}/${imageName}
  # Remove file extension
  extractedName=${imageName%.*}
  stmt="![${extractedName}](${relativePath})"
  # Copy to clipboard
  echo ${stmt} | pbcopy
  successInfo "${stmt}"
fi

