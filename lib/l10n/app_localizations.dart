import 'package:flutter/material.dart';

abstract class AppLocalizations {
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Home
  String get homeTitle;
  String get homeCurrentLanguagePairLabel;
  String get homeEditButton;
  String get homeNoTopicsSelectedYet;
  String get homePlayWordMatch;
  String get homeStartQuiz;
  String get homePlayCompleteWord;
  String get homePickTopicsToStart;
  String get homeCurrentTopics;
  String get homeNoTopicsAvailable;
  String get homeAllTopicsSelected;
  String homeTopicsSelected(int count);
  String get homeTopicsSelectedLabel;

  // Navigation
  String get navWriting;
  String get navReading;
  String get navListening;
  String get navSpeaking;
  String get navProfile;

  // Quiz
  String get quizTitle;
  String get quizNoQuestionsBody;
  String get quizQuestionLabel;
  String quizReducedQuestionsInfo(int available, int requested);
  String quizPromptHowDoYouSay(String word, String language);
  String get commonNextQuestion;

  // Complete Word
  String get completeTitle;
  String completePromptHowDoYouWrite(String word, String language);
  String get completeYourAnswerLabel;
  String get completeIgnoreAccentsLabel;
  String get completeIgnoreAccentsQuestionTitle;
  String get completeIgnoreAccentsQuestionBody;
  String get commonYes;
  String get commonNo;
  String get completeRevealLetter;
  String get completeRevealWord;
  String get completeCorrect;
  String completeCorrectAnswer(String answer);
  String get completeTakeABreak;
  String get completeBreakBody;
  String get completeBreakContinue;
  String get completeFinish;
  String get completeCheckAnswer;

  // My List
  String get myListTitle;
  String get myListSelectPairFirst;
  String get myListNotEnoughWords;
  String get myListEmptyTitle;
  String get myListEmptyBody;
  String get myListFilterByTopic;
  String get myListAllTopics;
  String get myListQuizThisList;
  String get myListPlayPronunciation;
  String get myListRemovedFromList;
  String get myListRemoveFromList;
  String get commonAddedToMyList;
  String get commonAddToMyList;

  // Common
  String get commonStartQuiz;
  String get commonPlayCompleteWord;
  String get commonPlayWordMatch;
  String get commonPickTopicsToStart;
  String get commonOk;
  String get commonToday;
  String get commonYesterday;
  String get commonClose;
  String get commonAccuracy;
  String get commonTime;
  String get commonDate;
  String get commonScore;

  // Settings
  String get settingsSectionGeneral;
  String get settingsDarkMode;
  String get settingsSectionLanguage;
  String get settingsLanguageLabel;
  String get settingsSectionQuizSettings;
  String get settingsQuizSettingsTile;
  String get settingsSectionDataManagement;
  String get settingsViewStats;
  String get settingsLoadVocabulary;
  String settingsLastUpdated(String date);
  String get settingsLastUpdatedNever;
  String get settingsSectionSupport;
  String get settingsHelpSupport;
  String get settingsAbout;
  String get settingsComingSoonTitle;
  String get settingsComingSoonBody;
  String get settingsAboutTitle;
  String get settingsAboutBody;
  String get appTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es', 'it', 'fr', 'de'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'es':
        return _SpanishLocalizations();
      case 'it':
        return _ItalianLocalizations();
      case 'fr':
        return _FrenchLocalizations();
      case 'de':
        return _GermanLocalizations();
      case 'en':
      default:
        return _EnglishLocalizations();
    }
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}

class _EnglishLocalizations implements AppLocalizations {
  @override
  String get homeTitle => 'WordWeaver';

  @override
  String get appTitle => 'WordWeaver';

  @override
  String get homeCurrentLanguagePairLabel => 'Current language pair';

  @override
  String get homeEditButton => 'Edit';

  @override
  String get homeNoTopicsSelectedYet => 'No topics selected yet';

  @override
  String get homePlayWordMatch => 'Play Word Match';

  @override
  String get homeStartQuiz => 'Start Quiz';

  @override
  String get homePlayCompleteWord => 'Play Complete Word';

  @override
  String get homePickTopicsToStart => 'Pick topics to start';

  @override
  String get homeCurrentTopics => 'Current topics';

  @override
  String get homeNoTopicsAvailable => 'No topics available';

  @override
  String get homeAllTopicsSelected => 'All topics selected';

  @override
  String homeTopicsSelected(int count) => '$count topic(s) selected';

  @override
  String get homeTopicsSelectedLabel => 'Topics selected';

  @override
  String get navWriting => 'Writing';

  @override
  String get navReading => 'Reading';

