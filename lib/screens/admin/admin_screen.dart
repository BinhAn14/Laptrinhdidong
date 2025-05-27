import 'package:flutter/material.dart';

import '../common/welcome_screen.dart';
import 'package:zing_mp3_clone/screens/admin/music_manager_screen.dart';
import 'package:zing_mp3_clone/screens/admin/playlist_manager_screen.dart';

class AdminScreen extends StatelessWidget {
  static const routeName = '/admin';

  const AdminScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget _card(String title, String assetIcon, VoidCallback onTap) {
      final side = MediaQuery.of(context).size.width / 2.5;

      return GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: side,
          height: side,
          child: Card(
            elevation: 10,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                Flexible(
                    flex: 4,
                    child: Center(
                        child: Image.asset(
                      assetIcon,
                      fit: BoxFit.cover,
                    ))),
                Flexible(
                    flex: 2,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    )),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Quản trị viên'),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                    WelcomeScreen.routeName, (Route<dynamic> route) => false);
              },
              icon: const Icon(Icons.logout_rounded)),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _card(
                'Quản lý danh sách bài nhạc',
                'assets/icons/musical_notes_96.png',
                () =>
                    Navigator.pushNamed(context, MusicManagerScreen.routeName),
              ),
              _card(
                'Quản lý danh sách playlist',
                'assets/icons/playlist_2_96.png',
                () => Navigator.pushNamed(
                    context, PlaylistManagerScreen.routeName),
              ),
              _card(
                'Gửi thông báo',
                'assets/icons/email_send_96.png',
                () {
                  // TODO: Thêm điều hướng tới trang gửi thông báo nếu có
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
