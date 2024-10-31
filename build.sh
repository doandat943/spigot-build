#!/bin/bash

versions=($(curl -L -s https://joverse.us/spigot | grep -oP '(?<=href=")[^"]*' | grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?' | grep -v '-' | sed 's/.json//' | sort -V))

echo $versions

classify_java_version() {
    version="$1"
    IFS='.' read -r major minor patch <<<"$version"

    if ((major == 1 && minor < 17)); then
        echo "JAVA8"
    elif ((major == 1 && minor >= 17 && minor < 20)); then
        echo "JAVA17"
    elif ((major == 1 && minor >= 20)); then
        echo "JAVA21"
    fi
}

generate_readme() {
    declare -A version_families
    declare -A version_count

    for version in "${versions[@]}"; do
        IFS='.' read -r major minor patch <<<"$version"
        family="${major}.${minor}"
        version_families["$family"]+="$version "
        ((version_count["$family"]++))
    done

    max_versions=0
    for count in "${version_count[@]}"; do
        if ((count > max_versions)); then
            max_versions=$count
        fi
    done

    header="| Version Family |"
    for ((i = 0; i < max_versions; i++)); do
        header+=" |"
    done
    echo "$header" >README.md

    separator="|:---:"
    for ((i = 0; i < max_versions; i++)); do
        separator+="|---:"
    done
    separator+="|"
    echo "$separator" >>README.md

    for family in $(echo "${!version_families[@]}" | tr ' ' '\n' | sort -V -r); do
        echo -n "| $family " >>README.md

        versions_in_family=(${version_families["$family"]})
        count=0
        for version in "${versions_in_family[@]}"; do
            echo -n "| [${version}](https://github.com/doandat943/spigot-build/releases/download/20241028/spigot-${version}.jar) " >>README.md
            ((count++))
        done

        while ((count < max_versions)); do
            echo -n "| " >>README.md
            ((count++))
        done

        echo "|" >>README.md
    done
}

for version in $(printf "%s\n" "${versions[@]}" | sort -V); do
    classification=$(classify_java_version "$version")
    echo "$version:$classification"
done

generate_readme
