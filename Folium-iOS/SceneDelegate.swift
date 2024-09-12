//
//  SceneDelegate.swift
//  Folium
//
//  Created by Jarrod Norwell on 2/7/2024.
//

import AppleArchive
import Accelerate
import DirectoryManager
import Firebase
import FirebaseAuth
import LayoutManager
import System
import UIKit

enum ApplicationState : Int {
    case backgrounded = 0
    case foregrounded = 1
    case disconnected = 2
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        FirebaseApp.configure()
        
        guard let windowScene = scene as? UIWindowScene else {
            return
        }
        
        window = .init(windowScene: windowScene)
        guard let window else {
            return
        }
        
        window.tintColor = .systemGreen

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? NSString
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        
        if let version, let build {
            let currentlyInstalledVersion = "\(version).\(build)"
            let currentlySavedVersion = UserDefaults.standard.string(forKey: "currentlySavedVersion")
            
            if version.doubleValue >= 1.10 {
                if currentlySavedVersion == nil || currentlySavedVersion != currentlyInstalledVersion {
                    UserDefaults.standard.setValue(currentlyInstalledVersion, forKey: "currentlySavedVersion")
                }
                
                try? configureMissingDirectories(for: LibraryManager.shared.cores.map { $0.rawValue })
                configureAuthenticationStateListener()
            } else {
                fallbackToArchiveFeature(window, currentlySavedVersion, currentlyInstalledVersion)
            }
        }
        
        configureDefaultUserDefaults()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
        NotificationCenter.default.post(name: .init("applicationStateDidChange"), object: ApplicationState.disconnected)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        NotificationCenter.default.post(name: .init("applicationStateDidChange"), object: ApplicationState.foregrounded)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        NotificationCenter.default.post(name: .init("applicationStateDidChange"), object: ApplicationState.backgrounded)
    }
}

extension SceneDelegate {
    fileprivate func configureAuthenticationStateListener() {
        guard let window else {
            return
        }
        
        _ = Auth.auth().addStateDidChangeListener { auth, user in
            if let rootViewController = window.rootViewController {
                let viewController = if AppStoreCheck.shared.additionalFeaturesAreAllowed {
                    if user == nil, !UserDefaults.standard.bool(forKey: "userSkippedAuthentication") {
                        AuthenticationController()
                    } else {
                        UINavigationController(rootViewController: LibraryController(collectionViewLayout: LayoutManager.shared.library))
                    }
                } else {
                    UINavigationController(rootViewController: LibraryController(collectionViewLayout: LayoutManager.shared.library))
                }
                
                viewController.modalPresentationStyle = .fullScreen
                rootViewController.present(viewController, animated: true)
            } else {
                window.rootViewController = if AppStoreCheck.shared.additionalFeaturesAreAllowed {
                    if user == nil, !UserDefaults.standard.bool(forKey: "userSkippedAuthentication") {
                        AuthenticationController()
                    } else {
                        UINavigationController(rootViewController: LibraryController(collectionViewLayout: LayoutManager.shared.library))
                    }
                } else {
                    UINavigationController(rootViewController: LibraryController(collectionViewLayout: LayoutManager.shared.library))
                }
                
                window.makeKeyAndVisible()
            }
        }
    }
    
    func configureMissingDirectories(for cores: [String]) throws {
        try DirectoryManager.shared.createMissingDirectoriesInDocumentsDirectory(for: cores)
    }
    
    fileprivate func configureDefaultUserDefaults() {
        let defaults: [String : [String : Any]] = [
            "Cytrus" : [
                "cpuClockPercentage" : 100,
                "new3DS" : true,
                "lleApplets" : false,
                "regionValue" : -1,
                
                "spirvShaderGeneration" : true,
                "useAsyncShaderCompilation" : false,
                "useAsyncPresentation" : true,
                "useHardwareShaders" : true,
                "useDiskShaderCache" : true,
                "useShadersAccurateMul" : false,
                "useNewVSync" : true,
                "useShaderJIT" : false,
                "resolutionFactor" : 1,
                "textureFilter" : 0,
                "textureSampling" : 0,
                "render3D" : 0,
                "factor3D" : 0,
                "monoRender" : 0,
                "preloadTextures" : false,
                
                "audioMuted" : false,
                "audioEmulation" : 0,
                "audioStretching" : true,
                "realtimeAudio" : false,
                "outputType" : 0,
                "inputType" : 0,
                
                "hardwareVertexShaders" : false,
                "surfaceTextureCopy" : false,
                "flushCPUWrite" : false,
                "priorityBoostStarvedThreads" : true,
                "reduceDowncountSlice" : false
            ],
            "Grape" : [
                "directBoot" : true,
                "threaded2D" : true,
                "threaded3D" : true
            ]
        ]
        
        defaults.forEach { core, values in
            values.forEach { key, value in
                if UserDefaults.standard.value(forKey: "\(core.lowercased()).\(key)") == nil {
                    UserDefaults.standard.set(value, forKey: "\(core.lowercased()).\(key)")
                }
            }
        }
    }
    
    
    fileprivate func fallbackToArchiveFeature(_ window: UIWindow, _ currentlySavedVersion: String?, _ currentlyInstalledVersion: String?) {
        if currentlySavedVersion == nil || currentlySavedVersion != currentlyInstalledVersion {
            UserDefaults.standard.setValue(currentlyInstalledVersion, forKey: "currentlySavedVersion")
            
            if !FileManager.default.fileExists(atPath: FileManager.default.urls(for: .documentDirectory,
                                                                                in: .userDomainMask)[0].appending(component: "archive.aar").path) {
                window.rootViewController = ArchiveController()
                window.makeKeyAndVisible()
            } else {
                try? configureMissingDirectories(for: LibraryManager.shared.cores.map { $0.rawValue })
                configureAuthenticationStateListener()
            }
        } else {
            try? configureMissingDirectories(for: LibraryManager.shared.cores.map { $0.rawValue })
            configureAuthenticationStateListener()
        }
    }
}
