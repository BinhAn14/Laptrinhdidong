import 'package:flutter/material.dart';

import '../../controllers/player_controller.dart';
import '../../utils/converter.dart';

class SeekBar extends StatefulWidget {
  const SeekBar({Key? key}) : super(key: key);

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  final controller = PlayerController.instance;
  bool isDragging = false;
  double position = 0;

  @override
  Widget build(BuildContext context) {
    final duration =
        controller.current?.duration ?? 0; // Nếu không có duration thì dùng 0

    return StreamBuilder<Duration>(
        stream: controller.onPositionChanged,
        builder: (context, snapshot) {
          if (!isDragging && snapshot.hasData) {
            // Cập nhật position nếu đang phát
            position = snapshot.data!.inSeconds.toDouble();
          }

          // Giới hạn position không vượt quá duration
          if (position > duration) {
            position =
                duration.toDouble(); // Đảm bảo position không vượt quá duration
          }

          return Slider(
            value: position,
            onChangeStart: (_) {
              isDragging = true;
            },
            onChanged: (value) {
              setState(() {
                position = value;
              });
            },
            onChangeEnd: (value) {
              isDragging = false;
              controller.setPosition(value.toInt());
            },
            divisions: duration > 0 ? duration : 1, // Chỉ chia nếu duration > 0
            label: Converter.formatSecond(position.toInt()) +
                ' / ' +
                Converter.formatSecond(duration),
            min: 0,
            max: duration.toDouble(),
            activeColor: Theme.of(context).primaryColor,
          );
        });
  }
}
