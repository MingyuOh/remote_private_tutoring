import 'package:remote_private_tutoring/ui/document/documentHandler.dart';
import 'package:remote_private_tutoring/ui/pen/penHandler.dart';

class WhiteboardHandler{
  DocumentHandler _documentHandler;
  DocumentHandler get documentHandler => _documentHandler;

  PenHandler _penHandler;
  PenHandler get penHandler => _penHandler;

  WhiteboardHandler() {
    _documentHandler = DocumentHandler();
    _penHandler = PenHandler();
  }

  void releaseWhiteboard(){
    _documentHandler.releaseDocument();
    _penHandler.releasePen();
  }
}
