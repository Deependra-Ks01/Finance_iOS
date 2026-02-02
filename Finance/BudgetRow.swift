import SwiftUI

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
