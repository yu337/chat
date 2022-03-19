import 'dart:io';
import 'package:chat/model/user.dart';
import 'package:chat/utils/firebase.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/shared_prefs.dart';

class SettingProfilePage extends StatefulWidget {
  const SettingProfilePage({Key? key}) : super(key: key);

  @override
  _SettingProfilePageState createState() => _SettingProfilePageState();
}

class _SettingProfilePageState extends State<SettingProfilePage> {
  final picker = ImagePicker();
  String imagePath =
      'http://kumiho.sakura.ne.jp/twegg/gen_egg.cgi?r=59&g=148&b=217';
  File? image;
  TextEditingController controller = TextEditingController();

  Future<void> getImageFromGallery() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      image = File(pickedFile.path);
      uploadImage();
      setState(() {});
    }
  }

  Future<String> uploadImage() async {
    String myUid = SharedPrefs.getUid();
    final ref = FirebaseStorage.instance.ref(myUid + '.png');
    final storedImage = await ref.putFile(image!);
    imagePath = await loadImage(storedImage);
    return imagePath.toString();
  }

  Future<String> loadImage(TaskSnapshot storedImage) async {
    String downloadUrl = await storedImage.ref.getDownloadURL();
    return downloadUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('プロフィール編集'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(width: 100, child: Text('名前')),
                  Expanded(
                      child: TextField(
                    controller: controller,
                  ))
                ],
              ),
              SizedBox(
                height: 50,
              ),
              Row(
                children: [
                  Container(width: 100, child: Text('サムネイル')),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      child: Container(
                        width: 150,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {
                            getImageFromGallery();
                          },
                          child: Text('画像を選択'),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 30,
              ),
              image == null
                  ? Container()
                  : Container(
                      child: ClipOval(
                        child: Image.file(
                          image!,
                          fit: BoxFit.cover,
                          width: 200,
                          height: 200,
                        ),
                      ),
                    ),
              SizedBox(
                height: 30,
              ),
              ElevatedButton(
                onPressed: () {
                  String uid = SharedPrefs.getUid();
                  User newProfile = User(
                      name: controller.text, imagePath: imagePath, uid: uid);
                  Firestore.updateProfile(newProfile);
                },
                child: Text('保存'),
              )
            ],
          ),
        ));
  }
}
