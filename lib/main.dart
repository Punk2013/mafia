import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants.dart';
import 'gamelogic.dart';
import 'common_widgets.dart';

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
        '/mafiaTalk': (context) => Scaffold(body: TimerWidget(onFinished: () => Navigator.pushReplacementNamed(context, '/mafiaFallsAsleep'), text: texts.mafiaTalk, time: mafiaTalkTime)),
        '/mafiaFallsAsleep': (context) => Scaffold(body: TimerWidget(onFinished: () => Navigator.pushReplacementNamed(context, '/commissarLook'), text: texts.mafiaFallsAsleep, time: fallAsleepTime)),
        '/commissarLook': (context) => Scaffold(body: TimerWidget(onFinished: () => Navigator.pushReplacementNamed(context, '/commissarFallsAsleep'), text: texts.commissarLook, time: commissarLookTime)),
        '/commissarFallsAsleep': (context) => Scaffold(body: TimerWidget(onFinished: () => Navigator.pushReplacementNamed(context, '/wakeUp'), text: texts.commissarFallsAsleep, time: fallAsleepTime)),
        '/wakeUp': (context) => Scaffold(
          body: CenterButton(
            onPressed: () {
              if (context.read<GameLogic>().wasMurdered) {
                final int murdered = context.read<GameLogic>().personMurdered;
                texts.number = murdered;
                texts.numbers = [murdered];
                context.read<GameLogic>().startDay();
                Navigator.pushReplacementNamed(context, '/playerMurdered');
                return;
              }
              context.read<GameLogic>().startDay();
              Navigator.pushReplacementNamed(context, '/speeches');
            },
            text: texts.wakeUp,
          ),
        ),
        '/speeches': (context) => Speeches(time: playerSpeechTime),
        '/votes': (context) => Voting(),
        '/playersKilled': (context) {
          texts.numbers = context.read<GameLogic>().killed;
          return Scaffold(
            body: CenterButton(
              onPressed: () {
                final gameStatus = context.read<GameLogic>().gameStatus;
                if (gameStatus == GameStatus.civiliansWon) {
                  Navigator.pushReplacementNamed(context, '/civiliansWon');
                } else if (gameStatus == GameStatus.mafiaWon) {
                  Navigator.pushReplacementNamed(context, '/mafiaWon');
                } else {
                  Navigator.pushReplacementNamed(context, '/killedSpeeches');
                }
              },
              text: texts.playersKilled,
            ),
          );
        },
        '/nightStarts': (context) => Scaffold(body: CenterButton(onPressed: () => Navigator.pushReplacementNamed(context, '/nightPicking'), text: texts.nightStarts)),
        '/revote': (context) => Speeches(time: revoteSpeechTime, pushForVote: false),
        '/voteKillAll': (context) => VoteKillAll(),
        '/killedSpeeches': (context) => Speeches(time: killedSpeechTime, pushForVote: false, nextScreen: '/nightStarts'),
        '/nightPicking': (context) => NightPicking(),
        '/playerMurdered': (context) => Scaffold(
          body: CenterButton(
            onPressed: () {
              final gameStatus = context.read<GameLogic>().gameStatus;
              if (gameStatus == GameStatus.civiliansWon) {
                Navigator.pushReplacementNamed(context, '/civiliansWon');
              } else if (gameStatus == GameStatus.mafiaWon) {
                Navigator.pushReplacementNamed(context, '/mafiaWon');
              } else {
                Navigator.pushReplacementNamed(context, '/murderedTalk');
              }
            },
            text: texts.playersKilled,
          ),
        ),
        '/murderedTalk': (context) => Scaffold(body: Talk(onFinished: () => Navigator.pushReplacementNamed(context, '/speeches'), time: killedSpeechTime)),
        '/civiliansWon': (context) => Scaffold(body: CenterButton(onPressed: () => Navigator.pushReplacementNamed(context, '/homescreen'), text: texts.civiliansWon)),
        '/mafiaWon': (context) => Scaffold(body: CenterButton(onPressed: () => Navigator.pushReplacementNamed(context, '/homescreen'), text: texts.mafiaWon)),
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
          Navigator.pushReplacementNamed(context, '/getRoles');
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
    if (_playerNum == context.read<GameLogic>().playersAlive.length) {
      Navigator.pushReplacementNamed(context, '/mafiaTalk');
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

class Speeches extends StatefulWidget {
  const Speeches({
    super.key,
    required this.time,
    this.pushForVote = true,
    this.nextScreen = '/votes',
  });
  final int time;
  final bool pushForVote;
  final String nextScreen;

  @override
  State<Speeches> createState() => _SpeechesState();
}

class _SpeechesState extends State<Speeches> {
  int? _forVote;
  bool _resetTimer = false;
  Iterator<int>? _playersToSpeak;
  bool _running = false;

  void _nextPlayer(BuildContext context) {
    if (_forVote != null) {
      context.read<GameLogic>().addForVote(_forVote!);
      _forVote = null;
    }
    if (!_playersToSpeak!.moveNext()) {
      if (widget.pushForVote) {
        switch (context.read<GameLogic>().prevote()) {
          case (PrevoteResult.cancel):
            Navigator.pushReplacementNamed(context, '/nightStarts');
          case (PrevoteResult.killedOne):
            Navigator.pushReplacementNamed(context, '/playersKilled');
          case (PrevoteResult.needVote):
            Navigator.pushReplacementNamed(context, '/votes');
        }
      } else {
        Navigator.pushReplacementNamed(context, widget.nextScreen);
      }
      return;
    }
    setState(() {
      _resetTimer = true;
    });
  }

  void _changeForVote(int? value) {
    setState(() {
      _resetTimer = false;
      _forVote = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_running) {
      _playersToSpeak = context.read<GameLogic>().playersToSpeak(!widget.pushForVote);
      _running = true;
    }
    texts.number = _playersToSpeak!.current;
    texts.number2 = _forVote;
    return Scaffold(
      body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Talk(
            time: widget.time,
            onFinished: () => _nextPlayer(context),
            resetTimer: _resetTimer,
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

class Voting extends StatefulWidget {
  const Voting({super.key});

  @override
  State<Voting> createState() => _VotingState();
}

class _VotingState extends State<Voting> {
  int? _curVotes;
  Iterator<int>? _playersToVoteFor;
  bool _running = false;

  void _endVoting() {
      switch (context.read<GameLogic>().votingResult()) {
        case VotingResult.cancel:
          Navigator.pushReplacementNamed(context, '/nightStarts');
        case VotingResult.killed:
          Navigator.pushReplacementNamed(context, '/playersKilled');
        case VotingResult.revote:
          Navigator.pushReplacementNamed(context, '/revote');
        case VotingResult.voteKillAll:
          Navigator.pushReplacementNamed(context, '/voteKillAll');
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
    if (!_running) {
      _playersToVoteFor = context.read<GameLogic>().playersToVoteFor;
      _running = true;
    }
    final playerNum = _playersToVoteFor!.current;
    texts.number = playerNum;
    texts.number2 = _curVotes;
    texts.numbers = context.read<GameLogic>().playersForVote;
    return Scaffold(
      body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CenterButton(text: texts.forVote, onPressed: () => {}),
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
  const VoteKillAll({super.key});

  @override
  State<VoteKillAll> createState() => _VoteKillAllState();
}

class _VoteKillAllState extends State<VoteKillAll> {
  int? _votesForKillAll;

  void _onPressed() {
    if (_votesForKillAll != null) {
      final res = context.read<GameLogic>().votingKillAllResult(_votesForKillAll!);
      if (res == VotingResult.killed) {
        Navigator.pushReplacementNamed(context, '/playersKilled');
      } else {
        Navigator.pushReplacementNamed(context, '/nightStarts');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

class NightPicking extends StatefulWidget {
  const NightPicking({super.key});

  @override
  State<NightPicking> createState() => _NightPickingState();
}

class _NightPickingState extends State<NightPicking> {
  int? _picked;
  Iterator<int>? _playersToPick;
  int _currentPlayer = 0;
  bool _running = false;
  bool _donIsPicking = false;

  void _nextPick() {
    if (_picked == null) {
      return;
    }
    final res = context.read<GameLogic>().inputPick(_currentPlayer, _picked!, _donIsPicking);
    _donIsPicking = false;
    switch (res) {
      case PickResult.none:
        break;
      case PickResult.donPick:
        _donIsPicking = true;
      case PickResult.commissar:
        texts.number = _picked!;
        late OverlayEntry overlayEntry;
        overlayEntry = OverlayEntry(builder: (context) => Scaffold(body: CenterButton(text: texts.isCommissar, onPressed: () => overlayEntry.remove())));
        Overlay.of(context).insert(overlayEntry);
      case PickResult.notCommissar:
        texts.number = _picked!;
        late OverlayEntry overlayEntry;
        overlayEntry = OverlayEntry(builder: (context) => Scaffold(body: CenterButton(text: texts.isNotCommissar, onPressed: () => overlayEntry.remove())));
        Overlay.of(context).insert(overlayEntry);
      case PickResult.mafia:
        texts.number = _picked!;
        late OverlayEntry overlayEntry;
        overlayEntry = OverlayEntry(builder: (context) => Scaffold(body: CenterButton(text: texts.isMafia, onPressed: () => overlayEntry.remove())));
        Overlay.of(context).insert(overlayEntry);
      case PickResult.notMafia:
        texts.number = _picked!;
        late OverlayEntry overlayEntry;
        overlayEntry = OverlayEntry(builder: (context) => Scaffold(body: CenterButton(text: texts.isNotMafia, onPressed: () => overlayEntry.remove())));
        Overlay.of(context).insert(overlayEntry);
    }
    if (_donIsPicking) {
      setState(() {
        _picked = null;
        _running = true;
      });
      return;
    }
    if (!_playersToPick!.moveNext()) {
      Navigator.pushReplacementNamed(context, '/wakeUp');
      _running = false;
    } else {
      setState((){
        _picked = null;
        _running = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_running) {
      _playersToPick = context.read<GameLogic>().playersToPick;
      _running = true;
    }
    _currentPlayer = _playersToPick!.current;
    texts.number = _currentPlayer;
    texts.number2 = _picked;
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NumberDropdown(
            hint: _donIsPicking ? texts.checkForCommissar : texts.pickPlayer,
            items: context.read<GameLogic>().pickList,
            onChanged: (value) => setState(() => _picked = value),
          ),
          CenterButton(onPressed: _nextPick, text: texts.next),
        ],
      ),
    );
  }
}
