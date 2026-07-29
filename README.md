# Archer Tower Defense Starter

Kingshot reklamlarındaki okçu + kule savunması fikrine benzeyen, ancak tamamen özgün ve dış varlık kullanmayan bir Godot 4 prototipidir.

## Özellikler

- Okçu otomatik olarak en yakın düşmana ateş eder.
- Öldürülen düşmanlar altın verir.
- Sarı halkalara tıklayarak okçu kulesi kurulur.
- Kule maliyeti her yeni kulede artar.
- Dalgalar ilerledikçe düşman canı, hızı, büyüklüğü ve hasarı artar.
- Her 5. dalgada boss çıkar.
- Kale canı sıfıra düşünce oyun biter.
- Mouse ve dokunmatik giriş desteklenir.
- Harici görsel veya ses dosyası gerekmez.

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
    ├── enemy.gd
    ├── shooter.gd
    ├── arrow.gd
    └── base.gd
```

## Geliştirme sırası

1. Ses ve vurma efektleri
2. Okçu/kule yükseltme sistemi
3. Farklı düşman tipleri
4. Kule seçim menüsü
5. Seviye haritası ve bölüm sistemi
6. Kalıcı para ve kayıt sistemi
7. Mobil arayüz
8. iOS export ve TestFlight

## Not

Kingshot adı, karakterleri, görselleri, sesleri, arayüzü ve bölüm tasarımları kullanılmamalıdır. Bu proje yalnızca genel okçu ve kule savunması mekaniklerini örnekleyen özgün bir başlangıç prototipidir.
