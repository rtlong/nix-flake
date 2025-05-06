#!/usr/bin/env bash

SOURCE_DIR="/data/downloads/Downloads"
DEST_DIR="/data/media"
IGNORE_EXTENSIONS="jpg jpeg txt nfo png gif"
VIDEO_EXTENSIONS="mp4 mkv mov avi"

DRY_RUN=false
[[ "$1" == "--dry-run" || "$1" == "-n" ]] && DRY_RUN=true

# Helpers
clean_name() {
  echo "$1" | sed -E 's/\[[^][]]*\]//g' | sed -E 's/[^a-zA-Z0-9.() -]/ /g' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//'
}

is_ignored() {
  local ext="${1,,}"
  [[ " $IGNORE_EXTENSIONS " == *" $ext "* ]]
}

# Main loop
find "$SOURCE_DIR" -type f ! -iname "*.part" | while read -r FILE; do
  ext="${FILE##*.}"
  ext_lc="${ext,,}"
  filename="$(basename "$FILE")"
  [[ "$(is_ignored "$ext_lc")" == 1 ]] && continue

  relpath="${FILE#$SOURCE_DIR/}"

  if [[ "$relpath" == Movies/* ]]; then
    movie_path="${relpath#Movies/}"
    movie_dir="${movie_path%%/*}"
    subpath="${movie_path#*/}"
    [[ "$subpath" == "$movie_path" ]] && subpath="$filename"

    clean_movie_dir="$(clean_name "$movie_dir")"
    target_path="$DEST_DIR/movies/$clean_movie_dir/$subpath"
    target_dir="$(dirname "$target_path")"

  elif [[ "$relpath" == TV/* ]]; then
    if [[ "$FILE" =~ S([0-9]{2})E[0-9]{2} ]]; then
      season_num="${BASH_REMATCH[1]}"
    elif [[ "$FILE" =~ Season[[:space:]]*([0-9]+) ]]; then
      season_num=$(printf "%02d" "${BASH_REMATCH[1]}")
    else
      season_num="00"
    fi

    show_base="$(echo "$relpath" | cut -d'/' -f2 | sed -E 's/\(.*//')"
    show_clean="$(clean_name "$show_base")"
    target_dir="$DEST_DIR/tv/$show_clean/Season $season_num"
    target_path="$target_dir/$filename"
  else
    continue
  fi

  if [[ -e "$target_path" ]]; then
    continue
  fi

  if $DRY_RUN; then
    echo "$target_path"
  else
    mkdir -p "$target_dir"
    ln "$FILE" "$target_path"
  fi
done
