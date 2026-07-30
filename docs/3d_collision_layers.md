# 3D Çarpışma Katmanları

Merkezi sabitler:
`res://scripts/3d/systems/collision_layers_3d.gd`.
İsimler ayrıca `project.godot` içindeki `layer_names` bölümüne kaydedilmiştir.

| Katman | Bit | Sahipleri | Sorgulayan |
|---|---:|---|---|
| Road | 1 | Yol segmenti `StaticBody3D` düğümleri | Geçersiz ghost yüzey ray'i |
| Buildable | 2 | Dört `BuildPad3D` | Yerleştirme doğrulama ray'i |
| Environment | 4 | Build edilemeyen arazi | Geçersiz ghost yüzey ray'i |
| Castle | 8 | Kale `StaticBody3D` | Geçersiz ghost yüzey ray'i |
| Enemy | 16 | Düşman `HitArea` | Kule `RangeArea` maskesi |
| Tower | 32 | Kule `SelectionArea` | Gelecekte kule seçimi/yükseltme |

Yerleştirme onayı maskesi yalnızca `Buildable` (`2`) değeridir. Böylece
yol, arazi, kale, düşman veya kule broad-mask ile yanlışlıkla geçerli
konuma dönüşmez. Dolu pad ve yetersiz altın ayrıca alan mantığı katmanında
reddedilir.
