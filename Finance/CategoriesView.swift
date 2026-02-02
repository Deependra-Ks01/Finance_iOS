import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var context
    @Query private var categories: [Category]

    @State private var showAddSheet = false
    @State private var newCategoryName: String = ""
    @State private var newCategoryColorHex: String = "#999999"
    @State private var newCategoryColor: Color = Color(hexString: "#999999")

    var body: some View {
        List {
            ForEach(categories) { cat in
                HStack {
                    Circle().fill((cat.color as Color?) ?? .gray).frame(width: 12, height: 12)
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
                    newCategoryColor = Color(hexString: "#999999")
                    showAddSheet = true
                } label: { Label("Add", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                Form {
                    Section(header: Text("New Category")) {
                        TextField("Name", text: $newCategoryName)
                        ColorPicker("Color", selection: $newCategoryColor, supportsOpacity: false)
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
        let pickerHex = newCategoryColor.toHex() ?? "#999999"
        let typedHex = newCategoryColorHex.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalHex = typedHex.isEmpty ? pickerHex : typedHex
        context.insert(Category(name: name, colorHex: finalHex))
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
