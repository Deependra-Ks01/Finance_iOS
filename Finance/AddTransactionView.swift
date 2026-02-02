import SwiftUI
import SwiftData

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
