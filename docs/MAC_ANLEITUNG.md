# iPhone-App auf dem Mac bauen (Schritt für Schritt)

iOS-Apps lassen sich **nur auf einem Mac mit Xcode** kompilieren – Apple erlaubt das nicht unter Linux/Windows.
Das ZIP aus dem App Studio („🍏 iOS-Projekt“) enthält schon alles: Bundle-ID, App-Name, App-Icon, Kamera-Text.

## 1. Einmalig: Werkzeuge installieren (ca. 1 Stunde, meist Download)
1. **Xcode** aus dem Mac App Store installieren, einmal öffnen und die Zusatzkomponenten installieren lassen.
2. Terminal öffnen und eingeben:
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   xcodebuild -downloadPlatform iOS      # iOS-Simulator/Plattform
   ```
3. **Homebrew** (falls nicht vorhanden): Befehl von https://brew.sh kopieren und ausführen.
4. **Flutter + CocoaPods**:
   ```bash
   brew install --cask flutter
   brew install cocoapods
   flutter doctor          # alles bei „Xcode“ sollte grün sein
   ```

## 2. Projekt vorbereiten
```bash
cd ~/Downloads
unzip backstube-demo-ios-2.0.zip      # Name je nach App
cd backstube-demo-ios
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace               # WICHTIG: .xcworkspace, nicht .xcodeproj
```

## 3. Signieren mit deinem persönlichen (kostenlosen) Team
1. Xcode → **Einstellungen → Accounts** → „+“ → Apple-ID anmelden.
2. Links „Runner“ anklicken → Tab **Signing & Capabilities** → Target **Runner**.
3. Haken bei **Automatically manage signing**, bei **Team** „Dein Name (Personal Team)“ wählen.
4. Fehler „Bundle Identifier nicht verfügbar“? Dann die Bundle-ID leicht ändern,
   z. B. `de.example.loyalty.backstube.ios` (oder im App Studio das Feld „iOS Bundle-ID“ setzen und neu exportieren).

## 4. Aufs iPhone spielen
1. iPhone per Kabel anschließen, entsperren, „Diesem Computer vertrauen“.
2. Auf dem iPhone: **Einstellungen → Datenschutz & Sicherheit → Entwicklermodus** einschalten (Neustart).
3. Oben in Xcode dein iPhone als Ziel wählen → ▶︎ (Run). Alternativ im Terminal: `flutter run --release`.
4. Beim ersten Start: **Einstellungen → Allgemein → VPN & Geräteverwaltung** → deinem Entwickler-Profil vertrauen.

## ⚠️ Die 7-Tage-Grenze (kostenloses Personal Team)
- Mit kostenlosem Account läuft die App **nur 7 Tage**, danach startet sie nicht mehr → einfach erneut per Xcode installieren (Daten bleiben erhalten).
- Max. **3 eigene Apps** gleichzeitig pro Gerät, nur auf **deinen eigenen** Geräten, keine Weitergabe.
- Push über Apple-Server (APNs) geht nicht – die lokalen Benachrichtigungen der Demo funktionieren.
- **Für echte Kunden / App Store / TestFlight:** Apple Developer Program (99 €/Jahr). Dann Xcode → Product → **Archive** → Distribute App → App Store Connect.

## Updates
Im App Studio „Build-Nr.“ +1 (und ggf. Version) setzen → iOS-ZIP neu exportieren → Schritt 2–4 wiederholen.
