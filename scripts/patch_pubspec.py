"""
CI helper: patches pubspec.yaml to replace deepar_flutter with the local stub.
Run from the repo root: python3 scripts/patch_pubspec.py
"""
import re

with open("pubspec.yaml", "r") as f:
    content = f.read()

# Remove the deepar_flutter line from dependencies section
content = re.sub(r'\n[ \t]*deepar_flutter:[ \t]*\^?[\d\.]+\n', '\n', content)

# Add dependency_overrides block at the very end
if "dependency_overrides" not in content:
    content += "\ndependency_overrides:\n  deepar_flutter:\n    path: stubs/deepar_flutter\n"

with open("pubspec.yaml", "w") as f:
    f.write(content)

print("pubspec.yaml patched: deepar_flutter -> stubs/deepar_flutter")
