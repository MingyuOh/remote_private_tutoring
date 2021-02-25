import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:remote_private_tutoring/ui/document/pdfHandler.dart';

enum documentFormat { NONE, PDF, PPTX, PPT, DOCX, DOC }

class DocumentHandler {
  FilePickerResult _file;
  PDFHandler _pdfHandler;
  PDFHandler get pdfHandler => _pdfHandler;
  documentFormat currentDocumentFormat = documentFormat.NONE;
  ValueNotifier<int> currentPage = ValueNotifier(1);

  DocumentHandler({this.currentDocumentFormat});

  Future<bool> selectFile() async {
    print("documentHandler selectFile");
    _file = await FilePicker.platform.pickFiles(withData: true);
    if (_file != null) {
      return true;
    } else {
      // 사용자가 선택 취소(AlertDialog 또는 무시)
      return false;
    }
  }

  Future<bool> loadFile() async {
    print("documentHandler loadFile");
    if (_file != null) {
      await checkFileFormat(fileFormat: _file.files.first.extension, file: _file.files.first);
      return true;
    } else {
      // 사용자가 선택 취소(AlertDialog 또는 무시)
      return false;
    }
  }

  Widget openFile() {
    switch (currentDocumentFormat) {
      case documentFormat.PDF:
        return ValueListenableBuilder<int>(
            valueListenable: currentPage,
            builder: (context, value, _) {
              return Image(image: MemoryImage(pdfHandler.pageImages[value - 1].bytes),
            fit: BoxFit.fill);
            });
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

  void changeDocumentPage({bool isNext}){
    switch(currentDocumentFormat){
      case documentFormat.PDF:
        if(isNext == true){
          if(_pdfHandler.document.pagesCount > currentPage.value){
            currentPage.value +=1;
          }
        }else{
          if(currentPage.value > 1)
            currentPage.value -= 1;
        }
        print("PDF current page : $currentPage");
        break;
      default:
        break;
    }
  }

  void releaseDocument(){
    switch (currentDocumentFormat){
      case documentFormat.PDF:
        _pdfHandler.releasePDFDocument();
        break;
      default:
        break;
    }

    currentDocumentFormat = documentFormat.NONE;
  }

}
