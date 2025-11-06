import Foundation
import Carbon
import AppKit

@MainActor
class HotkeyManager {
    weak var panelController: OmniPanelController?
    private var eventHandler: EventHandlerRef?
    
    // --- THIS IS THE FIX ---
    // This "lock" prevents the hotkey from firing a dozen times
    // if you press it rapidly.
    private var isCapturingContext = false
    // --- END OF FIX ---
    
    init(panelController: OmniPanelController?) {
        self.panelController = panelController
    }
    
    func registerHotkey() {
        let hotKeyID = EventHotKeyID(signature: FourCharCode("omni".fourCharCodeValue), id: 1)
        var eventHotKey: EventHotKeyRef?
        let keyCode = UInt32(kVK_Space)
        let modifiers = UInt32(optionKey)
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &eventHotKey
        )
        
        if status != noErr {
            print("Failed to register hotkey")
            return
        }
        
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let callback: EventHandlerUPP = { _, event, userData in
            guard let userData = userData else { return noErr }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            
            // --- MODIFICATION START ---
            
            // If we are already busy, ignore this key press.
            guard !manager.isCapturingContext else {
                print("Hotkey pressed, but context capture is already in progress. Ignoring.")
                return noErr
            }
            
            // Set the lock
            manager.isCapturingContext = true
            
            ContextCaptureService.shared.captureCurrentContext { [weak manager] capturedText in
                if let text = capturedText, !text.isEmpty {
                    print("--- OMNI: CONTEXT CAPTURED ---")
                    print(text)
                    print("---------------------------------")
                } else {
                    print("--- OMNI: CONTEXT CAPTURED ---")
                    print("No text was captured from the active window.")
                    print("---------------------------------")
                }
                
                // TODO: Pass 'capturedText' to the panelController
                
                // Toggle the panel
                manager?.panelController?.toggle()
                
                // --- THIS IS THE FIX ---
                // Release the lock so the hotkey can be used again.
                manager?.isCapturingContext = false
                // --- END OF FIX ---
            }
            // --- MODIFICATION END ---
            
            return noErr
        }
        
        InstallEventHandler(
            GetEventDispatcherTarget(),
            callback,
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
    }
    
    deinit {
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
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
