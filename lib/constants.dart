import 'package:flutter/material.dart';
import 'gamelogic.dart';

const double fontsize = 18;
const double fontsizeLarge = 24;
const double spacing = 5.0;
const buttonColor = Colors.grey;

int mafiaTalkTime = 1;
int playerSpeechTime = 60;
int killedSpeechTime = 60;
int revoteSpeechTime = 30;

abstract class Texts {
  int number = 1;
  int? number2;
  List<int>? numbers;
  String str = '';

  String role(Role role);

  String get title;
  String get start;
  String get getRole;
  String get showRole;
  String get mafiaTalk;
  String get wakeUp;
  String get playerSpeech;
  String get endSpeech;
  String get addForVote;
  String get inputVotes;
  String get next;
  String get playersKilled;
  String get nightStarts;
  String get whoForKillAll;
  String get pickPlayer;
  String get checkForCommissar;
  String get isCommissar;
  String get isNotCommissar;
  String get isMafia;
  String get isNotMafia;
  String get civiliansWon;
  String get mafiaWon;
}

class RuTexts extends Texts {
  @override
  String role(Role role) {
    switch (role) {
      case Role.civilian:
        return "Мирный житель";
      case Role.commissar:
        return "Комиссар";
      case Role.mafia:
        return "Мафия";
      case Role.don:
        return "Дон";
    }
  }

  @override
  String get title {
    return "Мафия";
  }
  @override
  String get start {
    return "Начать";
  }

  @override
  String get getRole {
    return "Получить роль игрока $number";
  }

  @override
  String get showRole {
    return "Роль игрока $number: $str";
  }

  @override
  String get mafiaTalk {
    return "Мафии договариваются";
  }

  @override
  String get wakeUp {
    return "Город просыпается";
  }

  @override
  String get playerSpeech {
    return "Речь игрока $number";
  }

  @override
  String get endSpeech {
    return "Закончить";
  }

  @override 
  String get addForVote {
    if (number2 == null) {
      return "Выставить";
    } else {
      return "Выставить(выбран $number2)";
    }
  }

  @override
  String get inputVotes {
    if (number2 == null) {
      return "Введите количество голосов за игрока $number";
    } else {
      return "Введите количество голосов за игрока $number(выбрано $number2)";
    }
  }

  @override
  String get next {
    return "Далее";
  }

  @override
  String get playersKilled {
    assert(numbers != null);
    if (numbers!.length == 1) {
      return "Игрок ${numbers![0]} убит";
    } else {
      return "Игроки ${numbers!.join(', ')} убиты";
    }
  }

  @override 
  String get nightStarts {
    return "Город засыпает";
  }

  @override
  String get whoForKillAll {
    if (number2 == null) {
      return "Голосов за то, чтобы убрать всех";
    } else {
      return "Голосов за то, чтобы убрать всех(выбрано $number2)";
    }
  }

  @override
  String get pickPlayer {
    if (number2 == null) {
      return "Игрок $number, выберете одного игрока";
    } else {
      return "Игрок $number, выберете одного игрока(выбран $number2)";
    }
  }

  @override
  String get checkForCommissar {
    if (number2 == null) {
      return "Выберете игрока для проверки";
    } else {
      return "Выберете игрока для проверки(выбран $number2)";
    }
  }

  @override
  String get isCommissar {
    return "Игрок $number комиссар";
  }
  @override
  String get isNotCommissar {
    return "Игрок $number не комиссар";
  }
  @override
  String get isMafia {
    return "Игрок $number мафия";
  }
  @override
  String get isNotMafia {
    return "Игрок $number не мафия";
  }
  @override
  String get civiliansWon {
    return "Победа мирных";
  }
  @override
  String get mafiaWon {
    return "Победа мафии";
  }
}
