import SwiftUI
import SwiftData
import Charts

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
