import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Binding var showAddSheet: Bool
    @State private var seeded = false
    @Query private var categories: [Category]
    @Query private var transactions: [Transaction]
    @Query private var budgets: [Budget]
    @State private var showResetAlert = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome to Finance")
                .font(.title2)
            Button {
                showAddSheet = true
            } label: {
                Label("Add Transaction", systemImage: "plus.circle.fill")
            }
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                Label("Reset All Data", systemImage: "trash")
            }
        }
        .padding()
        .navigationTitle("Home")
        .onAppear(perform: seedDefaultsIfNeeded)
        .alert("Erase all app data?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Erase", role: .destructive) { resetAllData() }
        } message: {
            Text("This will permanently delete all transactions, budgets, categories, and tags.")
        }
    }

    private func seedDefaultsIfNeeded() {
        guard !seeded else { return }
        if categories.isEmpty {
            let defaults: [(String, String)] = [
                ("Food", "#FF9500"), ("Rent", "#FF3B30"), ("Transport", "#34C759"), ("Salary", "#0A84FF")
            ]
            for (name, hex) in defaults {
                context.insert(Category(name: name, colorHex: hex))
            }
            try? context.save()
        }
        seeded = true
    }

    private func resetAllData() {
        // Delete all Transactions
        for tx in transactions {
            context.delete(tx)
        }
        // Delete all Budgets
        for b in budgets {
            context.delete(b)
        }
        // Delete all Categories
        for cat in categories {
            context.delete(cat)
        }
        // Delete all Tags (if Tag model exists)
        if (true) {
            do {
                let descriptor = FetchDescriptor<Tag>()
                let tags = try context.fetch(descriptor)
                for tag in tags { context.delete(tag) }
            } catch {
                // Ignore if Tag isn't part of the model or fetch fails
            }
        }
        // Save changes
        try? context.save()
        // Allow seeding to run again on next appear
        seeded = false
    }
}
