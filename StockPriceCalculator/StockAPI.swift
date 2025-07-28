import Foundation

class StockAPI {
    static let shared = StockAPI()

    private let apiKey: String = {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["RapidAPIKey"] as? String else {
            fatalError("Missing or invalid RapidAPIKey in Secrets.plist")
        }
        return key
    }()

    private let host = "yh-finance.p.rapidapi.com"

    func fetchStockPrice(for symbol: String, completion: @escaping (Double?, Date?, Date?, Bool, Bool) -> Void) {
        let urlString = "https://yh-finance.p.rapidapi.com/market/v2/get-quotes?region=US&symbols=\(symbol)"
        guard let url = URL(string: urlString) else {
            completion(nil, nil, nil, false, false)
            return
        }

        var request = URLRequest(url: url)
        request.setValue(host, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")

        print("\n📤 Full Request:")
        print("URL: \(urlString)")
        print("Headers:")
        print("x-rapidapi-host: \(host)")
        print("x-rapidapi-key: \(apiKey)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil, nil, nil, false, false)
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("HTTP Error: \(httpResponse.statusCode)")
                print("Headers: \(httpResponse.allHeaderFields)")
                if let body = String(data: data, encoding: .utf8) {
                    print("Response body:\n\(body)")
                } else {
                    print("Unable to decode response body.")
                }

                if httpResponse.statusCode == 401 {
                    completion(nil, nil, nil, false, true)
                } else {
                    completion(nil, nil, nil, false, false)
                }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("\n📝 Stock Price Response:\n\(json)")
                }
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let quoteResponse = json["quoteResponse"] as? [String: Any],
                   let results = quoteResponse["result"] as? [[String: Any]],
                   let first = results.first,
                   let rawPrice = first["regularMarketPrice"] as? Double,
                   let regTime = first["regularMarketTime"] as? TimeInterval {

                    let priceDate = Date(timeIntervalSince1970: regTime)

                    let earningsDate: Date? = {
                        if let ts = first["earningsTimestampStart"] as? TimeInterval {
                            return Date(timeIntervalSince1970: ts)
                        }
                        return nil
                    }()

                    completion(rawPrice, priceDate, earningsDate, true, false)
                } else {
                    print("API returned valid HTTP response but missing expected fields — likely invalid symbol")
                    completion(nil, nil, nil, true, false)
                }
            } catch {
                print("JSON parse error: \(error.localizedDescription)")
                completion(nil, nil, nil, false, false)
            }
        }.resume()
    }


    func fetchHistoricalPrices(for symbol: String, range: String, completion: @escaping (Double?, Double?, Date?, Date?) -> Void){
        let urlString = "https://yh-finance.p.rapidapi.com/stock/v3/get-chart?interval=1d&range=\(range)&region=US&symbol=\(symbol)"
        print(urlString)
        guard let url = URL(string: urlString) else {
            completion(nil, nil, nil, nil)
            return
        }

        var request = URLRequest(url: url)
        request.setValue(host, forHTTPHeaderField: "x-rapidapi-host")
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, nil, nil, nil)
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("\n\u{1F4DD} Historical Prices Response:\n\(json)")

                    if let chart = json["chart"] as? [String: Any],
                       let result = (chart["result"] as? [[String: Any]])?.first,
                       let timestamp = result["timestamp"] as? [TimeInterval],
                       let indicators = result["indicators"] as? [String: Any],
                       let quote = (indicators["quote"] as? [[String: Any]])?.first,
                       let closes = quote["close"] as? [Double?] {

                        let paired = zip(timestamp, closes).compactMap { ts, close in
                            if let c = close { return (ts, c) } else { return nil }
                        }

                        if let minPair = paired.min(by: { $0.1 < $1.1 }),
                           let maxPair = paired.max(by: { $0.1 < $1.1 }) {
                            completion(minPair.1, maxPair.1, Date(timeIntervalSince1970: minPair.0), Date(timeIntervalSince1970: maxPair.0))
                        } else {
                            completion(nil, nil, nil, nil)
                        }
                    } else {
                        completion(nil, nil, nil, nil)
                    }
                } else {
                    completion(nil, nil, nil, nil)
                }
            } catch {
                print("Error decoding historical prices JSON: \(error.localizedDescription)")
                completion(nil, nil, nil, nil)
            }
        }.resume()
    }
}
