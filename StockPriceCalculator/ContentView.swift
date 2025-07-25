import SwiftUI

struct ContentView: View {
    @State private var symbol: String = "NFLX"
    @State private var dateRange: Int = 10
    @State private var rangeUnit: String = "Days"
    @State private var currentPrice: Double = 0.0
    @State private var currentPriceTime: Date? = nil
    @State private var minPrice: Double? = nil
    @State private var maxPrice: Double? = nil
    @State private var minDate: Date? = nil
    @State private var maxDate: Date? = nil
    @State private var percentChange: Double = 0.0
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false

    var effectiveDays: Int {
        rangeUnit == "Weeks" ? dateRange * 7 : dateRange
    }

    var newPrice: Double {
        currentPrice * (1 + percentChange / 100)
    }

    func percentageChange(from value: Double) -> Double {
        ((value - currentPrice) / currentPrice) * 100
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Symbol")) {
                    TextField("Symbol", text: $symbol)
                        .disableAutocorrection(true)
                        .autocapitalization(.allCharacters)
                        .onSubmit {
                            fetchStock()
                        }
                }

                Section(header: Text("Date Range")) {
                    Picker("Date Range", selection: $dateRange) {
                        ForEach([5, 10, 15, 30], id: \.self) { range in
                            Text("\(range) \(rangeUnit.lowercased())").tag(range)
                        }
                    }
                    .pickerStyle(.menu) 

                    Picker("Range Unit", selection: $rangeUnit) {
                        Text("Days").tag("Days")
                        Text("Weeks").tag("Weeks")
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Current Price")) {
                    if isLoading {
                        ProgressView()
                    } else {
                        VStack(alignment: .leading) {
                            Text("\(currentPrice, specifier: "%.2f")")
                            if let time = currentPriceTime {
                                Text("As of: \(time.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }

                if let min = minPrice, let max = maxPrice, let minD = minDate, let maxD = maxDate {
                    Section(header: Text("\(effectiveDays)-Day Range")) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Min: \(min, specifier: "%.2f")")
                                Text(minD.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text(String(format: "(%.1f%%)", percentageChange(from: min)))
                                .foregroundColor(.red)
                        }
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Max: \(max, specifier: "%.2f")")
                                Text(maxD.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text(String(format: "(%.1f%%)", percentageChange(from: max)))
                                .foregroundColor(.green)
                        }
                    }
                }

                Section(header: Text("% Change")) {
                    HStack {
                        Text("\(percentChange, specifier: "%.0f")%")
                        Slider(value: $percentChange, in: -20...20, step: 1)
                    }
                }

                Section(header: Text("New Price")) {
                    Text("\(newPrice, specifier: "%.2f")")
                        .font(.title)
                        .foregroundColor(.blue)
                }

                Button("Update Price") {
                    fetchStock()
                }
                .disabled(isLoading)
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

    private func fetchStock() {
        isLoading = true
        currentPrice = 0
        currentPriceTime = nil
        minPrice = nil
        maxPrice = nil
        minDate = nil
        maxDate = nil

        StockAPI.shared.fetchStockPrice(for: symbol) { price, timestamp, success, isUnauthorized in
            DispatchQueue.main.async {
                isLoading = false
                if let fetchedPrice = price {
                    currentPrice = fetchedPrice
                    currentPriceTime = timestamp
                } else if success {
                    showAlert = true
                }
            }
        }

        StockAPI.shared.fetchHistoricalPrices(for: symbol, daysBack: effectiveDays) { min, max, minD, maxD in
            DispatchQueue.main.async {
                minPrice = min
                maxPrice = max
                minDate = minD
                maxDate = maxD
            }
        }
    }
}
