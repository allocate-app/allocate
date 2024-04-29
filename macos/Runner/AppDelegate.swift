import Cocoa
import FlutterMacOS

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }



  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
//       if !flag {
//           for window in NSApp.windows {
//               if !window.isVisible {
//                   window.setIsVisible(true)
//               }
//
//               window.makeKeyAndOrderFront(self)
//               NSApp.activate(ignoringOtherApps: true)
//           }
//       }
      if let window = sender.windows.first{
        if flag{
            window.orderFront(nil)
        }else{
            window.makeKeyAndOrderFront(nil)
        }
      }
      return true
  }

}
