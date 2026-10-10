# Gemini Phone Assistant for Termux

A personal Android assistant powered by the Gemini API. It understands typed
requests and can use Termux:API speech recognition for English, Hindi, Punjabi,
and mixed-language input, depending on the Android speech-recognition service.

## Features

- Gemini-powered command understanding
- Optional speech input through Termux:API
- Android actions through ADB
- Confirmation before every supported phone action
- Termux:Widget shortcut
- Installer validates each user's own API key
- API key stored in a private config file, not in this repository

## Requirements

- Android with Termux (preferably from F-Droid)
- Internet access
- Termux:API app and the `termux-api` package for speech input
- ADB wireless debugging configured for Android phone actions
- Your own Google AI Studio API key

## Install

Open Termux and run:

```bash
pkg update -y
pkg install -y git python android-tools termux-api
git clone https://github.com/YOUR_GITHUB_USERNAME/gemini-phone-assistant.git
cd gemini-phone-assistant
bash install.sh
```

The installer opens Google AI Studio. Create your own key at
https://aistudio.google.com/apikey and paste it when prompted. Input is hidden.
The installer checks the key and selects an available Gemini Flash model.

Run the assistant:

```bash
~/.local/bin/gemini-phone-assistant
```

Press Enter to start voice recognition, or type a command. Each phone action
requires you to type `YES` before it runs.

## ADB setup

1. Enable Developer options and Wireless debugging in Android settings.
2. Use `adb pair IP:PAIRING_PORT` with the pairing code shown by Android.
3. Connect with `adb connect IP:DEBUG_PORT`.
4. Check with `adb devices`.

Pairing and connection ports may be different. Keep Wireless debugging on while
you want ADB actions to work. Do not expose ADB to untrusted networks.

## Home-screen widget

Install the Termux:Widget companion app, then add its widget to your home
screen. The installer creates a shortcut named `Gemini Phone Assistant`
under `~/.shortcuts`.

## Security

- Each person must use their own API key.
- The installer saves the key under `~/.config/gemini-phone-assistant/env`
  with restrictive permissions.
- Never commit API keys, environment files, or recordings.
- Never paste your API key into a public issue, chat, or source file.
- The API key is used to call Google's API; follow Google's current terms,
  quotas, and billing settings.
- Review the code before running it. Phone actions are limited to an
  allowlist and require explicit confirmation.

## Troubleshooting

- **Invalid key:** create/check a key at https://aistudio.google.com/apikey.
- **No model available:** verify that your key has API access and rerun
  `bash install.sh` with a working key.
- **ADB disconnected:** reconnect Wireless debugging and run `adb devices`.
- **Voice command fails:** install the Termux:API Android app and run
  `pkg install termux-api`. Speech quality/language support depends on the
  speech service and its language settings.
- **Widget missing:** install Termux:Widget and refresh the home-screen widget.
- **Permission denied:** run `chmod 700 install.sh phone` and retry.

## License

MIT
# Google-Gemini-assistant-for-controlling-phone
