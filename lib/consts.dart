class VoteValue {
  late int value;
  late String displayValue;
  late String displayName;

  VoteValue({
    this.value = 0,
    this.displayName = '',
    this.displayValue = '',
  });
}

class Consts {
  static double storyCardHeight = 255;
  static double storyCardWidth = 260;
  static double storiesAreaWidth = storyCardWidth + 5;

  static double userCardWidth = 300;
  static double usersArea = userCardWidth + 5;

  //static double mainAreaHeight = 500;

  static List<VoteValue> fibonacciListValues = [
    VoteValue(value: 0, displayValue: 'Um café', displayName: 'Um café'),
    VoteValue(value: 1, displayValue: '1', displayName: 'Um'),
    VoteValue(value: 2, displayValue: '2', displayName: 'Dois'),
    VoteValue(value: 3, displayValue: '3', displayName: 'Três'),
    VoteValue(value: 5, displayValue: '5', displayName: 'Cinco'),
    VoteValue(value: 8, displayValue: '8', displayName: 'Oito'),
    VoteValue(value: 13, displayValue: '13', displayName: 'Treze'),
    VoteValue(value: 21, displayValue: '21', displayName: 'Vinte e um'),
    VoteValue(value: 34, displayValue: '34', displayName: 'Trinta e quatro'),
    VoteValue(value: 55, displayValue: '55', displayName: 'Cinquenta e cinco'),
    VoteValue(value: 100, displayValue: '100', displayName: 'Cem'),
  ];

  static List<VoteValue> tshirtListValues = [
    VoteValue(value: 0, displayValue: 'PP', displayName: 'Muito Pequeno'),
    VoteValue(value: 1, displayValue: 'P', displayName: 'Pequeno'),
    VoteValue(value: 2, displayValue: 'M', displayName: 'Médio'),
    VoteValue(value: 3, displayValue: 'G', displayName: 'Grande'),
    VoteValue(value: 5, displayValue: 'GG', displayName: 'Muito Grande'),
    VoteValue(value: 8, displayValue: 'XG', displayName: 'Extremamente Grande'),
  ];
}
