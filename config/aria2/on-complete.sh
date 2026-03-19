#!/bin/bash
set -euo pipefail

# aria2 callback parameters：
# $1 = GID
# $2 = files number
# $3 = first file path (if multiple files, this is the first one; if single file, this is the only one)q
FILE_PATH="${3:-}"

# Exit directly with empty parameters
[ -z "$FILE_PATH" ] && exit 0

# BT may appear in directory/temporary state, skip the directory here
[ -d "$FILE_PATH" ] && exit 0

DOWNLOADS="$HOME/Downloads"

# if the file is not in ~/Downloads, do nothing (safety check to avoid moving files from other locations)
case "$FILE_PATH" in
  "$DOWNLOADS"/*) ;;
  *) exit 0 ;;
esac

FILE_NAME="$(basename "$FILE_PATH")"
EXT="${FILE_NAME##*.}"
EXT_LC="$(printf '%s' "$EXT" | tr '[:upper:]' '[:lower:]')"

# It will be moved only if the category is hit; if it is not hit, it will remain in the ~/Downloads root directory.
dest_dir=""

case "$EXT_LC" in
  # images
  jpg|jpeg|png|gif|webp|heic|tif|tiff|bmp|svg)
    dest_dir="$DOWNLOADS/images"
    ;;

  # media
  mp4|mkv|mov|avi|webm|m4v)
    dest_dir="$DOWNLOADS/videos"
    ;;

  # audio
  mp3|m4a|aac|flac|wav|ogg|opus)
    dest_dir="$DOWNLOADS/audio"
    ;;

  # archives
  zip|rar|7z|tar|gz|bz2|xz)
    dest_dir="$DOWNLOADS/archives"
    ;;

  # installers
  dmg|pkg|iso)
    dest_dir="$DOWNLOADS/installers"
    ;;

  # documents
  pdf|txt|md|rtf|doc|docx|ppt|pptx|xls|xlsx)
    dest_dir="$DOWNLOADS/docs"
    ;;
esac

# If the file extension does not match any category, do nothing and leave it in the root of ~/Downloads
[ -z "$dest_dir" ] && exit 0

mkdir -p "$dest_dir"

# If a file with the same name already exists in the destination directory, append a timestamp to the filename to avoid overwriting.
target="$dest_dir/$FILE_NAME"
if [ -e "$target" ]; then
  base="${FILE_NAME%.*}"
  suffix=""
  if [ "$base" != "$FILE_NAME" ]; then
    suffix=".${FILE_NAME##*.}"
  fi
  ts="$(date '+%Y%m%d-%H%M%S')"
  target="$dest_dir/${base}-${ts}${suffix}"
fi

# Move the file to the target directory
mv "$FILE_PATH" "$target"

# Create a symbolic link in the original location pointing to the new location, so that if there are any applications still referencing the old path, they can still find the file. This is optional and can be removed if you prefer to just move the file without leaving a link.
ln -sf "$target" "$FILE_PATH"

# In case there are applications that still reference the old path and may have issues with the symbolic link, we can set a timer to remove the symbolic link after a certain period (e.g., 3 minutes). This allows enough time for most applications to update their references to the new location, while ensuring that we don't leave broken links indefinitely.
(
  sleep 180
  if [ -L "$FILE_PATH" ]; then
    link_dest="$(readlink "$FILE_PATH" || true)"
    if [ "$link_dest" = "$target" ]; then
      rm -f "$FILE_PATH"
    fi
  fi
) >/dev/null 2>&1 &