  @override
  String get navListening => 'Listening';

  @override
  String get navSpeaking => 'Speaking';

  @override
  String get navProfile => 'Profile';

  @override
  String get quizTitle => 'Quiz';

  @override
  String get quizNoQuestionsBody =>
      'No questions available for the selected topics.\nTry selecting more topics, a different language pair, or reducing the number of questions.';

  @override
  String get quizQuestionLabel => 'Question';

  @override
  String quizReducedQuestionsInfo(int available, int requested) =>
      'Only $available of $requested questions were available for the selected topics.';

  @override
  String quizPromptHowDoYouSay(String word, String language) =>
      'How do you say \'$word\' in $language?';

  @override
  String get commonNextQuestion => 'Next question';

  @override
  String get completeTitle => 'Complete the word';

  @override
  String completePromptHowDoYouWrite(String word, String language) =>
      'How do you write \'$word\' in $language?';

  @override
  String get completeYourAnswerLabel => 'Your answer';

  @override
  String get completeIgnoreAccentsLabel => 'Ignore accents (è = e)';

  @override
  String get completeIgnoreAccentsQuestionTitle => 'Ignore accents?';

  @override
  String get completeIgnoreAccentsQuestionBody =>
      'Do you want to ignore accents (è = e) for this quiz?';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get completeRevealLetter => 'Reveal letter';

  @override
  String get completeRevealWord => 'Reveal word';

  @override
  String get completeCorrect => 'Correct!';

  @override
  String completeCorrectAnswer(String answer) => 'Correct answer: $answer';

  @override
  String get completeTakeABreak => 'Take a break';

  @override
  String get completeBreakBody =>
      'Small break. In the future, an ad could be shown here.';

  @override
  String get completeBreakContinue => 'Continue';

  @override
  String get completeFinish => 'Finish';

  @override
  String get completeCheckAnswer => 'Check answer';

  @override
  String get myListTitle => 'My List';

  @override
  String get myListSelectPairFirst => 'Select a language pair first.';

  @override
  String get myListNotEnoughWords =>
      'Not enough words in My List to start a quiz yet.';

  @override
  String get myListEmptyTitle => 'No words saved yet';

  @override
  String get myListEmptyBody =>
      'Tap "Add to My List" during a quiz or in Complete Word to save vocabulary here.';

  @override
  String get myListFilterByTopic => 'Filter by topic';

  @override
  String get myListAllTopics => 'All topics';

  @override
  String get myListQuizThisList => 'Quiz this list';

  @override
  String get myListPlayPronunciation => 'Play pronunciation';

  @override
  String get myListRemovedFromList => 'Removed from My List';

  @override
  String get myListRemoveFromList => 'Remove from My List';

  @override
  String get commonAddedToMyList => 'Added to My List';

  @override
  String get commonAddToMyList => 'Add to My List';

  @override
  String get commonStartQuiz => 'Start Quiz';

  @override
  String get commonPlayCompleteWord => 'Play Complete Word';

  @override
  String get commonPlayWordMatch => 'Play Word Match';

  @override
  String get commonPickTopicsToStart => 'Pick topics to start';

  @override
  String get commonOk => 'OK';

  @override
  String get commonToday => 'Today';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get commonClose => 'Close';

  @override
  String get commonAccuracy => 'Accuracy';

  @override
  String get commonTime => 'Time';

  @override
  String get commonDate => 'Date';

  @override
  String get commonScore => 'Score';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get settingsSectionQuizSettings => 'Quiz Settings';

  @override
  String get settingsQuizSettingsTile => 'Quiz Settings';

  @override
  String get settingsSectionDataManagement => 'Data Management';

  @override
  String get settingsViewStats => 'View Stats';

  @override
  String get settingsLoadVocabulary => 'Load Vocabulary';

  @override
  String settingsLastUpdated(String date) => 'Last updated: $date';

  @override
  String get settingsLastUpdatedNever => 'Never';

  @override
  String get settingsSectionSupport => 'Support';

  @override
  String get settingsHelpSupport => 'Help & Support';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsComingSoonTitle => 'Coming Soon';

  @override
  String get settingsComingSoonBody =>
      'This feature will be available in a future update.';

  @override
  String get settingsAboutTitle => 'About WordWeaver';

  @override
  String get settingsAboutBody =>
      'WordWeaver v1.0.0\n\nA vocabulary quiz application to help you master languages.\n\nSupports: English, Spanish, French, German, Italian, Portuguese, Russian, Japanese, Chinese and Korean.';
}

// Add other language implementations similarly...
class _SpanishLocalizations implements AppLocalizations {
  @override
  String get homeTitle => 'WordWeaver';

