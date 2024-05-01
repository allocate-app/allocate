import Cocoa
import FlutterMacOS
import macos_window_utils

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
//    let flutterViewController = FlutterViewController()
//    let windowFrame = self.frame
//    self.contentViewController = flutterViewController
//    self.setFrame(windowFrame, display: true)
//
//    RegisterGeneratedPlugins(registry: flutterViewController)
//
//    super.awakeFromNib()
      let windowFrame = self.frame
      let macOSWindowUtilsViewController = MacOSWindowUtilsViewController()
      self.contentViewController = macOSWindowUtilsViewController
      self.setFrame(windowFrame, display: true)
      MainFlutterWindowManipulator.start(mainFlutterWindow:self)
      RegisterGeneratedPlugins(registry: macOSWindowUtilsViewController.flutterViewController)
      
      super.awakeFromNib()
  }
}
