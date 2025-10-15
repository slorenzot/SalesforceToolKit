
# Project Overview

This is a macOS menu bar application called **SalesforceToolKit**. It is built using Swift and SwiftUI.

The application provides a convenient way for Salesforce developers and administrators to access frequently used Salesforce-related links. These links are categorized into:

*   **Orgs:** Production and Sandbox environments.
*   **Specialized Orgs:** Trial orgs for various Salesforce clouds like Financial Services Cloud, Health Cloud, etc.
*   **Tools:** A collection of useful developer tools like Workbench, JSON2Apex, etc.
*   **DevOp Tools:** Links to CI/CD tools like Gearset and Copado.
*   **Help:** Links to Salesforce Help and Trailhead.

The application is localized in English and Spanish.

# Building and Running

This is an Xcode project. To build and run the application:

1.  Open the `SalesforceToolKit.xcodeproj` file in Xcode.
2.  Select the "SalesforceToolKit" scheme.
3.  Click the "Run" button.

There are no command-line build scripts available in the project.

# Development Conventions

*   **Language:** The project is written entirely in Swift.
*   **User Interface:** The UI is built using SwiftUI.
*   **Architecture:** The project follows a basic Model-View-Controller (MVC) pattern for organizing code.
    *   **Model:** The data model is defined in `Model/BookMark.swift`.
    *   **View:** The views are located in the `View` directory.
    *   **Controller:** The business logic is in the `Controller` directory.
*   **Testing:** The project includes targets for both unit tests (`SalesforceToolKitTests`) and UI tests (`SalesforceToolKitUITests`).
*   **Dependencies:** The project has no external dependencies.
*   **Localization:** All user-facing strings are localized. The localization files are in the `SalesforceToolKit/Localizables` directory.
