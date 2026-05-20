---
date: 2026-05-20
project: OpenFlow
topics: [electron, python, faster-whisper, voice-dictation, windows-paste, scintilla, notepad++, powershell]
---

# Session Summary

## What We Did
- Cloné et configuré OpenFlow depuis GitHub (Electron + Python + Faster-Whisper)
- Installé Python 3.12 via winget (Python 3.14 incompatible avec numpy 2.3.0)
- Configuré le venv, installé toutes les dépendances, copié .env
- Diagnostiqué le problème de raccourci : l'app n'a pas de bouton UI, seulement Ctrl+Windows
- Diagnostiqué et résolu le problème de non-détection vocale (VAD webrtcvad fonctionnel)
- Changé le raccourci de Ctrl+Windows → Ctrl+F9 (touche Windows cause des problèmes de focus Windows)
- Ajouté le support des touches F1-F12 dans hotkey_listener.py
- Capturé le HWND cible au moment de `hotkey-released` (Python ctypes) pour garantir la bonne fenêtre cible même après switch d'app
- Résolu le problème de paste dans Notepad++ via WM_PASTE direct sur Scintilla
- Laissé le texte transcrit dans le presse-papier après paste

## Decisions Made
- **Ctrl+F9 comme raccourci** : évite les problèmes de focus liés à la touche Windows
- **WM_PASTE pour Scintilla** : Notepad++ filtre les événements clavier (SendInput/SendKeys bloqués par Scintilla), WM_PASTE passe par le WndProc directement
- **Pas de restauration clipboard** : le texte transcrit reste disponible pour Ctrl+V manuel
- **HWND capturé dans Python au release** : le timing est critique — 3+ secondes de transcription peuvent changer le focus

## Key Learnings
- Notepad++ (Scintilla) bloque SendInput et SendKeys mais répond à WM_PASTE via SendMessage
- `AttachThreadInput + SetForegroundWindow` casse le paste dans tous les cas — à éviter
- `ForceFocus` custom via P/Invoke est moins fiable que `SendKeys.SendWait` natif
- WM_PASTE retourne toujours IntPtr.Zero (0) même en cas de succès — ne pas utiliser la valeur de retour comme indicateur d'échec
- `ctrl+shift+space` déclenche le mode hands-free (espace dans le combo = hands-free automatique)
- Python 3.14 n'a pas de wheels pour numpy 2.3.0, nécessite la compilation — utiliser Python 3.12

## Open Threads
- Le paste automatique dans Notepad++ fonctionne via WM_PASTE mais n'a pas été testé après multiples switches d'app — à surveiller
- Aucun test sur d'autres éditeurs (VS Code, Sublime, etc.)
- Mode hands-free non testé

## Tools & Systems Touched
- C:\Projects\OpenFlow (dépôt cloné)
- python\hotkey_listener.py — ajout F1-F12 + capture HWND ctypes
- scripts\send_text.ps1 — logique WM_PASTE / SendKeys selon app cible
- src\main\main.js — transmission HWND, lastTargetHwnd
- .env — raccourci Ctrl+F9, langues fr+en
