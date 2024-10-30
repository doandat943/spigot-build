#!/bin/bash

get_version_map() {
    declare -A version_map
    longest=0

    for file in spigot-1.*.jar; do
        if [[ $file =~ ^spigot-1\.([0-9]{1,2})(?:\.([0-9]))?\.jar$ ]]; then
            major=${BASH_REMATCH[1]}
            minor=${BASH_REMATCH[2]:-0}
            version_map["$major,$minor"]="$file"

            if [[ ${#file} -gt longest ]]; then
                longest=${#file}
            fi
        fi
    done

    echo "| Version Family |"
    for ((i=0; i<longest; i++)); do
        echo -n " |"
    done
    echo ""
    echo "|:---:|"
    for ((i=0; i<longest; i++)); do
        echo -n "---|"
    done
    echo ""

    for major in $(printf "%s\n" "${!version_map[@]}" | cut -d, -f1 | sort -rn | uniq); do
        echo -n "| 1.$major |"
        for minor in $(printf "%s\n" "${!version_map[@]}" | grep "^$major," | cut -d, -f2 | sort -n); do
            file="${version_map["$major,$minor"]}"
            version="1.$major"
            if [ "$minor" -ne 0 ]; then
                version="$version.$minor"
            fi
            echo -n " [${version}](https://github.com/BaldGang/spigot-build/releases/download/${tag}/$file) |"
        done
        for ((i=0; i<longest-$(printf "%s\n" "${!version_map[@]}" | grep "^$major," | wc -l); i++)); do
            echo -n " |"
        done
        echo ""
    done
}

if [[ $# -ne 2 ]]; then
    exit 1
fi

tag="$1"
output="$2"

exec > "$output"

get_version_map
