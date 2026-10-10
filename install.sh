#!/data/data/com.termux/files/usr/bin/bash
set -eu

REPO="$HOME/gemini-phone-assistant"
APP="$HOME/.local/share/gemini-phone-assistant"
CONFIG="$HOME/.config/gemini-phone-assistant"
BIN="$HOME/.local/bin"
ENVFILE="$CONFIG/env"

echo "Gemini Phone Assistant installer"
echo
echo "Opening Google AI Studio to create your OWN API key:"
echo "https://aistudio.google.com/apikey"

if command -v am >/dev/null 2>&1; then
    am start -a android.intent.action.VIEW \
       -d "https://aistudio.google.com/apikey" >/dev/null 2>&1 || true
fi

printf "\nPaste your Gemini API key here (input will be hidden): "
IFS= read -r -s GEMINI_API_KEY
printf "\n"

if [ -z "$GEMINI_API_KEY" ]; then
    echo "No key entered. Installer cancelled."
    exit 1
fi

mkdir -p "$CONFIG" "$APP" "$BIN" "$HOME/.shortcuts"
chmod 700 "$CONFIG"

export GEMINI_API_KEY
echo "Checking the key and selecting an available Gemini Flash model..."

MODEL="$(python - <<'PY'
import os, json, urllib.request, urllib.error, sys

key = os.environ["GEMINI_API_KEY"]
url = "https://generativelanguage.googleapis.com/v1beta/models?pageSize=1000"
req = urllib.request.Request(url, headers={"x-goog-api-key": key})

try:
    with urllib.request.urlopen(req, timeout=30) as r:
        data = json.loads(r.read().decode())
except urllib.error.HTTPError as e:
    print("API key validation failed (HTTP %s)." % e.code, file=sys.stderr)
    print(e.read().decode(errors="replace")[:500], file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print("Could not contact Google API:", str(e), file=sys.stderr)
    sys.exit(1)

models = []
for item in data.get("models", []):
    name = item.get("name", "").removeprefix("models/")
    methods = item.get("supportedGenerationMethods", [])
    if "generateContent" in methods and "flash" in name.lower():
        models.append(name)

preferred = [
    "gemini-2.5-flash",
    "gemini-2.0-flash",
    "gemini-3.5-flash-lite",
    "gemini-3-flash-preview"
]
ordered = [m for m in preferred if m in models]
ordered += [m for m in models if m not in ordered and "preview" not in m.lower()]
ordered += [m for m in models if m not in ordered]

for model in ordered:
    endpoint = "https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent"
    body = json.dumps({
        "contents": [{"parts": [{"text": "Reply with OK."}]}],
        "generationConfig": {"maxOutputTokens": 8}
    }).encode()
    request = urllib.request.Request(
        endpoint, data=body,
        headers={"Content-Type": "application/json", "x-goog-api-key": key},
        method="POST"
    )
    try:
        with urllib.request.urlopen(request, timeout=25):
            print(model)
            sys.exit(0)
    except Exception:
        continue

print("No usable Gemini Flash model was found for this key.", file=sys.stderr)
sys.exit(1)
PY
)" || {
    unset GEMINI_API_KEY
    echo "Validation failed. Check the key, internet connection, and API access."
    exit 1
}

echo
echo "=== ADB Setup Wizard ==="
pkg update -y && pkg install -y android-tools termux-api
echo "Enable Developer options > Wireless debugging."
printf "Set up wireless ADB now? [y/N]: "
read -r yn
if [ "$yn" = y ] || [ "$yn" = Y ]; then
  printf "Pairing address (IP:PORT): "
  read -r pair_addr
  printf "Pairing code: "
  read -r pair_code
  adb pair "$pair_addr" "$pair_code" || echo "Pairing failed."
  printf "Device address (IP:PORT): "
  read -r device_addr
  [ -z "$device_addr" ] || adb connect "$device_addr"
fi
adb devices
echo
umask 077
printf 'export GEMINI_API_KEY=%q\nexport GEMINI_MODEL=%q\n' \
    "$GEMINI_API_KEY" "$MODEL" > "$ENVFILE"
unset GEMINI_API_KEY
chmod 600 "$ENVFILE"

cp "$REPO/gemini_assistant.py" "$APP/gemini_assistant.py"
cp "$REPO/phone" "$APP/phone"
chmod 700 "$APP/phone"

cat > "$BIN/gemini-phone-assistant" <<'RUN'
#!/data/data/com.termux/files/usr/bin/bash
source "$HOME/.config/gemini-phone-assistant/env"
exec python "$HOME/.local/share/gemini-phone-assistant/gemini_assistant.py"
RUN
chmod 700 "$BIN/gemini-phone-assistant"

cat > "$HOME/.shortcuts/Gemini Phone Assistant" <<'WIDGET'
#!/data/data/com.termux/files/usr/bin/bash
source "$HOME/.config/gemini-phone-assistant/env"
exec python "$HOME/.local/share/gemini-phone-assistant/gemini_assistant.py"
WIDGET
chmod 700 "$HOME/.shortcuts/Gemini Phone Assistant"

echo
echo "Setup complete! Selected model: $MODEL"
echo "Your key is saved privately in: $ENVFILE"
echo "Start the assistant with:"
echo '  ~/.local/bin/gemini-phone-assistant'
echo
echo "Next: configure ADB Wireless debugging if phone actions are not connected."
