import SwiftUI

struct ContentView: View {
    @StateObject private var firebaseManager = FirebaseManager()
    @StateObject private var arCoordinator = ARCoordinator()
    @State private var selectedTask: Task?
    @State private var showingTaskList = false
    
    var body: some View {
        ZStack {
            if arCoordinator.isARSupported {
                ARViewContainer(
                    firebaseManager: firebaseManager,
                    coordinator: arCoordinator,
                    selectedTask: $selectedTask
                )
                .edgesIgnoringSafeArea(.all)
                
            } else {
                Text("AR не поддерживается на этом устройстве")
                    .foregroundColor(.red)
                    .padding()
            }
            
            VStack {
                HStack {
                    Button(action: {
                        showingTaskList = true
                    }) {
                        Image(systemName: "list.bullet")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    if let selectedTask = selectedTask {
                        VStack {
                            Text("Выбрана задача:")
                                .font(.caption)
                                .foregroundColor(.white)
                            Text(selectedTask.title)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Нажмите на поверхность для размещения")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                        
                        Button("Отмена") {
                            self.selectedTask = nil
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.6))
                        .cornerRadius(10)
                    }
                }
                .padding()
                
                Spacer()
                
                TaskProgressView(firebaseManager: firebaseManager)
                    .padding(.bottom)
            }
        }
        .sheet(isPresented: $showingTaskList) {
            TaskListView(firebaseManager: firebaseManager, selectedTask: $selectedTask)
        }
        .onAppear {
            firebaseManager.startListening()
        }
    }
}
