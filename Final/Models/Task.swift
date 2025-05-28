// Task.swift
import SwiftUI
import Firebase
import FirebaseFirestore

struct Task: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var isCompleted: Bool
    var priority: Priority
    var createdAt: Date
    var position: SIMD3<Float>?
    
    enum Priority: String, CaseIterable, Codable {
        case low = "Низкий"
        case medium = "Средний"
        case high = "Высокий"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
}
