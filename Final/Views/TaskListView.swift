import SwiftUI

struct TaskListView: View {
    @ObservedObject var firebaseManager: FirebaseManager
    @State private var showingAddTask = false
    @State private var showingChat = false
    @Binding var selectedTask: Task?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(firebaseManager.tasks) { task in
                    TaskRowView(
                        task: task,
                        firebaseManager: firebaseManager,
                        selectedTask: $selectedTask
                    )
                }
                .onDelete(perform: deleteTasks)
            }
            .navigationTitle("Задачи")
            .navigationBarItems(
                leading: Button(action: {
                    showingChat = true
                }) {
                    Image(systemName: "message.circle")
                        .imageScale(.large)
                },
                trailing: Button(action: {
                    showingAddTask = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(firebaseManager: firebaseManager)
            }
            .sheet(isPresented: $showingChat) {
                GeminiChatView() // Переход в чат
            }
        }
    }

    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            offsets.map { firebaseManager.tasks[$0] }.forEach { task in
                firebaseManager.deleteTask(task)
            }
        }
    }
}

struct TaskRowView: View {
    let task: Task
    @ObservedObject var firebaseManager: FirebaseManager
    @Binding var selectedTask: Task?
    
    private var currentTask: Task {
        return firebaseManager.tasks.first { $0.id == task.id } ?? task
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(currentTask.title)
                    .font(.headline)
                    .strikethrough(currentTask.isCompleted)
                
                Text(currentTask.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(currentTask.priority.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(currentTask.priority.color.opacity(0.2))
                        .foregroundColor(currentTask.priority.color)
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    if currentTask.position != nil {
                        Image(systemName: "arkit")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            VStack {
                Button(action: {
                    var updatedTask = currentTask
                    updatedTask.isCompleted.toggle()
                    firebaseManager.updateTask(updatedTask)
                }) {
                    Image(systemName: currentTask.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(currentTask.isCompleted ? .green : .gray)
                }
                
                Button(action: {
                    selectedTask = currentTask
                }) {
                    Image(systemName: "arkit")
                        .foregroundColor(selectedTask?.id == currentTask.id ? .blue : .gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
