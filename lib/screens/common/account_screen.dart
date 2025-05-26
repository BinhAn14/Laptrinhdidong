import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import 'package:zing_mp3_clone/controllers/player_controller.dart'; // hoặc đường dẫn đúng của bạn

class AccountScreen extends StatefulWidget {
  static const routeName = '/account';

  const AccountScreen({Key? key}) : super(key: key);

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill the name controller with the current name from Firebase/Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Dùng Future.delayed để đảm bảo Navigator hoạt động đúng trong initState
      Future.microtask(() {
        Navigator.of(context).pushNamedAndRemoveUntil(
          WelcomeScreen.routeName,
          (Route<dynamic> route) => false,
        );
      });
    } else {
      // Nếu đã đăng nhập, load tên người dùng
      _nameController.text = user.displayName ?? '';
    }
  }

  // Function to save the new name
  void _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      try {
        // Update Firebase Authentication Profile
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updateProfile(displayName: newName);
          await user.reload();
          user = FirebaseAuth.instance.currentUser;
        }

        // Update Firestore with the new name
        FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .update({'name': newName});

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật tên thành công')),
        );

        // Go back to the previous screen
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi khi cập nhật tên')),
        );
        print('Error updating name: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên không thể để trống')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget settingItem(String title, IconData icon, void Function() onTap) {
      return ListTile(
        leading: Icon(
          icon,
          color: Colors.black,
          size: 28,
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
        onTap: onTap,
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.keyboard_backspace_rounded,
            color: Colors.black,
          ),
        ),
        titleSpacing: 0,
        title: const Text(
          'Tài khoản cá nhân',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          // Avatar and current name with gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF65509E), Color(0xFF8947AD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
              leading: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/account/avatar.png'),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                    color: Colors.white,
                    width: 2.5,
                  ),
                ),
              ),
              title: Text(
                FirebaseAuth.instance.currentUser?.displayName ?? 'Không tên',
                style: const TextStyle(
                    color: Colors.white, // Chỉnh màu chữ cho phù hợp
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Button to change name
          ListTile(
            leading: const Icon(
              Icons.edit,
              color: Colors.black,
              size: 28,
            ),
            title: const Text(
              'Đổi tên',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Đổi tên'),
                  content: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Nhập tên mới'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _saveName();
                      },
                      child: const Text('Lưu'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Hủy'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Logout and Info
          settingItem('Đăng xuất', Icons.logout, () async {
            // ⛔ Dừng nhạc trước khi đăng xuất
            PlayerController.instance.stopMusic();

            // Đăng xuất Firebase
            await FirebaseAuth.instance.signOut();

            // Chuyển về màn hình Welcome
            Navigator.of(context).pushNamedAndRemoveUntil(
              WelcomeScreen.routeName,
              (Route<dynamic> route) => false,
            );
          }),
          settingItem('Giới thiệu', Icons.info_outline_rounded, () {
            // Action for "Giới thiệu"
          }),
        ],
      ),
    );
  }
}
