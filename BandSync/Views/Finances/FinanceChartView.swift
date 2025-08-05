// FinanceChartView.swift

import SwiftUI
import Charts

struct FinanceChartView: View {
    let records: [FinanceRecord]
    @Binding var selectedCurrency: Currency  // Now uses shared Currency enum
    @State private var chartType: ChartType = .monthly
    @State private var selectedIndex: Int? = nil
    @State private var animateChart = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Chart Type Support
    enum ChartType: String, CaseIterable, Identifiable {
        case monthly = "MONTHLY"
        case category = "CATEGORY"
        
        var id: String { self.rawValue }

        var localizedName: String {
            switch self {
            case .monthly:
                return NSLocalizedString("Monthly", comment: "Monthly chart type label")
            case .category:
                return NSLocalizedString("Category", comment: "Category chart type label")
            }
        }
        
        var icon: String {
            switch self {
            case .monthly:
                return "calendar"
            case .category:
                return "folder"
            }
        }
    }

    private var monthlyRecords: [(month: Date, income: Double, expense: Double)] {
        let calendar = Calendar.current
        let groupedRecords = Dictionary(grouping: records) { record in
            calendar.date(from: calendar.dateComponents([.year, .month], from: record.date)) ?? Date()
        }

        return groupedRecords.map { (month, records) in
            let income = records.filter { $0.type == .income }.reduce(0.0) { $0 + $1.amount }
            let expense = records.filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }
            return (month, income, expense)
        }.sorted { $0.month < $1.month }
    }

    private var categoryRecords: [(category: String, amount: Double, isIncome: Bool)] {
        let income = Dictionary(grouping: records.filter { $0.type == .income }) { $0.category }
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
            .map { (category: $0.key, amount: $0.value, isIncome: true) }

        let expense = Dictionary(grouping: records.filter { $0.type == .expense }) { $0.category }
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
            .map { (category: $0.key, amount: $0.value, isIncome: false) }

        return (income + expense).sorted { $0.amount > $1.amount }
    }

    var body: some View {
        ZStack {
            // Background with gradient
            backgroundGradient
            
            VStack(spacing: 0) {
                // Header area with close button and currency selector
                headerSection
                
                // Main Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Chart type selector
                        chartTypeSelector
                        
                        // Financial statistics cards
                        statsSection
                        
                        // Main chart section
                        mainChartSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            // Currency is now passed from parent via @Binding
            // No need to set it here
            
            // Animate the chart after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animateChart = true
                }
            }
        }
        .navigationBarHidden(true)
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
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("Financial Statistics", comment: "Header title for financial statistics view"))
                        .font(.title2.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text(String(format: NSLocalizedString("%d transactions", comment: "Number of transactions label"), records.count))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color(hex: "2a2a2a") : Color(hex: "f0f0f0"))
                        )
                }
            }
            
            // Currency indicator
            HStack {
                HStack(spacing: 8) {
                    Text(NSLocalizedString("currency:", comment: "Currency indicator label"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(selectedCurrency.symbol)
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    Text(selectedCurrency.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? Color(hex: "2c2c2e") : Color(.systemGray6))
                )
                
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
    
    // MARK: - Chart Type Selector
    private var chartTypeSelector: some View {
        HStack(spacing: 10) {
            ForEach(ChartType.allCases) { type in
                Button {
                    withAnimation {
                        chartType = type
                        selectedIndex = nil
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: type.icon)
                            .font(.subheadline)
                        
                        Text(type.localizedName)
                            .font(.subheadline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(chartType == type ?
                                  (colorScheme == .dark ? Color.blue : Color.blue) :
                                  (colorScheme == .dark ? Color(hex: "222222") : Color.white))
                            .shadow(color: chartType == type ? Color.blue.opacity(0.4) : Color.black.opacity(0.05),
                                    radius: 5, x: 0, y: 2)
                    )
                    .foregroundColor(chartType == type ? .white : .primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Financial Statistics Section
    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                // Income card
                statCard(
                    title: NSLocalizedString("Income", comment: "Income card title"),
                    value: totalIncome,
                    icon: "arrow.down.circle.fill",
                    color: .green
                )
                
                // Expense card
                statCard(
                    title: NSLocalizedString("Expenses", comment: "Expenses card title"),
                    value: totalExpense,
                    icon: "arrow.up.circle.fill",
                    color: .red
                )
            }
            
            // Balance card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "banknote.fill")
                        .font(.headline)
                        .foregroundColor(profit >= 0 ? .green : .red)
                    
                    Text(NSLocalizedString("Balance", comment: "Balance card title"))
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                    
                    Text(formatCurrency(profit))
                        .font(.title3.bold())
                        .foregroundColor(profit >= 0 ? .green : .red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                // Balance gauge
                if totalIncome + totalExpense > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background track
                            Capsule()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            // Income section
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.7), Color.green],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: animateChart ?
                                        max(10, geo.size.width * CGFloat(totalIncome / (totalIncome + totalExpense))) : 0,
                                    height: 8
                                )
                            
                            // Zero marker
                            Rectangle()
                                .fill(Color.gray)
                                .frame(width: 2, height: 14)
                                .offset(x: geo.size.width / 2 - 1, y: -3)
                        }
                    }
                    .frame(height: 8)
                    
                    // Legend for gauge
                    HStack {
                        Text(NSLocalizedString("Income", comment: "Income label for gauge legend"))
                            .font(.caption)
                            .foregroundColor(.green)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        Spacer()
                        
                        Text(NSLocalizedString("Expenses", comment: "Expenses label for gauge legend"))
                            .font(.caption)
                            .foregroundColor(.red)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(hex: "222222") : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
    
    // Stats card
    private func statCard(title: String, value: Double, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: icon)
                            .font(.subheadline)
                            .foregroundColor(color)
                        
                        Text(title)
                            .font(.subheadline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    
                    Text(formatCurrency(value))
                        .font(.headline)
                        .foregroundColor(color)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color.opacity(0.2))
            }
            
            // Progress indicator
            if totalIncome + totalExpense > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(color.opacity(0.2))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(color)
                            .frame(
                                width: animateChart ?
                                    max(10, geo.size.width * CGFloat(value / (totalIncome + totalExpense))) : 0,
                                height: 6
                            )
                    }
                }
                .frame(height: 6)
                
                // Percentage
                Text(String(format: "%.1f%%", (value / (totalIncome + totalExpense)) * 100))
                    .font(.caption2)
                    .foregroundColor(color)
                    .padding(.top, 2)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "222222") : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Main Chart Section
    private var mainChartSection: some View {
        VStack {
            if records.isEmpty {
                emptyStateView
            } else {
                switch chartType {
                case .monthly:
                    improvedMonthlyChartView
                case .category:
                    improvedCategoryChartView
                }
            }
        }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 60))
                .foregroundColor(Color.blue.opacity(0.6))
                .padding(.top, 40)
            
            VStack(spacing: 12) {
                Text(NSLocalizedString("No financial data", comment: "Empty state title"))
                    .font(.title3.bold())
                
                Text(NSLocalizedString("Add income or expense transactions to track your finances", comment: "Empty state description"))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
            }
            
            Button {
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text(NSLocalizedString("Add Transactions", comment: "Button to add transactions"))
                }
                .font(.headline)
                .padding(.vertical, 14)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                )
                .foregroundColor(.white)
                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(hex: "222222") : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .padding(.vertical, 16)
    }
    
    // Info button helper
    private func infoButton() -> some View {
        Button {
            // Show info about chart
        } label: {
            Image(systemName: "info.circle")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(8)
                .background(
                    Circle()
                        .fill(colorScheme == .dark ? Color(hex: "333333") : Color(hex: "f0f0f0"))
                )
        }
    }
    
    // Improved monthly chart
    private var improvedMonthlyChartView: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !monthlyRecords.isEmpty {
                // Chart period
                let startDate = monthlyRecords.first?.month ?? Date()
                let endDate = monthlyRecords.last?.month ?? Date()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Period", comment: "Chart period label"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(formattedDate(startDate)) — \(formattedDate(endDate))")
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    
                    Spacer()
                    
                    // Info button
                    infoButton()
                }
                .padding(.horizontal, 16)
                
                // Monthly chart container
                VStack(spacing: 16) {
                    // Selected month details overlay
                    if let selectedIndex = selectedIndex, selectedIndex < monthlyRecords.count {
                        selectedMonthDetails(monthlyRecords[selectedIndex])
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Main chart
                    monthlyChart
                        .frame(height: 300)
                        .padding(.bottom, 8)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color(hex: "222222") : Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
                
                // Monthly breakdown
                monthlyBreakdownSection
            } else {
                // No data
                noDataView(NSLocalizedString("No monthly data", comment: "No monthly data available message"))
            }
        }
    }
    
    // Monthly chart component
    private var monthlyChart: some View {
        Chart {
            ForEach(monthlyRecords.indices, id: \.self) { index in
                let record = monthlyRecords[index]
                
                // Income bars
                BarMark(
                    x: .value("Month", record.month, unit: .month),
                    y: .value(NSLocalizedString("Income", comment: "Chart axis label for income"), record.income)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green.opacity(0.7), .green.opacity(0.9)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
                .opacity(selectedIndex == nil || selectedIndex == index ? 1 : 0.4)
                
                // Expense bars (negative values)
                BarMark(
                    x: .value("Month", record.month, unit: .month),
                    y: .value(NSLocalizedString("Expense", comment: "Chart axis label for expense"), -record.expense)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red.opacity(0.7), .red.opacity(0.9)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
                .opacity(selectedIndex == nil || selectedIndex == index ? 1 : 0.4)
                
                // Balance points
                if monthlyRecords.count > 1 {
                    PointMark(
                        x: .value("Month", record.month, unit: .month),
                        y: .value("Bal", record.income - record.expense)
                    )
                    .symbolSize(selectedIndex == index ? 120 : 80)
                    .foregroundStyle(.blue)
                    .opacity(selectedIndex == nil || selectedIndex == index ? 1 : 0.4)
                }
            }
            
            // Balance line
            if monthlyRecords.count > 1 {
                ForEach(0..<monthlyRecords.count-1, id: \.self) { index in
                    LineMark(
                        x: .value("Month", monthlyRecords[index].month, unit: .month),
                        y: .value("Bal", monthlyRecords[index].income - monthlyRecords[index].expense)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .opacity(0.8)
                    
                    LineMark(
                        x: .value("Month", monthlyRecords[index+1].month, unit: .month),
                        y: .value("Bal", monthlyRecords[index+1].income - monthlyRecords[index+1].expense)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .opacity(0.8)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let doubleValue = value.as(Double.self) {
                    AxisValueLabel {
                        Text(formatShortCurrency(abs(doubleValue)))
                            .font(.caption2)
                            .foregroundColor(doubleValue >= 0 ? .primary : .red)
                            .lineLimit(1)
                    }
                    
                    if doubleValue == 0 {
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            .foregroundStyle(Color.gray)
                    } else {
                        AxisGridLine()
                            .foregroundStyle(Color.gray.opacity(0.2))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(shortMonthFormatter.string(from: date))
                            .font(.caption2)
                            .lineLimit(1)
                    }
                    AxisGridLine()
                        .foregroundStyle(Color.gray.opacity(0.2))
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let xPosition = value.location.x
                                let chartWidth = geometry.size.width
                                let stepWidth = chartWidth / CGFloat(monthlyRecords.count)
                                
                                let index = min(max(Int(xPosition / stepWidth), 0), monthlyRecords.count - 1)
                                selectedIndex = index
                            }
                            .onEnded { _ in
                                selectedIndex = nil
                            }
                    )
            }
        }
        .animation(.easeInOut, value: selectedIndex)
    }
    
    // Selected month details
    private func selectedMonthDetails(_ record: (month: Date, income: Double, expense: Double)) -> some View {
        VStack(spacing: 10) {
            Text(formattedDate(record.month))
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            HStack(spacing: 16) {
                // Income
                VStack(spacing: 2) {
                    Text(NSLocalizedString("Income", comment: "Income label for selected month details"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(record.income))
                        .foregroundColor(.green)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                
                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 30)
                
                // Expense
                VStack(spacing: 2) {
                    Text(NSLocalizedString("Expense", comment: "Expense label for selected month details"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(record.expense))
                        .foregroundColor(.red)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                
                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 30)
                
                // Balance
                VStack(spacing: 2) {
                    Text(NSLocalizedString("Balance", comment: "Balance label for selected month details"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(record.income - record.expense))
                        .foregroundColor(record.income - record.expense >= 0 ? .green : .red)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "2a2a2a") : Color(hex: "f5f5f5"))
        )
    }
    
    // Monthly breakdown
    private var monthlyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Monthly Breakdown", comment: "Monthly breakdown section title"))
                .font(.headline)
                .padding(.horizontal, 16)
            
            VStack(spacing: 8) {
                ForEach(monthlyRecords.indices, id: \.self) { index in
                    let record = monthlyRecords[index]
                    
                    HStack(spacing: 8) {
                        // Month
                        Text(formattedDate(record.month))
                            .font(.caption)
                            .frame(width: 60, alignment: .leading)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        // Income/Expense bars
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                // Income bar
                                Capsule()
                                    .fill(Color.green.opacity(0.2))
                                    .frame(height: 6)
                                
                                Capsule()
                                    .fill(Color.green)
                                    .frame(
                                        width: animateChart ? calculateBarWidth(
                                            value: record.income,
                                            maxValue: maxIncomeExpense,
                                            width: geo.size.width
                                        ) : 0,
                                        height: 6
                                    )
                                
                                // Expense bar - positioned below income
                                Capsule()
                                    .fill(Color.red.opacity(0.2))
                                    .frame(height: 6)
                                    .offset(y: 12)
                                
                                Capsule()
                                    .fill(Color.red)
                                    .frame(
                                        width: animateChart ? calculateBarWidth(
                                            value: record.expense,
                                            maxValue: maxIncomeExpense,
                                            width: geo.size.width
                                        ) : 0,
                                        height: 6
                                    )
                                    .offset(y: 12)
                            }
                        }
                        .frame(height: 18)
                        
                        // Amounts
                        HStack(spacing: 12) {
                            Text(formatShortCurrency(record.income))
                                .font(.caption2)
                                .foregroundColor(.green)
                                .frame(width: 50, alignment: .trailing)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            
                            Text(formatShortCurrency(record.expense))
                                .font(.caption2)
                                .foregroundColor(.red)
                                .frame(width: 50, alignment: .trailing)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            selectedIndex = selectedIndex == index ? nil : index
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedIndex == index ?
                                  (colorScheme == .dark ? Color(hex: "333333") : Color(hex: "f0f0f0")) :
                                  Color.clear)
                    )
                    .padding(.horizontal, 8)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(hex: "222222") : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
    
    // Calculate bar width proportionally
    private func calculateBarWidth(value: Double, maxValue: Double, width: CGFloat) -> CGFloat {
        let maxWidth = width * 0.8
        return value > 0 ? max(CGFloat(value / maxValue) * maxWidth, 10) : 0
    }
    
    // Maximum income or expense for scaling
    private var maxIncomeExpense: Double {
        let maxIncome = monthlyRecords.map { $0.income }.max() ?? 0
        let maxExpense = monthlyRecords.map { $0.expense }.max() ?? 0
        return max(maxIncome, maxExpense)
    }
    
    // MARK: - Category Chart
    private var improvedCategoryChartView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Category filter tabs
            HStack {
                Text(NSLocalizedString("Categories", comment: "Categories section title"))
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Picker("", selection: Binding(
                    get: { self.categoryFilter },
                    set: { newFilter in
                        withAnimation {
                            self.categoryFilter = newFilter
                            self.selectedIndex = nil
                        }
                    }
                )) {
                    Text(NSLocalizedString("All", comment: "All categories filter option")).tag(CategoryFilter.all)
                    Text(NSLocalizedString("Income", comment: "Income categories filter option")).tag(CategoryFilter.income)
                    Text(NSLocalizedString("Expense", comment: "Expense categories filter option")).tag(CategoryFilter.expense)
                }
                .pickerStyle(.segmented)
                .padding(3)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? Color(hex: "333333") : Color(hex: "f0f0f0"))
                )
            }
            .padding(.horizontal, 16)
            
            if filteredCategoryRecords.isEmpty {
                // No data for selected filter
                noDataView(NSLocalizedString("No data for category", comment: "No data message for category filter"))
            } else {
                // Category chart
                VStack(spacing: 20) {
                    // Selected category details
                    if let selectedIndex = selectedIndex, selectedIndex < filteredCategoryRecords.count {
                        selectedCategoryDetails(filteredCategoryRecords[selectedIndex])
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Main category chart
                    categoryChart
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color(hex: "222222") : Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
                
                // Category breakdown
                categoryBreakdownSection
                
                // Recent transactions in category
                if let selectedIndex = selectedIndex, selectedIndex < filteredCategoryRecords.count {
                    recentTransactionsSection(for: filteredCategoryRecords[selectedIndex])
                }
            }
        }
    }
    
    // No data view
    private func noDataView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie")
                .font(.system(size: 50))
                .foregroundColor(Color.gray.opacity(0.6))
                .padding(.top, 20)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(hex: "222222") : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // Category chart
    private var categoryChart: some View {
        Chart {
            ForEach(filteredCategoryRecords.indices, id: \.self) { index in
                let record = filteredCategoryRecords[index]
                
                BarMark(
                    x: .value("Amount", animateChart ? record.amount : 0),
                    y: .value("Cat", localizedCategoryName(for: record.category))
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            record.isIncome ? Color.green.opacity(0.7) : Color.red.opacity(0.7),
                            record.isIncome ? Color.green : Color.red
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
                .opacity(selectedIndex == nil || selectedIndex == index ? 1 : 0.4)
                .annotation(position: .trailing) {
                    Text(formatShortCurrency(record.amount))
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(record.isIncome ? Color.green : Color.red)
                        )
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                if let amount = value.as(Double.self) {
                    AxisValueLabel {
                        Text(formatShortCurrency(amount))
                            .font(.caption2)
                            .lineLimit(1)
                    }
                    AxisGridLine()
                        .foregroundStyle(Color.gray.opacity(0.2))
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                if let category = value.as(String.self) {
                    AxisValueLabel {
                        HStack(spacing: 4) {
                            let isIncome = filteredCategoryRecords.first { $0.category == category }?.isIncome ?? false
                            Circle()
                                .fill(isIncome ? Color.green : Color.red)
                                .frame(width: 6, height: 6)
                            
                            Text(category)
                                .font(.caption2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .truncationMode(.tail)
                        }
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let yPosition = value.location.y
                                let chartHeight = geometry.size.height
                                let stepHeight = chartHeight / CGFloat(filteredCategoryRecords.count)
                                
                                let index = min(max(Int(yPosition / stepHeight), 0), filteredCategoryRecords.count - 1)
                                selectedIndex = index
                            }
                            .onEnded { _ in
                                // Keep selection when ended
                            }
                    )
            }
        }
        .frame(height: CGFloat(min(filteredCategoryRecords.count, 8) * 40))
        .animation(.easeInOut, value: selectedIndex)
        .padding(.vertical, 8)
    }
    
    // Selected category details
    private func selectedCategoryDetails(_ record: (category: String, amount: Double, isIncome: Bool)) -> some View {
        VStack(spacing: 12) {
            HStack {
                // Category icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(
                                    colors: record.isIncome ?
                                    [Color.green.opacity(0.7), Color.green.opacity(0.4)] :
                                    [Color.red.opacity(0.7), Color.red.opacity(0.4)]
                                ),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: categoryIcon(for: record.category))
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                // Category details
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizedCategoryName(for: record.category))
                        .font(.headline)
                    
                    Text(record.isIncome ?
                         NSLocalizedString("Income Category", comment: "Income category type label") :
                         NSLocalizedString("Expense Category", comment: "Expense category type label"))
                        .font(.subheadline)
                        .foregroundColor(record.isIncome ? .green : .red)
                }
                
                Spacer()
                
                // Amount
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(record.amount))
                        .font(.title3.bold())
                        .foregroundColor(record.isIncome ? .green : .red)
                    
                    // Percentage of total
                    let percentage = record.isIncome ?
                        (record.amount / totalIncome) * 100 :
                        (record.amount / totalExpense) * 100
                    
                    Text(String(format: "%.1f%%", percentage))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(colorScheme == .dark ? Color(hex: "333333") : Color(hex: "f0f0f0"))
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(record.isIncome ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }
    
    // Category breakdown section
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("Category Overview", comment: "Category overview section title"))
                .font(.headline)
                .padding(.horizontal, 16)
            
            VStack(spacing: 12) {
                ForEach(Array(filteredCategoryRecords.prefix(5).enumerated()), id: \.offset) { index, record in
                    HStack(spacing: 10) {
                        // Category icon
                        ZStack {
                            Circle()
                                .fill(record.isIncome ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: categoryIcon(for: record.category))
                                .font(.system(size: 14))
                                .foregroundColor(record.isIncome ? .green : .red)
                        }
                        
                        // Category name
                        Text(localizedCategoryName(for: record.category))
                            .font(.subheadline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Spacer()
                        
                        // Amount
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatCurrency(record.amount))
                                .font(.subheadline)
                                .foregroundColor(record.isIncome ? .green : .red)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            // Percentage
                            let total = record.isIncome ? totalIncome : totalExpense
                            let percentage = total > 0 ? (record.amount / total) * 100 : 0
                            
                            Text(String(format: "%.1f%%", percentage))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedIndex == index ?
                                  (colorScheme == .dark ? Color(hex: "333333") : Color(hex: "f0f0f0")) :
                                  Color.clear)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            selectedIndex = selectedIndex == index ? nil : index
                        }
                    }
                }
                
                // More categories button if needed
                if filteredCategoryRecords.count > 5 {
                    Button {
                        // Show more categories
                    } label: {
                        Text(NSLocalizedString("View All", comment: "View all categories button"))
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.top, 8)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(hex: "222222") : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
    }
    
    // Recent transactions section
    private func recentTransactionsSection(for record: (category: String, amount: Double, isIncome: Bool)) -> some View {
        let categoryTransactions = records.filter {
            $0.category == record.category &&
            (record.isIncome ? $0.type == .income : $0.type == .expense)
        }.sorted { $0.date > $1.date }
        
        return VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("Recent Transactions", comment: "Recent transactions section title"))
                .font(.headline)
                .padding(.horizontal, 16)
            
            VStack(spacing: 12) {
                ForEach(categoryTransactions.prefix(3)) { transaction in
                    HStack(spacing: 16) {
                        // Date circle
                        VStack {
                            Text("\(calendar.component(.day, from: transaction.date))")
                                .font(.headline.bold())
                            
                            Text(shortMonthFormatter.string(from: transaction.date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(transaction.type == .income ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        )
                        
                        // Transaction details
                        VStack(alignment: .leading, spacing: 4) {
                            Text(transaction.details.isEmpty ?
                                 NSLocalizedString("No description", comment: "No description for transaction") :
                                 transaction.details)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Text(dateFormatter.string(from: transaction.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Amount
                        Text(formatCurrency(transaction.amount))
                            .font(.subheadline.bold())
                            .foregroundColor(transaction.type == .income ? .green : .red)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(hex: "2a2a2a") : Color(hex: "f9f9f9"))
                    )
                }
                
                // View all transactions button
                if categoryTransactions.count > 3 {
                    Button {
                        // Show all transactions
                    } label: {
                        HStack {
                            Text(NSLocalizedString("View All", comment: "View all transactions button"))
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.top, 8)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(hex: "222222") : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(), value: selectedIndex)
    }
    
    // MARK: - Helper Functions
    
    // Format currency with selected currency symbol
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = selectedCurrency.symbol
        formatter.maximumFractionDigits = selectedCurrency == .jpy ? 0 : 2
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(selectedCurrency.symbol)\(Int(amount))"
    }
    
    // Format short currency (for axes and labels)
    private func formatShortCurrency(_ amount: Double) -> String {
        if abs(amount) >= 1_000_000 {
            return "\(selectedCurrency.symbol)\(String(format: "%.0f", amount / 1_000_000))M"
        } else if abs(amount) >= 1_000 {
            return "\(selectedCurrency.symbol)\(String(format: "%.0f", amount / 1_000))K"
        } else {
            return "\(selectedCurrency.symbol)\(Int(amount))"
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
    
    // MARK: - Properties and States
    
    // Category filter
    @State private var categoryFilter: CategoryFilter = .all
    
    enum CategoryFilter {
        case all
        case income
        case expense
    }
    
    // Filtered category records
    private var filteredCategoryRecords: [(category: String, amount: Double, isIncome: Bool)] {
        switch categoryFilter {
        case .all:
            return categoryRecords
        case .income:
            return categoryRecords.filter { $0.isIncome }
        case .expense:
            return categoryRecords.filter { !$0.isIncome }
        }
    }
    
    // Date formatting with fix for short year issue
    private func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        let monthName = monthNamesShort[month - 1]
        return "\(monthName) \(year)"
    }
    
    // Array of short month names for more reliable formatting
    private let monthNamesShort = [
        NSLocalizedString("Jan", comment: "Short month name for January"),
        NSLocalizedString("Feb", comment: "Short month name for February"),
        NSLocalizedString("Mar", comment: "Short month name for March"),
        NSLocalizedString("Apr", comment: "Short month name for April"),
        NSLocalizedString("May", comment: "Short month name for May"),
        NSLocalizedString("Jun", comment: "Short month name for June"),
        NSLocalizedString("Jul", comment: "Short month name for July"),
        NSLocalizedString("Aug", comment: "Short month name for August"),
        NSLocalizedString("Sep", comment: "Short month name for September"),
        NSLocalizedString("Oct", comment: "Short month name for October"),
        NSLocalizedString("Nov", comment: "Short month name for November"),
        NSLocalizedString("Dec", comment: "Short month name for December")
    ]
    
    // Date formatters
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    private var shortMonthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }
    
    private var shortMonthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    private var calendar: Calendar {
        return Calendar.current
    }
    
    // Computed properties for statistics
    private var totalIncome: Double {
        records.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpense: Double {
        records.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
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
