"""
CI helper: patches pubspec.yaml to replace deepar_flutter with the local stub.
Run from the repo root: python3 scripts/patch_pubspec.py
"""
import re

with open("pubspec.yaml", "r") as f:
    content = f.read()

# Remove the deepar_flutter line AND any surrounding blank line from dependencies
# Handles lines like:  deepar_flutter: ^0.0.1
content = re.sub(r'\n[ \t]*# DeepAR for filters\n[ \t]*deepar_flutter:[^\n]*', '', content)
content = re.sub(r'\n[ \t]*deepar_flutter:[^\n]*', '', content)

# Remove any existing dependency_overrides block so we can re-add cleanly
content = re.sub(r'\ndependency_overrides:.*', '', content, flags=re.DOTALL)

# Append dependency_overrides block at the very end
content = content.rstrip() + "\n\ndependency_overrides:\n  deepar_flutter:\n    path: stubs/deepar_flutter\n"

with open("pubspec.yaml", "w") as f:
    f.write(content)

print("pubspec.yaml patched: deepar_flutter -> stubs/deepar_flutter")

# Print the result so we can see it in CI logs
with open("pubspec.yaml", "r") as f:
    print(f.read())
