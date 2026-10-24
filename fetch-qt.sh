#!/bin/sh
set -eu

QT=6.12.0
QT_ID=6120
WEBENGINE_DIR=6120/61400
ADDONS="qtwebchannel qtpositioning"
REPO=https://download.qt.io/online/qtsdkrepository

SEVENZIP_X64="7z2604-linux-x64.tar.xz fc0327ba27e89bd086cf426dff17d77de582953cdbbc10a6576540a06853ffcd"
SEVENZIP_ARM64="7z2604-linux-arm64.tar.xz 5b0ac3aa91c1e3499f011d6af69d7f6b4de3ef2f011d9e2ff44c58ebd04aa388"

usage() {
    echo "usage: fetch-qt.sh <linux-x86_64|linux-aarch64|windows-x86_64|windows-aarch64> <install root>" >&2
    exit 1
}

fail() {
    echo "fetch-qt: $1" >&2
    exit 1
}

get() {
    curl -fsSL --retry 6 --retry-delay 5 "$@"
}

[ $# -eq 2 ] || usage
case "$1" in
    linux-x86_64)
        host=linux_x64 base=qt6_$QT_ID/qt6_$QT_ID arch=linux_gcc_64 webengine=x86_64 dir=gcc_64 built_at=/home/qt/work/install ;;
    linux-aarch64)
        host=linux_arm64 base=qt6_$QT_ID/qt6_$QT_ID arch=linux_gcc_arm64 webengine=arm64 dir=gcc_arm64 built_at=/home/qt/work/install ;;
    windows-x86_64)
        host=windows_x86 base=qt6_$QT_ID/qt6_${QT_ID}_msvc2022_64 arch=win64_msvc2022_64 webengine=msvc2022_64 dir=msvc2022_64 built_at=c:/Users/qt/work/install ;;
    windows-aarch64)
        host=windows_x86 base=qt6_$QT_ID/qt6_${QT_ID}_msvc2022_arm64_cross_compiled arch=win64_msvc2022_arm64_cross_compiled webengine=msvc2022_arm64 dir=msvc2022_arm64 built_at= ;;
    *)
        usage ;;
esac

mkdir -p "$2"
root=$(cd "$2" && pwd)
prefix=$root/$QT/$dir
[ ! -e "$prefix" ] || fail "$prefix already exists"
mkdir -p "$prefix"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

case $(uname -m) in
    x86_64 | amd64) set -- $SEVENZIP_X64 ;;
    aarch64 | arm64) set -- $SEVENZIP_ARM64 ;;
    *) fail "no 7-Zip build for $(uname -m)" ;;
esac
get -o "$work/7z.tar.xz" "https://www.7-zip.org/a/$1"
echo "$2  $work/7z.tar.xz" | sha256sum -c - >/dev/null || fail "$1 does not match its sha256"
tar -xJf "$work/7z.tar.xz" -C "$work" 7zz

package() {
    awk -v want="$2" '
        function inner(text, tag) {
            if (!match(text, "<" tag ">[^<]*</" tag ">")) return ""
            return substr(text, RSTART + length(tag) + 2, RLENGTH - 2 * length(tag) - 5)
        }
        { doc = doc $0 "\n" }
        END {
            while ((end = index(doc, "</PackageUpdate>")) > 0) {
                block = substr(doc, 1, end)
                doc = substr(doc, end + 16)
                if (!index(block, "<Name>" want "</Name>")) continue
                print inner(block, "Version")
                rest = block
                while ((at = index(rest, "<Operation name=\"Extract\">")) > 0) {
                    rest = substr(rest, at + 26)
                    target = inner(rest, "Argument")
                    rest = substr(rest, RSTART + RLENGTH)
                    archive = inner(rest, "Argument")
                    rest = substr(rest, RSTART + RLENGTH)
                    sub(/^@TargetDir@\//, "", target)
                    targets[archive] = target
                }
                count = split(inner(block, "DownloadableArchives"), archives, ",")
                for (i = 1; i <= count; i++) {
                    gsub(/^[ \t\n]+|[ \t\n]+$/, "", archives[i])
                    if (archives[i] != "") print archives[i] "\t" targets[archives[i]]
                }
                exit
            }
        }' "$1"
}

install() {
    get -o "$work/Updates.xml" "$1/Updates.xml"
    package "$work/Updates.xml" "$2" >"$work/package"
    version=$(head -n 1 "$work/package")
    [ -n "$version" ] || fail "$2 is not in $1/Updates.xml"
    tail -n +2 "$work/package" | while IFS="$(printf '\t')" read -r archive target; do
        case "$archive" in "${3:-/}"*) continue ;; esac
        echo "fetching $archive"
        url="$1/$2/$version$archive"
        get -o "$work/archive.7z" "$url"
        expected=$(get "$url.sha1" | cut -d ' ' -f 1)
        actual=$(sha1sum "$work/archive.7z" | cut -d ' ' -f 1)
        [ "$expected" = "$actual" ] || fail "$archive does not match its sha1"
        destination=$prefix
        [ -z "$target" ] || destination=$root/$target
        mkdir -p "$destination"
        "$work/7zz" x -y -snld20 -bso0 -bsp0 "-o$destination" "$work/archive.7z"
        rm "$work/archive.7z"
    done
}

desktop=$REPO/$host/desktop/$base
install "$desktop" "qt.qt6.$QT_ID.$arch"
for addon in $ADDONS; do
    install "$desktop" "qt.qt6.$QT_ID.addons.$addon.$arch"
done
install "$REPO/$host/extensions/qtwebengine/$WEBENGINE_DIR/$webengine" "extensions.qtwebengine.$(echo $WEBENGINE_DIR | tr / .).$arch" qtwebview

if [ -n "$built_at" ]; then
    printf '[Paths]\nPrefix=..\n' >"$prefix/bin/qt.conf"
    find "$prefix/lib" -maxdepth 2 -path '*/pkgconfig/*.pc' -exec sed -i "s|prefix=$built_at|prefix=$prefix|" {} +
    find "$prefix/lib" -maxdepth 1 -name '*.la' -exec sed -i "s|$built_at/lib|$prefix/lib|g" {} +
    find "$prefix/lib" -maxdepth 1 -name '*.prl' -exec sed -i "s|$built_at/lib|\$\$[QT_INSTALL_LIBS]|g" {} +
fi

echo "$prefix"
