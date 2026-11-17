#!/usr/bin/env python3
"""Register the ajnotes Typst package on this machine and create its env.typ.

Usage:
    python3 scripts/install.py            # register + env.typ
    python3 scripts/install.py --venv     # also create the venv for the figure tasks
    python3 scripts/install.py --vscode   # also install the VS Code helper extension

Safe to re-run. What it does:

  1. Links package/ into Typst's local package directory as
     @local/ajnotes:<version>, so `#import "@local/ajnotes:<version>": *` resolves
     from any folder. A link (not a copy) means edits to the package in this repo
     take effect immediately. On Windows a directory junction is used, which
     needs no administrator rights; if even that fails, it copies (re-run after
     editing the package).
  2. Creates package/env.typ from env.example.typ if it doesn't exist yet. It is
     git-ignored: your name and regional settings stay out of the repository.
  3. With --venv: creates ~/.local/share/ajnotes-venv (%LOCALAPPDATA% on
     Windows) with watchdog and pyperclip, for Watch figures and clipboard
     copying. The LaTeX ajnotes toolkit uses the same venv.
  4. With --vscode: packages vscode-extension/ and installs it with the `code`
     CLI. It adds "ajnotes: Preview Document" and "ajnotes: Export Document PDF",
     which preview or export the whole document a file belongs to; see the
     README for binding them to Cmd/Ctrl+K V and Cmd/Ctrl+Alt+B.
"""
import argparse
import os
import json
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

from config import PACKAGE, PACKAGE_DIR, PACKAGE_NAME, PACKAGE_VERSION, TOOLKIT, TYPST

EXTENSION_DIR = TOOLKIT / 'vscode-extension'


def typst_data_dir():
    """Typst's data directory, where local packages live (see `typst info`)."""
    if sys.platform == 'darwin':
        return Path.home() / 'Library' / 'Application Support' / 'typst'
    if os.name == 'nt':
        return Path(os.environ.get('APPDATA', Path.home() / 'AppData' / 'Roaming')) / 'typst'
    return Path(os.environ.get('XDG_DATA_HOME') or Path.home() / '.local' / 'share') / 'typst'


def link_package():
    target = typst_data_dir() / 'packages' / 'local' / PACKAGE_NAME / PACKAGE_VERSION
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.is_symlink() or target.exists():
        if target.resolve() == PACKAGE_DIR.resolve():
            print(f'Already registered: {PACKAGE} -> {PACKAGE_DIR}')
            return
        if target.is_symlink() or getattr(os.path, 'isjunction', lambda p: False)(target):
            target.unlink()
        else:
            shutil.rmtree(target)
    try:
        target.symlink_to(PACKAGE_DIR, target_is_directory=True)
        how = 'linked'
    except OSError:
        if os.name == 'nt' and subprocess.run(
                ['cmd', '/c', 'mklink', '/J', str(target), str(PACKAGE_DIR)],
                stdout=subprocess.DEVNULL).returncode == 0:
            how = 'linked (junction)'
        else:
            shutil.copytree(PACKAGE_DIR, target)
            how = 'copied — re-run this script after editing the package'
    print(f'Registered {PACKAGE}: {target} {how}')


def create_env():
    env = PACKAGE_DIR / 'env.typ'
    if env.exists():
        print(f'Keeping your settings: {env}')
        return
    shutil.copy(PACKAGE_DIR / 'env.example.typ', env)
    print(f'Created {env} — set your name there.')


def create_venv():
    if os.name == 'nt':
        venv = Path(os.environ.get('LOCALAPPDATA', Path.home())) / 'ajnotes-venv'
        python = venv / 'Scripts' / 'python.exe'
    else:
        venv = Path.home() / '.local' / 'share' / 'ajnotes-venv'
        python = venv / 'bin' / 'python'
    if not python.exists():
        subprocess.run([sys.executable, '-m', 'venv', str(venv)], check=True)
    subprocess.run([str(python), '-m', 'pip', 'install', '--quiet', 'watchdog', 'pyperclip'],
                   check=True)
    print(f'Venv ready: {venv}')


def install_vscode_extension():
    """Package vscode-extension/ as a .vsix (a zip with a manifest; no Node tools
    needed) and install it with VS Code's `code` command."""
    meta = json.loads((EXTENSION_DIR / 'package.json').read_text(encoding='utf-8'))
    manifest = f'''<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="{meta['name']}" Version="{meta['version']}" Publisher="{meta['publisher']}" />
    <DisplayName>{meta['displayName']}</DisplayName>
    <Description xml:space="preserve">{meta['description']}</Description>
    <Categories>Other</Categories>
    <Properties>
      <Property Id="Microsoft.VisualStudio.Code.Engine" Value="{meta['engines']['vscode']}" />
      <Property Id="Microsoft.VisualStudio.Code.ExtensionDependencies" Value="{','.join(meta.get('extensionDependencies', []))}" />
    </Properties>
  </Metadata>
  <Installation><InstallationTarget Id="Microsoft.VisualStudio.Code" /></Installation>
  <Dependencies />
  <Assets>
    <Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true" />
  </Assets>
</PackageManifest>
'''
    content_types = ('<?xml version="1.0" encoding="utf-8"?>'
                     '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
                     '<Default Extension=".json" ContentType="application/json" />'
                     '<Default Extension=".js" ContentType="application/javascript" />'
                     '<Default Extension=".vsixmanifest" ContentType="text/xml" /></Types>')
    code = shutil.which('code')
    if code is None:
        print('VS Code\'s `code` command is not on your PATH (in VS Code: Command Palette → '
              '"Shell Command: Install \'code\' command in PATH"), so the extension was not installed.')
        return
    with tempfile.TemporaryDirectory() as tmp:
        vsix = Path(tmp) / f"{meta['name']}-{meta['version']}.vsix"
        with zipfile.ZipFile(vsix, 'w', zipfile.ZIP_DEFLATED) as z:
            z.writestr('[Content_Types].xml', content_types)
            z.writestr('extension.vsixmanifest', manifest)
            for f in ('package.json', 'extension.js'):
                z.write(EXTENSION_DIR / f, f'extension/{f}')
        result = subprocess.run([code, '--install-extension', str(vsix), '--force'],
                                capture_output=True, text=True)
    if result.returncode == 0:
        print(f"Installed the VS Code extension {meta['publisher']}.{meta['name']} "
              f"{meta['version']} — reload VS Code to activate it.")
    else:
        print('Installing the VS Code extension failed:\n' + result.stderr.strip())


def check_typst():
    try:
        out = subprocess.check_output([TYPST, '--version'], universal_newlines=True)
        print(f'Found {out.strip()}')
    except (FileNotFoundError, subprocess.CalledProcessError):
        print('Typst is not installed yet — see the README. (The package is registered '
              'regardless; documents compile once Typst is there.)')


def main():
    parser = argparse.ArgumentParser(description='Register the ajnotes Typst package.')
    parser.add_argument('--venv', action='store_true',
                        help='Also create the venv used by the figure tasks.')
    parser.add_argument('--vscode', action='store_true',
                        help='Also install the VS Code helper extension.')
    args = parser.parse_args()

    link_package()
    create_env()
    if args.venv:
        create_venv()
    if args.vscode:
        install_vscode_extension()
    check_typst()
    return 0


if __name__ == '__main__':
    sys.exit(main())
