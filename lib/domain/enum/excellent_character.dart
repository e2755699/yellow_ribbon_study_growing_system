enum ExcellentCharacter {
  responsibility('責任感'),
  honesty('誠實'),
  respect('尊重'),
  selfDiscipline('自律'),
  courage('勇氣'),
  empathy('同理心'),
  cooperation('合作'),
  perseverance('毅力'),
  responsibleFreedom('負責任的自由'),
  gratitude('感恩'),
  homeworkCompleted('完成作業'),
  helper('小幫手');

  final String label;

  const ExcellentCharacter(this.label);

  factory ExcellentCharacter.fromString(String characterStr) {
    return ExcellentCharacter.values
        .where((character) => character.name == characterStr)
        .first;
  }

  static List<ExcellentCharacter> fromList(List<String> characterStrs) {
    if (characterStrs.isEmpty) return [];
    return characterStrs
        .map((str) => ExcellentCharacter.fromString(str))
        .toList();
  }

  bool get isSpecialTag => this == ExcellentCharacter.homeworkCompleted || this == ExcellentCharacter.helper;
} 