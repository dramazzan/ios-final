import SwiftUI

struct AddTaskView: View {
    @ObservedObject var firebaseManager: FirebaseManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var description = ""
    @State private var priority: Task.Priority = .medium
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Информация о задаче")) {
                    TextField("Название", text: $title)
                    TextField("Описание", text: $description)
                    
                    Picker("Приоритет", selection: $priority) {
                        ForEach(Task.Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Новая задача")
            .navigationBarItems(
                leading: Button("Отмена") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Сохранить") {
                    saveTask()
                }
                .disabled(title.isEmpty)
            )
        }
    }
    
    private func saveTask() {
        let newTask = Task(
            title: title,
            description: description,
            isCompleted: false,
            priority: priority,
            createdAt: Date(),
            position: nil
        )
        
        firebaseManager.addTask(newTask)
        presentationMode.wrappedValue.dismiss()
    }
}
