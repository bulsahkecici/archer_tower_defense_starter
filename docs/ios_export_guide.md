# Godot 4.7.1 iOS, Xcode ve TestFlight Rehberi

Bu rehber hazırlık içindir; Apple hesabında işlem, imzalama, archive veya
yükleme otomatik yapılmaz.

## Ön gereksinimler

1. macOS üzerinde tam Xcode’u App Store’dan kurun, bir kez açın ve lisansı kabul edin.
2. Xcode > Settings > Platforms bölümünden iOS desteğini kurun.
3. Xcode > Settings > Locations > Command Line Tools alanında kurulu Xcode’u seçin.
4. Godot > Editor > Manage Export Templates bölümünden tam olarak `4.7.1.stable` export template paketini kurun.

## Godot export

1. Project > Export ekranını açıp `iOS` presetini seçin.
2. Oyun adı, `1.0` sürümü, `1.0.0` build değeri ve portre ayarını kontrol edin.
3. `com.bulsahkecici.archertowerdefense` değerini size ait benzersiz Bundle ID ile doğrulayın/değiştirin.
4. `[APPLE TEAM ID]` yerine Apple Developer üyeliğinizdeki gerçek 10 karakterli Team ID’yi girin. Sahte değer kullanmayın.
5. Targeted Device Family’nin iPhone + iPad, minimum iOS sürümünün `14.1`, renderer’ın Compatibility ve ARM64’ün açık olduğunu kontrol edin.
6. Kamera, mikrofon, konum, kişiler, tracking, push notification ve Wi-Fi capability eklemeyin; uygulamanın davranışı değişirse izinleri ve gizlilik metnini yeniden değerlendirin.
7. Boş ve ayrı bir klasöre, boşluksuz proje adıyla Xcode projesi export edin. Preset `Export Project Only` kullanır.

## Xcode Build & Run

1. Üretilen `.xcodeproj` dosyasını Xcode’da açın.
2. Target > Signing & Capabilities altında gerçek Team’i seçin.
3. Automatically manage signing’i açın veya kuruluşunuzun onaylı manuel provisioning profilini seçin.
4. Bundle ID, Version ve Build değerlerini yeniden kontrol edin.
5. Kabloyla bağlı gerçek iPhone/iPad’i hedef seçin; güven ve Developer Mode adımlarını cihazda tamamlayın.
6. Product > Build, ardından Run ile gerçek cihaz testi yapın.
7. Portre yönü, safe-area, dokunma, pause, kayıt kalıcılığı, ikon ve splash’i hem iPhone hem iPad’de doğrulayın.

## Archive ve TestFlight

1. Release ayarını ve App Store dağıtım sertifikasını doğrulayın.
2. Generic iOS Device / Any iOS Device hedefini seçin.
3. Product > Archive çalıştırın.
4. Organizer’da Validate App ile uyarıları çözün.
5. Distribute App > App Store Connect > Upload yolunu kullanın.
6. App Store Connect’te build’in işlenmesini bekleyin.
7. TestFlight Internal Testing grubuna kullanıcı ekleyin ve dahili testi tamamlayın.
8. External Testing gerekiyorsa beta açıklaması, iletişim bilgileri ve Beta App Review alanlarını doldurun.
9. App Store submission öncesinde mağaza metinleri, ekran görüntüleri, yaş derecelendirmesi, privacy, export compliance, içerik hakları ve review notlarını son kez doğrulayın.

## Otomatik imzalama notu

Godot presetindeki Team ID ve provisioning alanlarının boş olması bilinçlidir.
Godot dokümantasyonuna göre Team ID ve Bundle ID gerçek export için zorunludur.
Gerçek değerler yalnızca hesap sahibi tarafından Godot/Xcode’da girilmelidir.
