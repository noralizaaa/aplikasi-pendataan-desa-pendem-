<a id="readme-top"></a>

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<br />
<div align="center">
  <a href="https://github.com/RazerArdi/Sensusku-bpsBatu">
    <img src="assets/images/bps.png" alt="Logo" width="80" height="80">
  </a>

<h3 align="center">SensusKu</h3>

  <p align="center">
    Aplikasi Pendataan dan Pengelolaan Desa oleh BPS Kota Batu
    <br />
    <a href="https://github.com/RazerArdi/Sensusku-bpsBatu"><strong>Explore the documentation »</strong></a>
    <br />
    <br />
    <a href="https://github.com/RazerArdi/Sensusku-bpsBatu">View Demo</a>
    ·
    <a href="https://github.com/RazerArdi/Sensusku-bpsBatu/issues/new?labels=bug&template=bug-report---.md">Report a Bug</a>
    ·
    <a href="https://github.com/RazerArdi/Sensusku-bpsBatu/issues/new?labels=enhancement&template=feature-request---.md">Request a Feature</a>
  </p>
</div>

<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#key-features">Key Features</a></li>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

## About The Project

![SensusKu Screenshot][product-screenshot]

**SensusKu** is a mobile application developed by BPS Kota Batu (Central Bureau of Statistics, Batu City) to streamline data collection and management processes in villages. Engineered with **Flutter** for cross-platform compatibility, **GetX** for state management, and **Firebase** for backend services, SensusKu offers a robust and intuitive solution for localized data initiatives. Its design prioritizes an engaging user experience, featuring dynamic form creation, real-time data synchronization, and secure authentication. This project is currently in active development, welcoming contributions to expand its capabilities and refine its performance.

### Key Features

Based on its active development and recent updates (up to version [1.2.1] , July 21, 2025), SensusKu boasts a comprehensive set of features:

* **Dynamic Form Builder**:
    * **Customizable Question Types**: Admins can create and modify forms using a variety of question types including Short Text, Paragraph, Number, Date, Multiple Choice, Checkboxes, Dropdown, and advanced Grid Numeric fields.
    * **Structured Forms**: Supports collapsible sections, Roman numeral titles for clarity, and features like cascading dropdowns and conditional jump logic for intricate survey flows.
    * **Advanced Validation**: Includes options for required fields, min/max length for text, numeric ranges, and predefined regex patterns (e.g., Indonesian phone numbers, NIK, No. KK).
    * **Repeatable Elements**: Allows questions and entire sections to be repeatable, with options to control repetition count via numeric answers from other questions.
    * **Auto-Calculate Age**: Automatically calculates and stores respondent age based on birth date input.

* **User and Account Management**:
    * **Secure Authentication**: Leverages Firebase Authentication for secure login/logout, with login state tracking in Firestore.
    * **Granular Role-Based Access (RBAC)**: Tailored interfaces and data access for **Global Admin**, **Village Admin**, **RW Admin**, and **RT Admin**.
    * **Admin Account Control**: Provides a dedicated interface for administrators to create, edit, and delete user accounts across the system, as well as manage form-specific access permissions.
    * **Profile Customization**: Users can update their usernames directly from their profile, with real-time synchronization to Firestore.

* **Efficient Data Collection & Hybrid Connectivity**:
    * **Hybrid Data Storage**: Seamlessly fetch and save data using both **Cloud (Firebase)** and **Local Village Servers (REST API)** to ensure data sovereignty and reliability in areas with limited internet.
    * **Auto-Duplicate Monthly**: Automatically copies relevant household data from the previous period to current surveys, drastically reducing enumerator workload.
    * **Dynamic Population Profiling**: Real-time classification of respondents into specific groups (Toddlers, Elderly, WUS, etc.) based on age and gender configuration.
    * **Intuitive Forms**: Offers user-friendly input forms, ensuring smooth data entry with auto-sorting of questions by code and clear answer options.

* **Admin Dashboard & Advanced Reporting**:
    * **Key Metrics Overview**: Displays vital statistics, daily submission trends, and **Local Server Connectivity Status** (Online/Offline).
    * **Strict Regional Filtering**: High-accuracy data filtering based on RT/RW profiles to ensure enumerators and monitors only see data relevant to their specific jurisdiction.
    * **Robust Data Export**: Advanced export engine for **JSON**, **CSV**, and **XLSX (Excel)** formats, featuring professional styling, dynamic headers, and smart handling of sensitive IDs like NIK.

