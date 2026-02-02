import SwiftUI
import SwiftData

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
