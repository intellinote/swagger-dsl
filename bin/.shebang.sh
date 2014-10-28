#!/bin/bash
# This script will run a JavaScript/CoffeeScript file of the same name found in `../lib/`.
BASENAME="$(basename "$0")"
if [ "$BASENAME" = ".shebang.sh" ]; then
  echo "The file .shebang.sh is not meant to be invoked directly."
  echo "See the README file for more information."
  exit 1
else
  COFFEE_EXE=`which coffee || which coffee.exe`
  NODE_EXE=`which node || which node.exe`
  # Resolve the full path to the directory that contains this script (respecting symlinks).
  # via: http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
  SOURCE="${BASH_SOURCE[0]}"
  while [ -h "$SOURCE" ]; do
    BIN_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$BIN_DIR/$SOURCE"
  done
  BIN_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  BASEDIR="$( cd "$BIN_DIR" && cd .. && pwd )"
  # Now BASEDIR is the project or module root directory
  if [ -x "$COFFEE_EXE" ]; then
    "$COFFEE_EXE" "$BASEDIR/lib/$BASENAME.coffee" "$@"
  else
    "$NODE_EXE" "$BASEDIR/lib/$BASENAME.js" "$@"
  fi
fi