* **UI/UX and Performance**:
    * **Modern Design**: Features a clean, card-based design with consistent color schemes, gradient headers, and intuitive navigation.
    * **Enhanced Feedback**: Provides clear user feedback through consolidated snackbar notifications for validation errors and improved loading indicators.
    * **Stability**: Incorporates bug fixes and optimizations to ensure smooth performance, address focus issues, and prevent UI overflows.

### Project Structure & Feature Mapping

Berikut adalah rincian detail mengenai lokasi file kode berdasarkan fungsi fitur untuk memudahkan navigasi bagi pengembang:

#### **1. Modul Admin (Pusat Kendali Sistem)**
| Pilar Fitur | Komponen | Lokasi File / Folder | Peran Teknis |
| :--- | :--- | :--- | :--- |
| **Dashboard** | Monitoring Utama | `lib/presentation/admin/admin_controller.dart` | Mengelola grafik statistik, status server lokal (Online/Offline), dan filtering global. |
| | Tampilan Utama | `lib/presentation/admin/admin_screen.dart` | Layout utama dashboard dengan sistem navigasi tab. |
| **Form Management** | Daftar Formulir | `lib/presentation/admin/formpage/admin_form_controller.dart` | Logika pengambilan daftar form, duplikasi form, dan hak akses otomatis desa. |
| | Pembangun Form | `lib/presentation/admin/formpage/form_builder/` | Otak pembuatan pertanyaan dinamis, logika lompatan (skip logic), dan aturan validasi. |
| **Data Submission** | Viewer Hasil | `lib/presentation/admin/submissions_form/` | Menampilkan ribuan jawaban petugas dengan filter RT/RW yang akurat. |
| | Engine Ekspor | `submissions_form_controller.dart` | Transformasi data mentah ke format **Excel (XLSX)**, CSV, dan JSON. |
| **Account & Security**| Manajemen Akun | `lib/presentation/admin/Admin_Profile/` | Kontrol penuh pembuatan akun petugas baru dan pengaturan izin per-formulir. |
| | Profil Admin | `lib/presentation/admin/profil/` | Pengaturan identitas pribadi admin dan proses logout. |
| **Village Settings** | Manajemen Desa | `lib/presentation/admin/village_management/` | Konfigurasi infrastruktur desa (Alamat IP lokal untuk sistem Hybrid). |

#### **2. Modul User (Aplikasi Petugas Lapangan)**
| Pilar Fitur | Komponen | Lokasi File / Folder | Peran Teknis |
| :--- | :--- | :--- | :--- |
| **Home** | Daftar Tugas | `lib/presentation/user/user_controller.dart` | Sinkronisasi daftar formulir yang ditugaskan kepada petugas secara spesifik. |
| **Data Entry** | Input Lapangan | `lib/presentation/user/input_form_user/` | Logika pengisian cerdas: hitung umur otomatis, slider anggota keluarga, dan upload foto. |
| **Submission List** | Riwayat Kerja | `lib/presentation/user/list_submission_form/` | Monitoring riwayat isian (Draf/Terkirim) dan pemicu **Auto-Duplicate Bulanan**. |
| **User Profile** | Identitas | `lib/presentation/user/user_profile/` | Pengaturan mandiri nama petugas dan informasi wilayah tugas (RT/RW). |

#### **3. Arsitektur Data & Infrastruktur**
| Lapangan | Lokasi | Peran |
| :--- | :--- | :--- |
| **Domain Models** | `lib/domain/` | Definisi struktur data (Form, Submission, User, Village) yang digunakan di seluruh aplikasi. |
| **Navigation** | `lib/infrastructure/navigation/` | Pengaturan rute (routing) dan pemetaan halaman aplikasi. |
| **Authentication** | `lib/domain/auth/` | Sistem login aman menggunakan Firebase Authentication. |

---

### Penjelasan Alur Kerja Sistem (Untuk Pengguna Non-IT)

Aplikasi SensusKu bekerja dalam satu siklus terpadu untuk menjamin validitas data desa:

