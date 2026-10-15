#!/usr/bin/env bash
set -euo pipefail
root="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
helper="$root/upstream/forge122/src/main/java/org/taumc/celeritas/impl/compat/littletiles/LittleTilesBufferCopy.java"
[[ -f "$helper" ]] || { echo 'Prepare the patched source with build.sh first.' >&2; exit 1; }
classes="$root/build/buffer-checks"
mkdir -p "$classes"
javac_command=javac
java_command=java
if [[ -n "${JAVA_HOME:-}" ]]; then
    javac_command="$JAVA_HOME/bin/javac"
    java_command="$JAVA_HOME/bin/java"
fi
"$javac_command" --release 8 -d "$classes" "$helper" "$root/LittleTilesBufferCopyCheck.java"
"$java_command" -cp "$classes" LittleTilesBufferCopyCheck
