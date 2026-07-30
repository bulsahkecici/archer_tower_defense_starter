# AŞAMA 7 Denge Özeti

| Dalga | Kompozisyon özeti | Toplam can/ödül | Boss | Önerilen savunma |
|---|---|---|---|---|
| 1 | 8 normal | WaveManager tarafından hesaplanır | Yok | 1–2 Okçu |
| 5 | 8 normal, 4 hızlı, 1 boss | `get_wave_balance(5)` | Taş Yürekli Dev | Okçu + Arbalet |
| 10 | Normal, hızlı, zırhlı, sürü, boss | `get_wave_balance(10)` | Güçlendirilmiş boss | Arbalet + Buz + Bomba |
| 15 | Artan karma grup ve boss | `get_wave_balance(15)` | Güçlendirilmiş boss | Yükseltilmiş karma savunma |
| 20 | Yoğun karma grup ve boss | `get_wave_balance(20)` | Güçlendirilmiş boss | Dört kule türü + Ok Yağmuru |

Kesin düşman sayıları, toplam can ve potansiyel ödül tek kaynak olarak
`WaveManager.get_wave_composition()` ve `get_wave_balance()` tarafından üretilir.
