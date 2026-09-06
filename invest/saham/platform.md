# Platform

## Stockbit

### Biaya Transaksi Saham

#### Komponen Utama Biaya

Stockbit menerapkan dua jenis biaya utama untuk setiap transaksi saham:

- **Fee Beli:** 0,15% dari total nilai pembelian.
- **Fee Jual:** 0,25% dari total nilai penjualan.

#### Rincian di Balik Persentase Tersebut

Angka 0,15% dan 0,25% tersebut sebenarnya adalah biaya **"all-in"** yang sudah mencakup beberapa komponen pajak dan biaya bursa berikut ini:

- **Biaya Broker:** Komisi untuk pihak Stockbit Sekuritas sebagai perantara.
- **Biaya Levy (0,043%):** Biaya jasa penggunaan fasilitas bursa yang dibayarkan ke BEI, KPEI, dan KSEI.
- **PPN Biaya Broker (10%–11%):** Pajak Pertambahan Nilai yang dikenakan hanya pada bagian komisi brokernya saja (bukan dari total nilai transaksi).
- **PPh Final (0,1%):** Hanya dikenakan saat **menjual** saham. Inilah alasan mengapa biaya jual (0,25%) lebih besar daripada biaya beli (0,15%).

#### Ilustrasi Perhitungan Biaya ("All-in")

Biaya 0,15% (beli) dan 0,25% (jual) bersifat **all-in**. Artinya, investor **tidak membayar biaya tambahan di luar persentase tersebut** — seluruh komponen pajak dan pungutan bursa sudah termasuk di dalamnya.

Contoh Pembelian Saham senilai Rp 10.000.000:

| Komponen                   | Perhitungan              | Nominal       | Keterangan                            |
| -------------------------- | ------------------------ | ------------- | ------------------------------------- |
| **Total Fee Beli (0,15%)** | `Rp 10.000.000 × 0,15%`  | **Rp 15.000** | **Total akhir yang dibayar investor** |
| Biaya Levy (0,043%)        | `Rp 10.000.000 × 0,043%` | Rp 4.300      | Disetor ke BEI, KPEI, KSEI            |
| Komisi Broker + PPN 11%    | `Rp 15.000 − Rp 4.300`   | Rp 10.700     | Porsi Stockbit & pajak komisi         |
| _— Porsi Komisi Broker_    | `Rp 10.700 ÷ 1,11`       | ± Rp 9.640    | Pendapatan bersih broker              |
| _— Porsi PPN 11%_          | `± Rp 9.640 × 11%`       | ± Rp 1.060    | Disetor oleh broker ke kas negara     |

> **Catatan:**
> Investor **tetap hanya membayar Rp 15.000**, **bukan** Rp 15.000 + PPN. PPN memang dibebankan kepada investor sebagai pengguna jasa, tetapi pemotongannya sudah otomatis tercakup di dalam total fee 0,15%.

## Kompetitor Lain (Other Apps)

Stockbit memiliki beberapa kompetitor kuat di pasar modal Indonesia yang secara umum dapat dibagi menjadi tiga kategori berdasarkan fokus pengguna dan ekosistemnya:

### 1. Kompetitor Langsung (Fokus Digital & Milenial)

Aplikasi dalam kategori ini memiliki gaya yang sangat mirip dengan Stockbit: antarmuka (_UI_) modern, proses pendaftaran 100% online, dan tanpa kewajiban minimum deposit awal.

- **Ajaib:**
  - Kompetitor terdekat Stockbit di segmen ritel pemula.
  - **Keunggulan:** Tampilan sangat simpel dan terintegrasi dengan aset kripto (Ajaib Kripto) serta reksa dana dalam satu aplikasi.
  - **Fee:** Mirip dengan Stockbit (Beli: 0,15%, Jual: 0,25%), dan persentase komisi bisa lebih murah jika volume transaksi bertambah besar (_tiering_).
- **Pluang:**
  - Aplikasi multi-aset yang menyediakan akses ke saham lokal Indonesia (IDX) bekerja sama dengan mitra sekuritas berizin OJK, melengkapi produk sebelumnya seperti saham AS (Nasdaq/NYSE), kripto, dan emas digital. Cocok bagi investor yang menginginkan satu aplikasi untuk semua instrumen.
- **Reku:**
  - Reku meluncurkan fitur **Saham AS (US Stocks & ETF)** dan kripto (berizin Bappebti / mekanisme PALN), **bukan** saham lokal Indonesia (IDX). Cocok sebagai pertimbangan jika ingin diversifikasi ke bursa global.
- **SimInvest (Sinarmas Sekuritas):** _(Alternatif Saham IDX)_
  - Platform digital murni saham Indonesia dari Sinarmas Sekuritas yang menyasar pemula/milenial tanpa minimum deposit dan dilengkapi sistem poin loyalitas (StarPoin).

### 2. Kompetitor Tradisional (Pemain Besar / Institusi)

Perusahaan sekuritas berpengalaman (_senior_) yang memiliki basis riset mendalam, stabilitas sistem yang tinggi, dan sering menjadi pilihan utama bagi _trader_ aktif maupun institusi.

- **Mirae Asset Sekuritas (HOTS / Neo HOTS / M-STOCK):**
  - Broker dengan frekuensi dan nilai transaksi saham salah satu yang terbesar di BEI.
  - **Karakteristik:** Fitur charting, screening, dan order book sangat lengkap. Umumnya membutuhkan deposit awal (mulai dari Rp1 juta hingga Rp10 juta tergantung tipe akun) sebelum bisa mulai bertransaksi.
  - **Fee:** Beli: 0,15%, Jual: 0,25%.
- **Indo Premier Sekuritas (IPOT):**
  - Pionir reksa dana (IPOTFund) dan saham online di Indonesia.
  - **Karakteristik:** Fitur charting dan analitik sangat mendalam dan lengkap, namun bagi sebagian pemula antarmukanya terasa lebih padat dan kompleks dibanding Stockbit. Tidak ada minimum deposit awal (Rp0).
  - **Fee:** Sedikit lebih tinggi dari Stockbit, yaitu Beli: 0,19% dan Jual: 0,29% (_all-in_).

### 3. Kompetitor Milik Bank (Ekosistem Perbankan)

Pilihan ideal untuk investor yang menginginkan rasa aman dari konglomerasi perbankan besar serta integrasi langsung dengan rekening bank utama.

- **Mandiri Sekuritas (Growin' / MOST):**
  - Bagian dari Bank Mandiri. Sangat tepercaya untuk investasi jangka panjang, terhubung erat dengan ekosistem Livin' by Mandiri, serta memiliki akses pemesanan obligasi/SBN ritel yang sangat mudah.
- **BCA Sekuritas (BEST / BCAS Mobile):**
  - Terintegrasi langsung dengan ekosistem BCA; proses pembukaan akun dan pemindahan dana sangat cepat jika sudah memiliki rekening BCA.
- **BNI Sekuritas (BIONS):**
  - Platform dari BNI Sekuritas (_BNI Sekuritas Innovative Online Trading Systems_) yang menawarkan sistem trading stabil, produk multi-investasi (saham, reksa dana, SBN, EBA), dan program edukasi yang masif.
