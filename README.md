# movieradar

## Android release signing

To install as an update (instead of uninstalling), the APK must be signed with the same keystore as the currently installed app.

1. Copy `android/key.properties.example` to `android/key.properties`.
2. Fill in the keystore values in `android/key.properties`.
3. Build with `flutter build apk --release`.

If `android/key.properties` is missing, release builds fall back to debug signing.

