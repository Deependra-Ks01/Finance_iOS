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
struct BudgetRow: View {
    let category: Category
    let budget: Budget?
    let spent: Decimal
    let onEdit: () -> Void
    
    private var total: Decimal {
        budget?.amount ?? 0
    }
    
    private var remaining: Decimal {
        total - spent
    }
    
    // Calculates the progress bar (0.0 to 1.0)
    private var progress: Double {
        if total == 0 { return 0 }
        // Convert Decimal to Double for progress calculation
        let spentDouble = NSDecimalNumber(decimal: spent).doubleValue
        let totalDouble = NSDecimalNumber(decimal: total).doubleValue
        
        let raw = totalDouble > 0 ? spentDouble / totalDouble : 0
        return min(max(raw, 0), 1)
    }
    
    // Logic for the text label (Remaining vs Over)
    private var remainingLabel: String? {
        guard total > 0 else { return nil }
        
        if remaining >= 0 {
            return "Remaining: \(currencyString(remaining))"
        } else {
            return "Over: \(currencyString(-remaining))"
        }
    }
    
    private var statusColor: Color {
        remaining >= 0 ? .secondary : .red
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Icon, Name, Total Budget
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(category.color)
                        .frame(width: 12, height: 12)
                    Text(category.name).font(.headline)
                }
                Spacer()
                if total != 0 {
                    Text(currencyString(total))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No Budget")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Progress Bar
            ProgressView(value: progress)
                .tint(progress >= 1 ? .red : .blue)
            
            // Footer: Spent and Remaining
            HStack {
                Text("Spent: \(currencyString(spent))")
                    .foregroundStyle(.secondary)
                Spacer()
                if let label = remainingLabel {
                    Text(label)
                        .foregroundStyle(statusColor)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
    }
    
    // Helper function for currency formatting inside the Row
    private func currencyString(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}

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
                        let sliceDouble = (slice.value as NSDecimalNumber).doubleValue
                        let totalDouble = (totalValue as NSDecimalNumber).doubleValue
                        if totalDouble > 0 {
                            let percent = sliceDouble / totalDouble
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

// testing github in Xcode
