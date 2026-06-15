import 'package:aplikasi_pendataan_desa/infrastructure/navigation/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Diperlukan untuk FirebaseAuth.instance.currentUser
import 'user_controller.dart';
import 'user_model.dart';

/// [UserScreen] adalah halaman utama bagi pengguna dengan level petugas lapangan.
/// 
/// Halaman ini menampilkan daftar formulir pendataan yang diotorisasikan kepada petugas,
/// serta menyediakan fitur pencarian, pengurutan, dan akses ke profil pribadi.
class UserScreen extends GetView<UserController> {
  const UserScreen({super.key});

  /// Latar belakang halaman utama user.
  static const Color pageBackgroundColor = Color(0xFFF2FAFF);
  /// Warna primer untuk bagian header gradasi.
  static const Color primaryHeaderColor = Color(0xFFFFCC80);
  /// Warna aksen untuk bagian header gradasi.
  static const Color accentHeaderColor = Color(0xFFFF9800);
  /// Warna standar untuk ikon navigasi.
  static const Color iconColor = Color(0xFFF57C00);
  /// Warna latar belakang kartu formulir.
  static const Color cardBackgroundColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    // Panggil controller.onReady() jika Anda ingin melakukan sesuatu saat screen siap,
    // atau pastikan _initializeController sudah menangani semua yang diperlukan.
    // Contoh: WidgetsBinding.instance.addPostFrameCallback((_) => controller.onReady());

    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          // fetchFormData sekarang juga akan me-refresh detail pengguna
          await controller.fetchFormData();
        },
        color: accentHeaderColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildHeader(context),
            _buildBody(context),
          ],
        ),
      ),
    );
  }

  /// Membangun bagian header aplikasi yang mencakup sapaan pengguna dan bar pencarian.
  /// 
  /// Menggunakan [SliverAppBar] dengan gradasi oranye dan desain lengkung modern.
  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent, // Membuat SliverAppBar transparan agar Container di FlexibleSpaceBar terlihat
      elevation: 0, // Menghilangkan shadow default jika header punya background sendiri
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentHeaderColor.withValues(alpha: 1.0),
                primaryHeaderColor.withValues(alpha: 0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(bottomRight: Radius.circular(80)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end, // Memposisikan konten ke bawah
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Hello,',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                          Obx(() => Text( // Widget ini akan otomatis update saat controller.userName.value berubah
                            controller.userName.value.isNotEmpty
                                ? controller.userName.value // Menampilkan username dari controller
                                : 'Pengguna', // Fallback jika username kosong
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Get.toNamed(AppRoutes.userProfile);
                      },
                      borderRadius: BorderRadius.circular(28),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withValues(alpha: 0.5),
                        child: Icon(Icons.person_outline_rounded, size: 30, color: Colors.deepOrangeAccent.withValues(alpha: 0.9)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: controller.updateSearchQuery,
                    decoration: const InputDecoration(
                      hintText: 'Cari berdasarkan form...', // Mengganti labelText menjadi hintText
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Padding agar teks tidak terlalu mepet
                    ),
                    // showCursor: false, // Biasanya cursor tetap ditampilkan saat user mengetik
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Membangun bagian body yang berisi kontrol pengurutan dan daftar kartu formulir.
  Widget _buildBody(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 25),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Opsi Pendataan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: Obx(() => DropdownButton<String>(
                    value: controller.currentSortOrder.value,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: accentHeaderColor, size: 22),
                    style: const TextStyle(
                        color: Color(0xFF424242), fontSize: 14, fontWeight: FontWeight.w500),
                    items: controller.sortOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: controller.changeSortOrder,
                    dropdownColor: Colors.white,
                  )),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Obx(() {
          if (controller.isLoading.value && controller.sortedFormDataList.isEmpty) { // Tampilkan loading hanya jika list kosong
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30.0),
                child: CircularProgressIndicator(color: accentHeaderColor),
              ),
            );
          }

          // Cek apakah pengguna sudah login sebelum menampilkan data atau pesan "Belum Ada Form"
          if (FirebaseAuth.instance.currentUser == null) {
            return _buildNoAuthorityMessage(); // Atau pesan spesifik "Silakan Login"
          }

          if (controller.sortedFormDataList.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: controller.sortedFormDataList
                    .map((form) => _buildFormCard(context, form))
                    .toList(),
              ),
            );
          }

          // Jika sudah login tapi tidak ada data dan tidak sedang loading
          return _buildNoDataMessage();
        }),
        const SizedBox(height: 30), // Padding di akhir list
      ]),
    );
  }

  /// Membangun kartu item individu untuk setiap formulir pendataan yang tersedia.
  /// 
  /// Menampilkan judul, kategori, lokasi, dan tanggal pembuatan formulir.
  Widget _buildFormCard(BuildContext context, FormDataModel form) {
    return Card(
      elevation: 2.5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardBackgroundColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.toNamed(AppRoutes.listSubmissionForm, arguments: form.idForm),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form.nama,
                      style: const TextStyle(
                          fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (form.idForm.isNotEmpty && form.idForm != 'N/A') ...[
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${form.idForm}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.layers_outlined, size: 15, color: Colors.grey.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Kategori: ${form.category}',
                            style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            form.lokasi,
                            style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (form.createdAt != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade700),
                          const SizedBox(width: 6),
                          Text(
                            // Format tanggal dan waktu dengan lebih aman
                            'Dibuat: ${MaterialLocalizations.of(context).formatMediumDate(form.createdAt!.toDate())} ${TimeOfDay.fromDateTime(form.createdAt!.toDate()).format(context)}',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded, color: iconColor, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Menampilkan pesan placeholder saat tidak ada formulir yang tersedia atau cocok dengan pencarian.
  Widget _buildNoDataMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Pusatkan konten
          children: [
            Icon(Icons.search_off_rounded, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            const Text(
              'Belum Ada Form',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 10),
            Text(
              'Tidak ada form pendataan yang tersedia atau diotorisasikan untuk Anda saat ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => controller.fetchFormData(), // Aksi refresh
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              label: const Text('Muat Ulang',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentHeaderColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Menampilkan pesan peringatan saat pengguna tidak memiliki hak akses atau belum login.
  Widget _buildNoAuthorityMessage() {
    // Widget ini bisa digunakan jika user belum login atau tidak punya hak akses sama sekali
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Pusatkan konten
          children: [
            Icon(Icons.lock_person_outlined, size: 70, color: Colors.red.shade300),
            const SizedBox(height: 20),
            const Text(
              'Akses Dibutuhkan',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 10),
            Text(
              FirebaseAuth.instance.currentUser == null
                  ? 'Anda perlu login untuk mengakses modul ini.'
                  : 'Anda tidak memiliki izin untuk mengakses modul ini atau belum ada form yang diotorisasikan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 30),
            // Tawarkan login jika belum login, atau refresh jika sudah login tapi mungkin belum ada data.
            if (FirebaseAuth.instance.currentUser == null)
              ElevatedButton.icon(
                onPressed: () => Get.offAllNamed(AppRoutes.login), // Arahkan ke login
                icon: const Icon(Icons.login_rounded, color: Colors.white, size: 20),
                label: const Text('Login Sekarang',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentHeaderColor, // Warna yang konsisten dengan tema
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  elevation: 2,
                ),
              )
            else // Jika sudah login, tawarkan logout atau refresh (tergantung konteks)
              ElevatedButton.icon(
                onPressed: () => controller.logout(), // Atau controller.fetchFormData() jika ingin coba refresh
                icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                label: const Text('Log Out',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  elevation: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}