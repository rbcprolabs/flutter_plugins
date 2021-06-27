class Page {
    let id: String
    let documentId: String
    let renderer: CGPDFPage
    let boxRect: CGRect

    init(id: String, documentId: String, renderer: CGPDFPage) {
        self.id = id
        self.documentId = documentId
        self.renderer = renderer
        self.boxRect = renderer.getBoxRect(.mediaBox)
    }

    var number: Int {
        get {
            return renderer.pageNumber
        }
    }

    var width: Int {
        get {
            return Int(boxRect.width)
        }
    }

    var height: Int {
        get {
            return Int(boxRect.height)
        }
    }
    
    var rotationAngle: Int32 {
        get {
            return renderer.rotationAngle
        }
    }

    var isLandscape: Bool {
        get {
            return Bool(rotationAngle == 90 || rotationAngle == 270)
        }
    }

    var infoMap: [String: Any] {
        get {
            return [
                "documentId": documentId,
                "id": id,
                "pageNumber": Int32(number),
                "width": Int32(width),
                "height": Int32(height)
            ]
        }
    }

    func render(width: Int, height: Int, crop: CGRect?, compressFormat: CompressFormat, backgroundColor: UIColor, quality: Int) -> Page.DataResult? {
        let box = renderer.getBoxRect(.mediaBox)
        let bitmapSize = isLandscape ? CGSize(width: height, height: width) : CGSize(width: width, height: height)
        let stride = Int(bitmapSize.width * 4)
        var tempData = Data(repeating: 0, count: stride * Int(bitmapSize.height))
        var data: Data?
        var fileURL: URL?
        var success = false
        var transform = renderer.getDrawingTransform(.mediaBox, rect: CGRect(origin: CGPoint.zero, size: bitmapSize), rotate: 0, preserveAspectRatio: true)
        let compressionQuality = CGFloat(quality) / 100
        tempData.withUnsafeMutableBytes { (ptr) in
            let rawPtr = ptr.baseAddress
            let rgb = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: rawPtr, width: Int(bitmapSize.width), height: Int(bitmapSize.height), bitsPerComponent: 8, bytesPerRow: stride, space: rgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            if context != nil {
                // Credit: https://stackoverflow.com/a/35985236
                // We change the context scale to fill completely the destination size (scale-down is handled by getDrawingTransform)
                if box.width < bitmapSize.width {
                    let sx = CGFloat(width) / box.width
                    let sy = CGFloat(height) / box.height
                    transform = transform.scaledBy(x: sx, y: sy)

                    transform.tx = -(box.origin.x * transform.a + box.origin.y * transform.b)
                    transform.ty = -(box.origin.x * transform.c + box.origin.y * transform.d)

                    // Rotation handling
                    if rotationAngle == 180 || rotationAngle == 270 {
                        transform.tx += bitmapSize.width
                    }
                    if rotationAngle == 90 || rotationAngle == 180 {
                        transform.ty += bitmapSize.height
                    }
                }
                context!.concatenate(transform)
                context!.setFillColor(backgroundColor.cgColor)
                context!.fill(box)
                context!.drawPDFPage(renderer)
                var image = UIImage(cgImage: context!.makeImage()!)

                if (crop != nil) {
                    // Perform cropping in Core Graphics
                    let cutImageRef: CGImage = (image.cgImage?.cropping(to:crop!))!
                    image = UIImage(cgImage: cutImageRef)
                }

                switch(compressFormat) {
                    case CompressFormat.JPEG:
                        data = image.jpegData(compressionQuality: compressionQuality) as Data?
                        break;
                    case CompressFormat.PNG:
                        data = image.pngData() as Data?
                        break;
                }

                if data != nil {
                    fileURL = writeToTempFile(data: data!, compressFormat: compressFormat)
                }

                success = true
            }
        }
        return success ? Page.DataResult(
            width: (crop != nil) ? Int(crop!.width) : width,
            height: (crop != nil) ? Int(crop!.height) : height,
            path: (fileURL != nil) ? fileURL!.path : ""
            ) : nil
    }

    func writeToTempFile(data: Data, compressFormat: CompressFormat) -> URL? {
        // Create missing directories
        let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let cacheURL = docURL.appendingPathComponent("native_pdf_renderer_cache")
        if !FileManager.default.fileExists(atPath: cacheURL.path) {
            do {
                try FileManager.default.createDirectory(at: cacheURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
                return nil
            }
        }
        // Create temporary filename
        let randomFileName = NSUUID().uuidString.replacingOccurrences(of: "-", with: "")
        var tempOutFileExtension: String?
        var tempOutFileName: String?
        switch(compressFormat) {
            case CompressFormat.JPEG:
                tempOutFileExtension = "jpg"
                break;
            case CompressFormat.PNG:
                tempOutFileExtension = "png"
                break;
            default:
                return nil
        }
        tempOutFileName = "\(randomFileName).\(tempOutFileExtension!)"
        let fileURL = cacheURL.appendingPathComponent(tempOutFileName!)
        // Write the data to the temporary file
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print(error.localizedDescription)
            return nil
        }
        return fileURL
    }

    class DataResult {
        let width: Int
        let height: Int
        let path: String

        init(width: Int, height: Int, path: String) {
            self.width = width
            self.height = height
            self.path = path
        }
    }
}

enum CompressFormat: Int {
    case JPEG = 0
    case PNG = 1
}
