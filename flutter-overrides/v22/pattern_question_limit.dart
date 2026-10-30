// Combined pattern quizzes use every selected question by default.
// A custom maximum only limits the session when explicitly selected.
List<T> selectedPatternQuestions<T>(List<T> questions, {int? maximum}) =>
    maximum == null ? List<T>.of(questions) : questions.take(maximum < 1 ? 1 : maximum).toList();
