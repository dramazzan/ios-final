import SwiftUI

struct TaskProgressView: View {
    @ObservedObject var firebaseManager: FirebaseManager

    var body: some View {
        let completedTasks = firebaseManager.tasks.filter { $0.isCompleted }.count
        let totalTasks = firebaseManager.tasks.count

        if totalTasks > 0 {
            VStack {
                Text("Прогресс")
                    .font(.caption)
                    .foregroundColor(.white)
                Text("\(completedTasks)/\(totalTasks)")
                    .font(.headline)
                    .foregroundColor(.white)

                ProgressView(value: Double(completedTasks), total: Double(totalTasks))
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .frame(width: 100)
            }
            .padding()
            .background(Color.black.opacity(0.6))
            .cornerRadius(10)
        }
    }
}
