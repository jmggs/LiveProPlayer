# Live Pro Player — Mobile (Flutter)

Port completo do **Live Pro Player** desktop para **Android e iOS/iPadOS**, desenvolvido em Flutter.

---

## Funcionalidades

| Funcionalidade             | Mobile |
|----------------------------|--------|
| Play / Cue / Pause / Stop / Next | ✅ |
| Playlist reordenável       | ✅ |
| Waveform preview interativo | ✅ |
| VU meter estéreo           | ✅ |
| Countdown timers (track + playlist) | ✅ |
| Modo Single / Continue     | ✅ |
| Seek por toque na waveform | ✅ |
| Controlo HTTP remoto       | ✅ |
| Guardar/carregar playlist XML | ✅ |
| Formatos: WAV, MP3, FLAC, AIFF | ✅ |
| Background audio (lock screen) | ✅ |
| Layout adaptativo iPhone/iPad | ✅ |

---

## Estrutura do Projeto

```
lib/
├── main.dart                    # Entry point
├── app_theme.dart               # Cores e tema escuro
├── models/
│   └── track.dart               # Modelo de faixa
├── providers/
│   └── player_provider.dart     # Estado central (ChangeNotifier)
├── services/
│   ├── audio_service.dart       # just_audio wrapper
│   ├── waveform_service.dart    # Extracção de waveform + RMS
│   ├── playlist_service.dart    # Save/load XML
│   └── remote_service.dart      # Servidor HTTP (shelf)
├── screens/
│   ├── main_screen.dart         # Ecrã principal (narrow + wide)
│   └── settings_screen.dart     # Definições
└── widgets/
    ├── waveform_widget.dart      # CustomPainter waveform
    ├── vu_meter_widget.dart      # VU meter estéreo (40 segmentos)
    ├── countdown_widget.dart     # Timer com cores dinâmicas
    ├── transport_controls.dart   # CUE/PLAY/PAUSE/STOP/NEXT
    └── playlist_widget.dart      # Lista reordenável
```

---

## Requisitos

### Flutter / Dart

| Componente | Versão mínima |
|------------|---------------|
| Flutter    | 3.16.0        |
| Dart SDK   | 3.2.0         |

### Android

| Componente             | Versão                          |
|------------------------|---------------------------------|
| Android SDK (minSdk)   | 21 (Android 5.0 Lollipop)       |
| Android SDK (targetSdk)| Gerido pelo Flutter SDK          |
| NDK                    | Gerido pelo Flutter SDK          |
| Java                   | 17 (JDK 17)                     |
| Gradle                 | 8.11.1                          |
| Kotlin Gradle Plugin   | 2.2.20                          |
| Android Studio / CLI   | qualquer versão recente          |

### iOS

| Componente | Versão mínima |
|------------|---------------|
| iOS        | 14.0          |
| Xcode      | 15+           |
| macOS      | obrigatório para build iOS |

---

## Instalação e Setup

### 1. Instalar Flutter

Segue a documentação oficial: https://flutter.dev/docs/get-started/install

### 2. Instalar dependências

```bash
cd live_pro_player
flutter pub get
```

### 3. Verificar ambiente

```bash
flutter doctor -v
```

Garante que Android toolchain, Java 17 e (se necessário) Xcode aparecem sem erros.

---

## Executar em desenvolvimento

### Android (via USB ou emulador)

```bash
flutter run -d android
```

Para escolher um dispositivo específico:

```bash
flutter devices              # listar dispositivos disponíveis
flutter run -d <device_id>
```

### iPhone/iPad (via USB — requer Mac + Xcode)

```bash
flutter run -d ios
```

---

## Build Android

### Pré-requisitos de ambiente

1. **JDK 17** instalado e `JAVA_HOME` configurado
2. **Android SDK** instalado (via Android Studio ou `sdkmanager`)
3. Caminho do SDK definido em `android/local.properties`:

```properties
sdk.dir=/caminho/para/Android/Sdk
flutter.sdk=/caminho/para/flutter
```

---

### APK universal (debug)

Útil para testes rápidos. Não requer assinatura.

```bash
flutter build apk --debug
# output: build/app/outputs/flutter-apk/app-debug.apk
```

---

### APK universal (release)

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

---

### APK separados por ABI (release)

Gera APKs menores, um por arquitectura. Recomendado para distribuição directa (sideload).

```bash
flutter build apk --release --split-per-abi
# outputs:
#   build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk   (ARM 32-bit)
#   build/app/outputs/flutter-apk/app-arm64-v8a-release.apk     (ARM 64-bit)
#   build/app/outputs/flutter-apk/app-x86_64-release.apk        (x86_64 emulator)
```

---

### App Bundle (AAB) para Google Play

Formato preferido pelo Google Play. Permite entrega optimizada por dispositivo.

```bash
flutter build appbundle --release
# output: build/app/outputs/bundle/release/app-release.aab
```

---

### Build com verbose (diagnóstico)

```bash
flutter build apk --release --verbose
```

---

### Configuração de assinatura (Keystore) para release

Por omissão, o release usa a chave de debug (apenas para desenvolvimento). **Para distribuição em produção**, é necessário configurar uma keystore própria.

#### Passo 1 — Criar keystore (uma única vez)

```bash
keytool -genkey -v \
  -keystore ~/live_pro_player_key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias live_pro_player
```

Guarda o ficheiro `.jks` num local seguro **fora** do repositório.

#### Passo 2 — Criar ficheiro de credenciais

Cria `android/key.properties` (não adicionar ao git):

