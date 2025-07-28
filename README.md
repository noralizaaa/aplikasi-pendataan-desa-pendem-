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

* **User and Account Management**:
    * **Secure Authentication**: Leverages Firebase Authentication for secure login/logout, with login state tracking in Firestore.
    * **Role-Based Access**: Seamlessly navigates users to either the admin dashboard or the user home page based on their assigned roles.
    * **Admin Account Control**: Provides a dedicated interface for administrators to create, edit, and delete user accounts across the system, as well as manage form-specific access permissions.
    * **Profile Customization**: Users can update their usernames directly from their profile, with real-time synchronization to Firestore.

* **Efficient Data Collection**:
    * **Intuitive Forms**: Offers user-friendly input forms, ensuring smooth data entry with auto-sorting of questions by code and clear answer options.
    * **Comprehensive Grid Inputs**: Facilitates the collection of complex data (e.g., household demographics) using flexible grid numeric questions.
    * **Real-time Validation**: Enforces data integrity through strict validation rules applied during input.

* **Admin Dashboard & Reporting**:
    * **Key Metrics Overview**: Displays vital statistics, such as "Jumlah Rumah Tangga yang Sudah Didata" (Number of Households Surveyed) and daily submission trends for specific forms.
    * **Date Range Filtering**: Allows administrators to filter and analyze data using a custom pop-up date range picker.
    * **Data Export**: Enables robust data export capabilities for form submissions in **JSON**, **CSV**, and **XLSX** formats, with options for custom headers and handling of various cell types.

* **UI/UX and Performance**:
    * **Modern Design**: Features a clean, card-based design with consistent color schemes, gradient headers, and intuitive navigation.
    * **Enhanced Feedback**: Provides clear user feedback through consolidated snackbar notifications for validation errors and improved loading indicators.
    * **Stability**: Incorporates bug fixes and optimizations to ensure smooth performance, address focus issues, and prevent UI overflows.

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
    git clone [https://github.com/RazerArdi/Sensusku-bpsBatu.git](https://github.com/RazerArdi/Sensusku-bpsBatu.git)
    ```
2.  **Navigate to the project directory**:
    ```sh
    cd Sensusku-bpsBatu
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
3.  **Authentication**: Users authenticate securely via Firebase. Their role (admin or regular user) dictates their access, routing them to the appropriate dashboard.
4.  **Data Collection (User)**:
    * Users can access forms based on their assigned permissions.
    * They can view their submission history and create new data entries or edit existing ones.
    * Forms are dynamic, supporting various question types, including smart features like cascading dropdowns and grid numeric inputs.
    * Input is guided by real-time validation and conditional logic, ensuring data quality.
5.  **Admin Dashboard**:
    * Administrators gain insights into data collection progress, such as the total number of surveyed households.
    * Data can be filtered by date ranges using an intuitive calendar interface.
    * Admins have full control over form definitions and user accounts.
    * Crucially, they can export collected data in **JSON**, **CSV**, or **XLSX** formats, choosing their preferred save location through the system's file picker.
6.  **Account Management (Admin)**:
    * A dedicated interface allows admins to create new user accounts, modify existing ones (e.g., updating usernames, changing roles), and delete accounts.
    * Granular authority management enables admins to assign specific forms to individual users, controlling who can submit data for which form.

For a more in-depth guide and visual walkthroughs, please refer to the [Wiki](https://github.com/RazerArdi/Sensusku-bpsBatu/wiki).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Roadmap

SensusKu is continually evolving. Here's a glimpse of planned enhancements and known areas for improvement:

-   [x] Implement splash screen with animation.
-   [x] Design a modern landing page with a gradient header.
-   [x] Integrate Firebase authentication and Firestore for robust backend services.
-   [x] Develop a dynamic form builder supporting diverse question types.
-   [x] Create an admin dashboard with comprehensive data filtering and export capabilities.
-   [x] Add user profile management and full account administration features.
-   [ ] Implement robust **offline data storage and synchronization** to ensure data collection continuity in areas with limited connectivity.
-   [ ] Enhance the reporting dashboard with **advanced data visualizations and analytics**.
-   [ ] Support more complex validation rules and improve the UI for **repeatable question groups**.
-   [ ] Address minor **UI/UX inconsistencies** and refine navigation flows.
-   [ ] Optimize overall **performance** for handling large datasets and highly complex forms.

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

* **Bayu Ardiyansyah**: Spearheaded core development, including the dynamic form builder, admin dashboard, robust authentication system, and comprehensive data export functionalities.
* **Lutfi Indra Nur Praditya**: Contributed significantly to form input enhancements, reliable login state tracking, and overall UI/UX improvements.
* **Febri Bagus Triwibowo**: Focused on enhancing critical UI elements, refining the splash screen, and improving submission history features.

<a href="https://github.com/RazerArdi/Sensusku-bpsBatu/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=RazerArdi/Sensusku-bpsBatu" alt="contrib.rocks image" />
</a>

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## License

This project is distributed under the **MIT License**. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contact

For any inquiries or collaborations, feel free to reach out:

* **Email**: [bayuardi30@outlook.com](mailto:bayuardi30@outlook.com)
* **GitHub Issues**: [Open an Issue](https://github.com/RazerArdi/Sensusku-bpsBatu/issues)

**Project Link**: [https://github.com/RazerArdi/Sensusku-bpsBatu](https://github.com/RazerArdi/Sensusku-bpsBatu)

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