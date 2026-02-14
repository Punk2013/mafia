import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:mafia/constants.dart';

enum Role {
  civilian,
  mafia,
  don,
  commissar;
}

class GameLogic with ChangeNotifier {
  final LinkedHashMap<int, Role> _players = LinkedHashMap();

  int _currentDay = 0;
  int _firstToSpeak = 1;

  List<int> _playersForVote = [];
  final LinkedHashMap<int, int> _votes = LinkedHashMap();
  List<int> _playersWonPrevVoting = [];

  int? _mafiaPick;

  Role getRole(int playerNum) {
    assert(playersAlive.contains(playerNum));
    return _players[playerNum]!;
  }

  Iterator<int> get playersToVoteFor {
    return _playersForVote.take(_playersForVote.length - 1).iterator
      ..moveNext();
  }

  PrevoteResult prevote() {
    if (playersForVote.isEmpty) {
      return PrevoteResult.cancel;
    } else if (playersForVote.length == 1) {
      if (_currentDay == 1) {
        return PrevoteResult.cancel;
      }
      final player = playersForVote[0];
      _playersWonPrevVoting = [player];
      kill(player);
      return PrevoteResult.killedOne;
    } else {
      return PrevoteResult.needVote;
    }
  }

  int get alive {
    return _players.length;
  }

  Iterable<int> get playersAlive {
    return _players.keys;
  }

  List<int> get playersNotForVote {
    return playersAlive.where((el) => !_playersForVote.contains(el)).toList();
  }

  Iterator<int> playersToSpeak([bool voting=false]) {
    if (!voting) {
      return playersAlive
          .skipWhile((el) => el != _firstToSpeak)
          .followedBy(playersAlive.takeWhile((el) => el != _firstToSpeak))
          .iterator
        ..moveNext();
    } else {
      return _playersWonPrevVoting.iterator..moveNext();
    }
  }

  Iterator<int> get playersToPick {
    late int firstToPick;
    final playerIt = playersAlive.skipWhile((el) => el < _firstToSpeak);
    if (playerIt.isEmpty) {
      firstToPick = playersAlive.first;
    } else {
      firstToPick = playerIt.first;
    }

    return playersAlive
        .skipWhile((el) => el != firstToPick)
        .followedBy(playersAlive.takeWhile((el) => el != firstToPick))
        .iterator
      ..moveNext();
  }

  List<int> get pickList {
    return _players.keys.toList();
  }

  PickResult inputPick(int player, int playerPicked, [bool donIsPicking=false]) {
    final role = _players[player];
    final checkedRole = _players[playerPicked];
    if (role == Role.civilian) {
      return PickResult.none; 
    }
    if (donIsPicking) {
      assert(role == Role.don);
      if (checkedRole == Role.commissar) {
        return PickResult.commissar;
      }
      return PickResult.notCommissar;
    }
    if (role == Role.commissar) {
      if (checkedRole == Role.mafia || checkedRole == Role.don) {
        return PickResult.mafia;
      }
      return PickResult.notMafia;
    } else {
      if (_mafiaPick == null) {
        _mafiaPick = playerPicked;
      } 
      else if (_mafiaPick != playerPicked) {
        _mafiaPick = 0;
      }
      if (role == Role.don) {
        return PickResult.donPick;
      } else {
        return PickResult.none;
      }
    }
  }

  bool get wasMurdered {
    if (_currentDay != 0) {
      assert(_mafiaPick != null);
      return _mafiaPick != 0;
    } else {
      return false;
    }
  }

  int get personMurdered {
    assert(_mafiaPick != null);
    kill(_mafiaPick!);
    return _mafiaPick!;
  }

  int get voting {
    return alive;
  }

  void kill(int playerNum) {
    _players.remove(playerNum);
    debugPrint("$_players");
  }

  List<int> get killed {
    return _playersWonPrevVoting;
  }

  void genRoles() {
    final rolesShuffled = List<Role>.from(defaultRoles)..shuffle();
    for (int i = 1; i <= rolesShuffled.length; i++) {
      _players[i] = rolesShuffled[i - 1];
    }

    // debug
    // _players[1] = Role.civilian;
    // _players[2] = Role.civilian;
    // _players[3] = Role.civilian;
    // _players[4] = Role.civilian;
    // _players[5] = Role.commissar;
    // _players[6] = Role.civilian;
    // _players[7] = Role.don;
    // _players[8] = Role.mafia;
    // _players[9] = Role.civilian;
    // _players[10] = Role.mafia;
    debugPrint("$_players");
  }

