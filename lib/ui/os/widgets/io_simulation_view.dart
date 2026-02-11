import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/os_provider.dart';

class IOSimulationView extends StatelessWidget {
  const IOSimulationView({super.key});

  @override
  Widget build(BuildContext context) {
    final osProvider = context.watch<OSProvider>();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "FLUX DE DONNÉES (ENTRÉES / SORTIES)",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.blueAccent,
            ),
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildColumn("ENTRÉES", [
                _buildIOItem(
                  "Clavier",
                  Icons.keyboard,
                  "Lettre 'A'",
                  "CPU",
                  osProvider,
                ),
                _buildIOItem(
                  "Micro",
                  Icons.mic,
                  "Audio Chunk",
                  "CPU",
                  osProvider,
                ),
                _buildIOItem(
                  "Scanner",
                  Icons.scanner,
                  "Image Data",
                  "CPU",
                  osProvider,
                ),
              ], Colors.green),

              _buildColumn("ENTRÉE-SORTIE", [
                _buildIOItem(
                  "Clé USB",
                  Icons.usb,
                  "Fichier ZIP",
                  "CPU",
                  osProvider,
                ),
                _buildIOItem(
                  "Disque Ext",
                  Icons.album,
                  "Backup Data",
                  "CPU",
                  osProvider,
                ),
              ], Colors.purple),

              _buildCenterPiece(osProvider),

              _buildColumn("SORTIES", [
                _buildIOItem(
                  "Écran",
                  Icons.tv,
                  "Pixel Data",
                  "Screen",
                  osProvider,
                  isTarget: true,
                ),
                _buildIOItem(
                  "Imprimante",
                  Icons.print,
                  "Page PDF",
                  "Printer",
                  osProvider,
                  isTarget: true,
                ),
                _buildIOItem(
                  "Disque",
                  Icons.save,
                  "Fichier.txt",
                  "Disk",
                  osProvider,
                  isTarget: true,
                ),
              ], Colors.orange),
            ],
          ),
        ),
        _buildLegend(),
      ],
    );
  }

  Widget _buildColumn(String title, List<Widget> items, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 20),
        ...items,
      ],
    );
  }

  Widget _buildIOItem(
    String label,
    IconData icon,
    String data,
    String target,
    OSProvider provider, {
    bool isTarget = false,
  }) {
    final isActive =
        (isTarget ? provider.ioTarget : provider.ioSource) == label;

    return GestureDetector(
      onTap: isTarget ? null : () => provider.simulateIO(label, data, "CPU"),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.blueAccent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? Colors.blueAccent
                : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.blueAccent : Colors.white70,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPiece(OSProvider p) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.memory, size: 40, color: Colors.blueAccent),
                SizedBox(height: 8),
                Text(
                  "CPU / RAM",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        if (p.activeIOData != null) _buildAnimatingData(p),
      ],
    );
  }

  Widget _buildAnimatingData(OSProvider p) {
    // This is a simplified animation using the progress from provider
    return Positioned(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(seconds: 1),
        builder: (context, value, child) {
          return Opacity(
            opacity: 1 - (value > 0.8 ? (value - 0.8) * 5 : 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                p.activeIOData!,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blueAccent),
          SizedBox(width: 12),
          Text(
            "Cliquez sur un périphérique d'entrée pour envoyer des données au processeur.",
            style: TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
