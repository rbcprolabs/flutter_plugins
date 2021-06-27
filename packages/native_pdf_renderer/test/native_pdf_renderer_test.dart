import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_pdf_renderer/native_pdf_renderer.dart';

const String _testFilePath = '/dev/test/file/path/file.pdf';
const String _testAssetPath = '/assets/file.pdf';
final Uint8List _testData = Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final List<MethodCall> log = <MethodCall>[];
  PdfDocument? document;

  setUpAll(() async {
    MethodChannel('io.scer.native_pdf_renderer')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'open.document.file':
          return {
            'id': 'uuid-file',
            'pagesCount': 1,
          };
        case 'open.document.asset':
          return {
            'id': 'uuid-asset',
            'pagesCount': 2,
          };
        case 'open.document.data':
          return {
            'id': 'uuid-data',
            'pagesCount': 3,
          };
        case 'close.document':
          return null;
        case 'open.page':
          return {
            'id': 'page-id',
            'width': 720,
            'height': 1280,
          };
        case 'close.page':
          return null;
        case 'render':
          return {
            'width': methodCall.arguments['width'],
            'height': methodCall.arguments['height'],
            'data': _testData,
          };
        default:
          return null;
      }
    });
  });

  tearDown(log.clear);

  group('Open document', () {
    test('from file path', () async {
      final document = await PdfDocument.openFile(_testFilePath);
      expect(log, <Matcher>[
        isMethodCall(
          'open.document.file',
          arguments: _testFilePath,
        ),
      ]);
      expect(document.pagesCount, 1);
    });

    test('from asset', () async {
      final document = await PdfDocument.openAsset(_testAssetPath);
      expect(log, <Matcher>[
        isMethodCall(
          'open.document.asset',
          arguments: _testAssetPath,
        ),
      ]);
      expect(document.pagesCount, 2);
      await document.close();
      expect(document.isClosed, isTrue);
    });

    test('from data', () async {
      document = await PdfDocument.openData(_testData);
      expect(log, <Matcher>[
        isMethodCall(
          'open.document.data',
          arguments: _testData,
        ),
      ]);
      expect(document!.pagesCount, 3);
    });
  });

  group('Page', () {
    late PdfPage page;

    test('open', () async {
      // page number 0 - not available
      expect(
        document!.getPage(0),
        throwsA(isInstanceOf<PdfPageNotFoundException>()),
      );

      page = await document!.getPage(3);
      expect(log, <Matcher>[
        isMethodCall(
          'open.page',
          arguments: {
            'documentId': 'uuid-data',
            'page': 3,
          },
        ),
      ]);
      expect(page.pageNumber, 3);
      expect(page.height, 1280);
      expect(page.width, 720);

      expect(page.document, document);

      // page number 4 more than the document
      expect(
        document!.getPage(4),
        throwsA(isInstanceOf<PdfPageNotFoundException>()),
      );
    });

    test('render', () async {
      final width = page.width * 2, height = page.height * 2;
      final pageImage = (await page.render(
        width: width,
        height: height,
        format: PdfPageFormat.JPEG,
        backgroundColor: '#ffffff',
      ))!;

      expect(log, <Matcher>[
        isMethodCall(
          'render',
          arguments: {
            'pageId': page.id,
            'width': width,
            'height': height,
            'format': PdfPageFormat.JPEG.value,
            'backgroundColor': '#ffffff',
            'crop': false,
            'crop_x': null,
            'crop_y': null,
            'crop_height': null,
            'crop_width': null,
            'quality': 100,
          },
        ),
      ]);

      expect(pageImage.bytes, _testData);
      expect(pageImage.format, PdfPageFormat.JPEG);
      expect(pageImage.width, width);
      expect(pageImage.height, height);
      expect(pageImage.pageNumber, page.pageNumber);
      expect(pageImage.quality, 100);
    });

    test('close', () async {
      await page.close();
      expect(page.isClosed, isTrue);
      expect(
        page.close,
        throwsA(isInstanceOf<PdfPageAlreadyClosedException>()),
      );
      expect(
        page.render(width: 1, height: 1),
        throwsA(isInstanceOf<PdfPageAlreadyClosedException>()),
      );
    });
  });

  test('Close document', () async {
    await document!.close();
    expect(document!.isClosed, isTrue);
    expect(
      document!.close,
      throwsA(isInstanceOf<PdfDocumentAlreadyClosedException>()),
    );
    expect(
      document!.getPage(1),
      throwsA(isInstanceOf<PdfDocumentAlreadyClosedException>()),
    );
  });
}
