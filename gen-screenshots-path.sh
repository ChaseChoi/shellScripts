#!/bin/bash

# Specify default value

desktopPath="$HOME/Desktop"
# Filename
currentImgFolderInfoFile="currentImgFolder.log"
operationLogFile="imageOperations.log"
# Message
copied="Copied to clipboard successfully!"
failToUndo="Fail to undo!"
screenshotNotFound="Screenshot Not Found!"
emptyWorkingDir="Please define working directory first!"
noPreviousWorkingDir="No previous working directory!"
invalidPath="Invalid directory path!"
cacheCleared="Cache has been cleared!"
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

# Check existence of currentImgFolderInfoFile
checkCurrentImgFolderInfo() {
    if [[ ! -e "${currentImgFolderInfoFile}" ]]; then
        errorInfo "${emptyWorkingDir}"
        exit 1
    fi
}


checkLogFile() {
    if [[ ! -e ${operationLogFile} ]]; then
        errorInfo "${failToUndo}"
        exit 1
    fi
}

writeLog() {
    if [[ $# -ne 2 ]]; then
        echo -e "\033[1;31m -- writeLog() parameter Lost! -- \033[0m"
        exit 1
    else
        echo $1 >> $2
    fi
}

deleteLastLog() {
    sed -i '' '$ d' "$1"
}

# -d
definePath() {
    notesBaseFolderPath="$1"
    imageFolderPath="${notesBaseFolderPath}/images"
    mkdir -p "${notesBaseFolderPath}/images"
    if [[ -d "$1" ]]; then
        # store info
        writeLog "$imageFolderPath" "$currentImgFolderInfoFile"
        # Write a separator
        writeLog '-' "${operationLogFile}"
        displayWorkingDir
    else
        errorInfo "${invalidPath}"
    fi
}
# -c
displayWorkingDir() {
    checkCurrentImgFolderInfo
    currentImgFolder=`tail -n 1 "${currentImgFolderInfoFile}"`
    if [[ -d "${currentImgFolder}" ]]; then
        echo -e "\033[1;36;40m Current working folder: ${currentImgFolder%/*} \033[0m"
    else
        # if deleted
        errorInfo "${emptyWorkingDir}"
        exit 1
    fi
}
# -o
openWorkingDir() {
    checkCurrentImgFolderInfo
    currentImgFolder=`tail -n 1 "${currentImgFolderInfoFile}"`
    if [[ -d "${currentImgFolder}" ]]; then
        open "${currentImgFolder}"
    else
        errorInfo "${emptyWorkingDir}"
        exit 1
    fi
    
}
# -h
helpInfo() {
    echo -e "\033[1m Usage:\033[0m"
    echo -e "    cmd -d working-directory \t Define working directory."
    echo -e "    cmd -h \t Display this help message."
    echo -e "    cmd -c \t Check working directory."
    echo -e "    cmd -o \t Open working directory."
    echo -e "    cmd -u \t Undo: Move image back to Desktop."
    echo -e "    cmd -r \t Return to previous working directory."
    echo -e "    cmd -e \t Empty cache files."
    echo
}

# -u
undoFunction() {
    checkLogFile
    previousImage=`tail -n 1 ${operationLogFile}`
    
    if [[ ! -e "${previousImage}" ]]; then
        errorInfo "${failToUndo}"
        exit 1
    else
        mv "${previousImage}" "${desktopPath}"
        deleteLastLog "${operationLogFile}"
        filename=`basename "${previousImage}"`
        source="\033[1;31m - ${previousImage} \033[0m"
        target="\033[1;32m + ${desktopPath}/${filename} \033[0m"
        echo -e "${source}\n${target}"
    fi
    
}

# -r
returnToPreDir() {
    checkCurrentImgFolderInfo
    lineNumber=`wc -l "${currentImgFolderInfoFile}" | awk '{print $1}'`
    previousWorkingDir=`tail -n 2 "${currentImgFolderInfoFile}" | head -n 1`
    
    if [[ -d "${previousWorkingDir}" && "${lineNumber}" -gt 1 ]]; then
        deleteLastLog "${currentImgFolderInfoFile}"
        displayWorkingDir
        writeLog '-' "${operationLogFile}"
    else
        # directory deleted OR no previous log
        errorInfo "${noPreviousWorkingDir}"
        exit 1
    fi
}

# -e
emptyCache() {
    [ -e "${currentImgFolderInfoFile}" ] && rm "${currentImgFolderInfoFile}"
    [ -e "${operationLogFile}" ] && rm "${operationLogFile}"
    successInfo "${cacheCleared}"
}
# Handle options and arguments
while getopts ":d:hcorue" opt; do
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
        r )
            returnToPreDir
            exit 0
        ;;
        u )
            undoFunction
            exit 0
        ;;
        e)
            emptyCache
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

if [[ $# -gt 0 ]]; then
    helpInfo
    exit 1
fi

displayWorkingDir
lastRecord=`tail -n 1 "${currentImgFolderInfoFile}"`
# "currentImgFolder" may end with "/"
currentImgFolder=${lastRecord%/}

imageList=`find ${desktopPath} \( -name "*.png" -o -name "*.jpg" -o -name "*.gif" \) -atime -1h`
# Screenshot not found
if [[ -z $imageList ]]; then
    errorInfo "${screenshotNotFound}"
    exit 1
else
    # Find the latest image file
    image=`ls -t $desktopPath | egrep '\.png$|\.jpg$|\.gif$' | head -n 1`
    
    # Move to the target directory
    mv "$desktopPath/${image}" "${currentImgFolder}"
    writeLog "${currentImgFolder}/${image}" "${operationLogFile}"
    
    # Construct markdown image path
    imageName=`basename "${image}"`
    parentDirectory="${currentImgFolder##*/}"
    relativePath="${parentDirectory}/${imageName}"
    # Remove file extension
    extractedName="${imageName%.*}"
    stmt="![${extractedName}](${relativePath})"
    
    # Copy to clipboard
    echo "${stmt}" | tee >(pbcopy)
    successInfo "${copied}"
fi
