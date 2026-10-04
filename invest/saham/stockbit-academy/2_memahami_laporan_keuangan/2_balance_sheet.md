# Balance Sheet (Neraca Keuangan)

Sumber: [Stockbit Academy - Balance Sheet](https://stockbit.com/academy/modules/2/chapters/10)

---

## 1. Neraca Keuangan (_Balance Sheet_)

### Apa Itu Balance Sheet?

Laporan Posisi Keuangan (_Balance Sheet_) adalah laporan yang memotret kondisi kekayaan, kewajiban, dan permodalan perusahaan pada tanggal penutupan buku.

### Persamaan Dasar Akuntansi

$$
\text{Aset} = \text{Liabilitas} + \text{Ekuitas}
$$

![aset.jpg](attachments/aset.jpg)

- **Aset:** Seluruh kekayaan dan sumber daya ekonomi yang dimiliki dan dikuasai perusahaan.
- **Liabilitas:** Kewajiban atau utang perusahaan kepada pihak ketiga untuk mendanai operasional/ekspansi.
- **Ekuitas:** Modal bersih milik pemegang saham/pendiri perusahaan.

> **Contoh Ilustrasi (Stockbit Chickz):**  
> Pak Agus dan Pak Budi berencana mendirikan usaha ayam goreng bernama _Stockbit Chickz_ dengan kebutuhan modal awal sebesar **Rp12 miliar**.
>
> 1. Pak Agus dan Pak Budi masing-masing mengumpulkan modal Rp5 miliar $\rightarrow$ **Ekuitas = Rp10 miliar**.
> 2. Karena masih kurang Rp2 miliar, mereka meminjam dana ke bank $\rightarrow$ **Liabilitas = Rp2 miliar**.
> 3. Dana yang terkumpul disimpan dalam bentuk kas perusahaan $\rightarrow$ **Total Aset = Rp12 miliar**.
>
> Pembuktian:  
> $\text{Aset (Rp12 Miliar)} = \text{Liabilitas (Rp2 Miliar)} + \text{Ekuitas (Rp10 Miliar)}$

---

## 2. Klasifikasi dan Komponen Aset

**Aset** adalah seluruh sumber daya fisik maupun non-fisik yang bernilai ekonomis dan digunakan untuk menunjang kegiatan operasional perusahaan.

Aset dikelompokkan ke dalam 2 kategori utama:

```mermaid
flowchart LR
    TotalAset["Total Aset"] --> Lancar["Aset Lancar"]
    TotalAset --> TakLancar["Aset Tidak Lancar"]

    Lancar --> Kas["Kas dan Setara Kas"]
    Lancar --> Stok["Persediaan (Stok)"]
    Lancar --> AR["Piutang Dagang (AR)"]
    Lancar --> Prepaid["Beban Dibayar di Muka (Prepaid Expense)"]

    TakLancar --> PPE["Aset Tetap (PPE & Depresiasi)"]
    TakLancar --> Intangible["Aset Tidak Berwujud (Intangible & Amortisasi)"]
    TakLancar --> Goodwill["Goodwill"]
    TakLancar --> Investasi["Investasi Jangka Panjang"]
```

![aset_2.jpg](attachments/aset_2.jpg)

### A. Aset Lancar (_Current Assets_)

![aset_lancar.jpg](attachments/aset_lancar.jpg)

Aset yang likuid dan mudah dicairkan menjadi uang tunai dalam jangka waktu **kurang dari 1 tahun**:

1. **Kas dan Setara Kas (_Cash and Cash Equivalents_):**

   - _Kas:_ Uang tunai yang tersimpan di kasir toko, kantor, maupun saldo rekening bank.
   - _Setara Kas:_ Aset finansial yang sangat likuid dan berjangka pendek (jatuh tempo 3, 6, atau 9 bulan; < 1 tahun), seperti cek, giro, dan deposito jangka pendek.

1. **Persediaan / Stok (_Inventory_):**

   - Segala bahan mentah, barang dalam proses, atau produk jadi yang dibutuhkan untuk memproduksi barang jualan (pada _Stockbit Chickz_: ayam mentah, minyak goreng, kemasan).

1. **Piutang Dagang (_Accounts Receivable / AR_):**

   - Hak tagih perusahaan kepada pihak ketiga/pelanggan atas penjualan barang atau jasa yang belum dilunasi. Umumnya jatuh tempo dan tertagih dalam hitungan minggu hingga bulan (< 1 tahun).

1. **Beban Dibayar di Muka (_Prepaid Expense_):**

   - Biaya yang telah dibayarkan di awal sebelum barang/jasa dinikmati (contoh: biaya sewa ruko tahunan yang dibayar di muka setiap 1 Januari untuk masa sewa satu tahun berjalan).

---

### B. Aset Tidak Lancar (_Non-Current Assets_)

![aset_tidak_lancar.jpg](attachments/aset_tidak_lancar.jpg)

Aset yang memiliki masa manfaat **lebih dari 1 tahun** dan relatif membutuhkan waktu lama untuk dikonversi menjadi kas:

1. **Aset Tetap (_Property, Plant, and Equipment / PPE_):**

   - Aset berwujud fisik yang menunjang operasional jangka panjang (contoh: tanah, gedung, pabrik, mesin produksi, kendaraan, dan peralatan kerja).
   - **Beban Depresiasi (Penyusutan):** Pengurangan nilai tercatat aset tetap secara berkala sesuai masa manfaatnya:

     $$
     \text{Beban Depresiasi per Tahun} = \frac{\text{Harga Beli}}{\text{Masa Manfaat (Tahun)}}
     $$

     _Contoh Kasus:_  
     Stockbit Chickz membeli _kitchen set_ seharga **Rp1 miliar** dengan masa manfaat **10 tahun**.
     - Depresiasi per tahun: $\frac{\text{Rp1.000.000.000}}{10} = \text{Rp100.000.000/tahun}$.
     - Depresiasi Rp100 juta/tahun dicatat sebagai beban operasional di _income statement_.
     - Nilai aset tetap di _balance sheet_: Tahun ke-1 = Rp1 miliar, Tahun ke-2 = Rp900 juta, Tahun ke-3 = Rp800 juta, dan seterusnya hingga habis masa manfaatnya.

     ![tabel_depresiasi.jpg](attachments/tabel_depresiasi.jpg)

1. **Aset Tidak Berwujud (_Intangible Assets_):**

   - Aset non-moneter tanpa wujud fisik yang memberi nilai ekonomis masa depan dan dapat diidentifikasi (contoh: hak paten, hak cipta, lisensi, merek dagang, dan izin konsesi tambang).
   - Penurunan nilai aset tidak berwujud disebut **Amortisasi**.

1. **Goodwill:**

   - Aset tidak berwujud yang timbul ketika perusahaan mengakuisisi perusahaan lain dengan harga di atas nilai buku (_book value_) atau nilai ekuitasnya.
   - _Contoh Kasus:_  
     Pada tahun 2014, Stockbit Chickz membeli 100% saham _Bibit Chickz_ seharga **Rp15 miliar**, sedangkan nilai ekuitas Bibit Chickz hanya **Rp12 miliar**.

     $$
     \text{Goodwill} = \text{Harga Akuisisi} - \text{Nilai Ekuitas} = \text{Rp15 Miliar} - \text{Rp12 Miliar} = \text{Rp3 Miliar}
     $$

     Selisih **Rp3 miliar** dicatat sebagai akun _Goodwill_ pada neraca Stockbit Chickz.

1. **Investasi Jangka Panjang:**

   - Instrumen investasi yang dimiliki perusahaan untuk jangka waktu lebih dari 1 tahun (misal: kepemilikan saham/obligasi pada anak usaha atau entitas lain untuk tujuan strategis).

---

## 3. Liabilitas (Utang) [🔗](https://stockbit.com/academy/modules/2/chapters/10/lessons/71)

![chap-2-lesson-8.jpg](attachments/liabilitas.jpg)

### Apa Itu Liabilitas?

**Liabilitas** (atau utang) adalah kewajiban finansial masa kini yang harus dibayar atau dilunasi perusahaan kepada pihak ketiga di masa mendatang.

**Contoh-Contoh Liabilitas:**

- **Utang dagang (_accounts payable_):** Kewajiban jangka pendek kepada pemasok (_supplier_) atas pembelian persediaan bahan baku secara kredit/tempo tanpa bunga.
- **Utang gaji pegawai:** Hak upah/gaji karyawan atas pekerjaan yang telah dilakukan namun belum memasuki tanggal pembayaran gaji.
- **Utang pajak:** Kewajiban pajak perusahaan (misal: PPh, PPN) yang telah terutang namun belum disetorkan ke kas negara.
- **Utang dividen:** Porsi laba bersih yang telah disahkan untuk dibagikan dalam RUPS kepada pemegang saham namun belum ditransfer.
- **Beban yang masih harus dibayar (_accrued expenses_):** Jasa atau biaya yang telah dinikmati manfaatnya namun belum dibayarkan (misal: tagihan listrik, air, telepon, sewa akhir bulan).
- **Utang bank:** Kewajiban pinjaman formal dari lembaga perbankan (kredit modal kerja atau kredit investasi).
- **Utang obligasi:** Kewajiban jangka panjang atas penerbitan surat utang korporasi kepada investor pasar modal.
- **Pendapatan diterima di muka (_unearned revenue_):** Kas yang sudah diterima dari pelanggan di awal sebelum barang/jasa diserahkan.

#### 🔍 Studi Kasus: Alur Kerja Utang Dagang (_Stockbit Chickz_)

1. **Pemesanan Bahan Baku (Tempo/Kredit):**  
   _Stockbit Chickz_ memesan 1.000 ekor ayam potong dan minyak goreng senilai **Rp25 juta** dari peternak _PT Ayam Segar_ dengan syarat pembayaran tempo 30 hari (_Term of Payment_ / TOP 30).
1. **Pencatatan pada Hari Transaksi (Belum Ada Kas Keluar):**

   - **Aset Lancar (Persediaan):** Bertambah $+Rp25.000.000$ (bahan baku masuk dapur).
   - **Liabilitas Jangka Pendek (Utang Dagang):** Bertambah $+Rp25.000.000$ (kewajiban bayar dalam 30 hari).

1. **Perputaran Bisnis:**  
   Daging ayam diolah dan dijual secara tunai ke pelanggan restoran. Perusahaan berhasil mengumpulkan kas masuk dari hasil penjualan sebelum kewajiban ke pemasok harus dilunasi.
1. **Pelunasan Jatuh Tempo (Hari ke-30):**  
   _Stockbit Chickz_ mentransfer pembayaran Rp25 juta ke rekening _PT Ayam Segar_:

   - **Aset Lancar (Kas):** Berkurang $-Rp25.000.000$.
   - **Liabilitas Jangka Pendek (Utang Dagang):** Berkurang $-Rp25.000.000$ (kewajiban lunas).

```mermaid
sequenceDiagram
    autonumber
    actor Supplier as Pemasok (PT Ayam Segar)
    actor Company as Stockbit Chickz
    Supplier->>Company: 1. Kirim pasokan ayam + Invoice tempo 30 hari (Rp25 Jt)
    Note over Company: Persediaan (+) Rp25 Jt<br/>Utang Dagang (+) Rp25 Jt (Kas belum keluar)
    Company->>Company: 2. Ayam diolah & dijual ke pelanggan (Menghasilkan Kas)
    Company->>Supplier: 3. Pelunasan tagihan saat jatuh tempo (Hari ke-30)
    Note over Company: Kas (-) Rp25 Jt<br/>Utang Dagang (-) Rp25 Jt (Kewajiban lunas)
```

> [!TIP]
>
> **Mengapa Utang Dagang Menguntungkan bagi Emiten?**  
> Utang dagang merupakan **sumber pendanaan modal kerja tanpa beban bunga** (_interest-free financing_). Emiten dapat memutar persediaan menjadi penjualan tunai terlebih dahulu sebelum jatuh tempo pembayaran tiba (_Cash Conversion Cycle_ yang sehat).

---

### Klasifikasi Liabilitas

```mermaid
flowchart TD
    Liabilitas["Liabilitas (Kewajiban / Utang)"]

    Liabilitas --> Waktu["Berdasarkan Kurun Waktu"]
    Liabilitas --> Bunga["Berdasarkan Beban Bunga"]

    Waktu --> JkPendek["Liabilitas Jangka Pendek<br/>(Current Liabilities)<br/>&lt; 1 Tahun"]
    Waktu --> JkPanjang["Liabilitas Jangka Panjang<br/>(Non-Current Liabilities)<br/>&gt; 1 Tahun"]

    JkPendek --> ExPendek["Contoh: Utang dagang, utang gaji, cicilan &lt; 1 tahun"]
    JkPanjang --> ExPanjang["Contoh: Pinjaman bank jangka panjang, obligasi, cicilan &gt; 1 tahun"]

    Bunga --> IBL["Interest Bearing Liabilities<br/>(Utang Berbunga)"]
    Bunga --> NIBL["Non-Interest Bearing Liabilities<br/>(Utang Tanpa Bunga)"]

    IBL --> ExIBL["Contoh: Pinjaman bank, obligasi, sukuk<br/>(Tujuan: Ekspansi Bisnis)"]
    NIBL --> ExNIBL["Contoh: Utang pemasok/AP, utang gaji, utang dividen<br/>(Tujuan: Operasional Harian)"]
```

#### A. Berdasarkan Kurun Waktu Pelunasan

1. **Liabilitas Jangka Pendek (_Current Liabilities_):**

   - Kewajiban yang harus dilunasi perusahaan dalam jangka waktu **kurang dari satu tahun (< 1 tahun)** sejak tanggal _balance sheet_.
   - > **Contoh Kasus:**  
     > _Stockbit Chickz_ membeli kompor bekas milik restoran lain dengan cara mencicil selama **3 bulan**. Biaya cicilan ini dicatat sebagai **liabilitas jangka pendek**.

1. **Liabilitas Jangka Panjang (_Non-Current Liabilities_):**

   - Kewajiban yang dapat dilunasi perusahaan dalam jangka waktu **lebih dari satu tahun (> 1 tahun)** sejak tanggal _balance sheet_.
   - > **Contoh Kasus:**  
     > _Stockbit Chickz_ membeli sebidang tanah untuk dijadikan cabang baru. Karena harganya mahal, _Stockbit Chickz_ membayar dengan mencicil selama **5 tahun**. Utang ini dicatat sebagai **liabilitas jangka panjang**.

---

#### B. Berdasarkan Karakteristik Bunga

1. **_Interest Bearing Liabilities_ (Utang Berbunga):**

   - Utang yang membebankan bunga (_interest_) secara berkala, yang nantinya harus dibayar oleh perusahaan sebagai beban keuangan/bunga di _income statement_.
   - **Tujuan Penggunaan:** Biasanya ditarik untuk mendanai **ekspansi bisnis** atau belanja modal (_capex_).
   - **Contoh:** Pinjaman bank jangka menengah/panjang, obligasi korporasi, dan sukuk (obligasi syariah).

1. **_Non-Interest Bearing Liabilities_ (Utang Tanpa Bunga):**

   - Utang yang tidak mengenakan bunga sama sekali.
   - **Tujuan Penggunaan:** Timbul secara alami untuk mendanai **kebutuhan operasional harian** perusahaan.
   - **Contoh:** Utang kepada pemasok atau utang dagang (_accounts payable_), utang gaji karyawan, utang pajak, dan utang dividen.

---

## 4. Ekuitas (Modal)

### Apa Itu Ekuitas?

**Ekuitas** adalah hak residual atau nilai nominal kontribusi modal milik pemilik perusahaan/pemegang saham atas total aset perusahaan setelah dikurangi seluruh kewajibannya.

Ekuitas juga mencerminkan kekayaan bersih (_net worth_) atau estimasi nilai buku perusahaan.

$$
\text{Ekuitas} = \text{Aset} - \text{Liabilitas}
$$

```mermaid
flowchart TD
    Ekuitas["Total Ekuitas (Nilai Bersih)"]

    Ekuitas --> ModalPemilik["Komponen Modal Pemilik / Pemegang Saham"]
    Ekuitas --> HasilOperasional["Komponen Hasil Operasional"]

    ModalPemilik --> ModalDisetor["1. Modal Disetor<br/>(Setoran modal awal para pendiri)"]
    ModalPemilik --> TambahanModal["2. Tambahan Modal Disetor<br/>(Agio saham dari IPO, Rights Issue, Private Placement)"]
    ModalPemilik --> SahamTreasuri["3. Saham Treasuri<br/>(Pengurang ekuitas dari aksi buyback saham)"]

    HasilOperasional --> RetainedEarnings["4. Saldo Laba Ditahan<br/>(Retained Earnings)"]
    RetainedEarnings --> Alokasi1["Reinvestasi ekspansi cabang/pabrik"]
    RetainedEarnings --> Alokasi2["Pelunasan kewajiban/utang"]
    RetainedEarnings --> Alokasi3["Cadangan operasional bisnis"]
```

---

### Perbedaan Struktur Ekuitas Berdasarkan Bentuk Badan Usaha

- **Perusahaan Perseorangan atau Persekutuan (CV/Firma):**  
  Komponen ekuitas hanya terdiri dari satu akun tunggal, yaitu **Modal Pemilik**. Saldo ini langsung merefleksikan kontribusi modal pemilik terhadap total aset perusahaan.
- **Perseroan Terbatas (PT):**  
  Pada PT, struktur ekuitas lebih kompleks dan terbagi menjadi komponen yang berasal dari setoran pemegang saham serta akumulasi hasil usaha.

---

### Komponen Ekuitas pada Perseroan Terbatas (PT)

#### 1. Modal Disetor (_Paid-in Capital_)

- Akun yang mencatat total nominal modal yang telah disetor secara sah oleh para pendiri atau pemegang saham ke kas perusahaan (setara dengan akun Modal Pemilik pada perusahaan perseorangan).
- Nominal ini bersifat tetap kecuali ada perubahan anggaran dasar resmi.
- > **Contoh Kasus:**  
  > Modal disetor _Stockbit Chickz_ sebagai PT adalah sebesar **Rp10 miliar**. Angka ini bersifat tetap karena berasal dari setoran awal Pak Agus (**Rp5 miliar**) dan Pak Budi (**Rp5 miliar**).

#### 2. Tambahan Modal Disetor (_Additional Paid-in Capital / APIC_)

- Tambahan modal yang masuk setelah pembentukan awal perusahaan guna memenuhi kebutuhan ekspansi modal kerja dalam skala besar.
- **Metode Penghimpunan:** Melalui aksi korporasi pasar modal seperti penawaran umum perdana (_Initial Public Offering_ / IPO), penerbitan saham baru dengan hak memesan efek terlebih dahulu (_Rights Issue_), atau penambahan modal tanpa HMETD (_Private Placement_).
- > **Contoh Kasus:**  
  > Delapan tahun setelah didirikan, _Stockbit Chickz_ memutuskan untuk _go public_ (IPO). Dari proses IPO tersebut, perusahaan menerbitkan dan menjual 10 juta lembar saham baru sehingga berhasil menghimpun tambahan modal segar sebesar **Rp40 miliar**.

#### 3. Saham Treasuri (_Treasury Shares_)

- Jumlah lembar saham yang dibeli kembali (_shares buyback_) oleh perusahaan dari pasar reguler atau pemegang saham publik.
- **Sifat Akun:** Bersifat sebagai akun kontra-ekuitas (**pengurang nilai total ekuitas**).
- > **Contoh Kasus:**  
  > Manajemen _Stockbit Chickz_ menilai harga sahamnya di bursa (Rp500/lembar) sudah terdiskon (_undervalued_) dan terlalu murah. Perusahaan melakukan _buyback_ sebanyak 1 juta lembar saham dengan total pengeluaran **Rp500 juta**. Pembelian kembali senilai Rp500 juta ini dicatat sebagai **Saham Treasuri** pada pos ekuitas neraca.

---

### Saldo Laba Ditahan (_Retained Earnings_)

Berbeda dari ketiga komponen sebelumnya yang bersumber langsung dari kantong pemegang saham, **Saldo Laba Ditahan** merupakan komponen ekuitas yang berasal murni dari **hasil kinerja operasional internal perusahaan**.

Saldo ini merupakan akumulasi kumulatif dari laba bersih tahun-tahun berjalan yang **tidak dibagikan sebagai dividen** kepada para pemegang saham.

#### 3 Opsi Penggunaan Laba Bersih Perusahaan:

```mermaid
flowchart TD
    LabaBersih["Laba Bersih Perusahaan"] --> Opsi1["1. Dibagikan 100% sebagai Dividen"]
    LabaBersih --> Opsi2["2. Sebagian Dibagi Dividen & Sebagian Ditahan"]
    LabaBersih --> Opsi3["3. Ditahan 100% (Retained Earnings)"]

    Opsi2 --> DividenKas["Dividen Kas ke Investor"]
    Opsi2 --> DiputarKembali["Diputar Kembali ke Operasional"]

    Opsi3 --> Ekspansi["Ekspansi & Pertumbuhan Masa Depan"]
    Opsi3 --> PelunasanUtang["Membayar Utang & Beban Finansial"]
    Opsi3 --> Ketahanan["Memperkuat Ketahanan Likuiditas"]
```

1. **Membagikan seluruh (100%) laba bersih** kepada pemegang saham dalam bentuk dividen.
2. **Membagikan sebagian laba bersih** sebagai dividen dan menahan sebagian lainnya untuk diputar kembali ke dalam perputaran bisnis.
3. **Menahan seluruh laba bersih** untuk keperluan ekspansi, pelunasan utang, atau memperkuat modal kerja dan kelangsungan usaha.

> **Mengapa Perusahaan Menahan Laba?**  
> Ketika perusahaan berada dalam fase ekspansi yang agresif, manajemen umumnya membatasi atau bahkan tidak membagikan dividen. Dana laba bersih tersebut dialihkan untuk membuka cabang baru, membangun pabrik, membeli peralatan baru, maupun riset dan pengembangan (R&D) guna mencetak laba yang jauh lebih besar di masa depan.

> **Contoh Kasus:**  
> Pada tahun 2019, _Stockbit Chickz_ mencetak laba bersih sebesar **Rp850 juta**. Karena manajemen berencana memperluas jaringan cabang ke kota lain, rapat umum pemegang saham menyepakati untuk tidak membagikan dividen sama sekali (0%). Seluruh laba bersih tahun berjalan sebesar **Rp850 juta** dialokasikan ke akun **Saldo Laba Ditahan**.

---

## 5. Prinsip Pencatatan Laporan Posisi Keuangan

Terdapat dua prinsip akuntansi utama yang digunakan emiten dalam mencatat nilai aset, liabilitas, dan ekuitas pada laporan posisi keuangan:

```mermaid
flowchart LR
    subgraph Historis["1. Prinsip Biaya Historis (Historical Cost)"]
        H1["Perolehan di Masa Lalu"] --> H2["Dicatat Sesuai Harga Beli Asli"]
        H2 --> H3["Nilai Buku Tetap Tidak Berubah<br/>(Kecuali Beban Depresiasi/Amortisasi)"]
    end

    subgraph Wajar["2. Prinsip Nilai Wajar (Fair Value)"]
        W1["Perubahan Harga Pasar"] --> W2["Revaluasi Independen oleh KJPP"]
        W2 --> W3["Nilai Tercatat Disesuaikan Nilai Pasar Terkini"]
    end
```

### 1. Prinsip Biaya Historis (_Historical Cost_)

- Mencatat nilai komponen laporan keuangan sesuai dengan **harga nominal saat perolehan/transaksi terjadi di masa lalu**.
- Nilai yang tertera di neraca tidak berubah mengikuti fluktuasi harga pasar terkini (hanya dikurangi penyusutan akumulasi depresiasi jika ada).

### 2. Prinsip Nilai Wajar (_Fair Value_)

- Menyesuaikan nilai tercatat komponen neraca dengan **nilai estimasi pasar wajar saat ini** sebelum dicantumkan dalam laporan posisi keuangan.
- Penyesuaian nilai wajar aset tidak boleh dilakukan secara sepihak oleh internal emiten, melainkan wajib melalui proses penilaian kembali (**revaluasi aset**) yang dilakukan oleh penilai independen terakreditasi, yaitu **Kantor Jasa Penilai Publik (KJPP)**.

> **Contoh Kasus:**  
> Tiga tahun lalu, _Stockbit Chickz_ membeli sebidang tanah dengan harga perolehan **Rp700 juta**.
>
> - **Jika menggunakan prinsip Biaya Historis:**
>
> Nilai tanah yang tercantum pada neraca saat ini tetap tercatat sebesar **Rp700 juta**, terlepas dari kenaikan harga properti di sekitar lokasi.
>
> - **Jika menggunakan prinsip Nilai Wajar:**
>
> Karena harga pasar properti di daerah tersebut naik pesat, _Stockbit Chickz_ menunjuk KJPP untuk melakukan revaluasi aset. Hasil audit KJPP menyatakan bahwa nilai pasar wajar tanah tersebut kini telah meningkat menjadi **Rp900 juta**. Setelah sertifikat penilaian KJPP terbit, barulah _Stockbit Chickz_ dapat memperbarui nilai tercatat tanah di _balance sheet_ menjadi **Rp900 juta**.
