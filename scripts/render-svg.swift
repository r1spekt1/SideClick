// Renders an SVG into a square PNG with a transparent background, using WebKit.
// Usage: swift scripts/render-svg.swift <in.svg> <out.png> <size-px>
import AppKit
import WebKit

let args = CommandLine.arguments
guard args.count == 4, let size = Int(args[3]), size > 0 else {
    FileHandle.standardError.write("usage: render-svg.swift <in.svg> <out.png> <size-px>\n".data(using: .utf8)!)
    exit(2)
}
let svgURL = URL(fileURLWithPath: args[1])
let pngURL = URL(fileURLWithPath: args[2])
let svg = try String(contentsOf: svgURL, encoding: .utf8)

// The SVG is inlined and stretched to the page, whatever width/height it declares.
let html = """
<!doctype html><html><head><style>
html, body { margin: 0; background: transparent; width: \(size)px; height: \(size)px; overflow: hidden; }
svg { display: block; width: \(size)px; height: \(size)px; }
</style></head><body>\(svg)</body></html>
"""

final class Renderer: NSObject, WKNavigationDelegate {
    let webView: WKWebView
    let window: NSWindow
    let size: Int
    let output: URL

    init(size: Int, output: URL) {
        self.size = size
        self.output = output
        let frame = NSRect(x: 0, y: 0, width: size, height: size)
        webView = WKWebView(frame: frame)
        webView.setValue(false, forKey: "drawsBackground")
        window = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.contentView = webView
        super.init()
        webView.navigationDelegate = self
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let config = WKSnapshotConfiguration()
        config.rect = NSRect(x: 0, y: 0, width: size, height: size)
        webView.takeSnapshot(with: config) { image, error in
            guard let image else { fail("snapshot failed: \(error?.localizedDescription ?? "unknown")") }
            self.write(image)
            exit(0)
        }
    }

    private func write(_ image: NSImage) {
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                         colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else {
            fail("could not allocate bitmap")
        }
        rep.size = NSSize(width: size, height: size)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
        NSGraphicsContext.restoreGraphicsState()
        guard let data = rep.representation(using: .png, properties: [:]) else { fail("PNG encoding failed") }
        do { try data.write(to: output) } catch { fail("write failed: \(error.localizedDescription)") }
    }
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write("render-svg: \(message)\n".data(using: .utf8)!)
    exit(1)
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let renderer = Renderer(size: size, output: pngURL)
renderer.webView.loadHTMLString(html, baseURL: svgURL.deletingLastPathComponent())
DispatchQueue.main.asyncAfter(deadline: .now() + 20) { fail("timed out") }
app.run()
