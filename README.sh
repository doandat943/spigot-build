builds=($(echo "$builds" | jq -r '.[]'))
versions=($(echo "$versions" | jq -r '.[]'))
versions_to_build=($(echo "$versions_to_build" | jq -r '.[]'))

# Declare associative arrays for version families and counts
declare -A version_families
declare -A version_count

# Populate version families and counts
for i in "${!versions[@]}"; do
    version="${versions[i]}"
    build="${builds[i]}"
    IFS='.' read -r major minor patch <<<"$version"
    family="${major}.${minor}"
    version_families["$family"]+="$version:$build "
    version_count["$family"]=$((version_count["$family"] + 1))
done

# Determine max versions in any family
max_versions=0
for count in "${version_count[@]}"; do
    if [ "$count" -gt "$max_versions" ]; then
        max_versions=$count
    fi
done

# Create Markdown header
header="| Version Family |"
for ((i = 0; i < max_versions; i++)); do
    header+=" |"
done
echo "$header" > README.md

# Separator
separator="|:---:"
for ((i = 0; i < max_versions; i++)); do
    separator+="|:---:"
done
separator+="|"
echo "$separator" >> README.md

# Populate Markdown table with versions and builds
for family in $(echo "${!version_families[@]}" | tr ' ' '\n' | sort -V -r); do
    echo -n "| $family " >> README.md

    versions_in_family=(${version_families["$family"]})
    count=0
    for version_build in "${versions_in_family[@]}"; do
        version="${version_build%:*}"
        build="${version_build#*:}"
        echo -n "| [${version}](https://github.com/doandat943/spigot-build/releases/download/Spigot/spigot-${version}.jar) (${build}) " >> README.md
        count=$((count + 1))
    done

    # Fill remaining cells
    while [ "$count" -lt "$max_versions" ]; do
        echo -n "| " >> README.md
        count=$((count + 1))
    done

    echo "|" >> README.md
done
