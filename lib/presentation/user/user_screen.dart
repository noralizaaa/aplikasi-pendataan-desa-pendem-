// lib/presentation/user/user_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'user_controller.dart';
import 'user_model.dart';

class UserScreen extends GetView<UserController> {
  const UserScreen({Key? key}) : super(key: key);

  static const Color pageBackgroundColor = Color(0xFFF2FAFF);
  static const Color primaryHeaderColor = Color(0xFFFFCC80);
  static const Color accentHeaderColor = Color(0xFFFF9800);
  static const Color iconColor = Color(0xFFF57C00);
  static const Color cardBackgroundColor = Colors.white;
  static const Color searchTextColor = Color(0xFF424242);
  static const Color searchHintColor = Color(0xFF757575);
  static const Color searchIconColor = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryHeaderColor, accentHeaderColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
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
                                    fontSize: 26,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withOpacity(0.95),
                                  ),
                                ),
                                Obx(() => Text(
                                  controller.userName.value.isNotEmpty
                                      ? controller.userName.value
                                      : 'Pengguna',
                                  style: const TextStyle(
                                    fontSize: 30,
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
                              Get.snackbar('Profil', 'Navigasi ke halaman profil.', snackPosition: SnackPosition.BOTTOM);
                            },
                            borderRadius: BorderRadius.circular(28),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white.withOpacity(0.25),
                              child: Icon(Icons.person_outline_rounded, size: 30, color: Colors.white.withOpacity(0.9)),
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
                              color: Colors.black.withOpacity(0.08),
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          style: const TextStyle(color: searchTextColor, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Cari Form...',
                            hintStyle: const TextStyle(color: searchHintColor, fontSize: 15),
                            border: InputBorder.none,
                            prefixIcon: const Icon(Icons.search, color: searchIconColor, size: 22),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverList(
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
                              color: Colors.black.withOpacity(0.05),
                              spreadRadius: 0,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            )
                          ]
                      ),
                      child: DropdownButtonHideUnderline(
                        child: Obx(() => DropdownButton<String>(
                          value: controller.currentSortOrder.value,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: accentHeaderColor, size: 22),
                          style: const TextStyle(color: Color(0xFF424242), fontSize: 14, fontWeight: FontWeight.w500),
                          items: controller.sortOptions.map((String value) {
                            String displayText = value;
                            if (value == 'Default') displayText = 'Default';
                            if (value == 'Nama A-Z') displayText = 'Nama A-Z';
                            if (value == 'Terbaru') displayText = 'Terbaru';
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(displayText),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            controller.changeSortOrder(newValue);
                          },
                          dropdownColor: Colors.white,
                        )),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Obx(() {
                print("UserScreen Obx rebuilding: "
                    "isLoading=${controller.isLoading.value}, "
                    "hasAuthority=${controller.userHasAuthority.value}, "
                    "programId='${controller.userProgramId.value}', "
                    "isProgramIdEmpty=${controller.userProgramId.value.isEmpty}, "
                    "sortedListEmpty=${controller.sortedFormDataList.isEmpty}");

                if (controller.isLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30.0),
                      child: CircularProgressIndicator(color: accentHeaderColor),
                    ),
                  );
                }

                // Prioritas 1: Jika ada data form yang berhasil dimuat, tampilkan!
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

                // Prioritas 2: Jika tidak ada data form (sortedFormDataList kosong)
                // Tentukan pesan yang sesuai.
                if (FirebaseAuth.instance.currentUser == null) { // Jika tidak login
                  return _buildNoAuthorityMessage();
                }

                // Jika login, tapi tidak ada form (setelah semua pengecekan otorisasi)
                return _buildNoDataMessage();

              }),
              const SizedBox(height: 30),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, FormDataModel form) {
    return Card(
      elevation: 2.5,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardBackgroundColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Get.snackbar(
            'Form Dipilih: ${form.nama}',
            'ID Form: ${form.idForm}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: accentHeaderColor,
            colorText: Colors.white,
            margin: const EdgeInsets.all(12),
            borderRadius: 8,
          );
        },
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
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333)),
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
                            'Dibuat: ${MaterialLocalizations.of(context).formatMediumDate(form.createdAt!.toDate())} ${TimeOfDay.fromDateTime(form.createdAt!.toDate()).format(context)}',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.arrow_forward_ios_rounded, color: iconColor, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            const Text(
              'Belum Ada Form',
              textAlign: TextAlign.center,
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
              onPressed: () => controller.fetchFormData(), // Tombol refresh
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              label: const Text('Muat Ulang', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
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

  // Pesan ini lebih cocok jika pengguna tidak login, atau ada masalah otorisasi yang lebih fundamental
  Widget _buildNoAuthorityMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_person_outlined, size: 70, color: Colors.red.shade300),
            const SizedBox(height: 20),
            const Text(
              'Akses Dibutuhkan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: Color(0xFF555555)),
            ),
            const SizedBox(height: 10),
            Text(
              'Anda perlu login atau tidak memiliki izin dasar untuk mengakses modul ini. Hubungi administrator jika Anda sudah login dan merasa ini adalah kesalahan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => controller.logout(),
              icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
              label: const Text('Log Out', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
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