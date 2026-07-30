# 3D Dikey Kesit Geçiş Planı

## Kaynak ve sınır

Proje Godot `4.7.1` kullanıyor. Çalışan ana sahne
`res://scenes/main_menu.tscn`; mevcut 2D oyun sahnesi
`res://main.tscn`.

İstenen `design/` dizini ve `OKCULARIN_SON_KALESI_3D_ART_BIBLE`
depoda bulunamadı. Bu nedenle bu dikey kesitte nihai sanat yönü iddia
edilmiyor. Bütün 3D görseller açık isimli Godot primitive placeholder'larıdır.

Geçici ölçek sözleşmesi:

- 1 Godot birimi = 1 metre.
- Normal düşman yaklaşık 1,8 metre yüksekliğinde.
- Kule tabanı yaklaşık 2,8 metre çapında.
- Yol 3,3 metre genişliğinde.
- Ok, sabit kamera okunabilirliği için gerçek ölçüden büyük.

## Sistem sınıflandırması

| Sınıf | Sistemler |
|---|---|
| Değişmeden yeniden kullanılan | `EconomyManager`, `WaveManager`, `LevelData`, `EnemyData`, `TowerData`, `UIController`, `SettingsMenu`, `SaveManager`, `AudioManager`, `SafeAreaHelper` |
| Uyarlanarak yeniden kullanılan | `MainMenu` ve `MenuNavigation` yalnızca ayrı 3D prototip girişini açmak için genişletildi |
| 3D karşılığıyla değiştirilen | 2D `Main`, `GamePath`, `PathEnemy`, `ShooterUnit`, `ArrowProjectile`, `DefenseBase`, `TowerBuildManager` dünya temsilleri |
| Yalnızca legacy 2D | Bomba/Arbalet/Buz kulelerinin 2D temsilleri, 2D efekt ve kozmetik dünya görselleri, mevcut 2D sahneler |

Mevcut autoload'lar korunmuştur: `SaveManager`, `AudioManager`,
`AchievementManager`, `CosmeticManager`. Yeni global singleton eklenmemiştir.

## Dikey kesit mimarisi

```text
Game3D
├── WorldEnvironment
├── DirectionalLight3D
├── FixedCameraRig
│   └── Camera3D
├── EnemyRoute (Path3D)
│   └── Enemy3D...
├── TowerContainer
│   └── ArcherTower3D...
├── ProjectileContainer
│   └── ArrowProjectile3D...
├── EffectContainer
├── GreenValleyFortressApproach
│   ├── EnemyEntrance
│   ├── CastleDestination
│   ├── NonBuildableTerrain
│   ├── RoadCollisionLayer
│   ├── BuildPads
│   └── EnvironmentProps
├── CastleTarget
├── WaveManager
├── EconomyManager
├── TowerPlacement3D
└── UIController
    └── Interface (CanvasLayer)
        ├── SafeUI / HUD
        └── TowerSelectionPanel3D
```

Alan mantığı, 3D dünya temsili ve Control tabanlı UI ayrı tutulmuştur.
Kule ve düşman istatistikleri mevcut Resource sınıflarından alınır.

## Kamera ve harita

Seçim: ortografik sabit kamera.

- Konum: `(25, 34, 31)`
- Bakış hedefi: `(0, 0, -0.5)`
- Ortografik boyut: `66`
- Near / far: `0.1 / 160`
- Serbest dönüş ve zoom: kapalı

Bu seçim portre kadrajda dokuz noktalı rotanın girişini, dört build pad'i
ve kale hedefini aynı anda okunur tutmak için yapıldı.

`Green Valley Fortress Approach`, tek `Path3D` rotası kullanır. Düşman
`PathFollow3D.progress` ile hareket eder ve `progress_ratio` hedef önceliğine
açılır. Harita, ayrı yol segmentleri, arazi gövdesi, build pad'ler, ağaç,
kaya ve alçak tepe placeholder'ları içerir.

## Oynanış stratejileri

- Yerleştirme: kamera pointer/touch ray'i yalnızca Buildable katmanını
  doğrular. Road/Environment/Castle ikincil ray'i geçersiz kırmızı ghost'u
  konumlandırır. Altın tek merkezden `EconomyManager.spend_gold()` ile düşer.
- Hedefleme: her kule 0,20 saniyelik aralıkla menzil içindeki canlı düşmanları
  tarar ve en yüksek `progress_ratio` değerini seçer. Her frame global tarama
  yapılmaz.
- Kule mimarisi: ortak menzil, seçim, zamanlayıcı, hedefleme, üst bölüm dönüşü
  ve ateş akışı `Tower3D` tabanındadır. `ArcherTower3D` yalnızca model ve ok
  üretimini sağlar.
- Mermi: görünür, hafif homing ok; `FirePoint` dünya transformundan doğar,
  hedef ölürse son bilinen konuma gider, bir kez hasar verir ve üç saniye
  içinde temizlenir.
- Dalga: mevcut `WaveManager` ilk dalga verisi kullanılır; yalnızca normal
  düşman vardır. Zafer aktif düşman, üretim kuyruğu ve mermi tutarsızlığı
  kalmadığında açılır.
- Kale: sağlık değişikliği HUD'a sinyal verir; sağlıklı/hasarlı/kritik
  materyal kancaları vardır.
- Pause/settings: `SceneTree.paused` dünyadaki process ve timer'ları durdurur.
  Pause ve gömülü Settings katmanları `PROCESS_MODE_ALWAYS` ile etkileşimli
  kalır. Geri dönüş pause katmanını kapatmaz ve sahne yeniden yüklenmez.
- Ok Yağmuru: mevcut HUD/cooldown arayüzüne bağlı, en fazla altı görünür hafif
  ok üretir. Yüzlerce physics body veya ışık üretmez.

## Geçiş sırası

1. Bu ayrı sahne ve legacy 2D regresyonlarını birlikte koru.
2. Gerçek art bible teslim edildiğinde kamera, palet ve oranları onunla doğrula.
3. Placeholder modelleri wrapper/`ModelRoot` sözleşmesiyle gerçek `.glb`
   dosyalarıyla değiştir.
4. Fiziksel cihaz ve masaüstü görsel playtest yap.
5. Dikey kesit onayından sonra ek kule/düşman/haritalara geç.
