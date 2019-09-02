#!/bin/bash

titleBeginModifier="\033[1;37;40m"
warningBeginModifier="\033[1;31m"
endModifier="\033[0m"

if [[ $# -eq 1 ]]; then
    clippings="My Clippings.txt"
    # clippings="test"
   
    if [[ -e ${clippings} ]]; then
        timestamp=`date +%T`
        echo -e "${warningBeginModifier}${timestamp}\n>>>BEGIN${endModifier}"

        awk -v keyword="$1" -v begin=${titleBeginModifier} -v end=${endModifier} '
        BEGIN {
            titlePattern = ".*" keyword ".*\\)\r"
            pagePattern="^-[[:space:]].*[[:digit:]M]\r$"
            emptyPattern="^\r$"
            separatorPattern="={10}"
        }
        {
            if(tolower($0) ~ titlePattern){
                currentTitle=begin $0 end "\n"
                if (getline > 0 && $0 ~ pagePattern) {
                    if (getline > 0 && $0 ~ emptyPattern) {
                        if (getline > 0 && $0 !~ emptyPattern) {
                            note=$0
                            while (getline > 0 && $0 !~ separatorPattern) {
                                note=note "\n" $0
                            }
                            note=note "\n\n"
                            if (map[note] == 0) {
                                map[note] = currentTitle
                            }
                        }
                    }
                }
            }
        }
        END {
            for (key in map) {
                print map[key] key
            }
        }
        ' "${clippings}" | sed '$d' | sed '$d'

        echo -e "${warningBeginModifier}<<<END${endModifier}"
    else
        echo -e "${warningBeginModifier}No such file: ${clippings}${endModifier}"
    fi
else
    echo -e "Usage: ${0} [title|author]"
    echo -e "Description:\n  A simple search tool for kindle clippings. Keywords are supposed to be lower case."
fi