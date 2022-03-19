import 'package:chat/model/user.dart';
import 'package:chat/pages/talk_room.dart';

class TalkRoom{
  String roomId;
  User talkUser;
  String lastmessage;

  TalkRoom({required this.roomId,required this.talkUser,required this.lastmessage});
}