# 3D Placeholder Değiştirme Kontrol Listesi

Art bible ve gerçek 3D model paketi mevcut olmadığı için aşağıdaki yollar
primitive placeholder içerir. Oynanış kökü ve `ModelRoot` korunmalı; yalnızca
`ReplaceableVisual_*` içeriği değiştirilmelidir.

| Placeholder yolu | Hedef varlık | Pivot | Geçici ölçek | Animasyon | Materyal kancası | Bağlantı noktası |
|---|---|---|---|---|---|---|
| `CastleTarget/ModelRoot/ReplaceableVisual_Castle` | Fortress/castle `.glb` | Zemin merkezi, rota varışına bakan ileri eksen | Yaklaşık 6,5 × 5 × 5 m hacim | İsteğe bağlı `Damaged`, `Critical`, `Defeat` | Healthy, Damaged, Critical | Rota varış noktası; gelecekte VFX marker |
| `Enemy3D/ModelRoot/ReplaceableVisual_NormalEnemy` | Normal düşman `.glb` | Ayak tabanı merkezde | Yaklaşık 1,8 m yükseklik | `Idle`, `Walk`, `Hit`, `Death` | Hit-flash ile beyaza karışabilen gövde materyalleri | `HitArea` gameplay kökünde kalır |
| `ArcherTower3D/ModelRoot/ReplaceableVisual_ArcherTower` | Okçu Kulesi `.glb` | Taban merkezi | 2–3 m footprint | `Idle`, `Fire` isteğe bağlı | Taş taban, yeşil/teal çatı vurgu | `RotatingHead` ve onun altındaki `FirePoint` korunmalı |
| `ArrowProjectile3D/ModelRoot/ReplaceableVisual_Arrow` | Ok `.glb` | Şaft merkezi; uç yerel `-Z` yönünde | Kameradan okunur, yaklaşık 0,85 m | Yok | Şaft ve metal uç | Gameplay transformu `FirePoint`ten gelir |
| `BuildPad_*/ModelRoot/ReplaceableVisual_BuildPad` | Build pad `.glb` | Üst yüzey merkezi | 3,3–3,7 m çap | Yok | Boş, geçerli, geçersiz, dolu renk durumu | `BuildCost` Label3D ayrı kalır |
| `GreenValleyFortressApproach/NonBuildableTerrain/ReplaceableVisual_Terrain` | Green Valley terrain `.glb` | Harita merkezi | 34 × 48 m provisional | Yok | Çim/toprak low-poly paleti | Road ve BuildPad collision düğümleri ayrı kalır |
| `EnvironmentProps/ReplaceableVisual_TerrainVariation` | Tepe seti `.glb` | Her prop ayak/zemin merkezi | Harita kadrajına göre | Yok | Açık/koyu yeşil varyasyon | Collision gerekiyorsa Environment katmanı |
| `EnvironmentProps/PlaceholderTree_*` | Ağaç seti `.glb` | Gövde tabanı | 3–5 m | Hafif sway isteğe bağlı | Gövde ve yaprak | Environment katmanı |
| `EnvironmentProps/PlaceholderRock_*` | Kaya seti `.glb` | Alt merkez | 0,7–1,5 m | Yok | Mat low-poly kaya | Environment katmanı |

İçe aktarma kontrolü:

- `.glb` hiyerarşisini doğrudan düzenlemek yerine inherited/wrapper sahne kullan.
- Model dönüşümünü gameplay köküne dağıtma; görsel wrapper altında düzelt.
- Kulede taban sabit kalırken yalnızca `RotatingHead` hedefe dönmeli.
- Ok ucunun yerel `-Z` yönü ile projectile hareket yönü eşleşmeli.
- Düşman materyalleri hit-flash sonrası özgün renklerine dönebilmeli.
- Nihai kamera, renk, oran ve materyaller art bible teslim edilmeden onaylanmış
  kabul edilmemeli.