  @override
  String get appTitle => 'WordWeaver';

  @override
  String get homeCurrentLanguagePairLabel => 'Par de idiomas actual';

  @override
  String get homeEditButton => 'Editar';

  @override
  String get homeNoTopicsSelectedYet => 'Todavía no se han seleccionado temas';

  @override
  String get homePlayWordMatch => 'Jugar a Word Match';

  @override
  String get homeStartQuiz => 'Iniciar cuestionario';

  @override
  String get homePlayCompleteWord => 'Jugar Completa la palabra';

  @override
  String get homePickTopicsToStart => 'Elige temas para empezar';

  @override
  String get homeCurrentTopics => 'Temas actuales';

  @override
  String get homeNoTopicsAvailable => 'No hay temas disponibles';

  @override
  String get homeAllTopicsSelected => 'Todos los temas seleccionados';

  @override
  String homeTopicsSelected(int count) => '$count tema(s) seleccionado(s)';

  @override
  String get homeTopicsSelectedLabel => 'Temas seleccionados';

  @override
  String get navWriting => 'Escritura';

  @override
  String get navReading => 'Lectura';

  @override
  String get navListening => 'Escucha';

  @override
  String get navSpeaking => 'Hablar';

  @override
  String get navProfile => 'Perfil';

  @override
  String get quizTitle => 'Cuestionario';

  @override
  String get quizNoQuestionsBody =>
      'No hay preguntas disponibles para los temas seleccionados.\nPrueba a elegir más temas, una pareja de idiomas diferente o a reducir el número de preguntas.';

  @override
  String get quizQuestionLabel => 'Pregunta';

  @override
  String quizReducedQuestionsInfo(int available, int requested) =>
      'Solo $available de $requested preguntas estaban disponibles para los temas seleccionados.';

  @override
  String quizPromptHowDoYouSay(String word, String language) =>
      '¿Cómo se dice \'$word\' en $language?';

  @override
  String get commonNextQuestion => 'Siguiente pregunta';

  @override
  String get completeTitle => 'Completa la palabra';

  @override
  String completePromptHowDoYouWrite(String word, String language) =>
      '¿Cómo se escribe \'$word\' en $language?';

  @override
  String get completeYourAnswerLabel => 'Tu respuesta';

  @override
  String get completeIgnoreAccentsLabel => 'Ignorar acentos (è = e)';

  @override
  String get completeIgnoreAccentsQuestionTitle => '¿Ignorar acentos?';

  @override
  String get completeIgnoreAccentsQuestionBody =>
      '¿Quieres ignorar los acentos (è = e) para este cuestionario?';

  @override
  String get commonYes => 'Sí';

  @override
  String get commonNo => 'No';

  @override
  String get completeRevealLetter => 'Revelar letra';

  @override
  String get completeRevealWord => 'Revelar palabra';

  @override
  String get completeCorrect => '¡Correcto!';

  @override
  String completeCorrectAnswer(String answer) => 'Respuesta correcta: $answer';

  @override
  String get completeTakeABreak => 'Tomar un descanso';

  @override
  String get completeBreakBody =>
      'Pequeño descanso. En el futuro aquí se podrá mostrar un anuncio.';

  @override
  String get completeBreakContinue => 'Continuar';

  @override
  String get completeFinish => 'Terminar';

  @override
  String get completeCheckAnswer => 'Comprobar respuesta';

  @override
  String get myListTitle => 'Mi lista';

  @override
  String get myListSelectPairFirst => 'Primero selecciona un par de idiomas.';

  @override
  String get myListNotEnoughWords =>
      'No hay suficientes palabras en Mi lista para iniciar un cuestionario todavía.';

  @override
  String get myListEmptyTitle => 'Todavía no hay palabras guardadas';

  @override
  String get myListEmptyBody =>
      'Toca "Añadir a mi lista" durante un cuestionario o en Completa la palabra para guardar vocabulario aquí.';

  @override
  String get myListFilterByTopic => 'Filtrar por tema';

  @override
  String get myListAllTopics => 'Todos los temas';

  @override
  String get myListQuizThisList => 'Cuestionario con esta lista';

  @override
  String get myListPlayPronunciation => 'Reproducir pronunciación';

  @override
  String get myListRemovedFromList => 'Eliminado de Mi lista';

  @override
  String get myListRemoveFromList => 'Eliminar de Mi lista';

  @override
  String get commonAddedToMyList => 'Añadido a Mi lista';

  @override
  String get commonAddToMyList => 'Añadir a Mi lista';

  @override
  String get commonStartQuiz => 'Iniciar cuestionario';

