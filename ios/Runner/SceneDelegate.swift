import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
    private var privacyCovers: [UIView] = []

    override func sceneWillResignActive(_ scene: UIScene) {
        if let windowScene = scene as? UIWindowScene {
            for window in windowScene.windows {
                let cover = UIView(frame: window.bounds)
                cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                cover.backgroundColor = .systemBackground
                let label = UILabel(frame: cover.bounds)
                label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                label.text = "SUSPECTO"
                label.textAlignment = .center
                label.font = .boldSystemFont(ofSize: 28)
                cover.addSubview(label)
                window.addSubview(cover)
                privacyCovers.append(cover)
            }
        }
        super.sceneWillResignActive(scene)
    }

    override func sceneDidBecomeActive(_ scene: UIScene) {
        privacyCovers.forEach { $0.removeFromSuperview() }
        privacyCovers.removeAll()
        super.sceneDidBecomeActive(scene)
    }
}
