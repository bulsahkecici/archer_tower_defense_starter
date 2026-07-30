# Final Denge ve Playtest Raporu

Bu rapor mevcut `LevelData`, `WaveManager`, `EnemyData` ve build spot
maliyetlerinden hesaplanmıştır. Rastgele denge değişikliği yapılmamıştır.
Hikâye bölümlerindeki toplam can ve altın, bölümün bütün dalgaları; Sonsuz Mod
satırları ise belirtilen tek dalga içindir. “Kazanılabilir altın”, bütün
düşmanların yenildiği üst sınır senaryosudur.

| İçerik | Başlangıç altını | Ort. platform maliyeti | Tahmini altın | Toplam düşman canı | Boss canı | Düşman türleri |
|---|---:|---:|---:|---:|---:|---|
| Bölüm 1 — Yeşil Geçit | 35 | 22,5 | 911 | 8.414 | 483 | Normal, Hızlı, Zırhlı, Sürü, Boss |
| Bölüm 2 — Taş Vadi | 37 | 23,5 | 1.510 | 18.361 | 577 | Normal, Hızlı, Zırhlı, Sürü, Boss |
| Bölüm 3 — Donmuş Yol | 28 | 24,5 | 1.792 | 23.967 | 671 | Normal, Hızlı, Zırhlı, Sürü, Boss |
| Bölüm 4 — Kızıl Orman | 27 | 25,5 | 2.599 | 40.514 | 1.033 | Normal, Hızlı, Zırhlı, yoğun Sürü, Boss |
| Bölüm 5 — Son Kale | 30 | 27,5 | 3.869 | 75.575 | 1.562 | Normal, Hızlı, Zırhlı, Sürü, Boss |
| Sonsuz dalga 10 | 30 | 27,5 | 137 | 2.096 | 665 | 15 Normal, 4 Hızlı, 2 Zırhlı, 5 Sürü, 1 Boss |
| Sonsuz dalga 25 | 30 | 27,5 | 347 | 5.787 | 1.190 | 22 Normal, 8 Hızlı, 5 Zırhlı, 9 Sürü, 1 Boss |
| Sonsuz dalga 50 | 30 | 27,5 | 501 | 14.266 | 2.065 | 28 Normal, 14 Hızlı, 9 Zırhlı, 15 Sürü, 1 Boss |

## Önerilen kombinasyonlar ve zorluk noktaları

- Bölüm 1: Okçu + Arbalet. İlk iki platformu açacak 35 altın öğretici bir
  başlangıç sağlar. İlk boss, tek kuleyle girilirse ana zorluk noktasıdır.
- Bölüm 2: Arbalet + Bomba, ardından Okçu. Ek zırhlılar Arbaleti değerli kılar;
  yükselen platform maliyetleri erken yanlış yatırımın cezasını artırır.
- Bölüm 3: Buz + Bomba + Arbalet. Doğal %15 yol yavaşlatması Buz etkisiyle
  toplanmaz; doğal bölgenin dışında hızlı düşman kaçırmak ana risktir.
- Bölüm 4: Buz + Bomba alan kontrolü, yakında Okçu + Arbalet hız sinerjisi.
  Yoğun sürüler ve aynı anda gelen zırhlılar tek hedefli düzenleri zorlar.
- Bölüm 5: İki rotayı kapsayan Arbaletler, merkezde Buz/Bomba. Rota ayrımı ve
  16–20. dalgalardaki can artışı en belirgin zorluk sıçramasıdır.
- Sonsuz 10: Buz + Bomba ve en az bir Arbalet. İlk kontrollü boss eşiğidir.
- Sonsuz 25: Seviye 3 Buz menzil aurası ve iki rotayı kapsayan karışık düzen.
  Zırhlı/sürü karışımında hedefleme modlarını ayarlamak önemlidir.
- Sonsuz 50: Seviye 3 karma savunma, Okçu + Arbalet hız sinerjisi ve düzenli
  dalga ödülleri gerekir. Kompozisyon 67 düşmanda sınırlandığı için mobil node
  sayısı kontrol altında kalırken can baskısı sürer.

## Hesaplama notları

- Hikâye toplam canı, her dalganın sağlık çarpanı ile bölüm zorluk çarpanının
  EnemyData taban canına uygulanmasıyla hesaplandı.
- Boss canı, bölümde görülen en yüksek cana sahip boss dalgasını gösterir.
- Sonsuz sağlık çarpanı `min(25, 1 + (dalga - 1) × 0,10)` formülünü kullanır.
- Sonsuz kompozisyonu 28 Normal, 14 Hızlı, 10 Zırhlı ve 18 Sürü üst sınırlarına
  sahiptir; her beşinci dalgada tek boss eklenir.
- Bu hesap kontrollü veri analizi olup fiziksel cihazda oyuncu becerisi,
  hedefleme modu ve kule yerleşimiyle yapılacak manuel denge testinin yerini
  tutmaz.