  @override
  String get commonPlayCompleteWord => 'Jugar Completa la palabra';

  @override
  String get commonPlayWordMatch => 'Jugar a Word Match';

  @override
  String get commonPickTopicsToStart => 'Elige temas para empezar';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get commonToday => 'Hoy';

  @override
  String get commonYesterday => 'Ayer';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonAccuracy => 'Precisión';

  @override
  String get commonTime => 'Tiempo';

  @override
  String get commonDate => 'Fecha';

  @override
  String get commonScore => 'Puntuación';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsDarkMode => 'Modo oscuro';

  @override
  String get settingsSectionLanguage => 'Idioma';

  @override
  String get settingsLanguageLabel => 'Idioma';

  @override
  String get settingsSectionQuizSettings => 'Configuración de cuestionarios';

  @override
  String get settingsQuizSettingsTile => 'Configuración de cuestionarios';

  @override
  String get settingsSectionDataManagement => 'Gestión de datos';

  @override
  String get settingsViewStats => 'Ver estadísticas';

  @override
  String get settingsLoadVocabulary => 'Cargar vocabulario';

  @override
  String settingsLastUpdated(String date) => 'Última actualización: $date';

  @override
  String get settingsLastUpdatedNever => 'Nunca';

  @override
  String get settingsSectionSupport => 'Soporte';

  @override
  String get settingsHelpSupport => 'Ayuda y soporte';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsComingSoonTitle => 'Próximamente';

  @override
  String get settingsComingSoonBody =>
      'Esta función estará disponible en una futura actualización.';

  @override
  String get settingsAboutTitle => 'Acerca de WordWeaver';

  @override
  String get settingsAboutBody =>
      'WordWeaver v1.0.0\n\nUna aplicación de cuestionarios de vocabulario para ayudarte a dominar idiomas.\n\nSoporta: inglés, español, francés, alemán, italiano, portugués, ruso, japonés, chino y coreano.';
}

