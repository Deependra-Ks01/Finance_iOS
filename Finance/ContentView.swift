import SwiftUI
import SwiftData
import Charts

struct ContentView: View {
    @State private var showAddSheet = false

    var body: some View {
        TabView {
            NavigationStack {
                HomeView(showAddSheet: $showAddSheet)
            }
            .tabItem { Label("Home", systemImage: "house") }

            NavigationStack {
                TransactionsListView()
            }
            .tabItem { Label("Transactions", systemImage: "list.bullet") }

            NavigationStack {
                BudgetsView()
            }
            .tabItem { Label("Budgets", systemImage: "chart.pie") }

            NavigationStack {
                CategoriesView()
            }
            .tabItem { Label("Categories", systemImage: "folder") }

            NavigationStack {
                AnalyticsView()
            }
            .tabItem { Label("Analytics", systemImage: "chart.bar") }
        }
        .sheet(isPresented: $showAddSheet) {
            AddTransactionView()
        }
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Binding var showAddSheet: Bool
    @State private var seeded = false
    @Query private var categories: [Category]

    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome to Finance")
                .font(.title2)
            Button {
                showAddSheet = true
            } label: {
                Label("Add Transaction", systemImage: "plus.circle.fill")
            }
        }
        .padding()
        .navigationTitle("Home")
        .onAppear(perform: seedDefaultsIfNeeded)
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
}

