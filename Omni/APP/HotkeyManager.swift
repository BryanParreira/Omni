import Foundation
import Carbon
import AppKit

@MainActor
class HotkeyManager {
    weak var panelController: OmniPanelController?
    private var eventHandler: EventHandlerRef?
    
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
            
            // Now it just toggles the panel.
            manager.panelController?.toggle()
            
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
