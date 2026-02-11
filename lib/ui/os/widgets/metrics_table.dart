import 'package:flutter/material.dart';
import '../../../models/os_model.dart';
import '../../../theme.dart';

class MetricsTable extends StatelessWidget {
  final List<OSProcess> processes;
  final bool simulationFinished;
  final AppTheme theme;

  const MetricsTable({
    super.key,
    required this.processes,
    required this.simulationFinished,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (processes.isEmpty) return const SizedBox.shrink();

    double avgWaiting = 0;
    double avgTurnaround = 0;

    if (simulationFinished) {
      avgWaiting =
          processes.map((p) => p.waitingTime).reduce((a, b) => a + b) /
          processes.length;
      avgTurnaround =
          processes.map((p) => p.turnAroundTime).reduce((a, b) => a + b) /
          processes.length;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "MÉTRIQUES DE PERFORMANCE",
          style: TextStyle(
            color: Colors.amber,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Table(
          border: TableBorder.all(color: Colors.white12),
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
              ),
              children: [
                _buildCell("Processus", isHeader: true),
                _buildCell("Arrivée", isHeader: true),
                _buildCell("Burst", isHeader: true),
                _buildCell("Fin", isHeader: true),
                _buildCell("Rotation (TAT)", isHeader: true),
                _buildCell("Attente (WT)", isHeader: true),
              ],
            ),
            ...processes.map(
              (p) => TableRow(
                children: [
                  _buildColorCell(p.name, p.color),
                  _buildCell("${p.arrivalTime}"),
                  _buildCell("${p.burstTime}"),
                  _buildCell(simulationFinished ? "${p.completionTime}" : "-"),
                  _buildCell(simulationFinished ? "${p.turnAroundTime}" : "-"),
                  _buildCell(simulationFinished ? "${p.waitingTime}" : "-"),
                ],
              ),
            ),
          ],
        ),
        if (simulationFinished) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricCard(
                "Attente Moyenne (AWT)",
                avgWaiting.toStringAsFixed(2),
                Colors.greenAccent,
              ),
              const SizedBox(width: 16),
              _buildMetricCard(
                "Rotation Moyenne (ATT)",
                avgTurnaround.toStringAsFixed(2),
                Colors.blueAccent,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isHeader ? Colors.white : Colors.white70,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildColorCell(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, color: color),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
