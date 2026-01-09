//
//  FinanceApp.swift
//  Finance
//
//  Created by Deependra on 10/01/26.
//

import SwiftUI
import SwiftData

@main
struct FinanceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Transaction.self, Category.self, Tag.self, Budget.self])
        }
    }
}