```properties
storePassword=<password da keystore>
keyPassword=<password da chave>
keyAlias=live_pro_player
storeFile=/caminho/absoluto/para/live_pro_player_key.jks
```

Adiciona ao `.gitignore`:

```
android/key.properties
*.jks
```

#### Passo 3 — Configurar `android/app/build.gradle.kts`

Substitui o bloco `android { ... }` com a configuração de assinatura:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    // ... configuração existente ...

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
            storeFile = keyProperties["storeFile"]?.let { file(it as String) }
            storePassword = keyProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

---

### Verificar assinatura do APK

```bash
# Verificar certificado
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk

# Verificar com apksigner (Android SDK build-tools)
apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk
```

---

### Instalar APK directamente no dispositivo

```bash
# Via flutter
flutter install

# Via adb
adb install build/app/outputs/flutter-apk/app-release.apk

# Forçar reinstalação
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

### Gerar ícones Android

Os ícones são gerados a partir de `assets/icons/app_icon.png` com fundo adaptativo preto (`#000000`).

```bash
flutter pub run flutter_launcher_icons
```

Configuração em `flutter_launcher_icons.yaml`:

```yaml
flutter_launcher_icons:
  image_path: "assets/icons/app_icon.png"
  android: true
  ios: false
  min_sdk_android: 21
  adaptive_icon_background: "#000000"
  adaptive_icon_foreground: "assets/icons/app_icon.png"
```

---

### Permissões Android declaradas

Definidas em `android/app/src/main/AndroidManifest.xml`:

| Permissão | Propósito |
|-----------|-----------|
| `FOREGROUND_SERVICE` | Reprodução em background |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Serviço de media (Android 10+) |
| `READ_MEDIA_AUDIO` | Acesso a ficheiros de áudio (Android 13+) |
| `READ_EXTERNAL_STORAGE` | Acesso a ficheiros (Android ≤12) |
| `WRITE_EXTERNAL_STORAGE` | Escrita de ficheiros (Android ≤9) |
| `INTERNET` | Servidor HTTP de controlo remoto |
| `ACCESS_NETWORK_STATE` | Detecção de rede |
| `ACCESS_WIFI_STATE` | Obter IP Wi-Fi |
| `WAKE_LOCK` | Manter CPU activa durante reprodução |

---

## Build iOS — IPA para App Store / TestFlight

```bash
flutter build ios --release
# Depois abre Xcode:
open ios/Runner.xcworkspace
# Product → Archive → Distribute App
```

### Configuração iOS (Xcode)

1. Em **Signing & Capabilities**, define o teu Team e Bundle Identifier
2. Em **Deployment Info**, confirma iOS 14.0+
3. O `Info.plist` já inclui todas as permissões necessárias

---

## Controlo HTTP Remoto

Quando activado em **Settings → HTTP Remote Control**:

| Endpoint       | Acção                     |
|----------------|---------------------------|
| `GET /play`    | Iniciar reprodução        |
| `GET /pause`   | Pausar                    |
| `GET /stop`    | Parar + rebobinar         |
| `GET /cue`     | Rebobinar sem tocar       |
| `GET /next`    | Faixa seguinte            |
| `GET /previous`| Faixa anterior            |
| `GET /up`      | Selecção acima            |
| `GET /down`    | Selecção abaixo           |

**Porto por omissão**: 8000  
**Exemplo**: `http://192.168.1.42:8000/play`

> O IP do dispositivo é mostrado no ecrã de definições.

---

## Atalhos de teclado (iPad com teclado externo)

| Tecla        | Acção             |
|--------------|-------------------|
| `Space`      | Play / Pause      |
| `Enter`      | Play              |
| `C`          | Cue               |
| `N`          | Próxima faixa     |
| `↑` / `↓`   | Navegar playlist  |

---

## Cores dos contadores

| Tempo restante | Cor        |
|---------------|------------|
| > 30 segundos  | 🟢 Verde   |
| ≤ 30 segundos  | 🟡 Amarelo |
| ≤ 10 segundos  | 🔴 Vermelho |

---

## Dependências principais

| Pacote                  | Versão   | Função                            |
|-------------------------|----------|-----------------------------------|
| `just_audio`            | ^0.9.40  | Engine de reprodução de áudio     |
| `just_audio_background` | ^0.0.1-beta.17 | Background audio + lock screen |
| `just_waveform`         | ^0.0.6   | Extracção de waveform nativa      |
| `audio_session`         | ^0.1.21  | Gestão de sessão iOS              |
| `file_picker`           | ^8.0.7   | Selecção de ficheiros             |
| `shelf` + `shelf_router`| ^1.4.1   | Servidor HTTP remoto              |
| `xml`                   | ^6.5.0   | Playlists XML                     |
| `provider`              | ^6.1.2   | Gestão de estado                  |
| `shared_preferences`    | ^2.2.3   | Persistência de definições        |
| `network_info_plus`     | ^5.0.3   | Detecção de IP do dispositivo     |
| `permission_handler`    | ^11.3.1  | Permissões em runtime             |

---

## Diferenças face ao desktop

| Característica          | Desktop          | Mobile                     |
|------------------------|------------------|----------------------------|
| Selecção de interface de áudio | ✅ WASAPI/ALSA | ❌ Só áudio do sistema |
| Ficheiros locais       | Livre            | Via sistema de ficheiros do OS |
| Janela redimensionável | ✅               | Layout adaptativo automático |
| Atalhos de teclado     | Sempre disponíveis | iPad + teclado externo |

---

## Versão

`v1.8.0` — Port completo do desktop Live Pro Player
