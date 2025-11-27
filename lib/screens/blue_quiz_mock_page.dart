import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wordweaver/models/language_pair.dart';
import 'package:wordweaver/models/topic.dart';

class BlueQuizMockPage extends StatefulWidget {
  final LanguagePair languagePair;
  final List<Topic> selectedTopics;
  final int questionCount;

  const BlueQuizMockPage({
    super.key,
    required this.languagePair,
    required this.selectedTopics,
    this.questionCount = 10,
  });

  @override
  State<BlueQuizMockPage> createState() => _BlueQuizMockPageState();
}

class _BlueQuizMockPageState extends State<BlueQuizMockPage> {
  static const Color _blueBackground = Color(0xFF41B1FB);
  static const Color _white = Color(0xFFFFFEFF);
  static const Color _redWrong = Color(0xFFEE4A27);
  static const Color _greenCorrect = Color(0xFF13EC5B);
  static const Color _darkBlueAnswer = Color(0xFF748899);
  static const Color _blueTile = Color(0xFF0C7DE6);

  final int _correctIndex = 0; // A. azul
  int? _selectedIndex;
  bool _showCorrectness = false;

  void _onOptionTap(int index) {
    setState(() {
      _selectedIndex = index;
      _showCorrectness = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topGapAfterHeader = size.height * 0.14;
    final minCardHeight = size.height * 0.42;

    return Scaffold(
      backgroundColor: _blueBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'BLUE',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: _white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'DESIGN',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                    color: _redWrong,
                  ),
                ),
              ),
              SizedBox(height: topGapAfterHeader),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    minHeight: minCardHeight,
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 30,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Text(
                            "What is the Spanish word for 'blue'?",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF002C4B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildAnswerRow(0, 'A. azul', 1, 'B. rojo'),
                        const SizedBox(height: 16),
                        _buildAnswerRow(2, 'C. verde', 3, 'D. amarillo'),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question 2 of 5',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _white.withOpacity(0.95),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: 2 / 5,
                            minHeight: 6,
                            backgroundColor: _white,
                            color: const Color(0xFF0C7DE6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C7DE6),
                        foregroundColor: _white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'Next',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerRow(
    int leftIndex,
    String leftText,
    int rightIndex,
    String rightText,
  ) {
    return Row(
      children: [
        Expanded(child: _buildAnswerTile(leftIndex, leftText)),
        const SizedBox(width: 12),
        Expanded(child: _buildAnswerTile(rightIndex, rightText)),
      ],
    );
  }

  Widget _buildAnswerTile(int index, String label) {
    final bool isCorrect = index == _correctIndex;
    final bool isSelected = _selectedIndex == index;

    Color background = _blueTile;
    Color textColor = _darkBlueAnswer;

    if (_showCorrectness) {
      if (isCorrect) {
        background = _greenCorrect;
        textColor = _white;
      } else if (isSelected && !isCorrect) {
        background = _redWrong;
        textColor = _white;
      }
    }

    return GestureDetector(
      onTap: () => _onOptionTap(index),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
