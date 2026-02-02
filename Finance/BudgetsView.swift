import SwiftUI
import SwiftData

struct BudgetsView: View {
    @Environment(\.modelContext) private var context
    @Query private var budgets: [Budget]
    @Query private var categories: [Category]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var showEditor = false
    @State private var selectedCategory: Category? = nil
    @State private var amountString: String = ""

    var body: some View {
        List {
            ForEach(categories) { category in
                // 1. Calculate the data needed for the row
                let budget = budgets.first { $0.name == category.name }
                let spent = spentThisMonth(for: category)
                
                // 2. Pass data to the Subview
                BudgetRow(
                    category: category,
                    budget: budget,
                    spent: spent,
                    onEdit: { presentEditor(for: category, existing: budget) }
                )
                // 3. Apply Swipe Actions here
                .swipeActions {
                    Button {
                        presentEditor(for: category, existing: budget)
                    } label: {
                        Label("Set", systemImage: "pencil")
                    }
                    .tint(.blue)
                    
                    if let budget {
                        Button(role: .destructive) {
                            context.delete(budget)
                            try? context.save()
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Budgets")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(categories) { cat in
                        Button {
                            presentEditor(for: cat, existing: budgets.first { $0.name == cat.name })
                        } label: {
                            Label(cat.name, systemImage: "folder")
                        }
                    }
                } label: {
                    Label("Set Budget", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                Form {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories) { cat in
                            Text(cat.name).tag(Optional(cat))
                        }
                    }
                    TextField("Amount", text: $amountString)
                        .keyboardType(.decimalPad)
                    Text("Applies to the current month.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .navigationTitle("Set Budget")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showEditor = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { saveBudget() }
                            .disabled(Decimal(string: amountString) == nil || selectedCategory == nil)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func currentMonthPeriod() -> (start: Date, end: Date) {
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        let start = cal.date(from: comps) ?? now
        let end = cal.date(byAdding: DateComponents(month: 1), to: start) ?? now
        return (start, end)
    }

    private func presentEditor(for category: Category, existing: Budget?) {
        selectedCategory = category
        if let existing {
            amountString = "\(existing.amount)"
        } else {
            amountString = ""
        }
        showEditor = true
    }

    private func saveBudget() {
        guard let category = selectedCategory, let amount = Decimal(string: amountString) else { return }
        
        if let existing = budgets.first(where: { $0.name == category.name }) {
            existing.amount = amount
        } else {
            let period = currentMonthPeriod()
            let new = Budget(name: category.name, amount: amount, periodStart: period.start, periodEnd: period.end)
            context.insert(new)
        }
        try? context.save()
        showEditor = false
    }

    private func spentThisMonth(for category: Category) -> Decimal {
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        let start = cal.date(from: comps) ?? now
        let end = cal.date(byAdding: DateComponents(month: 1), to: start) ?? now
        
        var total: Decimal = 0
        
        // Note: Ideally, you should filter this using a predicate in the Query for better performance
        // But this logic works for smaller datasets.
        for tx in transactions {
            if tx.type != .expense { continue }
            // Using safe optional comparison for category logic
            if tx.category?.name != category.name { continue }
            if tx.date < start || tx.date >= end { continue }
            
            let amt = tx.amount < 0 ? -tx.amount : tx.amount
            total += amt
        }
        return total
    }
}
