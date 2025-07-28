import SwiftUI

struct ContentView: View {
    @State private var symbol: String = "NFLX"
    @State private var range: String = "5d"
    @State private var currentPrice: Double = 0.0
    @State private var currentPriceTime: Date? = nil
    @State private var minPrice: Double? = nil
    @State private var maxPrice: Double? = nil
    @State private var minDate: Date? = nil
    @State private var maxDate: Date? = nil
    @State private var percentChange: Double = 0.0
    @State private var manualNewPrice: String = ""
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var isEditingManualPrice = false
    @State private var earningsDate: Date? = nil

    var newPrice: Double {
        if let manual = Double(manualNewPrice), manual > 0 {
            return manual
        } else {
            return currentPrice * (1 + percentChange / 100)
        }
    }

    func percentageChange(from value: Double) -> Double {
        ((value - currentPrice) / currentPrice) * 100
    }

    var body: some View {
        NavigationView {
            Form {
                VStack {
                    HStack {
                        TextField("Symbol", text: $symbol)
                            .disableAutocorrection(true)
                            .autocapitalization(.allCharacters)
                            .onSubmit {
                                fetchStock()
                            }
                        
                        Picker("Range", selection: $range) {
                            ForEach(["1d", "5d", "1mo", "3mo", "6mo", "1y", "ytd"], id: \.self) { r in
                                Text(r).tag(r)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    Button("Update") { fetchStock() }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                        .disabled(isLoading)
                }
                
                List {
                    Section(header: Text("Current Price")) {
                        if isLoading {
                            ProgressView()
                        } else {
                            VStack(alignment: .leading) {
                                Text("\(currentPrice, specifier: "%.2f")").font(.title)
                                if let time = currentPriceTime {
                                    Text("As of: \(time.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    if let earnings = earningsDate {
                        Section(header: Text("Earnings Date")) {
                            Text(earnings.formatted(date: .abbreviated, time: .shortened))
                        }
                    }

                    if let min = minPrice, let max = maxPrice, let minD = minDate, let maxD = maxDate {
                        Section(header: Text("\(range)-Range")) {
                            HStack {
                                VStack(alignment: .leading) {
                                        Text("\(min, specifier: "%.2f")")
                                        Text(String(format: "(%.1f%%)", percentageChange(from: min)))
                                            .foregroundColor(.red)
                                        Text(minD.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("\(max, specifier: "%.2f")")
                                    Text(String(format: "(%.1f%%)", percentageChange(from: max)))
                                        .foregroundColor(.green)
                                    Text(maxD.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                }
                            }
                        }
                    }
                }.listSectionSpacing(1)
                
                Section(header: Text("% Change")) {
                    HStack {
                        Text("\(percentChange, specifier: "%.0f")%")
                        Slider(value: $percentChange, in: -20...20, step: 1)
                            .onChange(of: manualNewPrice) { oldValue, newValue in
                                isEditingManualPrice = true
                                if let val = Double(newValue) {
                                    percentChange = ((val - currentPrice) / currentPrice) * 100
                                }
                                DispatchQueue.main.async {
                                    isEditingManualPrice = false
                                }
                            }
                    }
                }

                Section(header: Text("New Price")) {
                    Stepper(value: Binding(
                        get: {
                            Double(manualNewPrice) ?? currentPrice
                        },
                        set: { newVal in
                            let rounded = roundToNearestHalf(newVal)
                            manualNewPrice = String(format: "%.2f", rounded)
                            percentChange = ((rounded - currentPrice) / currentPrice) * 100
                        }
                    ), in: 0...100000, step: 0.5) {
                        TextField("New Price", text: $manualNewPrice).font(.title)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: percentChange) { oldValue, newValue in
                                guard !isEditingManualPrice else { return }
                                let computed = currentPrice * (1 + newValue / 100)
                                let rounded = roundToNearestHalf(computed)
                                manualNewPrice = String(format: "%.2f", rounded)
                            }
                    }
                }
                }

            .navigationTitle("Stock Price Calculator")
            .alert("Invalid Symbol", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            }
            .onAppear {
                fetchStock()
            }
        }
    }
    
    func roundToNearestHalf(_ value: Double) -> Double {
        return (value * 2).rounded() / 2
    }
    
    private func fetchStock() {
        isLoading = true
        currentPrice = 0
        currentPriceTime = nil
        minPrice = nil
        maxPrice = nil
        minDate = nil
        maxDate = nil

        StockAPI.shared.fetchStockPrice(for: symbol) { price, timestamp, earnings, success, isUnauthorized in
            DispatchQueue.main.async {
                isLoading = false
                if let fetchedPrice = price {
                    currentPrice = fetchedPrice
                    currentPriceTime = timestamp
                    earningsDate = earnings
                } else if success {
                    showAlert = true
                }
            }
        }

        StockAPI.shared.fetchHistoricalPrices(for: symbol, range: range) { min, max, minD, maxD in
            DispatchQueue.main.async {
                minPrice = min
                maxPrice = max
                minDate = minD
                maxDate = maxD
            }
        }
    }
}