// Placeholder implementations for other languages
class _ItalianLocalizations implements AppLocalizations {
  @override
  String get homeTitle => 'WordWeaver';
  @override
  String get homeCurrentLanguagePairLabel => 'Coppia di lingue attuale';
  @override
  String get homeEditButton => 'Modifica';
  @override
  String get homeNoTopicsSelectedYet => 'Nessun argomento selezionato';
  @override
  String get homePlayWordMatch => 'Gioca a Word Match';
  @override
  String get homeStartQuiz => 'Inizia quiz';
  @override
  String get homePlayCompleteWord => 'Gioca a Completa la parola';
  @override
  String get homePickTopicsToStart => 'Scegli argomenti per iniziare';
  @override
  String get homeCurrentTopics => 'Argomenti attuali';
  @override
  String get homeNoTopicsAvailable => 'Nessun argomento disponibile';
  @override
  String get homeAllTopicsSelected => 'Tutti gli argomenti selezionati';
  @override
  String homeTopicsSelected(int count) => '$count argomento(i) selezionato(i)';
  @override
  String get homeTopicsSelectedLabel => 'Argomenti selezionati';
  @override
  String get navWriting => 'Scrittura';
  @override
  String get navReading => 'Lettura';
  @override
  String get navListening => 'Ascolto';
  @override
  String get navSpeaking => 'Parlato';
  @override
  String get navProfile => 'Profilo';
  @override
  String get quizTitle => 'Quiz';
  @override
  String get quizNoQuestionsBody =>
      'Nessuna domanda disponibile per gli argomenti selezionati.\nProva a selezionare più argomenti, una coppia di lingue diversa o a ridurre il numero di domande.';
  @override
  String get quizQuestionLabel => 'Domanda';
  @override
  String quizReducedQuestionsInfo(int available, int requested) =>
      'Solo $available di $requested domande erano disponibili per gli argomenti selezionati.';
  @override
  String quizPromptHowDoYouSay(String word, String language) =>
      'Come si dice \'$word\' in $language?';
  @override
  String get commonNextQuestion => 'Prossima domanda';
  @override
  String get completeTitle => 'Completa la parola';
  @override
  String completePromptHowDoYouWrite(String word, String language) =>
      'Come si scrive \'$word\' in $language?';
  @override
  String get completeYourAnswerLabel => 'La tua risposta';
  @override
  String get completeIgnoreAccentsLabel => 'Ignora accenti (è = e)';
  @override
  String get completeIgnoreAccentsQuestionTitle => 'Ignorare accenti?';
  @override
  String get completeIgnoreAccentsQuestionBody =>
      'Vuoi ignorare gli accenti (è = e) per questo quiz?';
  @override
  String get commonYes => 'Sì';
  @override
  String get commonNo => 'No';
  @override
  String get completeRevealLetter => 'Rivela lettera';
  @override
  String get completeRevealWord => 'Rivela parola';
  @override
  String get completeCorrect => 'Corretto!';
  @override
  String completeCorrectAnswer(String answer) => 'Risposta corretta: $answer';
  @override
  String get completeTakeABreak => 'Fai una pausa';
  @override
  String get completeBreakBody =>
      'Piccola pausa. In futuro, qui potrebbe essere mostrato un annuncio.';
  @override
  String get completeBreakContinue => 'Continua';
  @override
  String get completeFinish => 'Termina';
  @override
  String get completeCheckAnswer => 'Controlla risposta';
  @override
  String get myListTitle => 'La mia lista';
  @override
  String get myListSelectPairFirst => 'Seleziona prima una coppia di lingue.';
  @override
  String get myListNotEnoughWords =>
      'Non ci sono abbastanza parole nella mia lista per iniziare un quiz.';
  @override
  String get myListEmptyTitle => 'Nessuna parola salvata ancora';
  @override
  String get myListEmptyBody =>
      'Tocca "Aggiungi alla mia lista" durante un quiz o in Completa la parola per salvare il vocabolario qui.';
  @override
  String get myListFilterByTopic => 'Filtra per argomento';
  @override
  String get myListAllTopics => 'Tutti gli argomenti';
  @override
  String get myListQuizThisList => 'Quiz con questa lista';
  @override
  String get myListPlayPronunciation => 'Riproduci pronuncia';
  @override
  String get myListRemovedFromList => 'Rimosso dalla mia lista';
  @override
  String get myListRemoveFromList => 'Rimuovi dalla mia lista';
  @override
  String get commonAddedToMyList => 'Aggiunto alla mia lista';
  @override
  String get commonAddToMyList => 'Aggiungi alla mia lista';
  @override
  String get commonStartQuiz => 'Inizia quiz';
  @override
  String get commonPlayCompleteWord => 'Gioca a Completa la parola';
  @override
  String get commonPlayWordMatch => 'Gioca a Word Match';
  @override
  String get commonPickTopicsToStart => 'Scegli argomenti per iniziare';
  @override
  String get commonOk => 'OK';
  @override
  String get commonToday => 'Oggi';
  @override
  String get commonYesterday => 'Ieri';
  @override
  String get commonClose => 'Chiudi';
  @override
  String get commonAccuracy => 'Accuratezza';
  @override
  String get commonTime => 'Tempo';
  @override
  String get commonDate => 'Data';
  @override
  String get commonScore => 'Punteggio';

  @override
  String get appTitle => 'WordWeaver';

  @override
  String get settingsSectionGeneral => 'Generale';

  @override
  String get settingsDarkMode => 'Modalità scura';

  @override
  String get settingsSectionLanguage => 'Lingua';

  @override
  String get settingsLanguageLabel => 'Lingua';

  @override
  String get settingsSectionQuizSettings => 'Impostazioni quiz';

  @override
  String get settingsQuizSettingsTile => 'Impostazioni quiz';

  @override
  String get settingsSectionDataManagement => 'Gestione dati';

  @override
  String get settingsViewStats => 'Visualizza statistiche';

  @override
  String get settingsLoadVocabulary => 'Carica vocabolario';

  @override
  String settingsLastUpdated(String date) => 'Ultimo aggiornamento: $date';

  @override
  String get settingsLastUpdatedNever => 'Mai';

  @override
  String get settingsSectionSupport => 'Supporto';

  @override
  String get settingsHelpSupport => 'Aiuto e supporto';

  @override
  String get settingsAbout => 'Informazioni';

  @override
  String get settingsComingSoonTitle => 'Prossimamente';

  @override
  String get settingsComingSoonBody =>
      'Questa funzione sarà disponibile in un futuro aggiornamento.';

  @override
  String get settingsAboutTitle => 'Informazioni su WordWeaver';

  @override
  String get settingsAboutBody =>
      'WordWeaver v1.0.0\n\nUn\'applicazione di quiz di vocabolario per aiutarti a padroneggiare le lingue.\n\nSupporta: inglese, spagnolo, francese, tedesco, italiano, portoghese, russo, giapponese, cinese e coreano.';
}