struct TransactionsListView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    var body: some View {
        List {
            ForEach(transactions) { tx in
                HStack {
                    VStack(alignment: .leading) {
                        Text(tx.category?.name ?? "Uncategorized").font(.headline)
                        if !tx.note.isEmpty { Text(tx.note).font(.subheadline).foregroundStyle(.secondary) }
                        Text(tx.date, style: .date).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(amountString(tx))
                        .foregroundStyle(tx.type == .expense ? .red : .green)
                }
                .contextMenu {
                    ShareLink(item: shareText(for: tx)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .navigationTitle("Transactions")
    }

    private func amountString(_ tx: Transaction) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier
        return formatter.string(from: tx.amount as NSDecimalNumber) ?? "\(tx.amount)"
    }

    private func shareText(for tx: Transaction) -> String {
        let type = tx.type == .expense ? "Expense" : "Income"
        return "\(type): \(amountString(tx)) on \(DateFormatter.localizedString(from: tx.date, dateStyle: .medium, timeStyle: .none))\nCategory: \(tx.category?.name ?? "Uncategorized")\nNote: \(tx.note)"
    }
}

struct BudgetsView: View {
    @Query private var budgets: [Budget]
    var body: some View {
        List(budgets) { budget in
            VStack(alignment: .leading) {
                Text(budget.name).font(.headline)
                Text("Amount: \((budget.amount) as NSDecimalNumber)")
            }
        }
        .navigationTitle("Budgets")
    }
}

struct CategoriesView: View {
    @Environment(\.modelContext) private var context
    @Query private var categories: [Category]

    @State private var showAddSheet = false
    @State private var newCategoryName: String = ""
    @State private var newCategoryColorHex: String = "#999999"

    var body: some View {
        List {
            ForEach(categories) { cat in
                HStack {
                    Circle().fill(cat.color).frame(width: 12, height: 12)
                    Text(cat.name)
                }
            }
            .onDelete(perform: deleteCategories)
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newCategoryName = ""
                    newCategoryColorHex = "#999999"
                    showAddSheet = true
                } label: { Label("Add", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                Form {
                    Section(header: Text("New Category")) {
                        TextField("Name", text: $newCategoryName)
                        TextField("Color Hex (optional)", text: $newCategoryColorHex)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                .navigationTitle("Add Category")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showAddSheet = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { addCategory() }
                            .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func addCategory() {
        let name = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let hex = newCategoryColorHex.trimmingCharacters(in: .whitespacesAndNewlines)
        let colorHex = hex.isEmpty ? "#999999" : hex
        context.insert(Category(name: name, colorHex: colorHex))
        try? context.save()
        showAddSheet = false
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let cat = categories[index]
            context.delete(cat)
        }
        try? context.save()
    }
}

struct AnalyticsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @State private var selectedType: TransactionType? = nil

    private struct Slice: Identifiable {
        let id = UUID()
        let name: String
        let value: Decimal
        let color: Color
    }

    private var groupedSlices: [Slice] {
        // Filter by selected type if any
        let filtered = transactions.filter { tx in
            if let selectedType { return tx.type == selectedType } else { return true }
        }
        // Group by category name, sum amounts; for expenses, sum absolute amounts to show magnitude
        var totals: [String: Decimal] = [:]
        var colors: [String: Color] = [:]
        for tx in filtered {
            let key = tx.category?.name ?? "Uncategorized"
            let amount = tx.type == .expense ? (tx.amount < 0 ? -tx.amount : tx.amount) : tx.amount
            totals[key, default: 0] += amount
            if let cat = tx.category { colors[key] = cat.color } else { colors[key] = .gray }
        }
        // Build slices and drop zero values
        return totals.compactMap { (name, total) in
            guard total != 0 else { return nil }
            return Slice(name: name, value: total, color: colors[name] ?? .gray)
        }
        .sorted { $0.value > $1.value }
    }

    private var totalValue: Decimal {
        groupedSlices.reduce(0) { $0 + $1.value }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Type filter
            Picker("Type", selection: Binding(
                get: { selectedType ?? TransactionType.expense },
                set: { newValue in
                    // Toggle off if the same value selected again
                    if selectedType == newValue { selectedType = nil } else { selectedType = newValue }
                }
            )) {
                Text("Expenses").tag(TransactionType.expense)
                Text("Income").tag(TransactionType.income)
            }
            .pickerStyle(.segmented)

            if groupedSlices.isEmpty {
                ContentUnavailableView("No Data", systemImage: "chart.pie.fill", description: Text("Add some transactions to see analytics."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart(groupedSlices) { slice in
                    SectorMark(
                        angle: .value("Amount", (slice.value as NSDecimalNumber).doubleValue),
                        innerRadius: .ratio(0.5),
                        angularInset: 1
                    )
                    .foregroundStyle(slice.color)
                    .annotation(position: .overlay) {
                        // Show labels for sufficiently large slices
                        if totalValue > 0 {
                            let percent = (slice.value as NSDecimalNumber).doubleValue / (totalValue as NSDecimalNumber).doubleValue
                            if percent > 0.08 {
                                VStack(spacing: 2) {
                                    Text(slice.name).font(.caption).bold()
                                    Text(percentageString(percent)).font(.caption2)
                                }
                                .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                .chartLegend(position: .bottom, spacing: 8) {
                    ForEach(groupedSlices) { s in
                        HStack(spacing: 6) {
                            Circle().fill(s.color).frame(width: 10, height: 10)
                            Text(s.name)
                        }
                    }
                }
                .frame(height: 280)

                // Summary total
                VStack(spacing: 4) {
                    Text(summaryTitle)
                        .font(.headline)
                    Text(currencyString(totalValue))
                        .font(.title3)
                        .foregroundStyle(selectedType == .expense ? .red : .green)
                }
                .frame(maxWidth: .infinity)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Analytics")
    }

    private var summaryTitle: String {
        if let selectedType {
            return selectedType == .expense ? "Total Expenses" : "Total Income"
        } else {
            return "Total Amount"
        }
    }

    private func percentageString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }

    private func currencyString(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}

struct AddTransactionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var amount: String = ""
    @State private var date: Date = .now
    @State private var note: String = ""
    @State private var type: TransactionType = .expense
    @Query private var categories: [Category]
    @State private var selectedCategory: Category?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)

                Picker("Type", selection: $type) {
                    ForEach(TransactionType.allCases, id: \.self) { t in
                        Text(t.rawValue.capitalized).tag(t)
                    }
                }

                DatePicker("Date", selection: $date, displayedComponents: .date)

                Picker("Category", selection: $selectedCategory) {
                    Text("None").tag(Category?.none)
                    ForEach(categories) { cat in
                        Text(cat.name).tag(Category?.some(cat))
                    }
                }

                TextField("Note", text: $note)
            }
            .navigationTitle("Add Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(Decimal(string: amount) == nil)
                }
            }
        }
    }

    private func save() {
        guard let value = Decimal(string: amount) else { return }
        let tx = Transaction(amount: value, date: date, note: note, type: type, category: selectedCategory)
        context.insert(tx)
        dismiss()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, Category.self, Tag.self, Budget.self])
}
