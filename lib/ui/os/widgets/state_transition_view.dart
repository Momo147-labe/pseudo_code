import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/os_provider.dart';

class StateTransitionView extends StatelessWidget {
  const StateTransitionView({super.key});

  @override
  Widget build(BuildContext context) {
    final osProvider = context.watch<OSProvider>();
    final currentState = osProvider.processCurrentState;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "CYCLE DE VIE D'UN PROCESSUS",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.amber,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildStateNode(
                  "PRÊT",
                  currentState == "Prêt",
                  const Offset(-150, 0),
                  Colors.blue,
                ),
                _buildStateNode(
                  "ÉLU",
                  currentState == "Élu",
                  const Offset(0, -120),
                  Colors.green,
                ),
                _buildStateNode(
                  "BLOQUÉ",
                  currentState == "Bloqué",
                  const Offset(150, 0),
                  Colors.red,
                ),

                // Arrows (Simplified SVG-like lines or icons)
                _buildArrow(
                  const Offset(-100, -30),
                  const Offset(-30, -90),
                  "Admis / Débloqué",
                ),
                _buildArrow(
                  const Offset(30, -90),
                  const Offset(100, -30),
                  "Attente I/O",
                ),
                _buildArrow(
                  const Offset(30, -80),
                  const Offset(-80, -10),
                  "Quantum fini",
                  isReverse: true,
                ),
              ],
            ),
          ),
        ),
        _buildControls(osProvider),
      ],
    );
  }

  Widget _buildStateNode(
    String name,
    bool isActive,
    Offset offset,
    Color color,
  ) {
    return Transform.translate(
      offset: offset,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isActive
                  ? color.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? color : Colors.white.withValues(alpha: 0.1),
                width: isActive ? 3 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 15,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                name,
                style: TextStyle(
                  color: isActive ? color : Colors.white60,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (isActive)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "ACTIF",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArrow(
    Offset start,
    Offset end,
    String label, {
    bool isReverse = false,
  }) {
    return Stack(
      children: [
        // Arrow Line (Placeholder representation)
        // In a real app we might use CustomPainter
        Transform.translate(
          offset: Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white30, fontSize: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls(OSProvider p) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionButton(
            "Passer à PRÊT",
            Colors.blue,
            () => p.transitionTo("Prêt"),
          ),
          const SizedBox(width: 16),
          _buildActionButton(
            "Élire (CPU)",
            Colors.green,
            () => p.transitionTo("Élu"),
          ),
          const SizedBox(width: 16),
          _buildActionButton(
            "Bloquer (I/O)",
            Colors.red,
            () => p.transitionTo("Bloqué"),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