class _FrenchLocalizations implements AppLocalizations {
  @override
  String get homeTitle => 'WordWeaver';
  @override
  String get homeCurrentLanguagePairLabel => 'Paire de langues actuelle';
  @override
  String get homeEditButton => 'Modifier';
  @override
  String get homeNoTopicsSelectedYet => 'Aucun sujet sélectionné';
  @override
  String get homePlayWordMatch => 'Jouer à Word Match';
  @override
  String get homeStartQuiz => 'Commencer le quiz';
  @override
  String get homePlayCompleteWord => 'Jouer à Compléter le mot';
  @override
  String get homePickTopicsToStart => 'Choisissez des sujets pour commencer';
  @override
  String get homeCurrentTopics => 'Sujets actuels';
  @override
  String get homeNoTopicsAvailable => 'Aucun sujet disponible';
  @override
  String get homeAllTopicsSelected => 'Tous les sujets sélectionnés';
  @override
  String homeTopicsSelected(int count) => '$count sujet(s) sélectionné(s)';
  @override
  String get homeTopicsSelectedLabel => 'Sujets sélectionnés';
  @override
  String get navWriting => 'Écriture';
  @override
  String get navReading => 'Lecture';
  @override
  String get navListening => 'Écoute';
  @override
  String get navSpeaking => 'Parole';
  @override
  String get navProfile => 'Profil';
  @override
  String get quizTitle => 'Quiz';
  @override
  String get quizNoQuestionsBody =>
      'Aucune question disponible pour les sujets sélectionnés.\nEssayez de sélectionner plus de sujets, une paire de langues différente ou de réduire le nombre de questions.';
  @override
  String get quizQuestionLabel => 'Question';
  @override
  String quizReducedQuestionsInfo(int available, int requested) =>
      'Seulement $available sur $requested questions étaient disponibles pour les sujets sélectionnés.';
  @override
  String quizPromptHowDoYouSay(String word, String language) =>
      'Comment dit-on \'$word\' en $language?';
  @override
  String get commonNextQuestion => 'Question suivante';
  @override
  String get completeTitle => 'Compléter le mot';
  @override
  String completePromptHowDoYouWrite(String word, String language) =>
      'Comment écrit-on \'$word\' en $language?';
  @override
  String get completeYourAnswerLabel => 'Votre réponse';
  @override
  String get completeIgnoreAccentsLabel => 'Ignorer les accents (è = e)';
  @override
  String get completeIgnoreAccentsQuestionTitle => 'Ignorer les accents?';
  @override
  String get completeIgnoreAccentsQuestionBody =>
      'Voulez-vous ignorer les accents (è = e) pour ce quiz?';
  @override
  String get commonYes => 'Oui';
  @override
  String get commonNo => 'Non';
  @override
  String get completeRevealLetter => 'Révéler une lettre';
  @override
  String get completeRevealWord => 'Révéler le mot';
  @override
  String get completeCorrect => 'Correct!';
  @override
  String completeCorrectAnswer(String answer) => 'Réponse correcte: $answer';
  @override
  String get completeTakeABreak => 'Faire une pause';
  @override
  String get completeBreakBody =>
      'Petite pause. À l\'avenir, une publicité pourrait être affichée ici.';
  @override
  String get completeBreakContinue => 'Continuer';
  @override
  String get completeFinish => 'Terminer';
  @override
  String get completeCheckAnswer => 'Vérifier la réponse';
  @override
  String get myListTitle => 'Ma liste';
  @override
  String get myListSelectPairFirst =>
      'Sélectionnez d\'abord une paire de langues.';
  @override
  String get myListNotEnoughWords =>
      'Pas assez de mots dans Ma liste pour commencer un quiz.';
  @override
  String get myListEmptyTitle => 'Aucun mot sauvegardé';
  @override
  String get myListEmptyBody =>
      'Touchez "Ajouter à ma liste" pendant un quiz ou dans Compléter le mot pour sauvegarder le vocabulaire ici.';
  @override
  String get myListFilterByTopic => 'Filtrer par sujet';
  @override
  String get myListAllTopics => 'Tous les sujets';
  @override
  String get myListQuizThisList => 'Quiz avec cette liste';
  @override
  String get myListPlayPronunciation => 'Jouer la prononciation';
  @override
  String get myListRemovedFromList => 'Retiré de Ma liste';
  @override
  String get myListRemoveFromList => 'Retirer de Ma liste';
  @override
  String get commonAddedToMyList => 'Ajouté à Ma liste';
  @override
  String get commonAddToMyList => 'Ajouter à Ma liste';
  @override
  String get commonStartQuiz => 'Commencer le quiz';
  @override
  String get commonPlayCompleteWord => 'Jouer à Compléter le mot';
  @override
  String get commonPlayWordMatch => 'Jouer à Word Match';
  @override
  String get commonPickTopicsToStart => 'Choisissez des sujets pour commencer';
  @override
  String get commonOk => 'OK';
  @override
  String get commonToday => 'Aujourd\'hui';
  @override
  String get commonYesterday => 'Hier';
  @override
  String get commonClose => 'Fermer';
  @override
  String get commonAccuracy => 'Précision';
  @override
  String get commonTime => 'Temps';
  @override
  String get commonDate => 'Date';
  @override
  String get commonScore => 'Score';

