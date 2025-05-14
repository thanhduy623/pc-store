import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // GoogleSignIn sẽ được khởi tạo tùy nền tảng
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    _googleSignIn = GoogleSignIn(
      clientId:
          kIsWeb
              ? '522125772075-ef80k4l75eu9fo3qajr3v3cesfl2j10p.apps.googleusercontent.com'
              : null,
    );
  }

  // Đăng nhập bằng email + mật khẩu
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCred.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('Không tìm thấy tài khoản.');
      } else if (e.code == 'wrong-password') {
        print('Sai mật khẩu.');
      } else {
        print('Lỗi đăng nhập: ${e.message}');
      }
      return null;
    } catch (e) {
      print('Lỗi khác: $e');
      return null;
    }
  }

  // Đăng ký tài khoản mới
  Future<User?> register(String email, String password) async {
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCred.user;
    } on FirebaseAuthException catch (e) {
      // ✅ Ném lỗi ra ngoài để UI bắt và xử lý (ví dụ email đã tồn tại)
      rethrow;
    } catch (e) {
      print('Lỗi không xác định: $e');
      throw Exception('Đăng ký thất bại');
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // Đăng nhập bằng Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      return userCredential.user;
    } catch (e) {
      print('Lỗi đăng nhập Google: $e');
      return null;
    }
  }
}
