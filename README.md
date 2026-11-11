# xiao-ci

Build images for xiao apps.

## Images

| Image | Base | glibc | Qt 6.12.0 |
| --- | --- | --- | --- |
| `ghcr.io/twintailteam/xiao-ci:x86_64` | AlmaLinux 9 | 2.34 | `/opt/qt/6.12.0/gcc_64`, `/opt/qt/6.12.0/msvc2022_64` |
| `ghcr.io/twintailteam/xiao-ci:aarch64` | Ubuntu 24.04 | 2.39 | `/opt/qt/6.12.0/gcc_arm64`, `/opt/qt/6.12.0/msvc2022_arm64` |

Tags: `latest` and `qt-<version>` for both architectures, `<arch>` and `<arch>-qt<version>` for one.

The images hold a C/C++ toolchain and Qt for Linux and Windows. `QMAKE` points at the Linux Qt. Rust, Node, pnpm and cargo-xwin are installed by the CI job.

Linux builds need the image's glibc or newer to run. Windows is cross-built:

```sh
# x86_64 image
XIAO_TARGET_QT=/opt/qt/6.12.0/msvc2022_64 pnpm run bundle windows-portable --target x86_64-pc-windows-msvc --runner cargo-xwin
# aarch64 image
XIAO_TARGET_QT=/opt/qt/6.12.0/msvc2022_arm64 pnpm run bundle windows-portable --target aarch64-pc-windows-msvc --runner cargo-xwin
```

`--build-arg WINDOWS=0` leaves out the Windows Qt.

## Scripts

```sh
sh fetch-qt.sh <linux-x86_64|linux-aarch64|windows-x86_64|windows-aarch64> <install root>
sh slim-qt.sh <qt prefix>...
```

`fetch-qt.sh` downloads Qt from download.qt.io. It needs `curl`, `awk`, `sed`, `tar` and `xz`. `slim-qt.sh` removes debug libraries and Qt's own tooling.

## Examples

`examples/` holds example workflows.

| File | Goes to |
| --- | --- |
| `examples/release.yml` | `.github/workflows/release.yml` |
| `examples/actions/setup/action.yml` | `.github/actions/setup/action.yml` |
| `examples/actions/sign/action.yml` | `.github/actions/sign/action.yml` |
| `examples/installer.nsi` | repository root |

A `v<version>` tag creates a draft release with the Linux packages and a signed Windows installer. Needs:

- `"packageManager": "pnpm@<version>"` in `package.json`
- secrets `SIGNPATH_API_TOKEN`, `SIGNPATH_ORG_ID`, `SIGNPATH_PROJECT_SLUG`
- SignPath artifact configurations `portable`, `uninstaller`, `installer`

## License

MIT-0. The images contain Qt ([LGPL-3.0 or GPL-3.0](https://www.qt.io/licensing/open-source-lgpl-obligations)) and Qt WebEngine with Chromium ([third-party licenses](https://doc.qt.io/qt-6/qtwebengine-licensing.html)); each module's licenses are listed in `/opt/qt/6.12.0/<arch>/sbom`.
