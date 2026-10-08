# Aplikasi Enkripsi dan Dekripsi (Ruby + Sinatra)

Ini versi Ruby dari aplikasi enkripsi dan dekripsi untuk UTS Kriptografi (Bonus 2).
Tampilan webnya sama dengan versi Python (Flask). Yang berbeda hanya bagian belakangnya (backend), yang ditulis ulang dengan bahasa Ruby.

## Cipher yang tersedia
1. Vigenere Standard (26 huruf)
2. Auto-Key Vigenere (26 huruf)
3. Extended Vigenere (256 karakter ASCII)
4. Playfair (26 huruf)
5. Affine (26 huruf)
6. Hill (26 huruf)
7. Enigma (bonus 1)
8. Super Enkripsi (Extended Vigenere + transposisi kolom)

Semua cipher bisa dipakai untuk **teks** maupun **file apa saja** (gambar, database, audio, video, dokumen).

## Persiapan: memasang Ruby (Windows)
1. Unduh **Ruby+Devkit 3.4 (x64)** dari https://rubyinstaller.org/downloads/
2. Jalankan file yang diunduh. Pilih **Install for me only**, biarkan **Add Ruby executables to your PATH** tercentang, lalu klik **Install**.
3. Di akhir instalasi, biarkan **Run 'ridk install'** tercentang. Pada jendela hitam yang muncul, tekan **Enter** dan tunggu sampai selesai.
4. Tutup lalu buka ulang VS Code atau terminal, kemudian cek:

        ruby -v

   Jika muncul `ruby 3.x.x`, Ruby sudah siap dipakai.

## Cara menjalankan
1. Buka terminal di folder proyek ini (folder yang berisi `app.rb` dan `Gemfile`).
2. Pasang library yang dibutuhkan:

        bundle install

3. Jalankan program:

        bundle exec ruby app.rb

4. Buka browser dan masuk ke http://localhost:4567

Untuk menghentikan program, tekan **Ctrl+C** di terminal.

Kalau tidak memakai Bundler, library bisa dipasang manual:

        gem install sinatra puma rackup matrix

lalu jalankan dengan `ruby app.rb`.

## Cara memakai
1. Pilih cipher di daftar sebelah kiri.
2. Pilih jenis input: **Teks** (ketik pesan) atau **File** (pilih file apa saja).
3. Isi **Kunci**. Contoh format kunci ada di tabel berikut.
4. Klik **Enkripsi** untuk mengacak pesan, atau **Dekripsi** untuk mengembalikannya.
5. Hasil tampil dalam kode base64. Klik **Unduh sebagai file biner** untuk menyimpan hasilnya.

Untuk mendekripsi teks, tempel hasil base64 ke kotak teks lalu klik **Dekripsi** dengan kunci yang sama.
Untuk mendekripsi file, pilih file `.dat` hasil enkripsi lalu klik **Dekripsi** dengan cipher dan kunci yang sama.

## Format kunci
| Cipher | Isi kunci | Contoh |
|---|---|---|
| Vigenere, Auto-Key, Playfair | Satu kata, hanya huruf | `SECRET` |
| Extended Vigenere | Teks bebas | `rahasia` |
| Affine | Dua angka `a,b`; a harus koprima dengan 26 | `5,8` |
| Hill | Angka-angka matriks n x n; determinannya harus koprima dengan 26 | `3 3 2 5` (matriks 2x2) |
| Enigma | 3 huruf posisi awal rotor, boleh ditambah pasangan plugboard | `ABC` atau `ABC AB CD` |
| Super Enkripsi | Teks bebas; panjang kunci menentukan jumlah kolom transposisi | `rahasia` |

## Hal yang perlu diketahui
- **File yang dienkripsi** disimpan sebagai `cipherteks.dat`. Di dalamnya sudah tersimpan nama dan ekstensi file asli, jadi saat didekripsi file kembali dengan nama aslinya (misalnya `cat.jpeg`).
- **Teks pada cipher 26 huruf**: hanya huruf A-Z yang dienkripsi. Angka, spasi, dan tanda baca dibuang.
- **File pada cipher 26 huruf**: isi file diubah menjadi huruf lebih dulu, lalu dienkripsi. Dengan begitu file apa pun bisa dipulihkan utuh. Akibatnya, ukuran file `.dat` menjadi sekitar dua kali ukuran aslinya. Untuk file besar seperti video, sebaiknya pakai Extended Vigenere atau Super Enkripsi supaya lebih cepat.
- **Playfair dan Hill**: huruf `X` bisa ditambahkan sebagai pengisi pada teks, dan di Playfair huruf J digabung dengan I. Huruf tambahan itu tetap muncul di hasil dekripsi teks.
- **Enigma**: enkripsi dan dekripsi memakai langkah yang sama, asalkan kuncinya sama.
- Kunci Extended Vigenere dan Super Enkripsi membedakan huruf besar dan kecil (`rahasia` berbeda dengan `RAHASIA`).

## Jika ada masalah
- `cannot load such file -- matrix`: jalankan program dengan `bundle exec ruby app.rb` (bukan `ruby app.rb`), dan pastikan `Gemfile` berisi `gem 'matrix'`.
- `Address already in use`: ada program lain memakai port 4567. Tutup program itu, atau jalankan `bundle exec ruby app.rb -p 4570` lalu buka `http://localhost:4570`.
- Perintah `ruby` tidak dikenali: tutup lalu buka ulang VS Code atau terminal setelah memasang Ruby.
- Ketik perintah tanpa tanda tambahan di ujungnya (misalnya `app.rb\` akan menyebabkan error).

## Struktur folder
    app.rb              server web (Sinatra)
    ciphers.rb          semua cipher
    Gemfile             daftar library
    views/index.erb     halaman web
    public/static/      tampilan (style.css) dan skrip (app.js)