import 'package:chat/model/message.dart';
import 'package:chat/model/talkroom_data.dart';
import 'package:chat/model/user.dart';
import 'package:chat/utils/shared_prefs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Firestore{
  static FirebaseFirestore _firestoreInstance = FirebaseFirestore.instance;
  static final userRef = _firestoreInstance.collection('user');
  static final roomRef = _firestoreInstance.collection('room');
  static final roomSnapshot = roomRef.snapshots();

  static Future<void> addUser() async {
      final newDoc = await userRef.add({
        'name': '名無し',
        'image_path': 'https://assets.st-note.com/production/uploads/images/33258191/26e72cd1c817d16409230ea54273d3f2.png?width=330&height=240&fit=bounds'
      });
      print('アカウント作成完了');

      await SharedPrefs.setUid(newDoc.id);

      List<String> userIds = await getUser();
      userIds.forEach((user) async{
        if (user != newDoc.id){
          await roomRef.add({
            'joined_user_ids':[user, newDoc.id],
            'updated_time':Timestamp.now()
          });
        }
      });
      print('ルーム作成完了');


  }

  static Future<List<String>> getUser() async{
      final snapshot = await userRef.get();
      List<String> userIds = [];
      snapshot.docs.forEach((user) {
        userIds.add(user.id);
        print('ドキュメントID: ${user.id} --- 名前: ${user.data()['image_path']}');
      });

      return userIds;
  }

  static Future<User> getProfiles(String uid) async{
    final profile = await userRef.doc(uid).get();
    User myProfile = User(
      name: profile.data()!['name'],
      imagePath: profile.data()!['image_path'],
      uid: uid,
    );
    return myProfile;
  }

  static Future<void> updateProfile(User newProfile) async{
    String myUid = SharedPrefs.getUid();
    userRef.doc(myUid).update({
      'name': newProfile.name,
      'image_path':newProfile.imagePath,
    });
  }

  static Future<List<TalkRoom>> getRooms(String myUid) async{
    final snapshot = await roomRef.get();
    print('snapshot');
    print(myUid);
    List<TalkRoom> roomList = [];
    await Future.forEach<QueryDocumentSnapshot<Map<String, dynamic>>>(snapshot.docs, (doc) async {
      if(doc.data()['joined_user_ids'].contains(myUid)){
        String yourUid = '';
        doc.data()['joined_user_ids'].forEach((id){
          if(id != myUid){
            yourUid = id;
            return;
          }
        });
        print(yourUid);
        User yourProfile = await getProfiles(yourUid);
        print(yourProfile);
        TalkRoom room = TalkRoom(
            roomId: doc.id,
            talkUser: yourProfile,
            lastmessage: doc.data()['last_message'] ?? ''
        );
        roomList.add(room);
      }
    });
    print(roomList.length);
    return roomList;
  }
  static Future<List<Message>> getMessages(String roomId) async{
    final messageRef = roomRef.doc(roomId).collection('message');
    List<Message> messageList = [];
    final snapshot = await messageRef.get();
    await Future.forEach<QueryDocumentSnapshot<Map<String,dynamic>>>(snapshot.docs,(doc) async{
      bool isMe;
      String myUid = SharedPrefs.getUid();
      if(doc.data()['sender_id'] == myUid) {
        isMe = true;
      }else{
        isMe = false;
      }
      Message message = Message(
          message:doc.data()['message'],
          isMe:isMe,
          sendTime: doc.data()['send_time']
      );
      messageList.add(message);
    });
    messageList.sort((a,b) => b.sendTime.compareTo(a.sendTime));
    return messageList;
  }

  static Future<void> sendMessage(String roomId,String message) async{
    final messageRef = roomRef.doc(roomId).collection('message');
    String myUid = SharedPrefs.getUid();
    await messageRef.add({
      'message':message,
      'sender_id':myUid,
      'send_time':Timestamp.now()
    });

    roomRef.doc(roomId).update({
      'last_message':message
    });
  }

  static Stream<QuerySnapshot> messageSnapshot(String roomId){
    return roomRef.doc(roomId).collection('message').snapshots();
  }
}