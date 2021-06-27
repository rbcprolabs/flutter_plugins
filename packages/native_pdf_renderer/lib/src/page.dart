import 'dart:async';
import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'dart:ui';

import 'package:extension/enum.dart';
import 'package:flutter/services.dart';
import 'package:synchronized/synchronized.dart';
import 'document.dart';

part 'page_image.dart';

/// Image compression format
class PdfPageFormat extends Enum<int> {
  const PdfPageFormat(int val) : super(val);

  static const PdfPageFormat JPEG = PdfPageFormat(0);
  static const PdfPageFormat PNG = PdfPageFormat(1);

  /// ***Attention!*** Works only on android
  static const PdfPageFormat WEBP = PdfPageFormat(2);
}

/// An integral part of a document is its page,
/// which contains a method [render] for rendering into an image
class PdfPage {
  PdfPage({
    required this.document,
    required this.id,
    required this.pageNumber,
    required this.width,
    required this.height,
    required Lock lock,
  }) : _lock = lock;

  static const MethodChannel _channel =
      MethodChannel('io.scer.native_pdf_renderer');

  final Lock _lock;

  final PdfDocument document;

  /// Page unique id. Needed for rendering and closing page.
  /// Generated when opening page.
  final String id;

  /// Page number in document.
  /// Starts from 1.
  final int pageNumber;

  /// Page source width in pixels
  final int width;

  /// Page source height in pixels
  final int height;

  /// Is the page closed
  bool isClosed = false;

  /// Render a full image of specified PDF file.
  ///
  /// [width], [height] specify resolution to render in pixels.
  /// As default PNG uses transparent background. For change it you can set
  /// [backgroundColor] property like a hex string ('#FFFFFF')
  /// [format] - image type, all types can be seen here [PdfPageFormat]
  /// [cropRect] - render only the necessary part of the image
  /// [quality] - hint to the JPEG and WebP compression algorithms (0-100)
  Future<PdfPageImage?> render({
    required int width,
    required int height,
    PdfPageFormat format = PdfPageFormat.PNG,
    String? backgroundColor,
    Rect? cropRect,
    int quality = 100,
  }) =>
      _lock.synchronized<PdfPageImage?>(() async {
        if (document.isClosed) {
          throw PdfDocumentAlreadyClosedException();
        } else if (isClosed) {
          throw PdfPageAlreadyClosedException();
        }

        return PdfPageImage._render(
          pageId: id,
          pageNumber: pageNumber,
          width: width,
          height: height,
          format: format,
          backgroundColor: backgroundColor,
          crop: cropRect,
          quality: quality,
        );
      });

  /// Before open another page it is necessary to close the previous.
  ///
  /// The android platform does not allow parallel rendering.
  Future<void> close() => _lock.synchronized(() async {
        if (isClosed) {
          throw PdfPageAlreadyClosedException();
        } else {
          isClosed = true;
        }
        return _channel.invokeMethod('close.page', id);
      });

  @override
  bool operator ==(Object other) =>
      other is PdfPage &&
      other.document.hashCode == document.hashCode &&
      other.pageNumber == pageNumber;

  @override
  int get hashCode => document.hashCode ^ pageNumber;

  @override
  String toString() => '$runtimeType{'
      'document: $document, '
      'page: $pageNumber,  '
      'width: $width, '
      'height: $height}';
}

class PdfPageAlreadyClosedException implements Exception {
  @override
  String toString() => '$runtimeType: Page already closed';
}
