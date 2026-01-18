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
        '/mafiaTalk': (context) => Scaffold(body: TimerWidget(onFinished: () => Navigator.pushReplacementNamed(context, '/wakeUp'), text: texts.mafiaTalk, time: mafiaTalkTime)),
        '/wakeUp': (context) => Scaffold(
          body: CenterButton(
            onPressed: () {
              context.read<GameLogic>().startDay();
              Navigator.pushReplacementNamed(context, '/speeches');
            },
            text: texts.wakeUp,
          ),
        ),
        '/speeches': (context) => Speeches(time: playerSpeechTime),
        '/votes': (context) => Voting(),
        '/playerKilled': (context) {
          texts.number = context.read<GameLogic>().killed;
          return Scaffold(
            body: CenterButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/nightStarts'),
              text: texts.playerKilled,
            ),
          );
        },
        '/nightStarts': (context) => Scaffold(body: CenterButton(onPressed: () => Navigator.pushReplacementNamed(context, '/homescreen'), text: texts.nightStarts)),
        '/revote': (context) => Speeches(time: revoteSpeechTime, pushForVote: false),
        '/voteKillAll': (context) => VoteKillAll(),
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
    if (_playerNum == context.read<GameLogic>().playerCount) {
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
  const Speeches({super.key, required this.time, this.pushForVote = true});
  final int time;
  final bool pushForVote;

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
            Navigator.pushReplacementNamed(context, '/playerKilled');
          case (PrevoteResult.needVote):
            Navigator.pushReplacementNamed(context, '/votes');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/votes');
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
          Navigator.pushReplacementNamed(context, '/playerKilled');
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
  const VoteKillAll({super.key});

  @override
  State<VoteKillAll> createState() => _VoteKillAllState();
}

class _VoteKillAllState extends State<VoteKillAll> {
  int? _votesForKillAll;
  bool _showKilled = false;

  void _onPressed() {
    if (_votesForKillAll != null) {
      final res = context.read<GameLogic>().votingKillAllResult(_votesForKillAll!);
      if (res == VotingResult.killed) {
        setState(() {
          _showKilled = true;
        });
      } else {
        Navigator.pushReplacementNamed(context, '/nightStarts');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showKilled) {
      texts.numbers = context.read<GameLogic>().playersForVote;
      return Scaffold(body: CenterButton(onPressed: () => Navigator.pushReplacementNamed(context, '/nightStarts'), text: texts.multiplePlayersKilled));
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
