# Cihaz Oranı ve Safe-Area Test Matrisi

Release sahnelerinde debug overlay yoktur. Godot editöründeki pencere boyutu
override edilerek veya gerçek cihaz/simülatör kullanılarak şu çözünürlükler
kontrol edilmelidir:

| Boyut | Hedef |
|---|---|
| 1080×1920 | Temel 9:16 portre |
| 720×1280 | Küçük 9:16 |
| 1170×2532 | iPhone benzeri |
| 1290×2796 | Büyük iPhone benzeri |
| 1536×2048 | iPad 4:3 |
| 2048×2732 | iPad Pro 4:3 |

Her boyutta:

- [ ] HUD çentik/Dynamic Island altında kalmıyor
- [ ] Alt düğmeler home indicator üzerine gelmiyor
- [ ] Kule seçim, yükseltme, pause ve game-over panelleri taşmıyor
- [ ] Oyun dünyasında siyah veya boş şerit oluşmuyor
- [ ] Mouse/dokunma koordinatları BuildSpot ile eşleşiyor
- [ ] Bölüm seçimi kaydırılabiliyor
- [ ] Bütün eylem düğmeleri erişilebilir

Headless test fallback safe rect ve panel sınırlarını doğrular; çentik ve home
indicator davranışı fiziksel iPhone/iPad veya güncel iOS simülatöründe görsel
olarak ayrıca test edilmelidir.
