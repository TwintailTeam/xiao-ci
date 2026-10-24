# xiao-ci

Build images and release files for xiao apps.

## Images

| Image | Base | glibc | Qt 6.12.0 |
| --- | --- | --- | --- |
| `ghcr.io/twintailteam/xiao-ci:x86_64` | AlmaLinux 9 | 2.34 | `/opt/qt/6.12.0/gcc_64`, `/opt/qt/6.12.0/msvc2022_64` |
| `ghcr.io/twintailteam/xiao-ci:aarch64` | Ubuntu 24.04 | 2.39 | `/opt/qt/6.12.0/gcc_arm64`, `/opt/qt/6.12.0/msvc2022_arm64` |

Each image builds its architecture for Linux and Windows. The images contain the C/C++ toolchain, the libraries Qt links against and Qt. Rust, Node, pnpm and cargo-xwin are installed by the CI job. `QMAKE` is set to the Linux Qt.

Linux builds run on any distro with at least the image's glibc. Windows is cross-built with cargo-xwin:

```sh
# x86_64 image
XIAO_TARGET_QT=/opt/qt/6.12.0/msvc2022_64 pnpm run bundle windows-portable --target x86_64-pc-windows-msvc --runner cargo-xwin
# aarch64 image
XIAO_TARGET_QT=/opt/qt/6.12.0/msvc2022_arm64 pnpm run bundle windows-portable --target aarch64-pc-windows-msvc --runner cargo-xwin
```

`--build-arg WINDOWS=0` leaves out the Windows Qt. The Linux Qt is always included, Windows builds need its tools.

## Qt

`fetch-qt.sh` downloads Qt from download.qt.io while the images are built. It runs on Linux x86_64 and aarch64 with `sh`, `curl`, `awk`, `sed`, `tar` and `xz`, and downloads its own 7-Zip.

```sh
sh fetch-qt.sh <linux-x86_64|linux-aarch64|windows-x86_64|windows-aarch64> <install root>
```

`slim-qt.sh <prefix>...` removes files app builds don't use, such as debug libraries and Qt's own tooling.

## Reference release workflow

`examples/` holds TwintailLauncher's release setup, as a reference for app repositories. It uses pnpm and builds Linux x86_64 and aarch64 and Windows x86_64.

| File | Location in an app repository |
| --- | --- |
| `examples/release.yml` | `.github/workflows/release.yml` |
| `examples/actions/setup/action.yml` | `.github/actions/setup/action.yml` |
| `examples/actions/sign/action.yml` | `.github/actions/sign/action.yml` |
| `examples/installer.nsi` | repository root |

Pushing the tag `v<version>` from `xiao.conf.json` creates a draft release with the Linux packages and a signed Windows installer.

Requires:

- `"packageManager": "pnpm@<version>"` in `package.json`
- secrets `SIGNPATH_API_TOKEN`, `SIGNPATH_ORG_ID`, `SIGNPATH_PROJECT_SLUG`
- SignPath artifact configurations `portable`, `uninstaller`, `installer`

## License

The files in this repository are MIT-0.

The images contain Qt, licensed under [LGPL-3.0 or GPL-3.0](https://www.qt.io/licensing/open-source-lgpl-obligations), with third-party components under their own licenses. Qt WebEngine includes Chromium and its [third-party licenses](https://doc.qt.io/qt-6/qtwebengine-licensing.html). Each module's components and licenses are listed in `/opt/qt/6.12.0/<arch>/sbom`. The AlmaLinux and Ubuntu packages in the images are under their own licenses.
