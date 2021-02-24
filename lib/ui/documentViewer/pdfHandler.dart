import 'dart:typed_data';

import 'package:native_pdf_renderer/native_pdf_renderer.dart';

class PDFHandler {
  PdfDocument _document;
  PdfDocument get document => _document;

  List<PdfPageImage> _pageImages = List<PdfPageImage>();
  List<PdfPageImage> get pageImages => _pageImages;

  PDFHandler();

  // PDF 파일 생성
  Future<bool> setDocument({Uint8List data}) async {
    bool setState = await PdfDocument.openData(data).then((file) async {
      _document = file;
      for (int i = 0; i < _document.pagesCount; i++) {
        await _document.getPage(i + 1).then((page) async {
          await page
              .render(width: page.width, height: page.height)
              .then((image) {
            _pageImages.add(image);
            page.close();
          }).catchError((onError) {
            print("PdfPageImage.render() Error!");
            print("message : ${onError.toString()}");
          });
        }).catchError((onError) {
          print("PdfPage.getPage() Error!");
          print("message : ${onError.toString()}");
        });
      }
      return true;
    }).catchError((e) {
      print("PDF 파일을 불러오지 못하였습니다.");
      print("에러 : " + e.toString());
      return false;
    });
    return setState;
  }

  void releasePDFDocument(){
    pageImages.clear();
    document.close();
  }
}
