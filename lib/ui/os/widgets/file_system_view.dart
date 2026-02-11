import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/os_provider.dart';

class FileSystemView extends StatelessWidget {
  const FileSystemView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OSProvider>();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          Expanded(
            child: Row(
              children: [
                // File Explorer
                Expanded(flex: 1, child: _buildExplorer(p)),
                const SizedBox(width: 30),
                // Disk Block Visualization
                Expanded(flex: 2, child: _buildDiskBlocks(p)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          "SYSTÈME DE FICHIERS",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        Text(
          "Organisation des données sur le disque",
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildExplorer(OSProvider p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open, color: Colors.blueAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                p.currentFilePath,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white10),
          Expanded(
            child: ListView(
              children: p.fileSystemNodes
                  .map(
                    (node) => ListTile(
                      leading: const Icon(
                        Icons.folder,
                        color: Colors.amber,
                        size: 20,
                      ),
                      title: Text(
                        node,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () => p.navigateTo(node),
                      dense: true,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Double-cliquez pour explorer.",
            style: TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildDiskBlocks(OSProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "ALLOCATION DES BLOCS SUR DISQUE",
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            _buildLegend("Utilisé", Colors.blueAccent),
            const SizedBox(width: 12),
            _buildLegend("Libre", Colors.white10),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(16),
            ),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 16,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 128,
              itemBuilder: (context, index) {
                // Random simulation for demo
                bool isFull = (index % 7 == 0) || (index < 10);
                return Container(
                  decoration: BoxDecoration(
                    color: isFull
                        ? Colors.blueAccent.withValues(alpha: 0.5)
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white38, fontSize: 8)),
      ],
    );
  }
}
