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
      initialRoute: '/homescreen',
      routes: {
        '/homescreen': (context) => Homescreen(),
        '/getRoles': (context) => GetRoles(),
        '/mafiaTalk': (context) => Scaffold(body: TimerWidget(goNext: '/wakeUp', text: texts.mafiaTalk, time: mafiaTalkTime)),
        '/wakeUp': (context) => Scaffold(body: CenterButton(onPressed: () => context.read<GameLogic>().startDay(), goNext: '/speeches', text: texts.wakeUp)),
        '/speeches': (context) => Speeches(time: playerSpeechTime),
        '/votes': (context) => Voting(),
        '/playerKilled': (context) {
          texts.number = context.read<GameLogic>().killed;
          return Scaffold(
            body: CenterButton(
              goNext: '/nightStarts',
              text: texts.playerKilled,
            ),
          );
        },
        '/nightStarts': (context) => Scaffold(body: CenterButton(onPressed: () => {}, goNext: '/homescreen', text: texts.nightStarts)),
        '/revote': (context) => Speeches(time: revoteSpeechTime, pushForVote: false),
        '/voteKillAll': (context) => VoteKillAll(goNext: '/nightStarts'),
      },
    );
  }
}

class Homescreen extends StatelessWidget {
  const Homescreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CenterButton(
        onPressed: () {
          context.read<GameLogic>().genRoles();
          Navigator.pushNamed(context, '/getRoles');
        },
        text: texts.start,
      ),
    );
  }
}

class GetRoles extends StatefulWidget {
  const GetRoles({super.key});

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
      Navigator.pushNamed(context, '/mafiaTalk');
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
      return Scaffold(body: CenterButton(onPressed: _showRole, text: texts.getRole));
    } else {
      texts.str = texts.role(context.read<GameLogic>().getRole(_playerNum));
      return Scaffold(body: CenterButton(onPressed: _nextPlayer, text: texts.showRole));
    }
  }
}

class CenterButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final String? goNext;

  const CenterButton({super.key, this.onPressed, required this.text, this.goNext});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          if (onPressed != null) {
            onPressed!();
          }
          if (goNext != null) {
            Navigator.pushNamed(context, goNext!);
          }
        },
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
  const TimerWidget({super.key, required this.text, required this.time, this.goNext, this.onFinished, this.resetTimer=false});
  final String text;
  final int time;
  final String? goNext;
  final VoidCallback? onFinished;
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
            if (widget.onFinished != null) {
              widget.onFinished!();
            }
            if (widget.goNext != null) {
              Navigator.pushNamed(context, widget.goNext!);
            }
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
  const Speeches({super.key, required this.time, this.pushForVote = true});
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
      if (widget.pushForVote) {
        switch (context.read<GameLogic>().prevote()) {
          case (PrevoteResult.cancel):
            Navigator.pushNamed(context, '/nightStarts');
          case (PrevoteResult.killedOne):
            Navigator.pushNamed(context, '/playerKilled');
          case (PrevoteResult.needVote):
            Navigator.pushNamed(context, '/votes');
        }
      } else {
        Navigator.pushNamed(context, '/votes');
      }
      return;
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
    return Scaffold(
      body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Talk(
            time: widget.time,
            onFinished: () => _nextPlayer(context),
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
    ));
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

class Talk extends StatelessWidget {
  const Talk({super.key, required this.time, this.onFinished, this.resetTimer=false});
  final int time;
  final bool resetTimer;
  final VoidCallback? onFinished;

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TimerWidget(
            onFinished: onFinished,
            text: texts.playerSpeech,
            time: time,
            resetTimer: resetTimer,
          ),
          CenterButton(
            onPressed: onFinished,
            text: texts.endSpeech,
          ),
        ],
      );
  }
}

class Voting extends StatefulWidget {
  const Voting({super.key});

  @override
  State<Voting> createState() => _VotingState();
}

class _VotingState extends State<Voting> {
  int? _curVotes;
  Iterator<int>? _playersToVoteFor;
  bool running = false;

  void _endVoting() {
      switch (context.read<GameLogic>().votingResult()) {
        case VotingResult.cancel:
          Navigator.pushNamed(context, '/nightStarts');
        case VotingResult.killed:
          Navigator.pushNamed(context, '/playerKilled');
        case VotingResult.revote:
          Navigator.pushNamed(context, '/revote');
        case VotingResult.voteKillAll:
          Navigator.pushNamed(context, '/voteKillAll');
      }
  }

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
        _endVoting();
        return;
      }
      if (_playersToVoteFor!.moveNext()) {
        setState(() {
          _curVotes = null;
        });
      } else {
        context.read<GameLogic>().calculateVotesForLastPlayer();
        _endVoting();
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
    return Scaffold(
      body: Column(
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
    ));
  }
}

class VoteKillAll extends StatefulWidget {
  const VoteKillAll({super.key, required this.goNext});
  final String goNext;

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
        Navigator.pushNamed(context, widget.goNext);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (showKilled) {
      texts.numbers = context.read<GameLogic>().playersForVote;
      return Scaffold(body: CenterButton(goNext: widget.goNext, text: texts.multiplePlayersKilled));
    }
    texts.number2 = _votesForKillAll;
    return Scaffold( 
      body: Column(
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
    ));
  }
}
