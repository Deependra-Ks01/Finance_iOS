import Foundation
import SwiftData
#if canImport(SwiftUI)
import SwiftUI
#endif

enum TransactionType: String, Codable, CaseIterable {
    case expense
    case income
}

@Model final class Transaction {
    @Attribute(.unique) var id: UUID
    var amount: Decimal
    var date: Date
    var note: String
    var type: TransactionType
    var category: Category?
    var tags: [Tag]
    var isRecurring: Bool
    var recurrenceRule: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        amount: Decimal = 0,
        date: Date = Date(),
        note: String = "",
        type: TransactionType = .expense,
        category: Category? = nil,
        tags: [Tag] = [],
        isRecurring: Bool = false,
        recurrenceRule: String? = nil
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.note = note
        self.type = type
        self.category = category
        self.tags = tags
        self.isRecurring = isRecurring
        self.recurrenceRule = recurrenceRule
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }
}

@Model final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String

    init(id: UUID = UUID(), name: String, colorHex: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }

    #if canImport(SwiftUI)
    var color: Color {
        get { Color(hex: colorHex) ?? Color.accentColor }
        set { colorHex = newValue.toHex() ?? "#000000" }
    }
    #endif
}

@Model final class Tag {
    @Attribute(.unique) var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

@Model final class Budget {
    @Attribute(.unique) var id: UUID
    var name: String
    var amount: Decimal
    var periodStart: Date
    var periodEnd: Date
    var categories: [Category]

    init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        periodStart: Date,
        periodEnd: Date,
        categories: [Category] = []
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.categories = categories
    }
}

#if canImport(SwiftUI)
extension Color {
    init?(hex: String) {
        let r, g, b, a: Double

        var hexColor = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if hexColor.hasPrefix("#") {
            hexColor.removeFirst()
        }

        guard hexColor.count == 6 || hexColor.count == 8 else {
            return nil
        }

        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0

        guard scanner.scanHexInt64(&hexNumber) else {
            return nil
        }

        if hexColor.count == 8 {
            r = Double((hexNumber & 0xFF000000) >> 24) / 255
            g = Double((hexNumber & 0x00FF0000) >> 16) / 255
            b = Double((hexNumber & 0x0000FF00) >> 8) / 255
            a = Double(hexNumber & 0x000000FF) / 255
        } else {
            r = Double((hexNumber & 0xFF0000) >> 16) / 255
            g = Double((hexNumber & 0x00FF00) >> 8) / 255
            b = Double((hexNumber & 0x0000FF) / 255)
            a = 1.0
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }

    func toHex(includeAlpha: Bool = false) -> String? {
        #if os(iOS) || os(tvOS) || os(watchOS)
        typealias NativeColor = UIColor
        #elseif os(macOS)
        typealias NativeColor = NSColor
        #else
        return nil
        #endif

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        let nativeColor = NativeColor(self)
        nativeColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        if includeAlpha {
            return String(
                format: "#%02lX%02lX%02lX%02lX",
                lroundf(Float(red * 255)),
                lroundf(Float(green * 255)),
                lroundf(Float(blue * 255)),
                lroundf(Float(alpha * 255))
            )
        } else {
            return String(
                format: "#%02lX%02lX%02lX",
                lroundf(Float(red * 255)),
                lroundf(Float(green * 255)),
                lroundf(Float(blue * 255))
            )
        }
    }
}
#endif
