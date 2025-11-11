import Foundation
import Carbon
import AppKit

@MainActor
class HotkeyManager {
    weak var panelController: OmniPanelController?
    private var eventHandler: EventHandlerRef?
    private var textCaptureEventHandler: EventHandlerRef?
    
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
            
            // Check which hotkey was pressed
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
            
            if hotKeyID.id == 1 {
                // Original panel toggle hotkey
                manager.panelController?.toggle()
            }
            
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
    
    func registerTextCaptureHotkey() {
        let hotKeyID = EventHotKeyID(signature: FourCharCode("omnt".fourCharCodeValue), id: 2)
        var eventHotKey: EventHotKeyRef?
        let keyCode = UInt32(kVK_ANSI_X) // "X" key
        let modifiers = UInt32(cmdKey | optionKey) // Cmd+Option
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &eventHotKey
        )
        
        if status != noErr {
            print("Failed to register text capture hotkey")
            return
        }
        
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let callback: EventHandlerUPP = { _, event, userData in
            guard let userData = userData else { return noErr }
            
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            
            // Check which hotkey was pressed
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
            
            if hotKeyID.id == 2 {
                // Text capture hotkey
                print("🔥 Text capture hotkey pressed!")
                
                // Capture selected text
                guard let selectedText = HotkeyHelper.shared.captureSelectedText() else {
                    print("⚠️ No text selected")
                    return noErr
                }
                
                print("📋 Captured text: \(selectedText.prefix(50))...")
                
                // Handle the captured text
                Task { @MainActor in
                    manager.panelController?.handleCapturedText(selectedText)
                }
            }
            
            return noErr
        }
        
        InstallEventHandler(
            GetEventDispatcherTarget(),
            callback,
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &textCaptureEventHandler
        )
        
        print("✅ Text capture hotkey registered: Cmd+Shift+T")
    }
    
    deinit {
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
        if let handler = textCaptureEventHandler {
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
