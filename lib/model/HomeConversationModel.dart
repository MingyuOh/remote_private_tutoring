import 'package:remote_private_tutoring/model/ConversationModel.dart';

import 'User.dart';

class HomeConversationModel {
  bool isGroupChat = false;
  List<User> members = [];
  ConversationModel conversationModel = ConversationModel();

  HomeConversationModel(
      {this.isGroupChat, this.members, this.conversationModel});
}
