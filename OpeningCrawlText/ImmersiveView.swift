
import SwiftUI
import RealityKit
import RealityKitContent

import ARKit

struct ImmersiveView: View {
    
    let worldTrackingProvider = WorldTrackingProvider()
    let arkitSession = ARKitSession()
    
    var body: some View {
        ZStack {
            RealityView { content in
                let textEntity = generateCrawlingText()
                
                content.add(textEntity)
                
                _ = try? await arkitSession.run([worldTrackingProvider])
            } update: { content in
                
                guard let entity = content.entities.first(where: { $0.name == .textEntityName}) else { return }
                
                if let pose = worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) {
                    entity.position = .init(
                        x: pose.originFromAnchorTransform.columns.3.x,
                        y: pose.originFromAnchorTransform.columns.3.y,
                        z: pose.originFromAnchorTransform.columns.3.z
                    )
                }
                
                if let modelEntity = entity as? ModelEntity {
                    let rotation = Transform(rotation: simd_quatf(angle: -.pi / 6, axis: [1, 0, 0])) // Adjust angle as needed
                    modelEntity.transform = Transform(matrix: rotation.matrix * modelEntity.transform.matrix)
                    
                    let animationDuration: Float = 60.0  // Adjust the duration as needed
                    let moveUp = Transform(scale: .one, translation: [0, 2, 0])
                    modelEntity.move(to: moveUp, relativeTo: modelEntity, duration: TimeInterval(animationDuration), timingFunction: .linear)
                }
            }
            
            Starfield()
        }
    }
    
    private func generateCrawlingText() -> ModelEntity {
        let text = MeshResource.generateText(
            .sample,
            extrusionDepth: 0.005,
            font: .systemFont(ofSize: 0.1),
            containerFrame: .init(x: -1, y: -10, width: 2, height: 10),
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        
        let textColor = UIColor(red: 255/255, green: 232/255, blue: 31/255, alpha: 1.0)
        
        let entity = ModelEntity(mesh: text)
        
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: textColor)
        material.emissiveColor = .init(color: textColor.withAlphaComponent(0.5))
        material.emissiveIntensity = 0.5
        
        entity.model?.materials = [material]
        entity.name = .textEntityName
        entity.model?.mesh = text
        
        return entity
    }
}

private extension String {
    static let sample = """
It is a period of civil war.
Rebel spaceships, striking
from a hidden base, have won
their first victory against
the evil Galactic Empire.

During the battle, Rebel
spies managed to steal secret
plans to the Empire's
ultimate weapon, the DEATH
STAR, an armored space
station with enough power to
destroy an entire planet.

Pursued by the Empire's
sinister agents, Princess
Leia races home aboard her
starship, custodian of the
stolen plans that can save
her people and restore
freedom to the galaxy....
"""
    
    static let textEntityName = "CrawlingText"
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
