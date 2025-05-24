import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'user_controller.dart'; // Sesuaikan path ini
import 'user_model.dart'; // Sesuaikan path ini
import 'user_profile/user_profile_screen.dart'; // <-- Import the new profile screen

class UserScreen extends GetView<UserController> {
  const UserScreen({Key? key}) : super(key: key);

  // Definisi Warna (agar mudah diubah, sama dengan LoginScreen)
  static const Color pageBackgroundColor = Color(0xFFF2FAFF);
  static const Color primaryHeaderColor = Color(0xFFFFCC80); // Contoh warna header atas (oranye terang)
  static const Color accentHeaderColor = Color(0xFFFF9800); // Contoh warna aksen (oranye lebih gelap)
  static const Color iconColor = Color(0xFFF57C00); // Warna ikon profil/search
  static const Color cardBackgroundColor = Colors.white; // Warna dasar card

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackgroundColor,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryHeaderColor, accentHeaderColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0, left: 24.0, right: 24.0, bottom: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello,',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              Obx(() => Text(
                                controller.userName.value,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )),
                            ],
                          ),
                          // Icon profil pengguna - MADE CLICKABLE
                          InkWell( // <-- Wrap with InkWell for ripple effect and tap detection
                            onTap: () {
                              Get.toNamed('/user-profile'); // <-- Navigate to the user profile page
                            },
                            borderRadius: BorderRadius.circular(28), // Match avatar radius for good tap area
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              child: Icon(Icons.person, size: 30, color: iconColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search Form',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: InputBorder.none,
                            icon: Icon(Icons.search, color: Colors.grey[600]),
                            suffixIcon: Icon(Icons.search, color: iconColor),
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
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Opsi Pendataan',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: 'Default',
                          icon: Icon(Icons.keyboard_arrow_down, color: accentHeaderColor),
                          style: TextStyle(color: Colors.black87, fontSize: 14),
                          items: <String>['Default', 'Nama A-Z', 'Terbaru']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text('Urut Berdasarkan', style: TextStyle(color: accentHeaderColor)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            // Handle perubahan sort
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!controller.userHasAuthority.value) {
                  return _buildNoAuthorityMessage();
                }

                if (controller.formDataList.isEmpty) {
                  return _buildNoDataMessage();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: controller.formDataList.map((form) =>
                        _buildFormCard(form)
                    ).toList(),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(FormDataModel form) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardBackgroundColor,
      child: InkWell(
        onTap: () {
          Get.snackbar(
            'Form Dipilih',
            'Anda memilih form: ${form.nama}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
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
                      '${form.idForm}: ${form.nama}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.article_outlined, size: 16, color: Colors.black54),
                        const SizedBox(width: 5),
                        Text(
                          'Pendataan ${form.category}',
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(
                          form.lokasi,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(8),
                ),
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Oops! Tidak ada form pendataan yang ditemukan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            const Text(
              'Silakan coba lagi nanti atau hubungi administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => controller.fetchFormData(),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Refresh', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentHeaderColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAuthorityMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.redAccent),
            const SizedBox(height: 20),
            const Text(
              'Akses Dibatasi',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            const Text(
              'Maaf, Anda tidak memiliki otoritas untuk melihat form pendataan ini. Silakan hubungi administrator jika Anda merasa ini adalah kesalahan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => controller.logout(),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Log Out', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}