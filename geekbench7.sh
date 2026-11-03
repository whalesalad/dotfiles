bash <<'BASH'
set -euo pipefail
umask 077

version=7.1.0
case "$(uname -m)" in
  x86_64)        package="Linux" ;;
  aarch64|arm64) package="LinuxARMPreview" ;;
  *) echo "Unsupported CPU architecture: $(uname -m)"; exit 1 ;;
esac

for tool in curl tar tee; do
  command -v "$tool" >/dev/null || {
    echo "Please install $tool first."
    exit 1
  }
done

base="${XDG_DATA_HOME:-$HOME/.local/share}/geekbench"
mkdir -p "$base"
run="$(mktemp -d "$base/run-$(date +%Y%m%d-%H%M%S)-XXXXXX")"
mkdir "$run/app"

echo "Downloading Geekbench $version..."
curl --fail --location --retry 3 \
  "https://geekbench-cdn.b-cdn.net/Geekbench-${version}-${package}.tar.gz" \
  -o "$run/geekbench.tar.gz"

tar -xzf "$run/geekbench.tar.gz" \
  -C "$run/app" --strip-components=1
rm "$run/geekbench.tar.gz"

echo "Running CPU benchmark on $(hostname)..."
cd "$run/app"
./geekbench7 </dev/null 2>&1 | tee "$run/output.log"

./geekbench7 --gpu-list </dev/null 2>&1 | tee "$run/gpu-list.log"
if ! gpu_api="$(grep -m1 -E '^(CUDA|Vulkan|OpenCL)$' "$run/gpu-list.log")"; then
  echo "No supported GPU API found. Check $run/gpu-list.log"
  exit 1
fi

echo "Running $gpu_api GPU benchmark on $(hostname)..."
./geekbench7 --gpu "$gpu_api" </dev/null 2>&1 | tee "$run/gpu-output.log"

: > "$run/claim-url.txt"
for log in "$run/output.log" "$run/gpu-output.log"; do
  if ! grep -Eo 'https://browser\.geekbench\.com/[^[:space:]]+/claim\?key=[^[:space:]]+' \
    "$log" >> "$run/claim-url.txt"; then
    echo "No claim link found. Check $log"
    exit 1
  fi
done

echo
echo "Open these links while signed into your Geekbench account:"
cat "$run/claim-url.txt"

echo
echo "Saved logs and claim links in: $run"
BASH
