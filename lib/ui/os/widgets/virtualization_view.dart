import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/os_provider.dart';

class VirtualizationView extends StatelessWidget {
  const VirtualizationView({super.key});

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
                // Hypervisor Control
                Expanded(flex: 1, child: _buildHypervisorControl(p)),
                const SizedBox(width: 30),
                // Environment Visualization
                Expanded(flex: 2, child: _buildEnvironment(p)),
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
          "VIRTUALISATION",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        Text(
          "Abstraction du matériel et machines virtuelles",
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildHypervisorControl(OSProvider p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Icon(Icons.layers, color: Colors.purpleAccent, size: 40),
          const SizedBox(height: 20),
          const Text(
            "HYPERVISEUR",
            style: TextStyle(
              color: Colors.purpleAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text(
              "État",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            value: p.hypervisorActive,
            onChanged: (val) => p.toggleHypervisor(),
            activeColor: Colors.purpleAccent,
          ),
          const Divider(height: 40, color: Colors.white10),
          ElevatedButton.icon(
            onPressed: p.hypervisorActive ? () => p.addVM() : null,
            icon: const Icon(Icons.add, size: 16),
            label: const Text("AJOUTER VM"),
          ),
          const Spacer(),
          Text(
            "${p.vmCount} Machine(s) Virtuelle(s) active(s)",
            style: const TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironment(OSProvider p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "HARDWARE PHYSIQUE",
            style: TextStyle(
              color: Colors.white12,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // VMs Layer
          if (p.hypervisorActive)
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: List.generate(
                p.vmCount,
                (index) => _buildVM(index + 1),
              ),
            )
          else
            const Text(
              "Activez l'hyperviseur pour déployer des VMs.",
              style: TextStyle(color: Colors.white10),
            ),
          const Spacer(),
          // Shared Hardware
          _buildHardwareLayer(),
        ],
      ),
    );
  }

  Widget _buildVM(int id) {
    return Container(
      width: 120,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.computer, color: Colors.blueAccent, size: 24),
          const SizedBox(height: 8),
          Text(
            "VM #$id",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const Text(
            "OS Invité",
            style: TextStyle(color: Colors.white38, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareLayer() {
    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.memory, color: Colors.white24, size: 20),
          SizedBox(width: 20),
          Icon(Icons.storage, color: Colors.white24, size: 20),
          SizedBox(width: 20),
          Icon(Icons.speed, color: Colors.white24, size: 20),
        ],
      ),
    );
  }
}
