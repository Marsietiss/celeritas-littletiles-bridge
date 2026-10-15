#!/usr/bin/env bash
set -euo pipefail
root="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
source_dir="$root/upstream"
base_commit=7818b33172086d0576456a3acf04e1548ddbed74
patch_file="$root/celeritas-ltbridge2.patch"

if [[ ! -e "$source_dir" ]]; then
    git clone --no-checkout --filter=blob:none https://git.taumc.org/embeddedt/celeritas.git "$source_dir"
    git -C "$source_dir" fetch --depth 1 origin "$base_commit"
    git -C "$source_dir" checkout --detach "$base_commit"
fi
[[ -d "$source_dir/.git" ]] || { echo 'upstream is not a Git checkout.' >&2; exit 1; }
[[ "$(git -C "$source_dir" rev-parse HEAD)" == "$base_commit" ]] || {
    echo 'upstream is not at the pinned commit; inspect it before continuing.' >&2; exit 1;
}
if git -C "$source_dir" apply --check "$patch_file" 2>/dev/null; then
    git -C "$source_dir" apply "$patch_file"
elif ! git -C "$source_dir" apply --reverse --check "$patch_file" 2>/dev/null; then
    echo 'Patch does not apply cleanly and is not already applied; no reset performed.' >&2
    exit 1
fi
(cd "$source_dir" && bash ./gradlew '-Pceleritas_target_versions=1.12.2' packageJar --no-daemon)
jars=()
while IFS= read -r -d '' jar; do
    jars+=("$jar")
done < <(find "$source_dir/build/libs" -type f -name 'celeritas-forge-mc12.2-*.jar' -print0)
[[ ${#jars[@]} -eq 1 ]] || { echo 'Expected one packaged JAR; inspect build/libs.' >&2; exit 1; }
mkdir -p "$root/dist"
output="$root/dist/celeritas-forge-mc12.2-2.5.0-dev-ltbridge2-experimental.jar"
cp -- "${jars[0]}" "$output"
printf 'Built: %s\nExperimental build; see QC.md. No Minecraft instance was modified.\n' "$output"
