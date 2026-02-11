import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/os_provider.dart';

class SyncSimulationView extends StatelessWidget {
  const SyncSimulationView({super.key});

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
                // Semaphore Control
                Expanded(flex: 1, child: _buildSemaphoreControl(p)),
                const SizedBox(width: 20),
                // Visualization
                Expanded(flex: 2, child: _buildVisualization(p)),
                const SizedBox(width: 20),
                // Log
                Expanded(flex: 1, child: _buildLog(p)),
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
          "SYNCHRONISATION DES PROCESSUS",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        Text(
          "Simulation des Sémaphores et Mutex",
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSemaphoreControl(OSProvider p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Text(
            "SÉMAPHORE (S)",
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            p.semaphoreValue.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => p.setSemaphore(p.semaphoreValue + 1),
                icon: const Icon(Icons.add_circle, color: Colors.green),
              ),
              IconButton(
                onPressed: () => p.semaphoreValue > 0
                    ? p.setSemaphore(p.semaphoreValue - 1)
                    : null,
                icon: const Icon(Icons.remove_circle, color: Colors.red),
              ),
            ],
          ),
          const Divider(height: 40, color: Colors.white10),
          ElevatedButton(
            onPressed: () => p.simulateSyncAccess("Processus A"),
            child: const Text("DEMANDER ACCÈS (P1)"),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => p.simulateSyncAccess("Processus B"),
            child: const Text("DEMANDER ACCÈS (P2)"),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualization(OSProvider p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Critical Section
            Container(
              width: 200,
              height: 100,
              decoration: BoxDecoration(
                color: p.semaphoreValue == 0
                    ? Colors.red.withValues(alpha: 0.2)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: p.semaphoreValue == 0 ? Colors.red : Colors.green,
                ),
              ),
              child: Center(
                child: Text(
                  p.semaphoreValue == 0
                      ? "SECTION CRITIQUE\nOCCUPÉE"
                      : "SECTION CRITIQUE\nLIBRE",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: p.semaphoreValue == 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "Attente des processus...",
              style: TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLog(OSProvider p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "JOURNAL D'ÉVÉNEMENTS",
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: p.syncLog.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  p.syncLog[index],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
