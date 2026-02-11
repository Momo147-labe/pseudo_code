import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/challenge_model.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/challenge_validator.dart';
import '../../theme.dart';
import '../editeur_widget.dart';

import '../editor_controller.dart';

class ChallengeDetailView extends StatefulWidget {
  final Challenge challenge;

  const ChallengeDetailView({super.key, required this.challenge});

  @override
  State<ChallengeDetailView> createState() => _ChallengeDetailViewState();
}

class _ChallengeDetailViewState extends State<ChallengeDetailView>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final CodeEditorController _editorController = CodeEditorController();
  bool _isValidating = false;
  ChallengeValidationResult? _validationResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _editorController.text = widget.challenge.initialCode ?? "";
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _editorController.dispose();
    super.dispose();
  }

  Future<void> _runTests() async {
    setState(() {
      _isValidating = true;
      _validationResult = null;
    });

    // Switch to first tab (Instructions/Results) on mobile when testing
    if (MediaQuery.of(context).size.width < 800) {
      _tabController?.animateTo(0);
    }

    try {
      final validator = ChallengeValidator();
      final result = await validator.validate(
        challenge: widget.challenge,
        code: _editorController.text,
      );

      setState(() {
        _validationResult = result;
      });

      if (result.allPassed) {
        // Submit success to backend
        await context.read<ChallengeProvider>().submitResult(
          challengeId: widget.challenge.id,
          code: _editorController.text,
          success: true,
        );
        _showSuccessDialog();
      }
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Félicitations !",
          style: TextStyle(color: Colors.greenAccent),
        ),
        content: Text(
          "Vous avez réussi le défi '${widget.challenge.title}' !\nVous avez gagné ${widget.challenge.xpReward} XP.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800; // Increased threshold for side-by-side view

    return Scaffold(
      backgroundColor: ThemeColors.editorBg(theme),
      appBar: AppBar(
        backgroundColor: ThemeColors.topbarBg(theme),
        title: Text(
          widget.challenge.title,
          style: TextStyle(fontSize: isMobile ? 14 : 16),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.read<ChallengeProvider>().setActiveChallenge(null),
        ),
        actions: [
          if (_isValidating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: ElevatedButton.icon(
                onPressed: _runTests,
                icon: const Icon(Icons.play_arrow, size: 18),
                label: Text(isMobile ? "TESTER" : "TESTER LA SOLUTION"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
                  textStyle: TextStyle(
                    fontSize: isMobile ? 11 : 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
        bottom: isMobile && _tabController != null
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.amber,
                labelColor: Colors.amber,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(text: "ÉNIGME", icon: Icon(Icons.help_outline, size: 20)),
                  Tab(text: "ÉDITEUR", icon: Icon(Icons.code, size: 20)),
                ],
              )
            : null,
      ),
      body: isMobile && _tabController != null
          ? TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Instructions & Results
                Container(
                  padding: const EdgeInsets.all(16),
                  child: _buildInstructionsContent(),
                ),
                // Tab 2: Editor
                EditeurWidget(
                  controller: _editorController,
                  isStandalone: true,
                ),
              ],
            )
          : Row(
              children: [
                // Challenge Description (Left part on desktop)
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    child: _buildInstructionsContent(),
                  ),
                ),
                // Editor Section (Right part on desktop)
                Expanded(
                  flex: 3,
                  child: EditeurWidget(
                    controller: _editorController,
                    isStandalone: true,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInstructionsContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "INSTRUCTIONS",
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.challenge.description,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Text(
            widget.challenge.instructions,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),
          if (_validationResult != null) _buildValidationResults(),
        ],
      ),
    );
  }

  Widget _buildValidationResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "RÉSULTATS DES TESTS",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${_validationResult!.passedCount}/${_validationResult!.totalCount} PASSÉS",
              style: TextStyle(
                color: _validationResult!.allPassed
                    ? Colors.greenAccent
                    : Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._validationResult!.results.map((r) => _buildTestResultRow(r)),
      ],
    );
  }

  Widget _buildTestResultRow(TestCaseResult r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: r.success
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: r.success
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            r.success ? Icons.check_circle : Icons.cancel,
            color: r.success ? Colors.greenAccent : Colors.redAccent,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Input: ${r.testCase.input}",
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                if (r.success) ...[
                  Text(
                    "Output: ${r.testCase.expectedOutput}",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                    ),
                  ),
                ] else ...[
                  Text(
                    "Attendu: ${r.testCase.expectedOutput}",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    "Obtenu: ${r.actualOutput}",
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
