import Alamofire
import Foundation

class GeminiService {
    private let apiKey: String
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key="

    init() {
        if let key = Bundle.main.infoDictionary?["API_KEY"] as? String {
            self.apiKey = key
        } else {
            self.apiKey = ""
            print("⚠️ API_KEY not found in Info.plist")
        }
    }

    func sendMessage(_ message: String, completion: @escaping (String?) -> Void) {
        guard !apiKey.isEmpty else {
            completion("API key is missing")
            return
        }

        let url = "\(endpoint)\(apiKey)"
        let parameters: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": message]
                    ]
                ]
            ]
        ]

        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let data):
                    if let json = data as? [String: Any],
                       let candidates = json["candidates"] as? [[String: Any]],
                       let first = candidates.first,
                       let content = first["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]],
                       let text = parts.first?["text"] as? String {
                        completion(text)
                    } else {
                        completion("Invalid response format")
                    }
                case .failure(let error):
                    completion("Request failed: \(error.localizedDescription)")
                }
            }
    }
}
