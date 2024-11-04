import 'package:project1/repo/chatting/chat_repo.dart';
import 'package:project1/repo/chatting/data/signup_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';

class ChatApi {
  Future<String> chatSignUp(String email, String uid, String firstName, String imageUrl) async {
    try {
      ChatRepo chatRepo = ChatRepo();

      ChatSignupData chatSignupData = ChatSignupData();
      chatSignupData.email = email;
      chatSignupData.uid = uid.toString();
      chatSignupData.firstName = firstName;
      chatSignupData.imageUrl = imageUrl;
      ResData resData1 = await chatRepo.signup(chatSignupData);

      return resData1.data.toString();
    } catch (e) {
      lo.g('chatSignup : $e');
      return '';
    }
  }
}
