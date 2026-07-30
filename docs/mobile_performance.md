# Mobil Performans Profili

Mevcut hedef profil 75 eşzamanlı düşman ve çok sayıda mermi/alan etkisidir.
Runtime testleri 75 düşman ile stres geçişi, mermi temizliği, kısa ömürlü efekt
temizliği, slow süresi ve SaveManager/AudioManager’ın sessiz çalışmasını
denetler.

Uygulanan sınırlar:

- Düşman ve mermiler çözülünce `queue_free` ile temizlenir.
- Pause, victory ve game-over savaş process yükünü durdurur veya azaltır.
- Ok Yağmuru tek kullanımda en fazla 12 hedef işler.
- Bomba alan araması yalnızca vuruş anında yapılır.
- Büyük texture ve özel shader yoktur; ikon ve splash dışında görseller kodla çizilir.
- AudioManager dosya bulunmadığında oynatıcı node üretmeden sessiz çalışır.
- SaveManager yalnızca açık kaydetme/yükleme olaylarında dosya erişimi yapar.

Headless stres testi gerçek iPhone/iPad GPU, termal durum, bellek basıncı veya
FPS ölçümü yerine geçmez. Godot Profiler ve Xcode Instruments ile düşük,
orta ve yüksek donanım sınıflarında cihaz testi yayın öncesinde yapılmalıdır.
