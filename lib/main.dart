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
  speeches,
  votes,
  playerKilled,
  nightStarts,
  revote,
  voteKillAll;

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

  void _setScreen(GameScreenEnum screen) {
    setState(() {
      _screen = screen;
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
        return Speeches(
          goNext: () {
            switch (context.read<GameLogic>().prevote()) {
              case (PrevoteResult.cancel):
                _setScreen(GameScreenEnum.nightStarts);
              case (PrevoteResult.killedOne):
                texts.number = context.read<GameLogic>().killed;
                _setScreen(GameScreenEnum.playerKilled);
              case (PrevoteResult.needVote):
                _setScreen(GameScreenEnum.votes);
            }
          },
          time: playerSpeechTime,
        );
      case GameScreenEnum.votes:
        return Voting(
          goNext: () {
            switch (context.read<GameLogic>().votingResult()) {
              case VotingResult.cancel:
                _setScreen(GameScreenEnum.nightStarts);
              case VotingResult.killed:
                texts.number = context.read<GameLogic>().killed;
                _setScreen(GameScreenEnum.playerKilled);
              case VotingResult.revote:
                _setScreen(GameScreenEnum.revote);
              case VotingResult.voteKillAll:
                _setScreen(GameScreenEnum.voteKillAll);
            }
          },
        );
      case GameScreenEnum.playerKilled:
        return CenterButton(
          onPressed: () => _setScreen(GameScreenEnum.nightStarts),
          text: texts.playerKilled,
        );
      case GameScreenEnum.nightStarts:
        return CenterButton(
          onPressed: () => _setNextScreen,
          text: texts.nightStarts,
        );
      case GameScreenEnum.revote:
        context.read<GameLogic>().initRevote();
        return Speeches(goNext: () => _setScreen(GameScreenEnum.votes), time: revoteSpeechTime, pushForVote: false);
      case GameScreenEnum.voteKillAll:
        return VoteKillAll(goNext: () => _setScreen(GameScreenEnum.nightStarts));
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
  const TimerWidget({super.key, required this.text, required this.time, required this.goNext, this.resetTimer=false});
  final String text;
  final int time;
  final VoidCallback goNext;
  final bool resetTimer;

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
    if (widget.resetTimer) { 
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
  const Speeches({super.key, required this.goNext, required this.time, this.pushForVote = true});
  final VoidCallback goNext;
  final int time;
  final bool pushForVote;

  @override
  State<Speeches> createState() => _SpeechesState();
}

class _SpeechesState extends State<Speeches> {
  int? forVote;
  bool resetTimer = false;

  void _nextPlayer(BuildContext context) {
    if (forVote != null) {
      context.read<GameLogic>().addForVote(forVote!);
      forVote = null;
    }
    if (!context.read<GameLogic>().changeSpeaker()) {
      widget.goNext();
    }
    setState(() {
      resetTimer = true;
    });
  }

  void _changeForVote(int? value) {
    setState(() {
      resetTimer = false;
      forVote = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    texts.number = context.read<GameLogic>().personToSpeak;
    texts.number2 = forVote;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Talk(
            time: widget.time,
            goNext: () => _nextPlayer(context),
            resetTimer: resetTimer,
          ),
          if (widget.pushForVote)
            NumberDropdown(
              hint: texts.addForVote,
              items: context.read<GameLogic>().playersNotForVote,
              onChanged: _changeForVote,
            ),
        ],
      ),
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

class Talk extends StatefulWidget {
  const Talk({super.key, required this.time, required this.goNext, this.resetTimer=false});
  final int time;
  final bool resetTimer;
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
            resetTimer: widget.resetTimer,
          ),
          CenterButton(
            onPressed: widget.goNext,
            text: texts.endSpeech,
          ),
        ],
      );
  }
}

class Voting extends StatefulWidget {
  const Voting({super.key, required this.goNext});
  final VoidCallback goNext;

  @override
  State<Voting> createState() => _VotingState();
}

class _VotingState extends State<Voting> {
  int? _curVotes;
  Iterator<int>? _playersToVoteFor;
  bool running = false;

  void _changeVotesCount(int? value) {
    setState(() {
    _curVotes = value;
    });
  }

  void _nextCandidate(int playerNum) {
    if (_curVotes != null) {
      context.read<GameLogic>().inputVotesForPlayer(playerNum, _curVotes!);

      if (context.read<GameLogic>().votesLeft == 0) {
        context.read<GameLogic>().setLeftCandidatesZeroVotes();
        widget.goNext();
        return;
      }
      if (_playersToVoteFor!.moveNext()) {
        setState(() {
          _curVotes = null;
        });
      } else {
        context.read<GameLogic>().calculateVotesForLastPlayer();
        widget.goNext();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!running) {
      _playersToVoteFor = context.read<GameLogic>().playersToVoteFor;
      running = true;
    }
    final playerNum = _playersToVoteFor!.current;
    texts.number = playerNum;
    texts.number2 = _curVotes;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NumberDropdown(
          hint: texts.inputVotes,
          items: [
            for (int i = 0; i <= context.read<GameLogic>().votesLeft; i++) i,
          ],
          onChanged: _changeVotesCount,
        ),
        CenterButton(text: texts.next, onPressed: () => _nextCandidate(playerNum)),
      ],
    );
  }
}

class VoteKillAll extends StatefulWidget {
  const VoteKillAll({super.key, required this.goNext});
  final VoidCallback goNext;

  @override
  State<VoteKillAll> createState() => _VoteKillAllState();
}

class _VoteKillAllState extends State<VoteKillAll> {
  int? _votesForKillAll;
  bool showKilled = false;

  void _onPressed() {
    if (_votesForKillAll != null) {
      final res = context.read<GameLogic>().votingKillAllResult(_votesForKillAll!);
      if (res == VotingResult.killed) {
        setState(() {
          showKilled = true;
        });
      } else {
        widget.goNext();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (showKilled) {
      texts.numbers = context.read<GameLogic>().playersForVote;
      return CenterButton(onPressed: widget.goNext, text: texts.multiplePlayersKilled);
    }
    texts.number2 = _votesForKillAll;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NumberDropdown(
          hint: texts.whoForKillAll,
          items: [for (var i = 0; i <= context.read<GameLogic>().voting; i++) i],
          onChanged: (value) => setState(() {
            _votesForKillAll = value;
          }),
        ),
        CenterButton(onPressed: _onPressed, text: texts.next)
      ],
    );
  }
}
