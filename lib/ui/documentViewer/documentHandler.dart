import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:remote_private_tutoring/ui/documentViewer/pdfHandler.dart';

enum documentFormat { NONE, PDF, PPTX, PPT, DOCX, DOC }

class DocumentHandler {
  PDFHandler _pdfHandler;
  PDFHandler get pdfHandler => _pdfHandler;
  documentFormat currentDocumentFormat = documentFormat.NONE;

  DocumentHandler({this.currentDocumentFormat});

  Future<void> loadFile() async {
    print("documentHandler loadFile");
    await FilePicker.platform
        .pickFiles(
      /*allowedExtensions: ['pdf', 'pptx', 'ppt', 'doc', 'docx'],
      allowMultiple: false,*/
      withData: true,
    )
        .then((result) {
      if (result != null) {
        checkFileFormat(
            fileFormat: result.files.first.extension, file: result.files.first);
      } else {
        // 사용자가 선택 취소(AlertDialog 또는 무시)
      }
    });
    return currentDocumentFormat;
  }

  Widget openFile() {
    switch (currentDocumentFormat) {
      case documentFormat.PDF:
        return Container(
          child: Image(
              image: MemoryImage(
                  pdfHandler.pageImages[pdfHandler.currentPage].bytes)),
        );
      default:
        return Container();
    }
  }

  Future<void> checkFileFormat({String fileFormat, PlatformFile file}) async {
    switch (fileFormat) {
      case 'pdf':
        if (_pdfHandler == null) {
          _pdfHandler = PDFHandler();
        }
        await pdfHandler.setDocument(data: file.bytes).then((load) {
          if (load == true) {
            currentDocumentFormat = documentFormat.PDF;
          }
        }).catchError((e) {
          print("DocumentHandler : checkFileFormat()");
          print("Error message: ${e.toString()}");
        });
        break;
    }
  }
}
