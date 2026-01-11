# Finance Tracker 💰

![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Latest-blueviolet)
![SwiftData](https://img.shields.io/badge/Database-SwiftData-green)

A modern, native iOS application for tracking personal expenses, income, and budgets. Built entirely with **SwiftUI** and utilizing Apple's latest persistence framework, **SwiftData**.

## 📱 Screenshots

| Home Dashboard | Transactions | Add Transaction |
|:---:|:---:|:---:|
| <img src="docs/home.png" width="250"> | <img src="docs/list.png" width="250"> | <img src="docs/add.png" width="250"> |
## ✨ Features

* **Dashboard Overview:** Quick access to adding transactions and viewing default categories.
* **Transaction Logging:** Log Expenses and Income with amounts, dates, notes, and categories.
* **SwiftData Persistence:** All data is stored locally on-device using efficient, type-safe models.
* **Categorization:** Organize finances with color-coded categories (includes auto-seeding of defaults like Food, Rent, Salary).
* **Budgeting:** (In Progress) View and manage budget limits per category.
* **Share Context Menu:** Long-press transactions to share details as text.
* **Dark Mode Support:** Fully adaptive UI for light and dark themes.

## 🛠 Tech Stack

* **Language:** Swift 5.9
* **Framework:** SwiftUI
* **Data Persistence:** SwiftData (`@Model`, `@Query`, `ModelContext`)
* **Architecture:** Declarative MVVM
* **Minimum Target:** iOS 17.0

## 📂 Project Structure

```text
FinanceApp
├── App
│   ├── FinanceApp.swift       // Entry point & ModelContainer setup
│   └── ContentView.swift      // Main TabView navigation
├── Models
│   └── models.swift           // SwiftData schemas (Transaction, Category, Budget)
├── Views
│   ├── HomeView.swift         // Dashboard & Seeding logic
│   ├── TransactionsListView.swift // Query & List display
│   ├── AddTransactionView.swift   // Form entry
│   └── CategoriesView.swift   // Category management
└── Preview Content
