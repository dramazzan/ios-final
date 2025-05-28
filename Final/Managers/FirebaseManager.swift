// FirebaseManager.swift
import SwiftUI
import Firebase
import FirebaseFirestore
import Combine

class FirebaseManager: ObservableObject {
    @Published var tasks: [Task] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    func startListening() {
        listener = db.collection("tasks")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self?.tasks = documents.compactMap { document in
                    try? document.data(as: Task.self)
                }
            }
    }
    
    func addTask(_ task: Task) {
        do {
            try db.collection("tasks").addDocument(from: task)
        } catch {
            print("Error adding task: \(error.localizedDescription)")
        }
    }
    
    func updateTask(_ task: Task) {
        guard let id = task.id else { return }
        
        do {
            try db.collection("tasks").document(id).setData(from: task)
        } catch {
            print("Error updating task: \(error.localizedDescription)")
        }
    }
    
    func deleteTask(_ task: Task) {
        guard let id = task.id else { return }
        
        db.collection("tasks").document(id).delete { error in
            if let error = error {
                print("Error deleting task: \(error.localizedDescription)")
            }
        }
    }
    
    deinit {
        listener?.remove()
    }
}
