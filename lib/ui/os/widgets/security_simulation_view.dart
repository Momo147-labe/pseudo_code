import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/os_provider.dart';

class SecuritySimulationView extends StatelessWidget {
  const SecuritySimulationView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OSProvider>();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 40),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _buildLegendRow(),
                  const Divider(color: Colors.white10, height: 1),
                  ...p.permissions.keys
                      .map((res) => _buildPermissionRow(p, res))
                      .toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          _buildActionPanel(p),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          "SÉCURITÉ ET PROTECTION",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        Text(
          "Gestion des Droits d'Accès (rwx)",
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLegendRow() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "RESSOURCE",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          _buildHeaderCell("Read (r)"),
          _buildHeaderCell("Write (w)"),
          _buildHeaderCell("Execute (x)"),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return SizedBox(
      width: 100,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ),
    );
  }

  Widget _buildPermissionRow(OSProvider p, String resource) {
    final perms = p.permissions[resource]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.02)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              resource.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          _buildPermToggle(p, resource, 0, perms[0] == 'r'),
          _buildPermToggle(p, resource, 1, perms[1] == 'w'),
          _buildPermToggle(p, resource, 2, perms[2] == 'x'),
        ],
      ),
    );
  }

  Widget _buildPermToggle(OSProvider p, String res, int index, bool active) {
    return SizedBox(
      width: 100,
      child: Center(
        child: InkWell(
          onTap: () => p.togglePermission(res, index),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: active
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: active ? Colors.green : Colors.red),
            ),
            child: Icon(
              active ? Icons.check : Icons.close,
              size: 16,
              color: active ? Colors.green : Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionPanel(OSProvider p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield, color: Colors.blueAccent, size: 20),
          SizedBox(width: 12),
          Text(
            "Cliquez sur les cases pour modifier les permissions en temps réel.",
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
