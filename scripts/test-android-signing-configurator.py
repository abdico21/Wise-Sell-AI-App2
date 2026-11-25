#!/usr/bin/env python3
"""Offline smoke tests for the Android signing configurator (uses dummy test bytes only)."""
from __future__ import annotations

import base64
import os
import subprocess
import sys
import tempfile
from pathlib import Path


CONFIGURATOR = Path(__file__).with_name("configure-android-signing.py").resolve()
FIXTURES = {
    "build.gradle.kts": '''plugins {
    id("com.android.application")
}

android {
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
''',
    "build.gradle": '''plugins {
    id 'com.android.application'
}

android {
    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}
''',
}


def main() -> None:
    for filename, fixture in FIXTURES.items():
        with tempfile.TemporaryDirectory(prefix="wisesell-signing-test-") as temp:
            root = Path(temp)
            app = root / "android" / "app"
            app.mkdir(parents=True)
            (app / filename).write_text(fixture, encoding="utf-8")
            env = os.environ.copy()
            env.update({
                "ANDROID_KEYSTORE_BASE64": base64.b64encode(b"dummy-test-keystore").decode("ascii"),
                "ANDROID_KEYSTORE_PASSWORD": "test-store-password",
                "ANDROID_KEY_ALIAS": "test-upload",
                "ANDROID_KEY_PASSWORD": "test-key-password",
            })
            subprocess.run(
                [sys.executable, str(CONFIGURATOR)],
                cwd=root,
                env=env,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
            configured = (app / filename).read_text(encoding="utf-8")
            assert "signingConfigs" in configured and "release" in configured
            assert "signingConfigs.debug" not in configured
            assert "signingConfig" in configured and "release" in configured
            assert (root / "android" / "key.properties").is_file()
            assert (app / "upload-keystore.jks").read_bytes() == b"dummy-test-keystore"
    print("Android signing configurator smoke tests passed for Kotlin DSL and Groovy DSL.")


if __name__ == "__main__":
    main()
