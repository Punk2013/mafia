import 'main.dart';
import 'package:flutter/material.dart';
import 'constants.dart';
import 'dart:async';

class CenterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const CenterButton({super.key, required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 400,
          height: 300,
          alignment: Alignment.center,
          color: Colors.grey,
          child: Center(
            child: Text(text, style: const TextStyle(fontSize: fontsize)),
          ),
        ),
      ),
    );
  }
}

class TimerWidget extends StatefulWidget {
  const TimerWidget({super.key, required this.text, required this.time, required this.onFinished, this.resetOnRebuild=false});
  final String text;
  final int time;
  final VoidCallback onFinished;
  final bool resetOnRebuild;

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  Timer? _timer;
  int _secondsRemaining = 30;
  bool _isRunning = false;
  
  @override
  void didUpdateWidget(TimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetOnRebuild) { 
      _timer?.cancel();
      _isRunning = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    if (_isRunning) return;

    setState(() {
      _secondsRemaining = widget.time;
      _isRunning = true;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      debugPrint('bip');
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          widget.onFinished();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    startTimer();
    return Center(
      child: Container(
        alignment: Alignment.center,
        color: Colors.grey,
        width: 400,
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: spacing,
          children: [
            Text(widget.text, style: TextStyle(fontSize: fontsize)),
            Text(
              _secondsRemaining.toString(),
              style: TextStyle(fontSize: fontsizeLarge),
            ),
          ],
        ),
      ),
    );
  }
}

class Talk extends StatelessWidget {
  const Talk({super.key, required this.time, required this.onFinished, this.resetTimer=false});
  final int time;
  final bool resetTimer;
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TimerWidget(
            onFinished: onFinished,
            text: texts.playerSpeech,
            time: time,
            resetOnRebuild: resetTimer,
          ),
          CenterButton(
            onPressed: onFinished,
            text: texts.endSpeech,
          ),
        ],
      );
  }
}

class NumberDropdown extends StatelessWidget {
  const NumberDropdown({super.key, required this.hint, required this.items, required this.onChanged});
  final String hint;
  final List<int> items;
  final void Function(int?) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      hint: Text(hint, style: TextStyle(fontSize: fontsize)),
      items: items
          .map(
            (el) =>
                DropdownMenuItem<int>(value: el, child: Text(el.toString())),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}