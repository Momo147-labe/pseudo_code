import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/os_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../theme.dart';

class InternalArchitectureView extends StatefulWidget {
  const InternalArchitectureView({super.key});

  @override
  State<InternalArchitectureView> createState() =>
      _InternalArchitectureViewState();
}

class _InternalArchitectureViewState extends State<InternalArchitectureView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OSProvider>().initializeRAM();
    });
  }

  @override
  Widget build(BuildContext context) {
    final osProvider = context.watch<OSProvider>();
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Container(
      color: const Color(0xFF0A0E14), // Deep Tech Bg
      child: Column(
        children: [
          _buildTopBanner(osProvider),
          Expanded(
            child: Row(
              children: [
                // Main Architectural View
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildArchitectureHeader(),
                        const SizedBox(height: 20),
                        Expanded(child: _buildMotherboard(osProvider)),
                        const SizedBox(height: 20),
                        _buildPipelineView(osProvider),
                      ],
                    ),
                  ),
                ),
                // Detailed Sidebar (Registers & Cache)
                _buildRightSidebar(osProvider, theme),
              ],
            ),
          ),
          _buildHardwareControls(osProvider),
        ],
      ),
    );
  }

  Widget _buildTopBanner(OSProvider p) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: 4,
      width: double.infinity,
      color: p.isIrqActive ? Colors.red : Colors.blueAccent,
    );
  }

  Widget _buildArchitectureHeader() {
    return Row(
      children: [
        const Icon(Icons.hub, color: Colors.blueAccent, size: 24),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "NID DE CONTRÔLE MATÉRIEL",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
            Text(
              "SYSTÈME DE MICRO-ARCHITECTURE V1.0",
              style: TextStyle(
                color: Colors.white24,
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildStatusTag("BUS: OK", Colors.green),
        const SizedBox(width: 8),
        _buildStatusTag("VCO: 4.2GHz", Colors.blueAccent),
      ],
    );
  }

  Widget _buildStatusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMotherboard(OSProvider p) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141A24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Stack(
        children: [
          // Visualizing PCB traces (Simulated with CustomPaint or simple lines)
          _buildCircuitTrace(const Offset(100, 150), const Offset(300, 150)),
          _buildCircuitTrace(const Offset(150, 50), const Offset(150, 250)),

          // Components
          Center(
            child: Wrap(
              spacing: 40,
              runSpacing: 40,
              alignment: WrapAlignment.center,
              children: [
                _buildAdvancedComponent(
                  "CPU CORTEX",
                  Icons.memory,
                  p.instructionStep != "IDLE",
                  Colors.blueAccent,
                  subLabel: "Register: ${p.ir}",
                ),
                _buildAdvancedComponent(
                  "RAM SLOTS",
                  Icons.view_comfortable,
                  p.ramMapping.isNotEmpty,
                  Colors.orangeAccent,
                  subLabel: "${p.ramMapping.length} Blocks",
                ),
                _buildAdvancedComponent(
                  "STORAGE",
                  Icons.storage,
                  false,
                  Colors.greenAccent,
                  subLabel: "SSD NVMe",
                ),
                _buildAdvancedComponent(
                  "NETWORK",
                  Icons.wifi,
                  p.isIrqActive && p.lastIrqSource == "NETWORK",
                  Colors.purpleAccent,
                  subLabel: "10 Gbps",
                ),
              ],
            ),
          ),

          // Interruption Warning
          if (p.isIrqActive) _buildInterruptAlert(p.lastIrqSource),
        ],
      ),
    );
  }

  Widget _buildCircuitTrace(Offset start, Offset end) {
    return Positioned(
      left: start.dx,
      top: start.dy,
      child: Opacity(
        opacity: 0.1,
        child: Container(
          width: (end.dx - start.dx).abs() + 2,
          height: (end.dy - start.dy).abs() + 2,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.cyanAccent, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedComponent(
    String name,
    IconData icon,
    bool isActive,
    Color color, {
    String? subLabel,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : Colors.black38,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.05),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20)]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: isActive ? color : Colors.white24),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          if (subLabel != null)
            Text(
              subLabel,
              style: TextStyle(
                color: color.withValues(alpha: 0.5),
                fontSize: 8,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInterruptAlert(String source) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 20),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              "INTERRUPTION: $source",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineView(OSProvider p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "PIPELINE D'EXÉCUTION",
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPipelineStage("FETCH", p.pipeline[0], Colors.blue),
              _buildPipelineStage("DECODE", p.pipeline[1], Colors.purple),
              _buildPipelineStage("EXECUTE", p.pipeline[2], Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStage(String label, String instruction, Color color) {
    final isActive = instruction != "IDLE";
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.3) : Colors.white10,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              instruction,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white10,
                fontSize: 10,
                fontFamily: 'JetBrainsMono',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightSidebar(OSProvider p, AppTheme theme) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C),
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        children: [
          _buildSidebarSection("REGISTRES CPU", [
            _buildRegister(
              "PC (Program Counter)",
              "0x${p.pc.toRadixString(16).padLeft(4, '0')}",
              Colors.blueAccent,
            ),
            _buildRegister("IR (Instruction Reg)", p.ir, Colors.purpleAccent),
            _buildRegister(
              "ACC (Accumulateur)",
              p.acc.toString(),
              Colors.greenAccent,
            ),
          ]),
          _buildSidebarSection("HIÉRARCHIE CACHE", [
            _buildCacheIndicator("CACHE L1", p.l1Hit, "32 KB"),
            _buildCacheIndicator("CACHE L2", p.l2Hit, "256 KB"),
          ]),
          Expanded(child: _buildRAMMapping(p)),
        ],
      ),
    );
  }

  Widget _buildSidebarSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRegister(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: 'JetBrainsMono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheIndicator(String label, bool isHit, String size) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isHit
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHit
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                size,
                style: const TextStyle(color: Colors.white24, fontSize: 8),
              ),
            ],
          ),
          const Spacer(),
          if (isHit)
            const Text(
              "HIT !",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            )
          else
            Text(
              "MISS",
              style: TextStyle(
                color: Colors.red.withValues(alpha: 0.3),
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRAMMapping(OSProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "MAPPING MÉMOIRE RAM",
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 16, // Show first 16 slots
            itemBuilder: (context, index) {
              final addr = index * 0x10;
              final proc = p.ramMapping[addr];
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: proc != null
                      ? Colors.blueAccent.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.01),
                  border: Border.all(
                    color: proc != null
                        ? Colors.blueAccent.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Text(
                      "0x${addr.toRadixString(16).toUpperCase().padLeft(2, '0')}",
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 9,
                        fontFamily: 'JetBrainsMono',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      proc ?? "---",
                      style: TextStyle(
                        color: proc != null ? Colors.white : Colors.white10,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHardwareControls(OSProvider p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          _buildActionButton(
            label: "CYCLE PIPELINE",
            icon: Icons.fast_forward,
            color: Colors.blueAccent,
            onTap: p.runPipelineStep,
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            label: "INTERRUPTION RÉSEAU",
            icon: Icons.wifi_protected_setup,
            color: Colors.orangeAccent,
            onTap: () => p.triggerInterrupt("NETWORK"),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            label: "INTERRUPTION DISQUE",
            icon: Icons.save,
            color: Colors.purpleAccent,
            onTap: () => p.triggerInterrupt("DISK READ"),
          ),
          const Spacer(),
          const Text(
            "DIAGNOSTIC SYSTÈME: OPTIMAL",
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
