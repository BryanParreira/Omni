import Foundation
import Carbon
import AppKit

@MainActor
class HotkeyManager {
    weak var panelController: OmniPanelController?
    
    // Stored references for our hotkeys
    private var panelToggleHotKeyRef: EventHotKeyRef?
    
    // ONE shared event handler
    private var eventHandler: EventHandlerRef?
    
    // Define your hotkeys
    private let panelToggleHotKeyID = EventHotKeyID(signature: FourCharCode("omni".fourCharCodeValue), id: 1)
    
    init(panelController: OmniPanelController?) {
        self.panelController = panelController
    }
    
    // This is the ONLY public function you call from AppDelegate
    func registerAllHotkeys() {
        // --- 1. Register Panel Toggle Hotkey ---
        let panelKeyCode = UInt32(kVK_Space)
        let panelModifiers = UInt32(optionKey) // Option+Space
        
        let status = RegisterEventHotKey(
            panelKeyCode,
            panelModifiers,
            panelToggleHotKeyID,
            GetEventDispatcherTarget(),
            0,
            &panelToggleHotKeyRef // Store the reference
        )
        
        if status != noErr {
            print("❌ ERROR: Failed to register panel toggle hotkey (Option+Space). Status: \(status)")
        } else {
            print("✅ Panel toggle hotkey registered.")
        }

        // --- 2. Install ONE handler ---
        installSharedEventHandler()
    }
    
    private func installSharedEventHandler() {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let callback: EventHandlerUPP = { _, event, userData in
            guard let userData = userData else { return noErr }
            
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            
            var hotKeyID = EventHotKeyID()
            GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            // --- THIS IS THE ROUTER ---
            // It checks the ID and runs the correct code
            switch hotKeyID.id {
                
            case manager.panelToggleHotKeyID.id:
                print("🔥 Panel toggle hotkey pressed!")
                manager.panelController?.toggle()
                
            default:
                break
            }
            
            return noErr
        }
        
        // Install the SINGLE handler
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            callback,
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
        
        if status != noErr {
            print("❌ ERROR: Failed to install shared event handler. Status: \(status)")
        } else {
            print("✅ Shared hotkey event handler installed.")
        }
    }

    // This method is now nonisolated, so it can be called from deinit.
    nonisolated func unregisterAllHotkeys() {
        // We dispatch the actual cleanup work to the MainActor.
        Task { @MainActor in
            if let handler = self.eventHandler {
                RemoveEventHandler(handler)
                self.eventHandler = nil
            }
            
            if let hotKeyRef = self.panelToggleHotKeyRef {
                UnregisterEventHotKey(hotKeyRef)
                self.panelToggleHotKeyRef = nil
            }
            
            print("⌨️ All hotkeys and handlers unregistered.")
        }
    }
    
    deinit {
        // This is now a safe nonisolated-to-nonisolated call.
        unregisterAllHotkeys()
    }
}

extension String {
    var fourCharCodeValue: FourCharCode {
        var result: FourCharCode = 0
        for char in self.utf8.prefix(4) {
            result = (result << 8) + FourCharCode(char)
        }
        return result
    }
}
