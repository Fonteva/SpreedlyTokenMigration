# This script will remove ALL package dependencies from ALL metadata files
regexs=" *<packageVersions>.*</packageVersions>\n" 
for i in "$regexs";
do
    echo $i
    find $(pwd)/src -type f | while read line; do
        perl -pi -0 -w -e "s#$i##gms" "$line"
    done
done