1.  **Penyusunan (Admin):** Admin menggunakan *Form Builder* untuk membuat kuesioner digital. Di sini, Admin bisa mengatur agar kuesioner "pintar" (misal: pertanyaan tertentu hanya muncul untuk warga berjenis kelamin perempuan).
2.  **Penugasan (Otoritas):** Admin memberikan hak akses formulir tersebut kepada petugas-petugas tertentu di desa yang bersangkutan.
3.  **Pendataan (Petugas):** Petugas lapangan membuka aplikasi, melihat daftar kuesioner, dan mulai mengisi data warga. Data dapat disimpan sebagai **Draf** jika belum selesai, atau langsung **Kirim** jika sudah lengkap.
4.  **Penyimpanan Hybrid:** Saat dikirim, data otomatis masuk ke **Google Cloud** (agar bisa dilihat pusat) dan juga ke **Server Lokal Kantor Desa** (untuk arsip fisik mandiri desa).
5.  **Pemantauan & Pelaporan:** Admin memantau grafik progres harian di Dashboard. Jika pendataan sudah selesai, Admin tinggal klik "Export" untuk mendapatkan laporan dalam bentuk file **Excel** yang sudah rapi dan siap cetak.

### Built With

* [![Flutter][Flutter]][Flutter-url]
* [![GetX][GetX]][GetX-url]
* [![Firebase][Firebase]][Firebase-url]
* `uuid` for unique ID generation
* `intl` for internationalization and date formatting
* `file_picker` for custom file save locations
* `excel` for XLSX file manipulation
* `table_calendar` for enhanced date picking
* `permission_handler` for managing app permissions
* `device_info_plus` for device-specific information

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Getting Started

To get a local copy of SensusKu up and running, follow these simple steps.

### Prerequisites

Ensure you have the following installed:

* **Flutter SDK**:
    ```sh
    # Follow installation instructions at [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
    flutter doctor
    ```
* **Firebase CLI**:
    ```sh
    npm install -g firebase-tools
    ```
* **Dart/Flutter Dependencies**: The `pubspec.yaml` file lists all necessary packages, including `get`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `uuid`, `intl`, `file_picker`, `excel`, `table_calendar`, `permission_handler`, and `device_info_plus`.

### Installation

1.  **Clone the repository**:
    ```sh
    git clone https://github.com/noralizaaa/aplikasi-pendataan-desa-pendem-.git
    ```
2.  **Navigate to the project directory**:
    ```sh
    cd aplikasi_pendataan_desa
    ```
3.  **Install Flutter dependencies**:
    ```sh
    flutter pub get
    ```
