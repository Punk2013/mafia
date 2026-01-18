import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'dart:math';

enum Role {
  civilian,
  mafia,
  don,
  commissar;
}

class GameLogic with ChangeNotifier {
  final int playerCount = 10;
  final int activeCount = 4;

  final LinkedHashMap<int, Role> _players = LinkedHashMap();

  int _currentDay = 0;
  int _firstToSpeak = 1;
  Iterator<int>? _nextToSpeak;

  List<int> _playersForVote = [];
  final LinkedHashMap<int, int> _votes = LinkedHashMap();
  List<int> _playersWonPrevVoting = [];

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

  int get personToSpeak {
    return _nextToSpeak!.current;
  }

  void initRevote() {
    _nextToSpeak = _playersWonPrevVoting.iterator..moveNext();
  }

  bool changeSpeaker() {
    return _nextToSpeak!.moveNext();
  }

  int get voting {
    return alive;
  }

  void kill(int playerNum) {
    _players.remove(playerNum);
    debugPrint("$_players");
  }

  int get killed {
    return _playersWonPrevVoting[0];
  }

  void genRoles() {
    final rand = Random();
    for (int i = 1; i <= playerCount; i++) {
      _players[i] = Role.civilian;
    }

    var activeAssigned = 0;
    while (activeAssigned < activeCount) {
      var num = rand.nextInt(playerCount) + 1;

      if (activeAssigned == 0 && _players[num] == Role.civilian) {
        _players[num] = Role.commissar;
        activeAssigned++;
      } else if (activeAssigned == 1 && _players[num] == Role.civilian) {
        _players[num] = Role.don;
        activeAssigned++;
      } else if (_players[num] == Role.civilian) {
        _players[num] = Role.mafia;
        activeAssigned++;
      }
    }
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

    _nextToSpeak =
        playersAlive
            .skipWhile((el) => el != _firstToSpeak)
            .followedBy(playersAlive.takeWhile((el) => el != _firstToSpeak))
            .iterator
          ..moveNext();
  }

  void addForVote(int playerNum) {
    _playersForVote.add(playerNum);
    debugPrint("$_playersForVote");
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