  void startDay() {
    _playersForVote.clear();
    _votes.clear();
    _playersWonPrevVoting.clear();
    _currentDay++;

    if (_currentDay != 1) {
      final playerIt = playersAlive.skipWhile((el) => el <= _firstToSpeak);
      if (playerIt.isEmpty) {
        _firstToSpeak = playersAlive.first;
      } else {
        _firstToSpeak = playerIt.first;
      }
    }

    _mafiaPick = null;
  }

  void addForVote(int playerNum) {
    _playersForVote.add(playerNum);
    debugPrint("$_playersForVote");
  }

  GameStatus get gameStatus {
    int civilians = 0;
    int mafias = 0;
    for (final role in _players.values) {
      if (role == Role.civilian || role == Role.commissar) {
        civilians++;
      } else {
        mafias++;
      }
    }
    assert(civilians + mafias > 0);
    if (mafias == 0) {
      return GameStatus.civiliansWon;
    } else if (mafias >= civilians) {
      return GameStatus.mafiaWon;
    } else {
      return GameStatus.ongoing;
    }
  }

  List<int> get playersForVote {
    return _playersForVote;
  }

  void inputVotesForPlayer(int playerNum, int voteCount) {
    _votes[playerNum] = voteCount;
  }

  void calculateVotesForLastPlayer() {
    _votes[_playersForVote.last] = votesLeft;
  }

  int get votesLeft {
    if (_votes.values.isEmpty) {
      return voting;
    }
    return voting - _votes.values.reduce((value, element) => value + element);
  }

  void setLeftCandidatesZeroVotes() {
    for (final candidate in playersForVote) {
      if (!_votes.containsKey(candidate)) {
        _votes[candidate] = 0;
      }
    }
  }

  VotingResult votingResult() {
    debugPrint("$_votes");
    if (_playersForVote.isEmpty) {
      return VotingResult.cancel;
    }

    if (_playersForVote.length == 1 && _currentDay == 1) {
      return VotingResult.cancel;
    }

    List<int> playersWithMaxVotes = [_playersForVote[0]];
    int maxVotes = _votes[playersWithMaxVotes[0]]!;

    for (int i = 1; i < _playersForVote.length; i++) {
      final int player = _playersForVote[i];
      final int votes = _votes[player]!;
      if (votes > maxVotes) {
        maxVotes = votes;
        playersWithMaxVotes = [player];
      } else if (votes == maxVotes) {
        playersWithMaxVotes.add(player);
      }
    }

    if (playersWithMaxVotes.length == 1) {
      kill(playersWithMaxVotes[0]);
      _playersWonPrevVoting = [...playersWithMaxVotes];
      return VotingResult.killed;
    } else {
      if (listEquals(playersWithMaxVotes, _playersWonPrevVoting)) {
        if (playersWithMaxVotes.length == alive) {
          return VotingResult.cancel;
        }
        if (playersWithMaxVotes.length == 3 && alive == 9) {
          return VotingResult.cancel;
        }
        _playersWonPrevVoting = [...playersWithMaxVotes];
        _playersForVote = [...playersWithMaxVotes];
        return VotingResult.voteKillAll;
      } else {
        _votes.clear();
        _playersWonPrevVoting = [...playersWithMaxVotes];
        _playersForVote = [...playersWithMaxVotes];
        debugPrint("$_playersWonPrevVoting");
        return VotingResult.revote;
      }
    }
  }

  VotingResult votingKillAllResult(int votesToKill) {
    final votesToCancel = voting - votesToKill;
    if (votesToCancel >= votesToKill) {
      return VotingResult.cancel;
    } else {
      for (final player in _playersWonPrevVoting) {
        kill(player);
      }
      return VotingResult.killed;
    }
  }
}

enum VotingResult { cancel, killed, revote, voteKillAll }
enum PrevoteResult { cancel, needVote, killedOne }
enum PickResult {none, donPick, commissar, notCommissar, mafia, notMafia}
enum GameStatus{ongoing, civiliansWon, mafiaWon}