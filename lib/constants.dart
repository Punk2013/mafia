import 'package:flutter/material.dart';
import 'gamelogic.dart';

const double fontsize = 18;
const double fontsizeLarge = 24;
const double spacing = 5.0;
const buttonColor = Colors.grey;

int mafiaTalkTime = 1;
int playerSpeechTime = 60;

abstract class Texts {
  int number = 1;
  int? number2;
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
  String get playerKilled;
  String get nightStarts;
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
  String get playerKilled {
    return "Игрок $number убит";
  }

  @override 
  String get nightStarts {
    return "Город засыпает";
  }
}
