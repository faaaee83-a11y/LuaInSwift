#!/bin/sh
# Lua 5.1.5 の公式ソースを取得して CLua/ に配置する（Codespaces や Mac で実行）
set -e
V=5.1.5
T=$(mktemp -d)
curl -fsSL -o "$T/lua.tar.gz" https://www.lua.org/ftp/lua-$V.tar.gz
tar xzf "$T/lua.tar.gz" -C "$T"
mkdir -p CLua/include
for f in "$T"/lua-$V/src/*.c; do
  case $(basename $f) in lua.c|luac.c|print.c) ;; *) cp $f CLua/ ;; esac
done
for f in "$T"/lua-$V/src/*.h; do
  case $(basename $f) in
    lua.h|luaconf.h|lualib.h|lauxlib.h) cp $f CLua/include/ ;;
    *) cp $f CLua/ ;;
  esac
done
rm -rf "$T" CLua/include/.keep
echo "Lua $V を CLua/ に配置しました"