  @override
  String get appTitle => 'WordWeaver';

  @override
  String get settingsSectionGeneral => 'Général';

  @override
  String get settingsDarkMode => 'Mode sombre';

  @override
  String get settingsSectionLanguage => 'Langue';

  @override
  String get settingsLanguageLabel => 'Langue';

  @override
  String get settingsSectionQuizSettings => 'Paramètres du quiz';

  @override
  String get settingsQuizSettingsTile => 'Paramètres du quiz';

  @override
  String get settingsSectionDataManagement => 'Gestion des données';

  @override
  String get settingsViewStats => 'Voir les statistiques';

  @override
  String get settingsLoadVocabulary => 'Charger le vocabulaire';

  @override
  String settingsLastUpdated(String date) => 'Dernière mise à jour: $date';

  @override
  String get settingsLastUpdatedNever => 'Jamais';

  @override
  String get settingsSectionSupport => 'Support';

  @override
  String get settingsHelpSupport => 'Aide et support';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsComingSoonTitle => 'Bientôt disponible';

  @override
  String get settingsComingSoonBody =>
      'Cette fonctionnalité sera disponible dans une future mise à jour.';

  @override
  String get settingsAboutTitle => 'À propos de WordWeaver';

  @override
  String get settingsAboutBody =>
      'WordWeaver v1.0.0\n\nUne application de quiz de vocabulaire pour vous aider à maîtriser les langues.\n\nSupporte: anglais, espagnol, français, allemand, italien, portugais, russe, japonais, chinois et coréen.';
}

