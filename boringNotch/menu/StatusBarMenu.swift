import Cocoa

class BoringStatusMenu: NSMenu {
    override init(title: String) {
        super.init(title: title)
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
}
