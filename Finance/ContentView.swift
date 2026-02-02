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

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, Category.self, Tag.self, Budget.self])
}
