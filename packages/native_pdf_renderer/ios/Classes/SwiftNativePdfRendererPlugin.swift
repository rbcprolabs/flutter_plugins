import Flutter
import UIKit
import CoreGraphics

public class SwiftNativePdfRendererPlugin: NSObject, FlutterPlugin {
    static let invalid = NSNumber(value: -1)
    let dispQueue = DispatchQueue(label: "io.scer.native_pdf_renderer")

    let documents = DocumentRepository()
    let pages = PageRepository()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "io.scer.native_pdf_renderer", binaryMessenger: registrar.messenger())
        let instance = SwiftNativePdfRendererPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "open.document.data": openDocumentDataHandler(call: call, result: result)
        case "open.document.file": openDocumentFileHandler(call: call, result: result)
        case "open.document.asset": openDocumentAssetHandler(call: call, result: result)
        case "open.page": openPageHandler(call: call, result: result)
        case "close.document": closeDocumentHandler(call: call, result: result)
        case "close.page": closePageHandler(call: call, result: result)
        case "render": renderHandler(call: call, result: result)
        default: result(FlutterMethodNotImplemented)
        }
    }

    func openDocumentDataHandler(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void {
        guard let data = call.arguments as! FlutterStandardTypedData? else {
            return result(FlutterError(code: "RENDER_ERROR",
                                       message: "Arguments not sended",
                                       details: nil))
        }
        guard let renderer = openDataDocument(data: data.data) else {
            return result(FlutterError(code: "RENDER_ERROR",
                                       message: "Invalid PDF format",
                                       details: nil))
        }
        result(documents.register(renderer: renderer).infoMap as NSDictionary)
    }

    func openDocumentFileHandler(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void {
        guard let pdfFilePath = call.arguments as! String? else {
            return result(FlutterError(code: "RENDER_ERROR",
                                       message: "Arguments not sended",
                                       details: nil))
        }
        guard let renderer = openFileDocument(pdfFilePath: pdfFilePath)  else {
            return result(FlutterError(code: "RENDER_ERROR",
                                       message: "Invalid PDF format",
                                       details: nil))
        }
        result(documents.register(renderer: renderer).infoMap as NSDictionary)
    }

    func openDocumentAssetHandler(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void {
        guard let name = call.arguments as! String? else {
            return result(FlutterError(code: "RENDER_ERROR",
                                       message: "Arguments not sended",
                                       details: nil))
        }
        guard let renderer = openAssetDocument(name: name)  else {
            return result(FlutterError(code: "RENDER_ERROR",
                                       message: "Invalid PDF format",
                                       details: nil))
        }
        result(documents.register(renderer: renderer).infoMap as NSDictionary)
    }

    func closeDocumentHandler(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void {
        if let id = call.arguments as! String? {
            documents.close(id: id)
        }
        result(nil)
    }

    func closePageHandler(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void {
        if let id = call.arguments as! String? {
            pages.close(id: id)
        }
        result(nil)
    }

    func openDataDocument(data: Data) -> CGPDFDocument? {
        guard let datProv = CGDataProvider(data: data as CFData) else { return nil }
        return CGPDFDocument(datProv)
    }

    func openFileDocument(pdfFilePath: String) -> CGPDFDocument? {
        return CGPDFDocument(URL(fileURLWithPath: pdfFilePath) as CFURL)
    }

    func openAssetDocument(name: String) -> CGPDFDocument? {
        guard let path = Bundle.main.path(forResource: "Frameworks/App.framework/flutter_assets/" + name, ofType: "") else {
            return nil
        }
        return openFileDocument(pdfFilePath: path)
    }

    func openPageHandler(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void {
        guard let args = call.arguments as! NSDictionary? else {
            return result(FlutterError(code: "RENDER_ERROR",
                                       message: "Arguments not sended",
                                       details: nil))
        }
        do {
            let documentId = args["documentId"] as! String
            let pageNumber = args["page"] as! Int

            let renderer = try documents.get(id: documentId).openPage(pageNumber: pageNumber)
            let page = pages.register(documentId: documentId, renderer: renderer!)
            result(page.infoMap as NSDictionary)
        } catch {
            result(FlutterError(code: "RENDER_ERROR",
                                message: "Unexpected error: \(error).",
                details: nil))
        }
    }

    func renderHandler(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void {
        guard let args = call.arguments as! NSDictionary? else {
            return result(FlutterError(code: "RENDER_ERROR",
                                       message: "Arguments not sended",
                                       details: nil))
        }
        let pageId = args["pageId"] as! String
        let width = args["width"] as! Int
        let height = args["height"] as! Int
        let crop = args["crop"] as! Bool
        let compressFormat = args["format"]as! Int
        let backgroundColor = args["backgroundColor"] as! String
        let quality = args["quality"] as! Int

        // Set crop if required
        var cropZone: CGRect? = nil
        if (crop){
            let cWidth = args["crop_width"] as! Int
            let cHeight = args["crop_height"] as! Int
            if (cWidth != width || cHeight != height){
                cropZone = CGRect(x: args["crop_x"] as! Int,
                                  y: args["crop_y"] as! Int,
                                  width: cWidth,
                                  height: cHeight)
            }
        }


        dispQueue.async {
            var results: [String: Any]? = nil
            do {
                let page = try self.pages.get(id: pageId)
                if let data = page.render(
                    width: width,
                    height: height,
                    crop: cropZone,
                    compressFormat: CompressFormat(rawValue: compressFormat)!,
                    backgroundColor: UIColor(hexString: backgroundColor),
                    quality: quality
                ) {
                    results = [
                        "width": Int32(data.width),
                        "height": Int32(data.height),
                        "path": String(data.path)
                    ]
                }
            } catch {
                result(FlutterError(code: "RENDER_ERROR",
                                    message: "Unexpected error: \(error).",
                    details: nil))
            }
            DispatchQueue.main.async {
                result(results != nil ? (results! as NSDictionary) : nil)
            }
        }
    }
}
