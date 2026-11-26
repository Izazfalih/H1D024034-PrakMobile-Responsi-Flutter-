# SkyCast — Aplikasi Prakiraan Cuaca (Responsi Flutter)

Aplikasi mobile dan web berbasis **Flutter** untuk memantau informasi cuaca terkini serta prakiraan harian dari **Open-Meteo REST API**, dibangun menggunakan arsitektur **MVVM (Model-View-ViewModel)**, state management **Provider**, dan penyimpanan lokal **Hive**.

---

## Fitur Utama

1. **Home / Weather Screen (`HomeScreen`)**
   - Menampilkan nama kota yang dipilih, wilayah administratif, negara, serta zona waktu.
   - Menampilkan kondisi cuaca terkini lengkap dengan ikon adaptif, kode WMO, dan kartu gradien sesuai cuaca/siang-malam.
   - Menampilkan suhu saat ini (`current.temperature_2m`) dan suhu yang dirasakan (`current.apparent_temperature`).
   - Menampilkan metrik detail: kelembapan udara (`relative_humidity_2m`), kecepatan angin (`wind_speed_10m`), curah hujan (`precipitation`), peluang hujan hari ini, dan kode kondisi cuaca (`weather_code`).
   - Menampilkan prakiraan cuaca 7 hari ke depan (`daily`: suhu minimum, suhu maksimum, dan peluang hujan maksimum).
   - Mendukung *pull-to-refresh*, pintasan cepat kota favorit, dan peralihan mode terang/gelap (*Theme*).

2. **Search / Location Screen (`SearchScreen`)**
   - Pencarian kota secara langsung (*real-time* dengan *debounce* & *submit*) melalui **Open-Meteo Geocoding API**.
   - Menampilkan daftar hasil pencarian lengkap dengan koordinat dan zona waktu.
   - Memilih lokasi untuk langsung menampilkan informasi cuacanya di Home Screen.
   - Menyimpan lokasi ke **Favorit** dan mencatat **Riwayat Pencarian** secara otomatis di Hive.
   - Menangani seluruh kondisi state: *initial*, *loading*, *data kosong* (kota tidak ditemukan), dan *error* (beserta tombol *Coba Lagi*).

3. **Favorites Screen (`FavoritesScreen`)**
   - Mengelola daftar kota favorit yang tersimpan di penyimpanan lokal **Hive** agar tetap tersedia ketika aplikasi ditutup dan dibuka kembali.

---

## Struktur Aplikasi & Penerapan MVVM

Aplikasi memisahkan tanggung jawab kode secara tegas mengikuti pola **Model-View-ViewModel (MVVM)**:

```text
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart          # Endpoint Open-Meteo, query params, nama box Hive
│   ├── theme/
│   │   └── app_theme.dart              # Material 3 ThemeData (Light/Dark) & Typography
│   └── utils/
│       └── weather_code_helper.dart    # Pemetaan kode WMO ke label, ikon, gradien, & format tanggal
├── models/
│   ├── location_adapter.dart           # TypeAdapter biner Hive (typeId: 0) untuk LocationModel
│   ├── location_model.dart             # Model lokasi dari Geocoding API & penyimpanan lokal
│   └── weather_model.dart              # Model CurrentWeather, DailyForecast, & WeatherResponse
├── services/
│   ├── local_storage_service.dart      # Operasi Hive (favorit, riwayat pencarian, lokasi terakhir, tema)
│   └── weather_api_service.dart        # HTTP GET ke Open-Meteo Forecast & Geocoding API
├── viewmodels/
│   ├── location_viewmodel.dart         # ChangeNotifier untuk pencarian kota, riwayat, & favorit
│   ├── view_state.dart                 # Enum status UI (initial, loading, loaded, empty, error)
│   └── weather_viewmodel.dart          # ChangeNotifier untuk state cuaca terkini & tema
├── views/
│   ├── screens/
│   │   ├── favorites_screen.dart       # Screen daftar lokasi favorit tersimpan
│   │   ├── home_screen.dart            # Screen 1: Home / Weather Screen
│   │   ├── main_shell_screen.dart      # Navigasi responsif (NavigationBar & NavigationRail)
│   │   └── search_screen.dart          # Screen 2: Search / Location Screen (StatefulWidget)
│   └── widgets/
│       ├── current_weather_card.dart   # Kartu hero cuaca terkini
│       ├── daily_forecast_list.dart    # Daftar prakiraan cuaca 7 hari ke depan
│       ├── location_tile.dart          # Komponen baris lokasi (pencarian, riwayat, favorit)
│       ├── state_feedback_widget.dart  # Komponen reusable untuk state loading, empty, & error
│       └── weather_metrics_grid.dart   # Grid responsif detail metrik cuaca
└── main.dart                           # Inisialisasi Hive, MultiProvider, dan MaterialApp
```

