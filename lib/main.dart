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
      home: Scaffold(body: Game()),
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
  wakeUp,
  speeches;

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
        return TimerWidget(text: texts.mafiaTalk, time: mafiaTalkTime, goNext: _setNextScreen);
      case GameScreenEnum.wakeUp:
        return CenterButton(
          onPressed: () {
            context.read<GameLogic>().startDay();
            _setNextScreen();
          },
          text: texts.wakeUp,
        );
      case GameScreenEnum.speeches:
        return Speeches(goNext: _setNextScreen, time: playerSpeechTime);
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
  const TimerWidget({super.key, required this.text, required this.time, required this.goNext});
  final String text;
  final int time;
  final VoidCallback goNext;

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
    _timer?.cancel();
    _isRunning = false;
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
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timer?.cancel();
            widget.goNext();
          }
        });
      }
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

class Speeches extends StatefulWidget {
  const Speeches({super.key, required this.goNext, required this.time});
  final VoidCallback goNext;
  final int time;

  @override
  State<Speeches> createState() => _SpeechesState();
}

class _SpeechesState extends State<Speeches> {
  int? forVote;

  void _nextPlayer(BuildContext context) {
    if (forVote != null) {
      context.read<GameLogic>().addForVote(forVote!);
      forVote = null;
    }
    if (context.read<GameLogic>().allSpeaked()) {
      widget.goNext();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    texts.number = context.read<GameLogic>().nextToSpeak;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Talk(time: widget.time, goNext: () => _nextPlayer(context)),
          DropdownButton(
            hint: Text(texts.addForVote, style: TextStyle(fontSize: fontsize)),
            items: context
                .read<GameLogic>()
                .playersNotForVote
                .map(
                  (el) => DropdownMenuItem<int>(
                    value: el,
                    child: Text(el.toString()),
                  ),
                )
                .toList(),
            onChanged: (value) {
              forVote = value;
            },
          ),
        ],
      ),
    );
  }
}

class Talk extends StatefulWidget {
  const Talk({super.key, required this.time, required this.goNext});
  final int time;
  final VoidCallback goNext;

  @override
  State<Talk> createState() => _TalkState();
}

class _TalkState extends State<Talk> {
  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TimerWidget(
            goNext: widget.goNext,
            text: texts.playerSpeech,
            time: widget.time,
          ),
          CenterButton(
            onPressed: widget.goNext,
            text: texts.endSpeech,
          ),
        ],
      );
  }
}
