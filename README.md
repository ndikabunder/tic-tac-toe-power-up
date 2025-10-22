# Tic-Tac-Toe Power-Up

<p align="center">
  <strong>Sebuah sentuhan strategis pada permainan Tic-Tac-Toe klasik, kini dengan <i>power-up</i>!</strong>
</p>

<p align="center">
  Tantang dirimu melawan AI atau bermain bersama teman di versi modern dari game abadi ini.
</p>

<!-- Disarankan untuk menambahkan screenshot atau GIF gameplay di sini -->
<!-- <p align="center">
  <img src="docs/gameplay.gif" alt="Gameplay Demo">
</p> -->

## 🎮 Fitur Utama

-   **Papan 5x5**: Susun 4 bidak secara berderet untuk menang.
-   **Sistem Power-Up**: Gunakan kemampuan spesial untuk mendapatkan keuntungan taktis.
-   **Resource Points (RP)**: Kumpulkan poin di setiap giliran untuk mengaktifkan power-up.
-   **Lawan AI**: Uji strategimu melawan komputer yang cerdas.
-   **Mode 2 Pemain**: Bermain bersama teman secara lokal.

## ⚙️ Instalasi & Menjalankan

1.  Unduh dan install **[Godot Engine](https://godotengine.org/)** (versi 4.x atau lebih baru).
2.  Clone atau unduh repositori ini.
3.  Buka proyek melalui Godot Engine.
4.  Jalankan game dari editor dengan menekan tombol `Run Project` (F5).

## 📋 Cara Bermain

### Tujuan Permainan
Jadilah pemain pertama yang berhasil menyusun **4 bidak** (X atau O) secara berderet, baik secara horizontal, vertikal, maupun diagonal.

### Alur Dasar
1.  Pemain bergiliran meletakkan bidak di papan 5x5.
2.  Setiap akhir giliran, kamu akan mendapatkan **1 Resource Point (RP)**.
3.  Gunakan RP yang terkumpul untuk mengaktifkan berbagai power-up.

### Sistem Power-Up
Gunakan RP untuk mengaktifkan kemampuan spesial yang dapat mengubah alur permainan.

| Power-Up | Biaya (RP) | Deskripsi |
| :--- | :--- | :--- |
| 🛡️ **Shield** | 2 | Melindungi satu petak agar tidak bisa diisi atau diubah oleh lawan. |
| 💥 **Erase** | 4 | Menghapus satu bidak milik lawan dari papan. |
| ✨ **Golden Mark** | 2 | Meletakkan bidak emas yang kebal terhadap power-up **Erase**. |
| ⏩ **Double Move** | 6 | Meletakkan dua bidak biasa dalam satu giliran. |
| 🔄 **Swap** | 4 | Menukar posisi dua bidak apa pun yang ada di papan. |

## 🔧 Kontrol

-   **Klik Kiri**: Meletakkan bidak atau memilih petak untuk target power-up.
-   **Tombol Power-Up**: Mengaktifkan kemampuan spesial.
-   **Tombol Restart**: Memulai permainan baru.

## 🎯 Tips Strategi

-   **Kelola RP dengan bijak**: Jangan terburu-buru menghabiskan RP di awal permainan.
-   **Seimbangkan**: Cari keseimbangan antara menyerang (menyusun bidak) dan menggunakan power-up.
-   **Blokir Lawan**: Gunakan power-up untuk menghalangi lawan yang hampir menang.
-   **Amankan Posisi**: Gunakan **Shield** atau **Golden Mark** untuk melindungi petak strategis.
-   **Peluang Tak Terduga**: **Swap** bisa menjadi kunci untuk membalikkan keadaan atau menciptakan kemenangan instan.

## 🛠️ Detail Teknis

-   **Engine**: Godot 4.x
-   **Bahasa**: GDScript
-   **Ukuran Papan**: 5x5
-   **Kondisi Menang**: 4 bidak berderet

## 📜 Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE).

## 👨‍💻 Kredit

Dibuat oleh **Ghibran** sebagai proyek untuk mempelajari Godot Engine.
