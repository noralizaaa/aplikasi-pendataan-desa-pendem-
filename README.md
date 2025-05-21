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
  <a href="https://github.com/your_username/sensusku">
    <img src="assets/images/bps.png" alt="Logo" width="80" height="80">
  </a>

<h3 align="center">SensusKu</h3>

  <p align="center">
    Aplikasi Pendataan dan Pengelolaan Desa oleh BPS Kota Batu
    <br />
    <a href="https://github.com/your_username/sensusku"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/your_username/sensusku">View Demo</a>
    ·
    <a href="https://github.com/your_username/sensusku/issues/new?labels=bug&template=bug-report---.md">Report Bug</a>
    ·
    <a href="https://github.com/your_username/sensusku/issues/new?labels=enhancement&template=feature-request---.md">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
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

SensusKu is a mobile application developed by BPS Kota Batu to facilitate village data collection and management. It provides a user-friendly interface for data entry, visualization, and reporting, leveraging Firebase for secure data storage and authentication.

Here's why SensusKu stands out:
* Streamlines village data collection with an intuitive UI.
* Integrates with Firebase for real-time data syncing and secure authentication.
* Built with GetX for efficient state management and navigation.

This project is under active development, and we welcome contributions to enhance its features.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Built With

* [![Flutter][Flutter]][Flutter-url]
* [![GetX][GetX]][GetX-url]
* [![Firebase][Firebase]][Firebase-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->
## Getting Started

To get a local copy up and running, follow these steps.

### Prerequisites

* Flutter SDK
  ```sh
  # Install Flutter (follow instructions at https://flutter.dev/docs/get-started/install)
  flutter doctor
  ```
* Firebase CLI (for Firebase setup)
  ```sh
  npm install -g firebase-tools
  ```

### Installation

1. Clone the repo
   ```sh
   git clone https://github.com/your_username/sensusku.git
   ```
2. Install dependencies
   ```sh
   cd sensusku
   flutter pub get
   ```
3. Set up Firebase
    - Create a Firebase project at [https://console.firebase.google.com/](https://console.firebase.google.com/).
    - Add an Android/iOS app to your Firebase project.
    - Download the `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) and place it in the appropriate directory (`android/app/` or `ios/Runner/`).
    - Run:
      ```sh
      flutter pub add firebase_core
      flutter pub add firebase_auth
      flutter pub add cloud_firestore
      ```
4. Run the app
   ```sh
   flutter run
   ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- USAGE EXAMPLES -->
## Usage

1. **Splash Screen**: Displays the BPS logo with a fade-in animation.
2. **Prototype Screen**: Features a gradient header with the BPS and SensusKu logos, an illustration, and a "START" button to begin data collection.
3. **Data Collection**: (To be implemented) Allows users to input village data, stored in Firestore.
4. **Reporting**: (To be implemented) Generates reports based on collected data.

For more details, refer to the [Documentation](https://github.com/your_username/sensusku/wiki).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ROADMAP -->
## Roadmap

- [x] Implement Splash Screen with animation
- [x] Design Prototype Screen with custom UI
- [ ] Fix navigation issue (stuck on splash screen)
- [ ] Add Firebase authentication
- [ ] Implement data collection forms
- [ ] Develop reporting dashboard
- [ ] Support offline data storage

See the [open issues](https://github.com/your_username/sensusku/issues) for a full list of proposed features and known issues.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTRIBUTING -->
## Contributing

Contributions are welcome! To contribute:

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Top contributors:

<a href="https://github.com/your_username/sensusku/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=your_username/sensusku" alt="contrib.rocks image" />
</a>

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->
## Contact

- Email: [bayuardi30@outlook.com](mailto:bayuardi30@outlook.com)
- GitHub Issues: [Open an issue](https://github.com/yourusername/greensort/issues)

Project Link: [https://github.com/RazerArdi/Sensusku-bpsBatu#](https://github.com/RazerArdi/Sensusku-bpsBatu#)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* [Flutter](https://flutter.dev/)
* [GetX](https://pub.dev/packages/get)
* [Firebase](https://firebase.google.com/)
* [unDraw](https://undraw.co/) for illustrations
* [Keep a Changelog](https://keepachangelog.com/)
* [Semantic Versioning](https://semver.org/)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/your_username/sensusku.svg?style=for-the-badge
[contributors-url]: https://github.com/your_username/sensusku/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/your_username/sensusku.svg?style=for-the-badge
[forks-url]: https://github.com/your_username/sensusku/network/members
[stars-shield]: https://img.shields.io/github/stars/your_username/sensusku.svg?style=for-the-badge
[stars-url]: https://github.com/your_username/sensusku/stargazers
[issues-shield]: https://img.shields.io/github/issues/your_username/sensusku.svg?style=for-the-badge
[issues-url]: https://github.com/your_username/sensusku/issues
[license-shield]: https://img.shields.io/github/license/your_username/sensusku.svg?style=for-the-badge
[license-url]: https://github.com/your_username/sensusku/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/bayu-ardiyansyah
[product-screenshot]: assets/images/screenshot.png
[Flutter]: https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white
[Flutter-url]: https://flutter.dev/
[GetX]: https://img.shields.io/badge/GetX-000000?style=for-the-badge&logo=flutter&logoColor=white
[GetX-url]: https://pub.dev/packages/get
[Firebase]: https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black
[Firebase-url]: https://firebase.google.com/