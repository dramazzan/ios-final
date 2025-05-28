import SwiftUI
import ARKit
import RealityKit

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var firebaseManager: FirebaseManager
    @ObservedObject var coordinator: ARCoordinator
    @Binding var selectedTask: Task?

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)
        arView.session.delegate = context.coordinator

        // Добавляем жесты
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)

        let rotationGesture = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleRotation(_:)))
        arView.addGestureRecognizer(rotationGesture)

        context.coordinator.arView = arView
        context.coordinator.parent = self

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.parent = self

        if selectedTask == nil {
            updateARContent(in: uiView, coordinator: context.coordinator)
        }
    }

    func makeCoordinator() -> ARViewCoordinator {
        ARViewCoordinator()
    }

    private func updateARContent(in arView: ARView, coordinator: ARViewCoordinator) {
        coordinator.placedTasks.values.forEach { entity in
            entity.removeFromParent()
        }
        coordinator.placedTasks.removeAll()

        for task in firebaseManager.tasks {
            if let position = task.position, let taskId = task.id {
                let entity = coordinator.createTaskEntity(for: task)
                entity.position = position

                entity.scale = SIMD3<Float>(repeating: coordinator.currentScale)

                let anchor = AnchorEntity(world: position)
                anchor.addChild(entity)
                arView.scene.addAnchor(anchor)

                coordinator.placedTasks[taskId] = entity
            }
        }
    }

    class ARViewCoordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer!
        var placedTasks: [String: Entity] = [:]
        weak var arView: ARView?

        var currentScale: Float = 1.0
        var minScale: Float = 0.5
        var maxScale: Float = 3.0

        // Поворот
        var currentRotation: Float = 0.0

        func createTaskEntity(for task: Task) -> Entity {
            let containerEntity = Entity()

            let mesh = MeshResource.generateBox(size: 0.1)

            let color: UIColor
            if task.isCompleted {
                color = .green
            } else {
                switch task.priority {
                case .high:
                    color = .red
                case .medium:
                    color = .orange
                case .low:
                    color = .blue
                }
            }

            let material = SimpleMaterial(color: color, isMetallic: false)
            let cubeEntity = ModelEntity(mesh: mesh, materials: [material])

            let textMesh = MeshResource.generateText(
                task.title,
                extrusionDepth: 0.01,
                font: .systemFont(ofSize: 0.05),
                containerFrame: CGRect.zero,
                alignment: .center,
                lineBreakMode: .byWordWrapping
            )

            let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
            let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])

            textEntity.position = SIMD3<Float>(0, 0.1, 0)

            containerEntity.addChild(cubeEntity)
            containerEntity.addChild(textEntity)

            return containerEntity
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }

            let location = gesture.location(in: arView)

            if let raycastResult = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first {
                let position = raycastResult.worldTransform.translation

                if var selectedTask = parent.selectedTask {
                    selectedTask.position = position

                    DispatchQueue.main.async {
                        self.parent.firebaseManager.updateTask(selectedTask)
                        self.parent.selectedTask = nil
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let arView = self.arView {
                            self.parent.updateARContent(in: arView, coordinator: self)
                        }
                    }
                }
            }
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }

            switch gesture.state {
            case .changed:
                let newScale = currentScale * Float(gesture.scale)
                let clampedScale = max(minScale, min(maxScale, newScale))
                for entity in placedTasks.values {
                    entity.scale = SIMD3<Float>(repeating: clampedScale)
                }
            case .ended, .cancelled:
                let newScale = currentScale * Float(gesture.scale)
                currentScale = max(minScale, min(maxScale, newScale))
                gesture.scale = 1.0
            default:
                break
            }
        }

        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }

            switch gesture.state {
            case .changed:
                let deltaRotation = Float(gesture.rotation)
                for entity in placedTasks.values {
                    entity.transform.rotation *= simd_quatf(angle: deltaRotation, axis: [0, 1, 0])
                }
                gesture.rotation = 0 // Сбросить поворот после применения
            default:
                break
            }
        }

        func setScale(_ scale: Float) {
            currentScale = max(minScale, min(maxScale, scale))
            for entity in placedTasks.values {
                entity.scale = SIMD3<Float>(repeating: currentScale)
            }
        }

        func resetScale() {
            setScale(1.0)
        }
    }
}

// MARK: - Extensions
extension simd_float4x4 {
    var translation: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}

// MARK: - Дополнительный SwiftUI View для управления зумом
struct ARZoomControls: View {
    let coordinator: ARViewContainer.ARViewCoordinator

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                VStack(spacing: 10) {
                    Button(action: {
                        let newScale = coordinator.currentScale * 1.2
                        coordinator.setScale(newScale)
                    }) {
                        Image(systemName: "plus.magnifyingglass")
                            .foregroundColor(.white)
                            .font(.title2)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }

                    Button(action: {
                        coordinator.resetScale()
                    }) {
                        Image(systemName: "1.magnifyingglass")
                            .foregroundColor(.white)
                            .font(.title2)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }

                    Button(action: {
                        let newScale = coordinator.currentScale * 0.8
                        coordinator.setScale(newScale)
                    }) {
                        Image(systemName: "minus.magnifyingglass")
                            .foregroundColor(.white)
                            .font(.title2)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding(.trailing, 20)
            }
            .padding(.bottom, 50)
        }
    }
}
