# ERP Dot

A complete, offline-capable ERP (Enterprise Resource Planning) system built with Flutter. This application is designed to manage various business processes efficiently without requiring a continuous internet connection.

## 🚀 Features

ERP Dot includes a wide range of modules to support business operations:

-   **📊 Dashboard**: Real-time overview of business performance and key metrics.
-   **🛒 POS (Point of Sale)**: Efficient sales processing with receipt printing and barcode scanning.
-   **📦 Inventory Management**: Track stock levels, product movements, and valuations.
-   **💰 Sales**: Manage sales orders, invoices, and customer transactions.
-   **🛍️ Purchasing**: Handle purchase orders and supplier interactions.
-   **🧾 Accounting**: Comprehensive financial management including ledgers and expenses.
-   **👥 Partners**: Manage customer and supplier relationships.
-   **🚚 Vendors**: Dedicated module for vendor management.
-   **🔐 Authentication**: Secure user login and role-based access control.
-   **⚙️ Admin**: System administration and configuration.

## 🛠️ Tech Stack

This project uses a modern Flutter tech stack for performance and maintainability:

-   **Framework**: [Flutter](https://flutter.dev)
-   **Language**: [Dart](https://dart.dev)
-   **State Management**: [Riverpod](https://riverpod.dev)
-   **Database**: [Drift](https://drift.simonbinder.eu) (SQLite abstraction)
-   **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
-   **Printing**: [pdf](https://pub.dev/packages/pdf) & [printing](https://pub.dev/packages/printing)
-   **Scanning**: [mobile_scanner](https://pub.dev/packages/mobile_scanner) & [barcode_widget](https://pub.dev/packages/barcode_widget)
-   **Charts**: [fl_chart](https://pub.dev/packages/fl_chart)

## 🏁 Getting Started

Follow these steps to get a local copy up and running.

### Prerequisites

-   [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your machine.
-   An IDE (VS Code or Android Studio) with Flutter extensions.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/erp-dot.git
    cd erp_dot
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run Code Generation (for Database & Riverpod):**
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

4.  **Run the app:**
    ```bash
    flutter run
    ```

## 📂 Project Structure

-   `lib/core`: Core utilities, database configuration, and shared widgets.
-   `lib/features`: Feature-specific modules (POS, Inventory, etc.).
-   `lib/main.dart`: Application entry point.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
