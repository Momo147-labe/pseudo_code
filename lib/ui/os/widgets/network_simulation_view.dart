import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/os_provider.dart';

class NetworkSimulationView extends StatelessWidget {
  const NetworkSimulationView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OSProvider>();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 40),
          Expanded(
            child: Stack(
              children: [
                _buildNetworkTopology(p),
                if (p.networkStatus == "ENVOI...") _buildPacket(p),
              ],
            ),
          ),
          _buildControlPanel(p),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          "RÉSEAUX ET COMMUNICATION",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        Text(
          "Transmission de paquets et couches réseau",
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildNetworkTopology(OSProvider p) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNode(
          "ÉMETTEUR (IP: 192.168.1.1)",
          Icons.laptop,
          Colors.blueAccent,
        ),
        _buildRouter(),
        _buildRouter(),
        _buildNode("RÉCEPTEUR (IP: 8.8.8.8)", Icons.dns, Colors.greenAccent),
      ],
    );
  }

  Widget _buildNode(String label, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRouter() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white10),
      ),
      child: const Icon(Icons.router, color: Colors.white24, size: 16),
    );
  }

  Widget _buildPacket(OSProvider p) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 700),
      left: 100 + (p.packetHops * 150.0), // Simplified math for demo
      top: 150,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Colors.yellowAccent,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.yellowAccent, blurRadius: 10)],
        ),
      ),
    );
  }

  Widget _buildControlPanel(OSProvider p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                "STATUT RÉSEAU: ${p.networkStatus}",
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: p.networkStatus == "IDLE"
                    ? () => p.sendNetworkPacket()
                    : null,
                icon: const Icon(Icons.send, size: 16),
                label: const Text("ENVOYER UN PAQUET"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
