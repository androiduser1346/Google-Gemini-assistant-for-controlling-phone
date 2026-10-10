import os
import json
import urllib.request
import urllib.error
import subprocess

BASE = os.path.expanduser("~/.local/share/gemini-phone-assistant")
PHONE = os.path.join(BASE, "phone")

ALLOWED = {
    "home", "back", "recents", "settings", "display",
    "chrome", "youtube", "youtube-music", "youtube-search",
    "wifi-on", "wifi-off", "volume-up", "volume-down",
    "mute", "battery", "notifications", "quick-settings", "status"
}

SYSTEM = """
You are a multilingual Android phone assistant.
Understand English, Hindi, Punjabi, and mixed-language speech.
Return only JSON in this format:
{"reply":"short helpful response","action":"allowed action or none","query":"search words or empty"}

Allowed actions:
home, back, recents, settings, display, chrome, youtube,
youtube-music, youtube-search, wifi-on, wifi-off, volume-up,
volume-down, mute, battery, notifications, quick-settings, status.

Map only clear requests to allowed actions.
For YouTube song searches, use youtube-search and put the search terms in query.
Use youtube only when the user asks to open YouTube without a search.
For unsupported requests, explain the limitation and set action to none.
Never create shell commands or invent actions.
"""

def ask(history):
    key = os.environ.get("GEMINI_API_KEY")
    model = os.environ.get("GEMINI_MODEL")
    if not key or not model:
        raise RuntimeError("API configuration missing. Run install.sh again.")

    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        + model + ":generateContent"
    )
    body = {
        "systemInstruction": {"parts": [{"text": SYSTEM}]},
        "contents": history,
        "generationConfig": {
            "responseMimeType": "application/json",
            "temperature": 0.2,
            "maxOutputTokens": 400
        }
    }
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode(),
        headers={
            "Content-Type": "application/json",
            "x-goog-api-key": key
        },
        method="POST"
    )
    with urllib.request.urlopen(req, timeout=60) as response:
        data = json.loads(response.read().decode())

    text = data["candidates"][0]["content"]["parts"][0]["text"]
    return json.loads(text)

def listen():
    try:
        result = subprocess.run(
            ["termux-speech-to-text"],
            capture_output=True,
            text=True,
            timeout=90
        )
        spoken = result.stdout.strip()
        if result.returncode == 0 and spoken:
            return spoken
        print("Voice recognition returned no text.")
    except FileNotFoundError:
        print("Install the Termux:API companion app and termux-api package.")
    except subprocess.TimeoutExpired:
        print("Voice recognition timed out.")
    except Exception as error:
        print("Voice input error:", error)
    return ""

def main():
    history = []
    print("\nGemini Phone Assistant")
    print("Press Enter to speak, type a command, or type exit to quit.")
    print("Supported actions require confirmation before execution.")

    while True:
        try:
            user = input("\nYou > ").strip()
            if user.lower() in {"exit", "quit"}:
                break
            if not user:
                user = listen()
                if not user:
                    continue
                print("Recognized:", user)

            history.append({"role": "user", "parts": [{"text": user}]})
            result = ask(history)
            history.append({
                "role": "model",
                "parts": [{"text": json.dumps(result, ensure_ascii=False)}]
            })
            history = history[-10:]

            print("\nGemini >", result.get("reply", ""))
            action = str(result.get("action", "none")).lower().strip()
            query = str(result.get("query", "")).strip()

            if action == "none":
                continue
            if action not in ALLOWED:
                print("Unsupported action blocked.")
                continue

            args = [PHONE, action]
            if action == "youtube-search":
                query = query or user
                args.append(query)
                print("YouTube search:", query)
            else:
                print("Requested phone action:", action)

            confirm = input("Run this action? Type YES to confirm: ").strip()
            if confirm.lower() == "yes":
                subprocess.run(args, timeout=30, check=False)
            else:
                print("Action cancelled.")

        except (EOFError, KeyboardInterrupt):
            print("\nGoodbye!")
            break
        except urllib.error.HTTPError as error:
            print("Gemini API error:", error.code)
            print(error.read().decode(errors="replace")[:800])
        except Exception as error:
            print("Error:", error)

if __name__ == "__main__":
    main()
