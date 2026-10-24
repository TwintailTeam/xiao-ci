#!/bin/sh
set -eu

[ $# -gt 0 ] || { echo "usage: slim-qt.sh <qt prefix>..." >&2; exit 1; }

TOOLING_LIBS="Qt6QmlLS Qt6QmlDom Qt6QmlLint Qt6Qmltc Qt6QuickTestUtils Qt6QuickControlsTestUtils"

for prefix in "$@"; do
    [ -d "$prefix/lib" ] || { echo "slim-qt: $prefix is not a Qt prefix" >&2; exit 1; }

    find "$prefix" -type f \( -name '*d.dll' -o -name '*d.lib' -o -name '*d.pdb' \) | while read -r file; do
        if [ -f "${file%d.*}.${file##*.}" ]; then
            rm "$file"
        fi
    done

    for lib in $TOOLING_LIBS; do
        rm -f "$prefix/lib/lib$lib.a" "$prefix/lib/$lib.lib"
    done

    rm -f "$prefix/libexec/webenginedriver" "$prefix/bin/webenginedriver.exe" "$prefix/bin/qdoc" "$prefix/bin/qdoc.exe"
    if [ -d "$prefix/resources" ]; then
        find "$prefix/resources" -name '*.debug.pak' -delete
    fi
done
