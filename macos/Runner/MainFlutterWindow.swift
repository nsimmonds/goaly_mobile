import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    // Set minimum window size to ensure all content is visible
    // Using typical phone dimensions (similar to iPhone 14/15)
    self.minSize = NSSize(width: 390, height: 844)

    // Set initial window size if not already set
    if windowFrame.size.height < 844 || windowFrame.size.width < 390 {
      let newFrame = NSRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: 390, height: 844)
      self.setFrame(newFrame, display: true)
    }
  }
}