4.  **Set up Firebase**:
    * Create a new Firebase project at [https://console.firebase.google.com/](https://console.firebase.google.com/).
    * Add an Android and/or iOS application to your Firebase project.
    * Download the `google-services.json` (for Android) and place it in the `android/app/` directory.
    * Download the `GoogleService-Info.plist` (for iOS) and place it in the `ios/Runner/` directory.
    * **Crucially, configure your Firestore Security Rules** to allow authenticated read/write access to your `adminForms`, `users`, `submissions`, and other relevant collections.
    * Ensure Firebase authentication and Firestore are enabled in your Firebase project.
    * **Configure Firestore Indexes**: For efficient querying, create composite indexes in Firestore as required. For example, for the `users` collection, you might need an index on `role` (Ascending) and `username` (Ascending). You will be prompted by Firebase in the console if a specific query requires an index.

5.  **Run the application**:
    ```sh
    flutter run
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

**SensusKu** is designed for a seamless workflow, from initial app launch to complex data management:

1.  **Splash Screen**: Upon launch, the app displays a branded splash screen with a smooth fade-in animation, leading to the landing page.
2.  **Landing Page**: A visually appealing landing page welcomes users, featuring the BPS and SensusKu logos and a prominent "START" button to begin their journey.
3.  **Authentication**: Users authenticate securely via Firebase. Their specific role (**Global Admin**, **Village Admin**, **RW/RT Admin**, or **Enumerator**) determines their access level and dashboard layout.
4.  **Data Collection (Petugas/Enumerator)**:
    * Users access forms authorized by the admin.
    * **Auto-Duplicate**: Seamlessly continue surveys by automatically copying household data from the previous month.
    * Dynamic forms support smart features like cascading dropdowns, age-calculation, and real-time population classification.
    * Input is guided by real-time validation and skip logic, with data stored in both Cloud and **Local Village Servers**.
5.  **Admin Dashboard & Village Infrastructure**:
    * Monitor collection progress with real-time stats and daily trend charts.
    * **Hybrid Management**: Register and manage local village servers (IP, Port, VPN settings) to ensure data sovereignty.
    * Admins can perform high-accuracy regional filtering based on RT/RW boundaries.
    * Export collected data into professional **XLSX (Excel)**, **CSV**, or **JSON** files with styled headers and sorted data columns.
6.  **Account & Authority Management (Admin)**:
    * A dedicated interface allows admins to create new user accounts, modify existing ones (e.g., updating usernames, changing roles), and delete accounts.
    * Granular authority control: Assign specific forms to individual users or grant village-wide access otomatis.

For a more in-depth guide and visual walkthroughs, please refer to the [Wiki](https://github.com/RazerArdi/Sensusku-bpsBatu/wiki).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Roadmap

SensusKu is continually evolving. Here's a glimpse of planned enhancements and known areas for improvement:

- [x] Implement splash screen with animation.
- [x] Design a modern landing page with a gradient header.
- [x] Integrate Firebase authentication and Firestore for robust backend services.
- [x] Develop a dynamic form builder supporting diverse question types.
- [x] Create an admin dashboard with comprehensive data filtering and export capabilities.
- [x] Add user profile management and full account administration features.
- [x] Integrate **Local Village Server (Hybrid)** for data sovereignty.
- [x] Implement **Auto-Duplicate Monthly** for continuous data collection.
- [x] Enhance reporting with **real-time daily trend charts (fl_chart)**.
- [ ] Implement robust **offline data synchronization** for zero-connectivity environments.
- [ ] Support more complex validation rules and improve the UI for **repeatable question groups**.
- [ ] Optimize overall **performance** for handling extremely large datasets.

See the [open issues](https://github.com/RazerArdi/Sensusku-bpsBatu/issues) for a full list of proposed features and known issues that need attention.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contributing

We welcome and appreciate contributions to the SensusKu project! Whether it's reporting bugs, suggesting features, or submitting code, your help is invaluable.

To contribute code:

1.  **Fork** the project.
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3.  **Commit** your changes (`git commit -m 'Add some AmazingFeature'`).
4.  **Push** to the branch (`git push origin feature/AmazingFeature`).
5.  **Open a Pull Request**.

### Top Contributors

A huge thank you to our top contributors who have significantly shaped SensusKu:

* **Noraliza Putri Nabila**: Spearheaded core development, including the dynamic form builder, admin dashboard, robust authentication system, and comprehensive data export functionalities.
* **Nur Fitrah Wahyuni**: Contributed significantly to form input enhancements, reliable login state tracking, and overall UI/UX improvements.
* **Felda Mufarihati**: Focused on enhancing critical UI elements, refining the splash screen, and improving submission history features.


<p align="right">(<a href="#readme-top">back to top</a>)</p>

## License

This project is distributed under the **MIT License**. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Acknowledgments

We extend our gratitude to the following resources and communities:

* [Flutter](https://flutter.dev/) - For providing an excellent framework for building cross-platform mobile applications.
* [GetX](https://pub.dev/packages/get) - For simplifying state management and navigation in Flutter.
* [Firebase](https://firebase.google.com/) - For offering scalable backend services.
* [unDraw](https://undraw.co/) - For beautiful open-source illustrations.
* [Keep a Changelog](https://keepachangelog.com/) - For a standardized format for changelogs.
* [Semantic Versioning](https://semver.org/) - For clear version management.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

[contributors-shield]: https://img.shields.io/github/contributors/RazerArdi/Sensusku-bpsBatu.svg?style=for-the-badge
[contributors-url]: https://github.com/RazerArdi/Sensusku-bpsBatu/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/RazerArdi/Sensusku-bpsBatu.svg?style=for-the-badge
[forks-url]: https://github.com/RazerArdi/Sensusku-bpsBatu/network/members
[stars-shield]: https://img.shields.io/github/stars/RazerArdi/Sensusku-bpsBatu.svg?style=for-the-badge
[stars-url]: https://github.com/RazerArdi/Sensusku-bpsBatu/stargazers
[issues-shield]: https://img.shields.io/github/issues/RazerArdi/Sensusku-bpsBatu.svg?style=for-the-badge
[issues-url]: https://github.com/RazerArdi/Sensusku-bpsBatu/issues
[license-shield]: https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge
[license-url]: https://github.com/RazerArdi/Sensusku-bpsBatu/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/bayu-ardiyansyah
[product-screenshot]: assets/images/screenshot.png
[Flutter]: https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white
[Flutter-url]: https://flutter.dev/
[GetX]: https://img.shields.io/badge/GetX-000000?style=for-the-badge&logo=flutter&logoColor=white
[GetX-url]: https://pub.dev/packages/get
[Firebase]: https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black
[Firebase-url]: https://firebase.google.com/
