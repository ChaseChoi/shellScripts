#!/bin/bash

# Specify default value

desktopPath="$HOME/Desktop"
# Filename
targetInfoFile="currentImgFolder.info"
logFile="imageOperations.log"
# Message
copied="Copied to clipboard successfully!"
failToUndo="Fail to undo!"
screenshotNotFound="Screenshot Not Found!"
emptyTargetInfoFile="Please define working directory first!"
separator='-'

# Auxiliary Functions

successInfo() {
    if [[ -z $1 ]]; then
        echo -e "\033[1;31m -- successInfo() parameter Lost! -- \033[0m"
        exit 1
    else
        echo -e "\033[1;32m -- $1 -- \033[0m"
    fi
}

errorInfo() {
    if [[ -z $1 ]]; then
        echo -e "\033[1;31m -- errorInfo() parameter Lost! -- \033[0m"
        exit 1
    else
        echo -e "\033[1;31m -- $1 -- \033[0m"
    fi
}

# Check existence of targetInfoFile
checkTargetInfoFile() {
    if [[ ! -e ${targetInfoFile} ]]; then
        errorInfo "${emptyTargetInfoFile}"
        exit 1
    fi
}



checkLogFile() {
    if [[ ! -e ${logFile} ]]; then
        errorInfo "${failToUndo}"
        exit 1
    fi
}

definePath() {
    imageFolderPath=$1
    # store info
    echo $imageFolderPath > $targetInfoFile
    displayWorkingDir
    # Wring empty string
    writeLog '-'
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
    echo -e "    cmd -u \t Undo: Move image back to Desktop."
    echo
}

writeLog() {
    if [[ -z $1 ]]; then
        echo -e "\033[1;31m -- writeLog() parameter Lost! -- \033[0m"
        exit 1
    else
        echo $1 >> ${logFile}
    fi
}

deleteLastLog() {
    sed -i '' '$ d' ${logFile}
}

undoFunction() {
    checkLogFile
    previousImage=`tail -n 1 ${logFile}`
    
    if [[ "${previousImage}" = "${separator}" || ! -e "${previousImage}" ]]; then
        errorInfo "${failToUndo}"
        exit 1
    else
        mv "${previousImage}" "${desktopPath}"
        deleteLastLog
        successInfo "Move ${previousImage} back to ${desktopPath}"
    fi
    
}

# Handle options and arguments
while getopts ":d:hcou" opt; do
    case ${opt} in
        d )
            definePath "$OPTARG"
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
        u )
            undoFunction
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
    errorInfo "${screenshotNotFound}"
else
    # Find the latest image file
    image=`ls -t $desktopPath | egrep '\.png$|\.jpg$|\.gif$' | head -n 1`
    
    # Move to the target directory
    mv "$desktopPath/${image}" "${workingDir}"
    writeLog "${workingDir}/${image}"
    
    # Construct markdown image path
    imageName=`basename ${image}`
    parentDirectory=${workingDir##*/}
    relativePath=${parentDirectory}/${imageName}
    # Remove file extension
    extractedName=${imageName%.*}
    stmt="![${extractedName}](${relativePath})"
    # Copy to clipboard
    echo ${stmt} | tee pbcopy
    successInfo "${copied}"
fi

