import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_social_textfield/controller/social_text_editing_controller.dart';
import 'package:get/get.dart';
import 'package:healthhero/src/constants/global.dart';
import 'package:healthhero/src/theme/app_color.dart';
import 'package:healthhero/src/widgets/custom_circular.dart';
import 'package:http/http.dart' as https;
import 'package:healthhero/src/screen/helper/firebase_helper.dart';

class CreatePostController extends GetxController {
  User? user;
  TextEditingController summaryPostController = TextEditingController();
  TextEditingController hospitalNameController = TextEditingController();
  TextEditingController doctorName = TextEditingController();
  TextEditingController duration = TextEditingController();
  TextEditingController medicineController = TextEditingController();
  TextEditingController symptoms = TextEditingController();
  SocialTextEditingController postController = SocialTextEditingController();
  RxString selectedList = 'Brain'.obs;
  List itemList = ['Brain', 'Eye', 'Heart', 'Lungs', 'Stomach'];
  changeIdx(String val) => selectedList.value = val;
  getUserProfile() => firebaseAuth.currentUser?.photoURL;

  String? get getUserImg => firebaseAuth.currentUser?.photoURL;
  String? get getUsername => firebaseAuth.currentUser?.displayName;
  String get getPostImgUrl => '';

  Rx<PlatformFile>? pickedFile;

  postbutton(String imgUrl) async {
    if (hospitalNameController.text.isNotEmpty &&
        doctorName.text.isNotEmpty &&
        duration.text.isNotEmpty &&
        medicineController.text.isNotEmpty &&
        symptoms.text.isNotEmpty) {
      //hit server get result
      CustomCircleLoading.showDialog();
      hitUserAndGetPoints(symptoms.text, imgUrl);
    }
  }

  getScore(data) {
    RegExp scoreRegex = RegExp(r"Score: ([-+]?\d*\.?\d+)");
    String? scoreString = scoreRegex.firstMatch(data)?.group(1);
    double score = double.parse(scoreString ?? "0");
    return score;
  }

  // getMagnitudeData(data) {
  //   // Extracting the magnitude value
  //   RegExp magnitudeRegex = RegExp(r"Magnitude: ([-+]?\d*\.?\d+)");
  //   String? magnitudeString = magnitudeRegex.firstMatch(data)?.group(1);
  //   double magnitude = double.parse(magnitudeString ?? "0");
  //   return magnitude;
  // }

  hitUserAndGetPoints(String summary, String imgUrl) async {
    var request = await https
        .get(Uri.parse('http://34.171.253.214:5000/sen?content=$summary'));

    if (request.statusCode == 200) {
      var decode = jsonDecode(request.body);
      double score = getScore(decode);

      await firestore.collection(selectedList.value).doc().set({
        'userImg': getUserImg,
        'userName': sharedPreferences.getString('name'),
        'timestamp': DateTime.now(),
        'postText':
            '${hospitalNameController.text}**${doctorName.text}**${duration.text}**${medicineController.text}**${symptoms.text}',
        'postimgUrl': imgUrl,
        'email': firebaseAuth.currentUser?.email,
        'score': score
      }).then((value) async {
        firestore.collection('posts').doc().set({
          'id': firebaseAuth.currentUser?.uid,
          'username': sharedPreferences.getString('name'),
          'timestamp': DateTime.now(),
          'description':
              '${hospitalNameController.text}**${doctorName.text}**${duration.text}**${medicineController.text}**${symptoms.text}',
          'mediaUrl': imgUrl,
          'email': firebaseAuth.currentUser?.email,
          'ownerurl': firebaseAuth.currentUser?.photoURL,
          'score': score
        }).then((value) {
          firestore
              .collection('user')
              .doc(firebaseAuth.currentUser?.email)
              .collection("posts")
              .doc()
              .set({
            'id': firebaseAuth.currentUser?.uid,
            'username': sharedPreferences.getString('name'),
            'timestamp': DateTime.now(),
            'description':
                '${hospitalNameController.text}**${doctorName.text}**${duration.text}**${medicineController.text}**${symptoms.text}',
            'mediaUrl': imgUrl,
            'email': firebaseAuth.currentUser?.email,
            'ownerurl': firebaseAuth.currentUser?.photoURL,
            'score': score
          });
        });
        CustomCircleLoading.cancelDialog();
        Get.back();
        Get.back();
        showSnackBar("Your post is live", primaryColor, whiteColor);
      });
    }
  }

  handleFileUpload() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      pickedFile?.value = result.files.first;
    }
  }
}
