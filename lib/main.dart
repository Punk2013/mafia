import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants.dart';
import 'gamelogic.dart';
import 'dart:async';

// temporary
final Texts texts = RuTexts();

void main() {
  final game = GameLogic();
  runApp(ChangeNotifierProvider(create: (_) => game, child: MafiaApp()));
}

class MafiaApp extends StatelessWidget {
  const MafiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: texts.title,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.black)
      ),
      home: Game()
    );
  }
}

class Game extends StatefulWidget {
  const Game({super.key});

  @override
  State<Game> createState() => _GameState();
}

enum GameScreenEnum {
  homescreen,
  getRoles,
  mafiaTalk,
  wakeUp;

  GameScreenEnum get next {
    final values = GameScreenEnum.values;
    final nextIndex = (index + 1) % values.length;
    return values[nextIndex];
  }
    
}

class _GameState extends State<Game> {
  GameScreenEnum _screen = GameScreenEnum.homescreen;


  void _setNextScreen() {
    setState(() {
      _screen = _screen.next;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_screen) {
      case GameScreenEnum.homescreen:
        return Homescreen(goNext: _setNextScreen);
      case GameScreenEnum.getRoles:
        return GetRoles(goNext: _setNextScreen);
      case GameScreenEnum.mafiaTalk:
        return Talk(text: texts.mafiaTalk, time: mafiaTalkTime, goNext: _setNextScreen);
      case GameScreenEnum.wakeUp:
        return CenterButton(onPressed: _setNextScreen, text: texts.wakeUp);
    }
  }
}

class Homescreen extends StatelessWidget {
  final VoidCallback goNext;

  const Homescreen({super.key, required this.goNext});

  @override
  Widget build(BuildContext context) {
    return CenterButton(
      onPressed: () {
        context.read<GameLogic>().genRoles();
        goNext();
      },
      text: texts.start,
    );
  }
}

class GetRoles extends StatefulWidget {
  final VoidCallback goNext;
  const GetRoles({super.key, required this.goNext});

  @override
  State<GetRoles> createState() => _GetRolesState();
}

class _GetRolesState extends State<GetRoles> {
  int _playerNum = 1; 
  bool _show = false;

  void _showRole() {
    setState(() {
      _show = true;
    });
  }

  void _nextPlayer() {
    if (_playerNum == context.read<GameLogic>().playerCount) {
      widget.goNext();
      return;
    }
    setState(() {
      _show = false;
      _playerNum++;
    });
  }

  @override
  Widget build(BuildContext context) {
    texts.number = _playerNum;
    if (!_show) {
      return CenterButton(onPressed: _showRole, text: texts.getRole);
    } else {
      texts.str = texts.role(context.read<GameLogic>().getRole(_playerNum));
      return CenterButton(onPressed: _nextPlayer, text: texts.showRole);
    }
  }
}

class CenterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const CenterButton({super.key, required this.onPressed, required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
      ),
    );
  }
}

class Talk extends StatefulWidget {
  const Talk({super.key, required this.text, required this.time, required this.goNext});
  final String text;
  final int time;
  final VoidCallback goNext;

  @override
  State<Talk> createState() => _TalkState();
}

class _TalkState extends State<Talk> {
  Timer? _timer;
  int _secondsRemaining = 30;
  bool _isRunning = false;

  void startTimer() {
    if (_isRunning) return;

    setState(() {
      _secondsRemaining = widget.time;
      _isRunning = true;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          widget.goNext();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    startTimer();
    return Scaffold(
      body: Center(
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
      ),
    );
  }
}
