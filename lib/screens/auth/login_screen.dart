import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin/admin_screen.dart';
import '../../utils/config.dart';
import '../../models/account.dart';
import '../../models/playlist.dart';
import '../../utils/my_dialog.dart';
import '../../utils/my_exception.dart';
import '../../utils/validator.dart';
import '../../widgets/auth/login_card.dart';
import '../common/home_screen.dart';
import './forgot_screen.dart';
import './signup_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/auth/login';

  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSubmitting = false;

  Future<bool> _onSubmit(String email, String password) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Validate email
      if (Validator.email(email) == false) {
        throw MyException('Email không hợp lệ.');
      }

      // Validate password
      if (password.length < 6) {
        throw MyException('Mật khẩu phải ít nhất 6 ký tự.');
      }

      // Đăng nhập với Firebase
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = userCredential.user!;

      // Lấy thông tin user từ Firestore
      final firestore = FirebaseFirestore.instance;
      final documentSnapshot =
          await firestore.collection('users').doc(user.uid).get();

      final map = documentSnapshot.data();

      if (map == null) {
        throw MyException('Không tìm thấy dữ liệu người dùng.');
      }

      // Lấy playlist người dùng
      final querySnapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('user_playlists')
          .get();

      final mapPlaylist = querySnapshot.docs;
      List<Playlist> userPlaylists = [];

      if (mapPlaylist.isNotEmpty) {
        for (var query in mapPlaylist) {
          final playlist = Playlist.fromMapFirebase(query.data(), query.id);
          userPlaylists.add(playlist);
        }
      }

      // Lưu thông tin account vào Config
      Config.instance.myAccount = Account(
        uid: user.uid,
        name: map['name'],
        email: email,
        role: map['role'] ?? 'user',
        userPlaylists: userPlaylists,
      );

      await Config.instance.saveAccountInfo();
      await Config.instance.saveAccountPlaylists();

      // Chuyển trang theo quyền role
      if (map['role'] == 'admin') {
        Navigator.of(context).pushReplacementNamed(AdminScreen.routeName);
      } else {
        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
      }

      return true;
    } on MyException catch (error) {
      MyDialog.show(context, 'Lỗi', error.toString());
    } on FirebaseAuthException catch (error) {
      print('FirebaseAuthException: ${error.code} - ${error.message}');
      String errorMessage = 'Lỗi không xác định!\n(Firebase Auth)';

      if (error.code == 'user-not-found') {
        errorMessage = 'Tài khoản không tồn tại.';
      } else if (error.code == 'wrong-password') {
        errorMessage = 'Sai mật khẩu.';
      } else if (error.code == 'invalid-credential') {
        errorMessage = 'Thông tin xác thực không hợp lệ. Vui lòng thử lại.';
      }

      MyDialog.show(context, 'Lỗi', errorMessage);
    } catch (error) {
      print('Exception: $error');
      const errorMessage = 'Lỗi không xác định!';
      MyDialog.show(context, 'Lỗi', errorMessage);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.keyboard_backspace_rounded),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(ForgotScreen.routeName);
              },
              child: const Text(
                'Quên mật khẩu',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/images/auth/login_image.png'),
                const SizedBox(height: 10),
                const Text('Đăng nhập',
                    style:
                        TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text(
                  'Vui lòng điền thông tin đăng nhập bên dưới để tiếp tục',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 15),
                LoginCard(_onSubmit),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chưa có tài khoản?'),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(SignUpScreen.routeName);
                      },
                      child: const Text('Đăng ký'),
                    ),
                  ],
                ),
                if (_isSubmitting) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
