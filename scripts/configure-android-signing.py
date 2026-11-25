#!/usr/bin/env python3
"""Configure Android release signing from ephemeral CI environment secrets."""
from __future__ import annotations

import base64
import os
import re
from pathlib import Path


def required(name: str) -> str:
    value = os.environ.get(name, "")
    if not value:
        raise SystemExit(f"Missing required signing environment variable: {name}")
    if "\n" in value or "\r" in value:
        raise SystemExit(f"Invalid newline in {name}")
    return value


def escape_property(value: str) -> str:
    return (value.replace("\\", "\\\\")
            .replace(":", "\\:")
            .replace("=", "\\=")
            .replace(" ", "\\ "))


def main() -> None:
    encoded = required("ANDROID_KEYSTORE_BASE64")
    store_password = required("ANDROID_KEYSTORE_PASSWORD")
    key_alias = required("ANDROID_KEY_ALIAS")
    key_password = required("ANDROID_KEY_PASSWORD")

    try:
        keystore = base64.b64decode(encoded, validate=True)
    except Exception as exc:
        raise SystemExit("ANDROID_KEYSTORE_BASE64 is not valid base64") from exc
    if not keystore:
        raise SystemExit("Decoded Android keystore is empty")

    android_dir = Path("android")
    app_dir = android_dir / "app"
    app_dir.mkdir(parents=True, exist_ok=True)
    keystore_path = app_dir / "upload-keystore.jks"
    keystore_path.write_bytes(keystore)
    keystore_path.chmod(0o600)

    properties = android_dir / "key.properties"
    properties.write_text(
        "storePassword=" + escape_property(store_password) + "\n"
        "keyPassword=" + escape_property(key_password) + "\n"
        "keyAlias=" + escape_property(key_alias) + "\n"
        "storeFile=app/upload-keystore.jks\n",
        encoding="utf-8",
    )
    properties.chmod(0o600)

    gradle_files = [app_dir / "build.gradle.kts", app_dir / "build.gradle"]
    gradle_file = next((path for path in gradle_files if path.is_file()), None)
    if gradle_file is None:
        raise SystemExit("Generated Android app Gradle file was not found")

    source = gradle_file.read_text(encoding="utf-8")
    is_kotlin = gradle_file.suffix == ".kts"
    android_match = re.search(r"(?m)^android\s*\{", source)
    if not android_match:
        raise SystemExit("Could not locate the Android Gradle configuration block")

    if is_kotlin:
        loader = (
            'val keystoreProperties = java.util.Properties().apply {\n'
            '    load(java.io.FileInputStream(rootProject.file("key.properties")))\n'
            '}\n\n'
        )
        signing = (
            '    signingConfigs {\n'
            '        create("release") {\n'
            '            keyAlias = keystoreProperties.getProperty("keyAlias")\n'
            '            keyPassword = keystoreProperties.getProperty("keyPassword")\n'
            '            storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))\n'
            '            storePassword = keystoreProperties.getProperty("storePassword")\n'
            '        }\n'
            '    }\n'
        )
        patterns = [
            (r'signingConfig\s*=\s*signingConfigs\.getByName\(\s*"debug"\s*\)',
             'signingConfig = signingConfigs.getByName("release")'),
            (r"signingConfig\s*=\s*signingConfigs\.debug",
             'signingConfig = signingConfigs.getByName("release")'),
        ]
    else:
        loader = (
            "def keystoreProperties = new java.util.Properties()\n"
            "keystoreProperties.load(new java.io.FileInputStream(rootProject.file('key.properties')))\n\n"
        )
        signing = (
            "    signingConfigs {\n"
            "        release {\n"
            "            keyAlias keystoreProperties['keyAlias']\n"
            "            keyPassword keystoreProperties['keyPassword']\n"
            "            storeFile rootProject.file(keystoreProperties['storeFile'])\n"
            "            storePassword keystoreProperties['storePassword']\n"
            "        }\n"
            "    }\n"
        )
        patterns = [
            (r"""signingConfig\s*(?:=\s*)?signingConfigs\.getByName\(\s*['"]debug['"]\s*\)""",
             "signingConfig signingConfigs.getByName('release')"),
            (r"signingConfig\s*=\s*signingConfigs\.debug",
             "signingConfig signingConfigs.release"),
        ]

    if ("key.properties" in source or 'create("release")' in source
            or re.search(r"signingConfigs\s*\{\s*release", source)):
        raise SystemExit("Gradle signing configuration already exists; refusing to overwrite it")

    source = source[:android_match.start()] + loader + source[android_match.start():]
    build_types = re.search(r"(?m)^\s*buildTypes\s*\{", source)
    if not build_types:
        raise SystemExit("Could not locate buildTypes in Android Gradle configuration")
    source = source[:build_types.start()] + signing + source[build_types.start():]

    replaced = False
    for pattern, replacement in patterns:
        source, count = re.subn(pattern, replacement, source, count=1)
        if count:
            replaced = True
            break
    if not replaced:
        raise SystemExit("Could not safely replace the generated debug release-signing assignment")

    gradle_file.write_text(source, encoding="utf-8")
    print(f"Configured release signing in {gradle_file}; signing material remains on the runner.")


if __name__ == "__main__":
    main()