class _GermanLocalizations implements AppLocalizations {
  @override
  String get homeTitle => 'WordWeaver';
  @override
  String get homeCurrentLanguagePairLabel => 'Aktuelles Sprachpaar';
  @override
  String get homeEditButton => 'Bearbeiten';
  @override
  String get homeNoTopicsSelectedYet => 'Noch keine Themen ausgewählt';
  @override
  String get homePlayWordMatch => 'Word Match spielen';
  @override
  String get homeStartQuiz => 'Quiz starten';
  @override
  String get homePlayCompleteWord => 'Wort vervollständigen spielen';
  @override
  String get homePickTopicsToStart => 'Themen auswählen zum Starten';
  @override
  String get homeCurrentTopics => 'Aktuelle Themen';
  @override
  String get homeNoTopicsAvailable => 'Keine Themen verfügbar';
  @override
  String get homeAllTopicsSelected => 'Alle Themen ausgewählt';
  @override
  String homeTopicsSelected(int count) => '$count Thema(en) ausgewählt';
  @override
  String get homeTopicsSelectedLabel => 'Ausgewählte Themen';
  @override
  String get navWriting => 'Schreiben';
  @override
  String get navReading => 'Lesen';
  @override
  String get navListening => 'Hören';
  @override
  String get navSpeaking => 'Sprechen';
  @override
  String get navProfile => 'Profil';
  @override
  String get quizTitle => 'Quiz';
  @override
  String get quizNoQuestionsBody =>
      'Keine Fragen für die ausgewählten Themen verfügbar.\nVersuchen Sie, mehr Themen auszuwählen, ein anderes Sprachpaar oder die Anzahl der Fragen zu reduzieren.';
  @override
  String get quizQuestionLabel => 'Frage';
  @override
  String quizReducedQuestionsInfo(int available, int requested) =>
      'Nur $available von $requested Fragen waren für die ausgewählten Themen verfügbar.';
  @override
  String quizPromptHowDoYouSay(String word, String language) =>
      'Wie sagt man \'$word\' auf $language?';
  @override
  String get commonNextQuestion => 'Nächste Frage';
  @override
  String get completeTitle => 'Wort vervollständigen';
  @override
  String completePromptHowDoYouWrite(String word, String language) =>
      'Wie schreibt man \'$word\' auf $language?';
  @override
  String get completeYourAnswerLabel => 'Ihre Antwort';
  @override
  String get completeIgnoreAccentsLabel => 'Akzente ignorieren (è = e)';
  @override
  String get completeIgnoreAccentsQuestionTitle => 'Akzente ignorieren?';
  @override
  String get completeIgnoreAccentsQuestionBody =>
      'Möchten Sie Akzente (è = e) für dieses Quiz ignorieren?';
  @override
  String get commonYes => 'Ja';
  @override
  String get commonNo => 'Nein';
  @override
  String get completeRevealLetter => 'Buchstabe aufdecken';
  @override
  String get completeRevealWord => 'Wort aufdecken';
  @override
  String get completeCorrect => 'Korrekt!';
  @override
  String completeCorrectAnswer(String answer) => 'Korrekte Antwort: $answer';
  @override
  String get completeTakeABreak => 'Pause machen';
  @override
  String get completeBreakBody =>
      'Kurze Pause. In Zukunft könnte hier eine Anzeige gezeigt werden.';
  @override
  String get completeBreakContinue => 'Weiter';
  @override
  String get completeFinish => 'Beenden';
  @override
  String get completeCheckAnswer => 'Antwort prüfen';
  @override
  String get myListTitle => 'Meine Liste';
  @override
  String get myListSelectPairFirst => 'Wählen Sie zuerst ein Sprachpaar aus.';
  @override
  String get myListNotEnoughWords =>
      'Nicht genügend Wörter in Meiner Liste für ein Quiz.';
  @override
  String get myListEmptyTitle => 'Noch keine Wörter gespeichert';
  @override
  String get myListEmptyBody =>
      'Tippen Sie während eines Quiz oder in Wort vervollständigen auf "Zu Meiner Liste hinzufügen", um Vokabular hier zu speichern.';
  @override
  String get myListFilterByTopic => 'Nach Thema filtern';
  @override
  String get myListAllTopics => 'Alle Themen';
  @override
  String get myListQuizThisList => 'Quiz mit dieser Liste';
  @override
  String get myListPlayPronunciation => 'Aussprache abspielen';
  @override
  String get myListRemovedFromList => 'Von Meiner Liste entfernt';
  @override
  String get myListRemoveFromList => 'Von Meiner Liste entfernen';
  @override
  String get commonAddedToMyList => 'Zu Meiner Liste hinzugefügt';
  @override
  String get commonAddToMyList => 'Zu Meiner Liste hinzufügen';
  @override
  String get commonStartQuiz => 'Quiz starten';
  @override
  String get commonPlayCompleteWord => 'Wort vervollständigen spielen';
  @override
  String get commonPlayWordMatch => 'Word Match spielen';
  @override
  String get commonPickTopicsToStart => 'Themen auswählen zum Starten';
  @override
  String get commonOk => 'OK';
  @override
  String get commonToday => 'Heute';
  @override
  String get commonYesterday => 'Gestern';
  @override
  String get commonClose => 'Schließen';
  @override
  String get commonAccuracy => 'Genauigkeit';
  @override
  String get commonTime => 'Zeit';
  @override
  String get commonDate => 'Datum';
  @override
  String get commonScore => 'Punktzahl';

  @override
  String get appTitle => 'WordWeaver';

  @override
  String get settingsSectionGeneral => 'Allgemein';

  @override
  String get settingsDarkMode => 'Dunkler Modus';

  @override
  String get settingsSectionLanguage => 'Sprache';

  @override
  String get settingsLanguageLabel => 'Sprache';

  @override
  String get settingsSectionQuizSettings => 'Quiz-Einstellungen';

  @override
  String get settingsQuizSettingsTile => 'Quiz-Einstellungen';

  @override
  String get settingsSectionDataManagement => 'Datenverwaltung';

  @override
  String get settingsViewStats => 'Statistiken anzeigen';

  @override
  String get settingsLoadVocabulary => 'Vokabular laden';

  @override
  String settingsLastUpdated(String date) => 'Zuletzt aktualisiert: $date';

  @override
  String get settingsLastUpdatedNever => 'Nie';

  @override
  String get settingsSectionSupport => 'Support';

  @override
  String get settingsHelpSupport => 'Hilfe & Support';

  @override
  String get settingsAbout => 'Über';

  @override
  String get settingsComingSoonTitle => 'Demnächst verfügbar';

  @override
  String get settingsComingSoonBody =>
      'Diese Funktion wird in einem zukünftigen Update verfügbar sein.';

  @override
  String get settingsAboutTitle => 'Über WordWeaver';

  @override
  String get settingsAboutBody =>
      'WordWeaver v1.0.0\n\nEine Vokabular-Quiz-Anwendung, um Ihnen beim Erlernen von Sprachen zu helfen.\n\nUnterstützt: Englisch, Spanisch, Französisch, Deutsch, Italienisch, Portugiesisch, Russisch, Japanisch, Chinesisch und Koreanisch.';
}
