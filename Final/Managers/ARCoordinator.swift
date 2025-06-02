import SwiftUI
import ARKit
import RealityKit

class ARCoordinator: NSObject, ObservableObject, ARSessionDelegate {
    @Published var isARSupported = ARWorldTrackingConfiguration.isSupported
    @Published var placedTasks: [String: Entity] = [:]
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("AR Session failed: \(error.localizedDescription)")
    }
    
    func createTaskEntity(for task: Task) -> Entity {
        let entity = Entity()
        
        let mesh = MeshResource.generateBox(size: 0.1)
        let material = SimpleMaterial(color: UIColor(task.priority.color), isMetallic: false)
        let modelComponent = ModelComponent(mesh: mesh, materials: [material])
        
        entity.components.set(modelComponent)
        entity.components.set(CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])]))
        
        let textMesh = MeshResource.generateText(
            task.title,
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: 0.05)
        )
        let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let textEntity = Entity()
        textEntity.components.set(ModelComponent(mesh: textMesh, materials: [textMaterial]))
        textEntity.position.y = 0.08
        
        entity.addChild(textEntity)
        
        return entity
    }
}
