class FaqItem {
  final String question;
  final String answer;

  FaqItem({required this.question, required this.answer});

  Map<String, dynamic> toJson() => {
        'q': question,
        'a': answer,
      };

  factory FaqItem.fromJson(Map<String, dynamic> json) =>
      FaqItem(question: json['q'], answer: json['a']);
}

class TutorialItem {
  final String title;

  TutorialItem({required this.title});

  Map<String, dynamic> toJson() => {'title': title};

  factory TutorialItem.fromJson(Map<String, dynamic> json) =>
      TutorialItem(title: json['title']);
}
