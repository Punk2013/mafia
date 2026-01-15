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

  List<int> _playersForVote = [];
  final LinkedHashMap<int, int> _votes = LinkedHashMap();
  List<int> _playersWonPrevVoting = [];

  Role getRole(int playerNum) {
    assert(_players.keys.contains(playerNum));
    return _players[playerNum]!;
  }

  int get alive {
    return _players.length;
  }

  int get voting {
    return alive;
  }

  void kill(int playerNum) {
    _players.remove(playerNum);
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
  }

  void addForVote(int playerNum) {
    _playersForVote.add(playerNum);
  }

  List<int> get playersForVote {
    return _playersForVote;
  }

  void inputVotesForPlayer(int playerNum, int voteCount) {
    _votes[playerNum] = voteCount;
  }

  void calculateVotesForLastPlayer() {
    _votes[_playersForVote.last] =
        voting - _votes.values.reduce((value, element) => value + element);
  }

  VotingResult votingResult() {
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

enum VotingResult {
  cancel,
  killed,
  revote,
  voteKillAll;
}
