import 'package:flutter/material.dart';
import 'dart:math';

enum Role {
  civilian,
  mafia,
  don,
  commissar;
}

class GameLogic with ChangeNotifier {
  Map<int, Role> players = {};
  final int playerCount = 10;
  final int activeCount = 4;

  Role getRole(int playerNum) {
    assert (players.keys.contains(playerNum));
    return players[playerNum]!;
  }

  void genRoles() {
    final rand = Random();
    for (int i = 1; i <= playerCount; i++) {
      players[i] = Role.civilian;
    }

    var activeAssigned = 0;
    while (activeAssigned < activeCount) {
      var num = rand.nextInt(playerCount) + 1;

      if (activeAssigned == 0 && players[num] == Role.civilian) {
        players[num] = Role.commissar;
        activeAssigned++;
      } else if (activeAssigned == 1 && players[num] == Role.civilian) {
        players[num] = Role.don;
        activeAssigned++;
      } else if (players[num] == Role.civilian) {
        players[num] = Role.mafia;
        activeAssigned++;
      }
    }
    debugPrint("$players");
  }
}