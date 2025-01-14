#!/bin/bash
type exiftool >/dev/null 2>&1
if [ $? -gt 0 ]; then
    echo "Install exiftool first."
    exit 1
fi
set -e
if [[ "$@" == *"--help"* || "$1" == "" ]]; then
    echo
    echo M3U exporter by Irek Kubicki
    echo
    echo -e "Use \033[1mm3ue [path to M3U file] [path to destination] [flags]\033[0m"
    echo
    echo Flags:
    echo -e "\033[1m--skip\033[0m Skips files without ID3 tags."
    echo -e "\033[1m--force\033[0m Forces file copying using a filename."
    echo -e "\033[1m--dry\033[0m Dry run. No files will be copied."
    echo -e "\033[1m--noverify\033[0m Skips verificiation."
    echo -e "\033[1m--link\033[0m Creates a symlink to the script in /usr/local/bin and exit."
    echo -e "\033[1m--unlink\033[0m Removes the symlink from /usr/local/bin and exit."
    echo -e "\033[1m--help\033[0m This message."
    echo
    exit 0
fi
skip=false
force=false
dry=false
noverify=false
if [[ "$@" == *"--skip"* ]]; then
    skip=true
fi
if [[ "$@" == *"--force"* ]]; then
    force=true
fi
if [[ "$@" == *"--noverify"* ]]; then
    noverify=true
fi
if [[ "$@" == *"--dry"* ]]; then
    dry=true
    noverify=false
fi
if [[ "$@" == *"--link"* ]]; then
    if [ -f /usr/local/bin/m3ue ]; then
        echo "🖐️ Symlink already exits."
        exit 1
    fi
    sudo ln -s $(pwd)/m3ue.sh /usr/local/bin/m3ue
    if [ -f /usr/local/bin/m3ue ]; then
        echo "✅ Symlink created"
        exit 0
    else
        echo "⛔️ Could not create the link"
        exit 2
    fi
fi
if [[ "$@" == *"--unlink"* ]]; then
    if [ ! -f /usr/local/bin/m3ue ]; then
        echo "🖐️ Symlink already gone."
        exit 1
    fi
    sudo rm -f /usr/local/bin/m3ue
    if [ ! -f /usr/local/bin/m3ue ]; then
        echo "✅ Symlink removed"
        exit 0
    else
        echo "⛔️ Could not remove the link"
        exit 2
    fi
fi

if [ "$1" == "" ]; then
    echo Please provide a path to playlist file.
    exit 1
fi
if [ "$2" == "" ]; then
    echo Please provide a path destination directory.
    exit 1
fi
if [ ! -f $1 ]; then
    echo $1 is not a readable playlist file
    exit 1
fi
playlist=$(basename $1)
ext=${playlist##*.}
if [ $ext != "m3u" ]; then
    echo $1 is not a m3u file
    exit 1
fi
playlist=$(basename $1 .m3u)
if [ ! -d $2 ]; then
    echo $2 is not a writeable target directory
    exit 2
fi
target=$2
if [[ -d $target/$playlist && $force == false ]]; then
    echo $tagret/playlist directory already exists!
    exit 3
fi
if [ $noverify == false ]; then
    echo Verifying playlist...
    notags=0
    missing=0
    while IFS= read -r line; do
        if [[ $line == file:///* ]]; then
            file=${line#file://}
            if [ -f "$file" ]; then
                ext=${file##*.}
                data=$(exiftool -json -Artist -Title "$file")
                artist=$(echo $data | jq -r .[0].Artist | sed -re 's/[^ a-zA-Z0-9&._()-]//g')
                title=$(echo $data | jq -r .[0].Title | sed -re 's/[^ a-zA-Z0-9&._()-]//g')
                filename=$(basename "$file")
                echo -ne "\r\033[KProcessing $filename"
                if [[ "$artist" == "null" || "$title" == "null" ]]; then
                    ((notags++))
                    echo -e "\r\033[K⛔️ \033[1m$filename\033[0m ... no valid ID3 TAGS"
                    echo -ne "Processing $filename"
                else
                    echo -ne "\r\033[K✅ \033[1m$filename\033[0m ... $artist - $title"
                fi
            else
                ((missing++))
                echo -e "\r\033[KMissing ⛔️ $filename"
                echo -n ""
            fi
        fi
    done < $1
    echo
    if [ $missing -gt 0 ]; then
        echo 🖐️ $missing files are missing. We will skip them.
    fi
    if [ $notags -gt 0 ]; then
        if [ $skip == true ]; then
            echo 🖐️ $notags files have no ID3 TAGS. We will skip that files.
        elif [ $force == true ]; then
            echo 🖐️ $notags files have no ID3 TAGS. We will use source file names instead.
        else 
            echo ⛔️ $notags files have no ID3 TAGS. Please fix them to continue.
            exit 10
        fi
    fi
    if [ $dry == true ]; then
        exit 0
    fi
fi
echo
mkdir -p $target/$playlist
while IFS= read -r line; do
    if [[ $line == file:///* ]]; then
        file=${line#file://}
        if [ -f "$file" ]; then
            ext=${file##*.}
            data=$(exiftool -json -Artist -Title "$file")
            artist=$(echo $data | jq -r .[0].Artist | sed -re 's/[^ a-zA-Z0-9&._()-]//g')
            title=$(echo $data | jq -r .[0].Title | sed -re 's/[^ a-zA-Z0-9&._()-]//g')
            path=""
            filename=$(basename "$file")
            echo -ne "\r\033[KProcessing $filename"
            if [[ "$artist" == "null" || "$title" == "null" ]]; then
                if [ $force == true ]; then
                    path=$target/$playlist/
                    echo -e "\r\033[K\033[1m$filename\033[0m"
                    echo -e " \033[33m↳  $file\033[0m"
                    echo -ne "Processing $filename"
                fi
            else
                path=$target/$playlist/"$artist - $title.$ext"
            fi
            if [ "$path" != "" ]; then
                echo -ne "\r\033[KCopying $filename"
                if [[ ! -f $path && ! -d $path ]]; then
                    cp "$file" "$path"
                fi
            fi
        fi
    fi
done < $1
echo -ne "\r\033[KDone"
echo
