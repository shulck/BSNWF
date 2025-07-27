import SwiftUI
import Charts

struct FinancesView: View {
    // MARK: - Properties
    @StateObject private var service = FinanceService.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showAdd = false
    @State private var showScanner = false
    @State private var showChart = false
    @State private var scannedText = ""
    @State private var extractedFinanceRecord: FinanceRecord?
    @State private var selectedTab: FinanceTab = .all
    @State private var animateChart = false
    @State private var selectedCurrency: Currency = .usd

    // States for filtering
    @State private var showFilter = false
    @State private var filterType: FilterType = .all
    @State private var filterPeriod: FilterPeriod = .allTime
    @State private var showCurrencyPicker = false
    
    // MARK: - Currency Support
    enum Currency: String, CaseIterable, Identifiable {
        case usd = "USD"
        case eur = "EUR"
        case uah = "UAH"
        case gbp = "GBP"
        case cad = "CAD"
        case aud = "AUD"
        case chf = "CHF"
        case jpy = "JPY"
        case pln = "PLN"
        case czk = "CZK"
        case sek = "SEK"
        case nok = "NOK"
        case dkk = "DKK"
        
        var id: String { self.rawValue }
        
        var symbol: String {
            switch self {
            case .usd, .cad, .aud: return "$"
            case .eur: return "€"
            case .uah: return "₴"
            case .gbp: return "£"
            case .chf: return "₣"
            case .jpy: return "¥"
            case .pln: return "zł"
            case .czk: return "Kč"
            case .sek: return "kr"
            case .nok: return "kr"
            case .dkk: return "kr"
            }
        }
        
        var name: String {
            switch self {
            case .usd: return "US Dollar"
            case .eur: return "Euro"
            case .uah: return "Ukrainian Hryvnia"
            case .gbp: return "British Pound"
            case .cad: return "Canadian Dollar"
            case .aud: return "Australian Dollar"
            case .chf: return "Swiss Franc"
            case .jpy: return "Japanese Yen"
            case .pln: return "Polish Złoty"
            case .czk: return "Czech Koruna"
            case .sek: return "Swedish Krona"
            case .nok: return "Norwegian Krone"
            case .dkk: return "Danish Krone"
            }
        }
        
        var flag: String {
            switch self {
            case .usd: return "🇺🇸"
            case .eur: return "🇪🇺"
            case .uah: return "🇺🇦"
            case .gbp: return "🇬🇧"
            case .cad: return "🇨🇦"
            case .aud: return "🇦🇺"
            case .chf: return "🇨🇭"
            case .jpy: return "🇯🇵"
            case .pln: return "🇵🇱"
            case .czk: return "🇨🇿"
            case .sek: return "🇸🇪"
            case .nok: return "🇳🇴"
            case .dkk: return "🇩🇰"
            }
        }
        
        // Device default currency based on locale
        static var deviceDefault: Currency {
            let locale = Locale.current
            
            // Use the new iOS 16+ API if available, fallback to deprecated one for older versions
            let currencyCode: String
            if #available(iOS 16.0, *) {
                currencyCode = locale.currency?.identifier.uppercased() ?? "USD"
            } else {
                currencyCode = locale.currencyCode?.uppercased() ?? "USD"
            }
            