### Alur Data MVVM
1. **View (`views/`)**: Widget `StatelessWidget` dan `StatefulWidget` hanya bertugas merender UI berdasarkan state yang dipancarkan ViewModel melalui `Provider` (`context.watch` / `Consumer`) serta meneruskan aksi pengguna ke ViewModel (`context.read`).
2. **ViewModel (`viewmodels/`)**: Kelas turunan `ChangeNotifier` (`WeatherViewModel`, `LocationViewModel`) mengatur logika bisnis, memanggil `Service`, memperbarui `ViewState` (`loading`, `loaded`, `empty`, `error`), dan memanggil `notifyListeners()`.
3. **Model & Service (`models/`, `services/`)**: `WeatherApiService` melakukan HTTP `GET` dan mengubah respons JSON Open-Meteo menjadi model Dart (`WeatherResponse`, `LocationModel`), sementara `LocalStorageService` menyimpan serta membaca `LocationModel` menggunakan **Hive**.

---

## Implementasi API Open-Meteo

Aplikasi menggunakan dua endpoint resmi Open-Meteo melalui HTTP `GET` (`package:http`):

1. **Geocoding API**
   - Endpoint: `https://geocoding-api.open-meteo.com/v1/search`
   - Parameter: `name`, `count=12`, `language=id`, `format=json`
2. **Weather Forecast API**
   - Endpoint: `https://api.open-meteo.com/v1/forecast`
   - Parameter:
     - `latitude` & `longitude`: Koordinat kota terpilih
     - `current`: `temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,is_day`
     - `daily`: `weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max`
     - `timezone`: `auto`
     - `forecast_days`: `7`

### Pemetaan Field API ke UI
| Informasi Cuaca | Field Open-Meteo API | Lokasi Tampilan |
| :--- | :--- | :--- |
| Suhu saat ini | `current.temperature_2m` | Kartu Utama (`HomeScreen`) |
| Kelembapan udara | `current.relative_humidity_2m` | Grid Detail Cuaca |
| Suhu yang dirasakan | `current.apparent_temperature` | Kartu Utama & Grid Detail |
| Curah hujan | `current.precipitation` | Grid Detail Cuaca |
| Kode kondisi cuaca | `current.weather_code` | Badge WMO & Grid Detail |
| Kecepatan angin | `current.wind_speed_10m` | Grid Detail Cuaca |
| Suhu maksimum harian | `daily.temperature_2m_max` | Prakiraan 7 Hari |
| Suhu minimum harian | `daily.temperature_2m_min` | Prakiraan 7 Hari |
| Peluang hujan maksimum | `daily.precipitation_probability_max` | Prakiraan 7 Hari & Grid Detail |

---

## Cara Menjalankan Aplikasi

1. **Masuk ke direktori proyek dan pasang dependensi:**
   ```bash
   cd WeatherApp
   flutter pub get
   ```

2. **Jalankan analisis kode & unit/widget test:**
   ```bash
   flutter analyze
   flutter test
   ```

3. **Jalankan aplikasi (Android / iOS / Web Chrome):**
   ```bash
   # Menjalankan di Chrome
   flutter run -d chrome

   # Atau di emulator/perangkat Android/iOS yang terhubung
   flutter run
   ```

---

## Hasil Pengujian

Pengujian otomatis (`flutter test`) mencakup:
- **Parsing JSON Model**: Memverifikasi konversi respons `current`, `daily`, dan hasil pencarian Geocoding ke model Dart termasuk field opsional/nullable.
- **HTTP GET Service**: Memverifikasi parameter query Open-Meteo, penanganan hasil pencarian kosong, dan error status HTTP.
- **Persistensi Hive**: Memverifikasi penyimpanan dan pembacaan ulang data lokasi favorit, riwayat pencarian, lokasi aktif, dan preferensi tema setelah box ditutup dan dibuka kembali.
- **ViewModel & Widget Flow**: Memverifikasi alur `HomeScreen`, pencarian kota di `SearchScreen`, penyimpanan favorit, dan perubahan cuaca kota terpilih.

---

## Screenshot Aplikasi

> *Tambahkan screenshot aplikasi pada tabel di bawah ini sebelum pengumpulan final:*

| Home / Weather Screen | Search / Location Screen | Favorites Screen |
| :---: | :---: | :---: |
| *(Screenshot Home Screen)* | *(Screenshot Search Screen)* | *(Screenshot Favorites Screen)* |

## Video Penjelasan Kode
- Tautan Video: *(Tambahkan tautan video penjelasan kode)*
