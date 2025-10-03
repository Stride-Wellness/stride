class UserDataModel {
  final String id;
  final String name;
  final String email;
  final Map<String, List<String>> quizAnswers;

  UserDataModel({
    required this.id,
    required this.name,
    required this.email,
    Map<String, List<String>>? quizAnswers,
  }) : quizAnswers = quizAnswers ?? {};

  factory UserDataModel.fromMap(Map<String, dynamic> data) {
    return UserDataModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      quizAnswers: Map<String, List<String>>.from(
        data['quizAnswers']?.map((key, value) {
          return MapEntry(key, List<String>.from(value));
        }) ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'quizAnswers': quizAnswers,
    };
  }
}