            return Currency(rawValue: currencyCode) ?? .usd
        }
    }
    
    // Computed property for adaptive navigation title
    private var navigationTitle: String {
        // On smaller devices or compact size class, use shorter title
        if horizontalSizeClass == .compact {
            return "Finances".localized
        } else {
            // On larger devices like iPad, use more descriptive title
            return "Band Finances".localized
        }
    }

    // Enumerations for filtering
    enum FilterType: String, CaseIterable {
        case all = "All"
        case income = "Income"
        case expense = "Expenses"
        
        var localizedTitle: String {
            switch self {
            case .all: return "All Transactions".localized
            case .income: return "Income Transactions".localized
            case .expense: return "Expense Transactions".localized
            }
        }
    }

    enum FilterPeriod: String, CaseIterable, Identifiable {
        case allTime = "All"
        case thisMonth = "Month"
        case last3Months = "3 Months"
        case thisYear = "Year"
        
        var id: String { self.rawValue }
        
        var fullTitle: String {
            switch self {
            case .allTime: return "All Time".localized
            case .thisMonth: return "This Month".localized
            case .last3Months: return "Last 3 Months".localized
            case .thisYear: return "This Year".localized
            }
        }
    }
    
    enum FinanceTab: String, CaseIterable, Identifiable {
        case all = "All"
        case income = "Income"
        case expense = "Expenses"
        
        var id: String { self.rawValue }
        
        var localizedTitle: String {
            switch self {
            case .all: return "All Transactions".localized
            case .income: return "Income Transactions".localized
            case .expense: return "Expense Transactions".localized
            }
        }
        
        var shortName: String {
            switch self {
            case .all: return "All Transactions".localized
            case .income: return "Income".localized
            case .expense: return "Expense".localized
            }
        }
        
        var color: Color {
            switch self {
            case .income: return .green
            case .expense: return .red
            case .all: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .income: return "arrow.down.circle.fill"
            case .expense: return "arrow.up.circle.fill"
            case .all: return "circle.grid.2x2.fill"
            }
        }
    }

    // Filtered records
    private var filteredRecords: [FinanceRecord] {
        let filtered = service.records

        // Filter by type
        let typeFiltered = filtered.filter { record in
            switch filterType {
            case .all: return true
            case .income: return record.type == .income
            case .expense: return record.type == .expense
            }
        }

        // Filter by period
        return typeFiltered.filter { record in
            let calendar = Calendar.current
            let now = Date()
            let recordDate = record.date

            switch filterPeriod {
            case .allTime:
                return true
            case .thisMonth:
                let components = calendar.dateComponents([.year, .month], from: now)
                let startOfMonth = calendar.date(from: components)!
                return recordDate >= startOfMonth
            case .last3Months:
                let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!
                return recordDate >= threeMonthsAgo
            case .thisYear:
                let components = calendar.dateComponents([.year], from: now)
                let startOfYear = calendar.date(from: components)!
                return recordDate >= startOfYear
            }
        }
    }

    // MARK: - Main View
    var body: some View {
        ZStack {
            // Background with gradient
            backgroundGradient
            
            ScrollView {
                VStack(spacing: 16) {
                    // Currency selector
                    currencySelector
                    
                    // Main Finances Card
                    financesCard
                    
                    // Segmented Control for transaction types
                    segmentedControl
                    
                    // Recent Activity
                    recentActivityList
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 100) // Extra padding at bottom for floating action button
            }
            
            // Floating Action Button for adding new transactions
            floatingActionButton
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                toolbarMenu
            }
        }
        .onAppear {
            // Set device default currency
            selectedCurrency = Currency.deviceDefault
            
            // Fetch data and animate chart after a delay
            if let groupId = AppState.shared.user?.groupId {
                print("FinancesView: onAppear - fetching for groupId: \(groupId)")
                service.fetch(for: groupId)
                
                // Animate chart after a short delay for better UX
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        animateChart = true
                    }
                }
            } else {
                print("FinancesView: onAppear - no groupId found in AppState.shared.user")
            }
        }
        .sheet(isPresented: $showAdd) {
            AddTransactionView()
        }
        .sheet(isPresented: $showScanner) {
            EnhancedReceiptScannerView(recognizedText: $scannedText, extractedFinanceRecord: $extractedFinanceRecord)
        }
        .sheet(isPresented: $showChart) {
            FinanceChartView(records: filteredRecords)
        }
        .sheet(isPresented: $showFilter) {
            filterSheet
        }
        .sheet(isPresented: $showCurrencyPicker) {
            currencyPickerSheet
        }
    }
    
    // MARK: - Currency Selector
    private var currencySelector: some View {
        HStack {
            Button {
                showCurrencyPicker = true
            } label: {
                HStack(spacing: 8) {
                    Text(selectedCurrency.flag)
                        .font(.title3)
                    
                    Text(selectedCurrency.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? Color(hex: "2c2c2e") : Color(.systemGray6))
                )
            }
            
            Spacer()
        }
    }
    
    // MARK: - Currency Picker Sheet
    private var currencyPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(Currency.allCases) { currency in
                    Button {
                        selectedCurrency = currency
                        showCurrencyPicker = false
                    } label: {
                        HStack {
                            Text(currency.flag)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(currency.rawValue)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(currency.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(currency.symbol)
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                            
                            if selectedCurrency == currency {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Currency".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done".localized) {
                        showCurrencyPicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(
                colors: colorScheme == .dark ?
                    [Color(hex: "1a1a1a"), Color(hex: "121212")] :
                    [Color(hex: "f8f9fa"), Color(hex: "f1f3f5")]
            ),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Finances Card
    private var financesCard: some View {
        VStack(spacing: 12) {
            // Balance section
            VStack(spacing: 4) {
                Text("Balance".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("\(formatCurrency(profit))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(profit >= 0 ? .green : .red)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                // Percentage change indicator
                if let change = calculateChangePercentage() {
                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        
                        Text("\(abs(change), specifier: "%.1f")%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text("vs Previous".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundColor(change >= 0 ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(change >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
            
            // Chart section
            if !filteredRecords.isEmpty {
                balanceChart
                    .frame(height: 100)
                    .padding(.horizontal, 8)
            }
            
            Divider()
                .padding(.horizontal)
            
            // Income & Expense Cards
            HStack(spacing: 12) {
                // Income card
                cardView(
                    title: "Income".localized,
                    amount: totalIncome,
                    icon: "arrow.down.circle.fill",
                    color: .green
                )
                
                // Expense card
                cardView(
                    title: "Expenses".localized,
                    amount: totalExpense,
                    icon: "arrow.up.circle.fill",
                    color: .red
                )
            }
            .padding(.bottom, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "1e1e1e") : .white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // Income/Expense card
    private func cardView(title: String, amount: Double, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            Text(formatCurrency(amount))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Progress bar
            let percentage = totalIncome + totalExpense > 0 ? amount / (totalIncome + totalExpense) : 0
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(color.opacity(0.2))
                    .frame(height: 5)
                
                Capsule()
                    .fill(color)
                    .frame(width: animateChart ? max(CGFloat(percentage) * 150, 10) : 0, height: 5)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(hex: "252525") : color.opacity(0.05))
        )
    }
    
    // Balance Chart
    private var balanceChart: some View {
        let balanceHistory = calculateBalanceHistory()
        
        return GeometryReader { geometry in
            // Background grid lines
            VStack(spacing: geometry.size.height / 4) {
                ForEach(0..<4) { _ in
                    Divider()
                        .background(Color.gray.opacity(0.2))
                }
            }
            
            // Balance line chart
            Path { path in
                guard balanceHistory.count > 1 else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                
                // Find minimum and maximum values for scaling
                let minValue = min(0, balanceHistory.min() ?? 0)
                let maxValue = max(0, balanceHistory.max() ?? 0)
                let range = max(1.0, maxValue - minValue)
                
                // Initial point of the chart
                let firstX: CGFloat = 0
                let firstY = height - (CGFloat(balanceHistory[0] - minValue) / CGFloat(range)) * height
                path.move(to: CGPoint(x: firstX, y: firstY))
                
                // Draw chart line
                for i in 1..<balanceHistory.count {
                    let x = width * CGFloat(i) / CGFloat(balanceHistory.count - 1)
                    let y = height - (CGFloat(balanceHistory[i] - minValue) / CGFloat(range)) * height
                    
                    // Use smooth curves instead of straight lines
                    let controlPoint1 = CGPoint(
                        x: width * CGFloat(i-1) / CGFloat(balanceHistory.count - 1) + width / CGFloat(balanceHistory.count - 1) / 2,
                        y: height - (CGFloat(balanceHistory[i-1] - minValue) / CGFloat(range)) * height
                    )
                    
                    let controlPoint2 = CGPoint(
                        x: width * CGFloat(i) / CGFloat(balanceHistory.count - 1) - width / CGFloat(balanceHistory.count - 1) / 2,
                        y: height - (CGFloat(balanceHistory[i] - minValue) / CGFloat(range)) * height
                    )
                    
                    path.addCurve(to: CGPoint(x: x, y: y), control1: controlPoint1, control2: controlPoint2)
                }
            }
            .trim(from: 0, to: animateChart ? 1.0 : 0.0)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [profit >= 0 ? .green : .red, .blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
            
            // Area fill below the line
            Path { path in
                guard balanceHistory.count > 1 else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                
                // Find minimum and maximum values for scaling
                let minValue = min(0, balanceHistory.min() ?? 0)
                let maxValue = max(0, balanceHistory.max() ?? 0)
                let range = max(1.0, maxValue - minValue)
                
                // Initial point of the chart
                let firstX: CGFloat = 0
                let firstY = height - (CGFloat(balanceHistory[0] - minValue) / CGFloat(range)) * height
                path.move(to: CGPoint(x: firstX, y: height))
                path.addLine(to: CGPoint(x: firstX, y: firstY))
                
                // Draw chart line
                for i in 1..<balanceHistory.count {
                    let x = width * CGFloat(i) / CGFloat(balanceHistory.count - 1)
                    let y = height - (CGFloat(balanceHistory[i] - minValue) / CGFloat(range)) * height
                    
                    // Use smooth curves
                    let controlPoint1 = CGPoint(
                        x: width * CGFloat(i-1) / CGFloat(balanceHistory.count - 1) + width / CGFloat(balanceHistory.count - 1) / 2,
                        y: height - (CGFloat(balanceHistory[i-1] - minValue) / CGFloat(range)) * height
                    )
                    
                    let controlPoint2 = CGPoint(
                        x: width * CGFloat(i) / CGFloat(balanceHistory.count - 1) - width / CGFloat(balanceHistory.count - 1) / 2,
                        y: height - (CGFloat(balanceHistory[i] - minValue) / CGFloat(range)) * height
                    )
                    
                    path.addCurve(to: CGPoint(x: x, y: y), control1: controlPoint1, control2: controlPoint2)
                }
                
                // Close the path at the bottom right and left to create area fill
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))
            }
            .trim(from: 0, to: animateChart ? 1.0 : 0.0)
            .fill(
                LinearGradient(
                    gradient: Gradient(
                        colors: [
                            (profit >= 0 ? Color.green : Color.red).opacity(0.3),
                            (profit >= 0 ? Color.green : Color.red).opacity(0.1),
                            (profit >= 0 ? Color.green : Color.red).opacity(0.05)
                        ]
                    ),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Points on the chart
            ForEach(0..<balanceHistory.count, id: \.self) { index in
                if index % max(1, balanceHistory.count / 5) == 0 || index == balanceHistory.count - 1 {
                    let x = geometry.size.width * CGFloat(index) / CGFloat(balanceHistory.count - 1)
                    let minValue = min(0, balanceHistory.min() ?? 0)
                    let maxValue = max(0, balanceHistory.max() ?? 0)
                    let range = max(1.0, maxValue - minValue)
                    let y = geometry.size.height - (CGFloat(balanceHistory[index] - minValue) / CGFloat(range)) * geometry.size.height
                    
                    Circle()
                        .fill(balanceHistory[index] >= 0 ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                        .opacity(animateChart ? 1.0 : 0.0)
                        .animation(Animation.easeInOut(duration: 0.5).delay(0.8), value: animateChart)
                }
            }
        }
    }
    
    // MARK: - Segmented Control
    private var segmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(FinanceTab.allCases) { tab in
                Button {
                    withAnimation {
                        selectedTab = tab
                        filterType = FilterType(rawValue: tab.rawValue) ?? .all
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.subheadline)
                        
                        Text(horizontalSizeClass == .compact ? tab.shortName : tab.localizedTitle)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == tab ?
                                  tab.color.opacity(0.15) :
                                  (colorScheme == .dark ? Color(hex: "232323") : Color.white))
                            .shadow(color: selectedTab == tab ? tab.color.opacity(0.2) : Color.clear,
                                    radius: 5, x: 0, y: 2)
                    )
                    .foregroundColor(selectedTab == tab ? tab.color : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(hex: "1e1e1e") : .white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Recent Activity List
    private var recentActivityList: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Activity".localized)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                Button {
                    showFilter = true
                } label: {
                    HStack(spacing: 4) {
                        Text(filterPeriod.rawValue)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? Color(hex: "333333") : Color(hex: "f0f0f0"))
                    )
                }
            }
            
            if filteredRecords.isEmpty {
                emptyStateView
            } else {
                // Monthly sections with transactions
                ForEach(groupedByMonth(), id: \.key) { monthData in
                    VStack(alignment: .leading, spacing: 10) {
                        // Month header
                        monthHeaderView(for: monthData.key)
                        
                        // Transaction list
                        ForEach(monthData.records) { record in
                            NavigationLink {
                                TransactionDetailView(record: record)
                            } label: {
                                transactionRowView(for: record)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "1e1e1e") : .white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.vertical, 8)
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 50))
                .foregroundColor(Color.blue.opacity(0.6))
                .padding(.top, 20)
            
            VStack(spacing: 8) {
                Text("No Records".localized)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("Add income or expenses to track your finances".localized)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            
            Button {
                showAdd = true
            } label: {
                Text("Add".localized)
                    .font(.headline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    // Month header view
    private func monthHeaderView(for date: Date) -> some View {
        HStack {
            Text(formattedMonthYear(from: date))
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Spacer()
            
            // Total amount for month
            let monthSummary = calculateMonthSummary(for: date)
            Text(formatCurrency(monthSummary))
                .foregroundColor(monthSummary >= 0 ? .green : .red)
                .font(.subheadline.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(monthSummary >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
    
    // Transaction row
    private func transactionRowView(for record: FinanceRecord) -> some View {
        HStack(spacing: 14) {
            // Category icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(
                                colors: record.type == .income ?
                                [Color.green.opacity(0.7), Color.green.opacity(0.4)] :
                                [Color.red.opacity(0.7), Color.red.opacity(0.4)]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: categoryIcon(for: record.category))
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }

            // Transaction details
            VStack(alignment: .leading, spacing: 3) {
                Text(localizedCategoryName(for: record.category))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                HStack(spacing: 4) {
                    Text(dateFormatter.string(from: record.date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    if !record.details.isEmpty {
                        Circle()
                            .fill(Color.secondary.opacity(0.5))
                            .frame(width: 3, height: 3)
                        
                        Text(record.details)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 3) {
                Text(formatCurrency(record.type == .income ? record.amount : -record.amount))
                    .font(.subheadline)
                    .foregroundColor(record.type == .income ? .green : .red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // Show date relative to today if recent
                Text(timeAgo(from: record.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(hex: "252525") : Color(hex: "f9f9f9"))
        )
        .contextMenu {
            Button {
                // Creates a copy for repeating transaction
            } label: {
                Label("Repeat".localized, systemImage: "arrow.triangle.2.circlepath")
            }
            
            Button {
                // View details
            } label: {
                Label("Details".localized, systemImage: "doc.text.magnifyingglass")
            }
        }
    }
    
    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
                        )
                }
                .padding(20)
            }
        }
    }
    
    // MARK: - Filter Sheet
    private var filterSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Period filter
                VStack(alignment: .leading, spacing: 12) {
                    Text("Time Period".localized)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    ForEach(FilterPeriod.allCases) { period in
                        Button {
                            filterPeriod = period
                            showFilter = false
                        } label: {
                            HStack {
                                Text(period.fullTitle)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Spacer()
                                
                                if filterPeriod == period {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(filterPeriod == period ?
                                          Color.blue.opacity(0.1) :
                                          (colorScheme == .dark ? Color(hex: "232323") : Color(hex: "f5f5f5")))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Filter".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done".localized) {
                        showFilter = false
                    }
                }
            }
        }
    }
    
    // MARK: - Toolbar Menu
    private var toolbarMenu: some View {
        Menu {
            Button {
                showScanner = true
            } label: {
                Label("Scan Receipt".localized, systemImage: "doc.text.viewfinder")
            }
            
            Button {
                showChart = true
            } label: {
                Label("View Charts".localized, systemImage: "chart.bar")
            }
            
            Button {
                showFilter = true
            } label: {
                Label("Filter Transactions".localized, systemImage: "line.3.horizontal.decrease.circle")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
        }
    }
    
    // MARK: - Helper Functions
    
    // Format money with selected currency
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = selectedCurrency.symbol
        formatter.maximumFractionDigits = selectedCurrency == .jpy ? 0 : 2 // Japanese yen without decimal part
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(selectedCurrency.symbol)\(Int(amount))"
    }
    
    // Format short currency (for axes and small spaces)
    private func formatShortCurrency(_ amount: Double) -> String {
        if abs(amount) >= 1_000_000 {
            return "\(selectedCurrency.symbol)\(Int(amount / 1_000_000))M"
        } else if abs(amount) >= 1_000 {
            return "\(selectedCurrency.symbol)\(Int(amount / 1_000))K"
        } else {
            return "\(selectedCurrency.symbol)\(Int(amount))"
        }
    }
    
    // Calculate percentage change
    private func calculateChangePercentage() -> Double? {
        guard !filteredRecords.isEmpty else { return nil }
        
        let calendar = Calendar.current
        
        // Current period balance
        let currentPeriodBalance = profit
        
        // Previous period (same length as current filter)
        var previousPeriodStart: Date
        var previousPeriodEnd: Date
        
        let now = Date()
        
        switch filterPeriod {
        case .thisMonth:
            let components = calendar.dateComponents([.year, .month], from: now)
            let startOfMonth = calendar.date(from: components)!
            previousPeriodStart = calendar.date(byAdding: .month, value: -1, to: startOfMonth)!
            previousPeriodEnd = calendar.date(byAdding: .day, value: -1, to: startOfMonth)!
        case .last3Months:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!
            previousPeriodStart = calendar.date(byAdding: .month, value: -3, to: threeMonthsAgo)!
            previousPeriodEnd = calendar.date(byAdding: .day, value: -1, to: threeMonthsAgo)!
        case .thisYear:
            let components = calendar.dateComponents([.year], from: now)
            let startOfYear = calendar.date(from: components)!
            previousPeriodStart = calendar.date(byAdding: .year, value: -1, to: startOfYear)!
            previousPeriodEnd = calendar.date(byAdding: .day, value: -1, to: startOfYear)!
        case .allTime:
            return nil // Can't calculate percentage for all time
        }
        
        // Calculate previous period balance
        let previousPeriodRecords = service.records.filter { record in
            let date = record.date
            return date >= previousPeriodStart && date <= previousPeriodEnd
        }
        
        let previousIncome = previousPeriodRecords.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let previousExpense = previousPeriodRecords.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let previousBalance = previousIncome - previousExpense
        
        // If previous balance was zero or very small, return nil to avoid division issues
        if abs(previousBalance) < 0.01 {
            return currentPeriodBalance > 0 ? 100 : (currentPeriodBalance < 0 ? -100 : 0)
        }
        
        // Calculate percentage
        return ((currentPeriodBalance - previousBalance) / abs(previousBalance)) * 100
    }
    
    // Calculate balance history for chart
    private func calculateBalanceHistory() -> [Double] {
        var sortedRecords = filteredRecords.sorted { $0.date < $1.date }
        
        // Ensure we have at least two data points
        if sortedRecords.isEmpty {
            return [0, 0]
        } else if sortedRecords.count == 1 {
            let value = sortedRecords[0].type == .income ? sortedRecords[0].amount : -sortedRecords[0].amount
            return [0, value]
        }
        
        // Limit number of points for chart
        if sortedRecords.count > 15 {
            let step = sortedRecords.count / 15
            sortedRecords = stride(from: 0, to: sortedRecords.count, by: step).map { sortedRecords[$0] }
            
            // Always include the most recent transaction
            if !sortedRecords.contains(where: { $0.id == filteredRecords.sorted { $0.date > $1.date }.first?.id }) {
                sortedRecords.append(filteredRecords.sorted { $0.date > $1.date }.first!)
                sortedRecords.sort { $0.date < $1.date }
            }
        }
        
        var balance: Double = 0
        var history: [Double] = [0] // Start with 0 balance
        
        for record in sortedRecords {
            if record.type == .income {
                balance += record.amount
            } else {
                balance -= record.amount
            }
            history.append(balance)
        }
        
        return history
    }
    
    // Grouping by month
    private func groupedByMonth() -> [MonthRecords] {
        let grouped = Dictionary(grouping: filteredRecords) { record -> Date in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month], from: record.date)
            return calendar.date(from: components) ?? record.date
        }
        
        return grouped.map { (key, value) in
            MonthRecords(key: key, records: value.sorted { $0.date > $1.date })
        }.sorted { $0.key > $1.key }
    }
    
    // Month grouping structure
    struct MonthRecords {
        let key: Date
        let records: [FinanceRecord]
    }
    
    // Format month and year
    private func formattedMonthYear(from date: Date) -> String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        var year = calendar.component(.year, from: date)
        
        // Fix for short years - if the year is less than 100, assume it's 2000+
        if year < 100 {
            year += 2000
        }
        
        let monthName = shortMonthNames[month - 1]
        return "\(monthName) \(year)"
    }
    
    // Array of short month names
    private let shortMonthNames = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ]
    
    // Month formatter
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }
    
    // Date formatter
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }
    
    // Calculate total for month
    private func calculateMonthSummary(for date: Date) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        
        return filteredRecords
            .filter {
                let recordComponents = calendar.dateComponents([.year, .month], from: $0.date)
                return recordComponents.year == components.year && recordComponents.month == components.month
            }
            .reduce(0) { sum, record in
                sum + (record.type == .income ? record.amount : -record.amount)
            }
    }
    
    // Get icon for category
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Logistics": return "truck.box.fill"
        case "Food": return "fork.knife"
        case "Equipment": return "guitars.fill"
        case "Accommodation": return "house.fill"
        case "Promotion": return "megaphone.fill"
        case "Other": return "ellipsis.circle.fill"
        case "Performances": return "music.note.list"
        case "Merch": return "tshirt.fill"
        case "Royalties": return "music.quarternote.3"
        case "Sponsorship": return "dollarsign.circle.fill"
        case "Video/Photo Production": return "camera.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    // Format relative time
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let day = components.day, day > 7 {
            return dateFormatter.string(from: date)
        } else if let day = components.day, day > 0 {
            return day == 1 ? "Yesterday".localized : String(format: "%dd ago".localized, day)
        } else if let hour = components.hour, hour > 0 {
            return String(format: "%dh ago".localized, hour)
        } else if let minute = components.minute, minute > 0 {
            return String(format: "%dm ago".localized, minute)
        } else {
            return "Now".localized
        }
    }
    
    // Computed properties for statistics
    private var totalIncome: Double {
        filteredRecords.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpense: Double {
        filteredRecords.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var profit: Double {
        totalIncome - totalExpense
    }
    
    // MARK: - Helper Functions
    
    private func localizedCategoryName(for categoryString: String) -> String {
        if let category = FinanceCategory.allCases.first(where: { $0.rawValue == categoryString }) {
            return category.localizedTitle
        }
        return categoryString
    }
}
