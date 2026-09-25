"""Check local iOS release configuration without contacting Firebase or Apple.

Runs on Windows and Codemagic/macOS with Python 3's standard library.
This is a configuration check, not proof of native build or App Review readiness.
"""

import plistlib
import re
from pathlib import Path


def check(root: Path) -> list[str]:
    errors = []
    project = (root / "ios/Runner.xcodeproj/project.pbxproj").read_text(
        encoding="utf-8"
    )
    bundle_ids = set(
        re.findall(r"PRODUCT_BUNDLE_IDENTIFIER\s*=\s*([^;]+);", project)
    )
    bundle_ids = {value.strip().strip('"') for value in bundle_ids}
    # This repository currently has one application target, Runner.
    if len(bundle_ids) != 1:
        errors.append("Runner build configurations must agree on one Bundle ID.")

    with (root / "ios/Runner/GoogleService-Info.plist").open("rb") as source:
        firebase = plistlib.load(source)
    if bundle_ids and firebase.get("BUNDLE_ID") not in bundle_ids:
        errors.append(
            "Firebase BUNDLE_ID does not match Runner. Download the configuration "
            "for the matching iOS app from Firebase Console; do not just edit "
            "BUNDLE_ID inside GoogleService-Info.plist."
        )

    with (root / "ios/Runner/Info.plist").open("rb") as source:
        info = plistlib.load(source)
    if not str(info.get("NSPhotoLibraryUsageDescription", "")).strip():
        errors.append("Student photo selection needs NSPhotoLibraryUsageDescription.")
    for key, expected in {
        "CFBundleShortVersionString": "$(FLUTTER_BUILD_NAME)",
        "CFBundleVersion": "$(FLUTTER_BUILD_NUMBER)",
    }.items():
        if info.get(key) != expected:
            errors.append(f"{key} must use {expected}.")

    with (root / "ios/Runner/PrivacyInfo.xcprivacy").open("rb") as source:
        privacy = plistlib.load(source)
    if not privacy:
        print(
            "REVIEW: App privacy manifest is empty. Review the archived app and "
            "SDK manifests before declaring required-reason API usage."
        )
    if info.get("UIRequiresFullScreen"):
        print("REVIEW: iPad full-screen mode is enabled; split-view is not enabled.")
    return errors


def main() -> int:
    try:
        errors = check(Path(__file__).resolve().parents[1])
    except (OSError, ValueError, plistlib.InvalidFileException) as error:
        print(f"FAIL: Cannot read iOS configuration ({type(error).__name__}).")
        return 1
    for error in errors:
        print(f"FAIL: {error}")
    if errors:
        return 1
    print("PASS: Local iOS configuration checks. Native build and review still required.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
