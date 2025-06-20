```markdown
<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a id="readme-top"></a>

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/RazerArdi/Sensusku-bpsBatu">
    <img src="assets/images/bps.png" alt="Logo" width="80" height="80">
  </a>

  <h3 align="center">SensusKu</h3>

  <p align="center">
    Aplikasi Pendataan dan Pengelolaan Desa oleh BPS Kota Batu
    <br />
    <a href="https://github.com/RazerArdi/Sensusku-bpsBatu"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/RazerArdi/Sensusku-bpsBatu">View Demo</a>
    ·
    <a href="https://github.com/RazerArdi/Sensusku-bpsBatu/issues/new?labels=bug&template=bug-report---.md">Report Bug</a>
    ·
    <a href="https://github.com/RazerArdi/Sensusku-bpsBatu/issues/new?labels=enhancement&template=feature-request---.md">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
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

<!-- ABOUT THE PROJECT -->
## About The Project

![SensusKu Screenshot][product-screenshot]

**SensusKu** is a mobile application developed by BPS Kota Batu for efficient data collection and management in villages. Built with **Flutter**, **GetX**, and **Firebase**, it offers an intuitive user interface, splash screen animations, and a modern prototype design. The application supports dynamic form creation, real-time data synchronization, and secure authentication, making it a powerful tool for village data management. Currently under active development, SensusKu is open for contributions to enhance its features and performance.

### Key Features

Based on the development progress documented in the changelog (up to version 0.31.0, June 18, 2025), SensusKu includes the following features:

- **Splash Screen and Landing Page**:
  - Displays the BPS logo with a fade-in animation and a modern landing page featuring a gradient header, SensusKu logo, and a "START" button.
  - Enhanced with a scrollable landing page, updated application icon (`launcher_icon.png`), and a new splash screen image (`DaunSS.png`).

- **User Authentication and Profile Management**:
  - Secure login and logout via Firebase Authentication with login state tracking in Firestore (`isLogin` field).
  - Dynamic user profile page with editable usernames, role-based navigation (admin/user), and real-time synchronization with Firestore.
  - Automatic migration to add `isLogin: false` for existing users and sequential username generation (e.g., 'Pendata 1', 'Pendata 2').

- **Dynamic Form Builder**:
  - Administrators can create and edit forms with diverse question types: Short Text, Paragraph, Number, Date, Multiple Choice, Checkboxes, Dropdown, and Grid Numeric.
  - Supports collapsible sections/questions with Roman numeral titles, cascading dropdowns, conditional jump logic, repeatable questions, and validation rules (e.g., min/max length, Indonesian phone number regex: `^(\+62|0)8[0-9]{8,11}$`).
  - Forms are saved to Firestore with robust data export options (JSON, CSV, XLSX) and custom save locations via system file picker.

- **Data Collection and Submission**:
  - User-friendly input forms with automatic question sorting by code, answer option descriptions, and grid numeric questions for complex data (e.g., household data tracking).
  - Edit mode support with proper data population and visibility logic based on conditional jumps.
  - Strict validation, including 16-digit Family Card Number (No KK) checks and dynamic comparison logic for number questions.

- **Admin Dashboard**:
  - Displays metrics like "Jumlah Rumah Tangga yang Sudah Didata" and daily submission trends for DC-Penduduk forms.
  - Features a custom pop-up date range picker using `TableCalendar` for data filtering.
  - Includes form access overview, submission counts per form, and a modern UI with gradient headers and card-based styling.

- **Account Management**:
  - Global account management page for admins to create, edit, and delete user accounts in the `/users` Firestore collection.
  - Form-specific authority management via `managedAccounts` subcollection, enabling granular access control.
  - Modernized dialogs with rounded borders, search bars, and consistent styling for account creation and selection.

- **UI/UX Enhancements**:
  - Unified validation error notifications in a single, scrollable snackbar to prevent notification spam.
  - Improved readability with wrapped error messages, modern text field styling (`_modernInputDecoration`), and consistent color schemes.
  - Optimized navigation with pull-to-refresh for submission lists and automatic section expansion for single-section forms.

- **Data Export and Reporting**:
  - Form-specific export functions (`exportSubmissionsAsJson`, `exportSubmissionsAsCsv`, `exportSubmissionsAsXlsx`) with flexible header builders and proper cell type handling (e.g., `TextCellValue`, `DateTimeCellValue`).
  - Enhanced export flow with permission checks, snackbar feedback, and robust error handling.

- **Bug Fixes and Stability**:
  - Resolved issues like text input focus loss, Firestore permission errors, navigation glitches, and UI overflows.
  - Fixed specific bugs, such as empty `userName` storage, cascading dropdown filtering, and inconsistent state rendering in edit mode.

### Built With

- [![Flutter][Flutter]][Flutter-url]
- [![GetX][GetX]][GetX-url]
- [![Firebase][Firebase]][Firebase-url]
- Additional libraries: `uuid`, `intl`, `file_picker`, `excel`, `table_calendar`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->
## Getting Started

To set up and run SensusKu locally, follow these steps.

### Prerequisites

- **Flutter SDK**
  ```sh
  # Install Flutter (follow instructions at https://flutter.dev/docs/get-started/install)
  flutter doctor
  ```
- **Firebase CLI** (for Firebase setup)
  ```sh
  npm install -g firebase-tools
  ```
- **Dart/Flutter Dependencies**
  Ensure packages listed in `pubspec.yaml` are installed, including `get`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `uuid`, `intl`, `file_picker`, `excel`, and `table_calendar`.

### Installation

1. Clone the repository
   ```sh
   git clone https://github.com/RazerArdi/Sensusku-bpsBatu.git
   ```
2. Install dependencies
   ```sh
   cd Sensusku-bpsBatu
   flutter pub get
   ```
3. Set up Firebase
   - Create a Firebase project at [https://console.firebase.google.com/](https://console.firebase.google.com/).
   - Add an Android/iOS app to your Firebase project.
   - Download the `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) and place it in `android/app/` or `ios/Runner/`.
   - Update Firestore Security Rules to allow authenticated read/write access to collections (`adminForms`, `users`, `submissions`, etc.).
   - Run:
     ```sh
     flutter pub add firebase_core
     flutter pub add firebase_auth
     flutter pub add cloud_firestore
     ```
