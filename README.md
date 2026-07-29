# Archer Tower Defense Starter


## Özellikler

- Okçu otomatik olarak en yakın düşmana ateş eder.
- Öldürülen düşmanlar altın verir.
- Dört inşa noktasından Okçu veya Arbalet Kulesi seçilebilir.
- Merkezi ekonomi yöneticisi güvenli altın kazanma ve harcama sağlar.
- Normal, hızlı ve boss düşmanlar veri odaklı istatistikler kullanır.
- İlk beş dalga açık kompozisyonlarla, sonraki dalgalar kontrollü formülle ilerler.
- Her 5. dalgada tek boss çıkar.
- Kale canı sıfıra düşünce oyun biter.
- Mouse ve dokunmatik giriş desteklenir.
- Harici görsel veya ses dosyası gerekmez.
- Hasar, ölüm, kule kurma, geri tepme ve altın geri bildirimleri hafif Tween'ler kullanır.
- HUD ve seçim paneli anchor/container tabanlı mobil güvenli kenar boşluklarına sahiptir.
- Kule tabanı sabit kalır; yalnızca `TurretHead` ve altındaki `Muzzle` hedefe döner.
- Kule değerleri `TowerData`, HUD `UIController`, inşa akışı `TowerBuildManager` tarafından yönetilir.
- Gerçek cihaz güvenli alanı `SafeAreaHelper` üzerinden merkezi olarak uygulanır.

## Çalıştırma

1. Godot 4.7.1 veya daha yeni uyumlu bir Godot 4 sürümü kur.
2. Godot Project Manager içinde **Import** seç.
3. Bu klasördeki `project.godot` dosyasını göster.
4. Projeyi açıp sağ üstteki **Run Project** düğmesine bas veya `F6/F5` kullan.

## VS Code ile açma

VS Code Extensions bölümünde `Godot Tools` eklentisini kur:

```text
geequlim.godot-tools
```

Godot içinde:

- Editor > Editor Settings
- Text Editor > External
- Use External Editor: Açık
- Exec Path (macOS): `/Applications/Visual Studio Code.app/Contents/MacOS/Electron`
- Exec Flags: `{project} --goto {file}:{line}:{col}`

Terminalde `code` komutu aktifse proje klasöründe:

```bash
code .
```

## Dosyalar

```text
archer_tower_defense_starter/
├── project.godot
├── main.tscn
├── README.md
└── scripts/
    ├── main.gd
    ├── enemy_data.gd
    ├── wave_manager.gd
    ├── tower_data.gd
    ├── enemy.gd
    ├── shooter.gd
    ├── arrow.gd
    ├── base.gd
    ├── economy_manager.gd
    ├── visual_effect.gd
    ├── safe_area_helper.gd
    ├── ui_controller.gd
    ├── tower_build_manager.gd
    └── tower_selection_panel.gd
```

## Otomatik testler

```bash
"/Applications/Godot.app/Contents/MacOS/Godot" \
  --headless \
  --audio-driver Dummy \
  --display-driver headless \
  --rendering-driver dummy \
  --log-file "/private/tmp/archer_stage4_test.log" \
  --path "/path/to/archer_tower_defense_starter" \
  --script "res://tests/stage4_runtime_test.gd"
```

AŞAMA 5 görsel/runtime kontrolü için aynı komutta test yolunu
`res://tests/stage5_runtime_test.gd` olarak değiştir.

Mimari ve mobil uyumluluk regresyonu için test yolu:

```text
res://tests/refactor_runtime_test.gd
```

## Not

Kingshot adı, karakterleri, görselleri, sesleri, arayüzü ve bölüm tasarımları kullanılmamalıdır. Bu proje yalnızca genel okçu ve kule savunması mekaniklerini örnekleyen özgün bir başlangıç prototipidir.
