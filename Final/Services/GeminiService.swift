import Foundation

class GeminiService {
    private let apiKey = "AIzaSyA3gskqiD4MmXtf9QxHQzTWcl2hFBwa-fU"
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key="

    func sendMessage(_ message: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(endpoint)\(apiKey)") else {
            completion("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                [
                    // По твоему curl-запросу, role не передаётся — можно не указывать
                    "parts": [
                        ["text": message]
                    ]
                ]
            ]
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            completion("Failed to serialize JSON")
            return
        }

        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion("Request error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                completion("No data received")
                return
            }

            // Парсим JSON-ответ
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let first = candidates.first,
                   let content = first["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let text = parts.first?["text"] as? String {
                    completion(text)
                } else {
                    completion("Invalid response format")
                }
            } catch {
                completion("JSON parsing error: \(error.localizedDescription)")
            }
        }.resume()
    }
}