4. Configure Firestore Indexes
   - Set up composite indexes in Firestore for queries, e.g., `role` (Ascending) and `username` (Ascending) on the `users` collection.
5. Run the app
   ```sh
   flutter run
   ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- USAGE EXAMPLES -->
## Usage

1. **Splash Screen**: Displays the BPS logo with a fade-in animation, transitioning to the landing page after a 3-second delay.
2. **Landing Page**: Features a gradient header with BPS and SensusKu logos, an illustration, and a "START" button to initiate authentication.
3. **Authentication**: Users log in via Firebase Authentication, with role-based navigation to the admin dashboard or user home page.
4. **Data Collection**:
   - Users access forms based on permissions, view submission history, and create/edit entries.
   - Forms support various question types, cascading dropdowns, and grid numeric inputs with real-time validation and conditional logic.
5. **Admin Dashboard**:
   - Admins monitor household data collection progress, filter data by date range, and manage forms and user accounts.
   - Export data in JSON, CSV, or XLSX formats with custom save locations.
6. **Account Management**: Admins create new users, assign form-specific authorities, and manage accounts via a dedicated interface.

For detailed documentation, refer to the [Wiki](https://github.com/RazerArdi/Sensusku-bpsBatu/wiki).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ROADMAP -->
## Roadmap

- [x] Implement splash screen with animation
- [x] Design modern landing page with gradient header
- [x] Integrate Firebase authentication and Firestore
- [x] Develop dynamic form builder with diverse question types
- [x] Create admin dashboard with data filtering and export
- [x] Add user profile management and account administration
- [ ] Implement offline data storage and synchronization
- [ ] Enhance reporting dashboard with advanced visualizations
- [ ] Support complex validation rules and repeatable group UI
- [ ] Fix edit mode navigation issue (returns to edit page on back press)
- [ ] Optimize performance for large datasets and complex forms

See the [open issues](https://github.com/RazerArdi/Sensusku-bpsBatu/issues) for a full list of proposed features and known issues.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTRIBUTING -->
## Contributing

Contributions are welcome! To contribute:

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Top Contributors

- **Bayu Ardiyansyah**: Led core development, including form builder, admin dashboard, authentication, and data export features.
- **Lutfi Indra Nur Praditya**: Contributed to form input enhancements, login state tracking, and UI/UX improvements.
- **Febri Bagus Triwibowo**: Enhanced UI elements, splash screen, and submission history features.

<a href="https://github.com/RazerArdi/Sensusku-bpsBatu/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=RazerArdi/Sensusku-bpsBatu" alt="contrib.rocks image" />
</a>

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->
## Contact

- **Email**: [bayuardi30@outlook.com](mailto:bayuardi30@outlook.com)
- **GitHub Issues**: [Open an issue](https://github.com/RazerArdi/Sensusku-bpsBatu/issues)

**Project Link**: [https://github.com/RazerArdi/Sensusku-bpsBatu](https://github.com/RazerArdi/Sensusku-bpsBatu)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

- [Flutter](https://flutter.dev/)
- [GetX](https://pub.dev/packages/get)
- [Firebase](https://firebase.google.com/)
- [unDraw](https://undraw.co/) for illustrations
- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
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