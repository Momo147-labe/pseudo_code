import 'package:flutter/material.dart';
import '../../../models/os_model.dart';
import '../../../theme.dart';

class GanttChart extends StatelessWidget {
  final List<SimulationStep> steps;
  final int currentStepIndex;
  final AppTheme theme;

  const GanttChart({
    super.key,
    required this.steps,
    required this.currentStepIndex,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "DIAGRAMME DE GANTT (UTILISATION CPU)",
            style: TextStyle(
              color: Colors.amber,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _buildGanttBlocks()),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGanttBlocks() {
    List<Widget> blocks = [];
    if (steps.isEmpty) return blocks;

    // We only iterate up to currentStepIndex to show progress
    for (int i = 0; i <= currentStepIndex; i++) {
      final step = steps[i];

      // If we are at the last step of simulation, maybe nothing is running
      if (step.description == "Simulation terminée") continue;

      final runningProcess = step.runningProcessId != null
          ? step.processes.firstWhere((p) => p.id == step.runningProcessId)
          : null;

      blocks.add(
        Column(
          children: [
            Container(
              width: 30, // Width per time unit
              height: 40,
              decoration: BoxDecoration(
                color:
                    runningProcess?.color ?? Colors.grey.withValues(alpha: 0.1),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  runningProcess?.name ?? "",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${step.time}",
              style: const TextStyle(color: Colors.white54, fontSize: 9),
            ),
          ],
        ),
      );
    }

    // Add final time label if simulation is finished at this point
    if (currentStepIndex >= 0) {
      blocks.add(
        Column(
          children: [
            const SizedBox(height: 44),
            Text(
              "${steps[currentStepIndex].time + (steps[currentStepIndex].runningProcessId != null ? 1 : 0)}",
              style: const TextStyle(color: Colors.white54, fontSize: 9),
            ),
          ],
        ),
      );
    }

    return blocks;
  }
}
