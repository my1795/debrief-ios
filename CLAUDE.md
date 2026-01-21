# Debrief iOS Project - Development Guide

## Versioning (agvtool)

Bu proje `apple-generic` versioning system kullanıyor.

### Komutlar

```bash
# Mevcut versiyonu gör
agvtool what-version
agvtool what-marketing-version

# Build number artır (her TestFlight upload öncesi)
agvtool next-version -all

# Marketing version değiştir (major/minor release için)
agvtool new-marketing-version 1.2.0
```

### Ne Zaman Kullanılır

| Durum | Komut |
|-------|-------|
| Stage/TestFlight build | `agvtool next-version -all` |
| Production release | `agvtool new-marketing-version X.Y.0` |
| Hotfix | `agvtool new-marketing-version X.Y.Z` |

---

## Build Configurations

| Config | Bundle ID | Environment | Firebase |
|--------|-----------|-------------|----------|
| Debug | `com.musoft.debrief.stage` | local | GoogleService-Dev |
| Stage | `com.musoft.debrief.stage` | stage | GoogleService-Dev |
| Release | `com.musoft.debrief` | production | GoogleService-Prod |

---

## API URLs

- **Local**: `http://localhost:8080/v1`
- **Stage**: `https://debrief-service-306744525686.us-central1.run.app/v1`
- **Production**: `https://debrief-service-109210365587.us-central1.run.app/v1`

---

## TestFlight Release Checklist

1. `agvtool next-version -all` (build number artır)
2. Xcode'da **Product → Archive**
3. **Distribute App → App Store Connect**
4. TestFlight'ta test et

## Production Release Checklist

1. `agvtool new-marketing-version X.Y.0` (versiyon güncelle)
2. `agvtool next-version -all` (build number artır)
3. Xcode'da scheme'i **Release** yap
4. **Product → Archive**
5. App Store Connect'e gönder
