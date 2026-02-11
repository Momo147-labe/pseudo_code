import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/os_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/os_model.dart';
import '../../theme.dart';
import 'widgets/process_form.dart';
import 'widgets/gantt_chart.dart';
import 'widgets/metrics_table.dart';
import 'widgets/theory_view.dart';
import 'widgets/io_simulation_view.dart';
import 'widgets/state_transition_view.dart';
import 'widgets/internal_architecture_view.dart';
import 'widgets/sync_simulation_view.dart';
import 'widgets/memory_advanced_view.dart';
import 'widgets/file_system_view.dart';
import 'widgets/security_simulation_view.dart';
import 'widgets/network_simulation_view.dart';
import 'widgets/virtualization_view.dart';

class OSStudio extends StatelessWidget {
  const OSStudio({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final osProvider = context.watch<OSProvider>();

    return Row(
      children: [
        // Left Sidebar: Process Management (Only in Scheduling mode)
        if (osProvider.activeMode == OSStudioMode.simulation &&
            osProvider.activeCategory == SimulationCategory.scheduling)
          const ProcessForm(),

        // Main Area: Visualization and Controls
        Expanded(
          child: Container(
            color: ThemeColors.editorBg(theme),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
                  child: _buildHeader(osProvider, theme),
                ),

                if (osProvider.activeMode == OSStudioMode.simulation)
                  _buildSimulationSubNav(osProvider, theme),

                const SizedBox(height: 16),

                Expanded(
                  child: osProvider.activeMode == OSStudioMode.theory
                      ? const TheoryView()
                      : _buildActiveSimulation(osProvider, theme),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimulationSubNav(OSProvider p, AppTheme theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _buildSubNavItem(
            label: "ORDONNANCEMENT",
            isActive: p.activeCategory == SimulationCategory.scheduling,
            onTap: () => p.setActiveCategory(SimulationCategory.scheduling),
            theme: theme,
          ),
          const SizedBox(width: 8),
          _buildSubNavItem(
            label: "PÉRIPHÉRIQUES",
            isActive: p.activeCategory == SimulationCategory.io,
            onTap: () => p.setActiveCategory(SimulationCategory.io),
            theme: theme,
          ),
          const SizedBox(width: 8),
          _buildSubNavItem(
            label: "ÉTATS DES PROCESSUS",
            isActive: p.activeCategory == SimulationCategory.states,
            onTap: () => p.setActiveCategory(SimulationCategory.states),
            theme: theme,
          ),
          const SizedBox(width: 8),
          _buildSubNavItem(
            label: "ARCHITECTURE",
            isActive: p.activeCategory == SimulationCategory.internal,
            onTap: () => p.setActiveCategory(SimulationCategory.internal),
            theme: theme,
          ),
          const SizedBox(width: 8),
          _buildSubNavItem(
            label: "SYNCHRONISATION",
            isActive: p.activeCategory == SimulationCategory.sync,
            onTap: () => p.setActiveCategory(SimulationCategory.sync),
            theme: theme,
          ),
          const SizedBox(width: 8),
          _buildSubNavItem(
            label: "MÉMOIRE ADV",
            isActive: p.activeCategory == SimulationCategory.memoryAdvanced,
            onTap: () => p.setActiveCategory(SimulationCategory.memoryAdvanced),
            theme: theme,
          ),
          const SizedBox(width: 8),
          _buildSubNavItem(
            label: "FICHIERS",
            isActive: p.activeCategory == SimulationCategory.fileSystem,
            onTap: () => p.setActiveCategory(SimulationCategory.fileSystem),
            theme: theme,
          ),
          const SizedBox(width: 8),
          _buildSubNavItem(
            label: "SÉCURITÉ",
            isActive: p.activeCategory == SimulationCategory.security,
            onTap: () => p.setActiveCategory(SimulationCategory.security),
            theme: theme,
          ),
          const SizedBox(width: 8),
          _buildSubNavItem(
            label: "RÉSEAU",
            isActive: p.activeCategory == SimulationCategory.network,
            onTap: () => p.setActiveCategory(SimulationCategory.network),
            theme: theme,
          ),
          const SizedBox(width: 8),
          _buildSubNavItem(
            label: "VIRTUALISATION",
            isActive: p.activeCategory == SimulationCategory.virtualization,
            onTap: () => p.setActiveCategory(SimulationCategory.virtualization),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildSubNavItem({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required AppTheme theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.amber.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Colors.amber.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive
                ? Colors.amber
                : Colors.white.withValues(alpha: 0.5),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSimulation(OSProvider p, AppTheme theme) {
    switch (p.activeCategory) {
      case SimulationCategory.scheduling:
        return _buildSimulationView(p, theme);
      case SimulationCategory.io:
        return const IOSimulationView();
      case SimulationCategory.states:
        return const StateTransitionView();
      case SimulationCategory.internal:
        return const InternalArchitectureView();
      case SimulationCategory.sync:
        return const SyncSimulationView();
      case SimulationCategory.memoryAdvanced:
        return const MemoryAdvancedView();
      case SimulationCategory.fileSystem:
        return const FileSystemView();
      case SimulationCategory.security:
        return const SecuritySimulationView();
      case SimulationCategory.network:
        return const NetworkSimulationView();
      case SimulationCategory.virtualization:
        return const VirtualizationView();
    }
  }

  Widget _buildSimulationView(OSProvider osProvider, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (osProvider.processes.isEmpty)
            _buildEmptyState(theme)
          else ...[
            _buildSimulationStatusBar(osProvider, theme),
            const SizedBox(height: 24),

            // Gantt Chart
            GanttChart(
              steps: osProvider.steps,
              currentStepIndex: osProvider.currentStepIndex,
              theme: theme,
            ),

            const SizedBox(height: 32),

            // Performance Metrics
            Expanded(
              child: SingleChildScrollView(
                child: MetricsTable(
                  processes:
                      osProvider.currentStep?.processes ?? osProvider.processes,
                  simulationFinished:
                      osProvider.currentStepIndex ==
                      osProvider.steps.length - 1,
                  theme: theme,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(OSProvider p, AppTheme theme) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "STUDIO SYSTÈME D'EXPLOITATION",
              style: TextStyle(
                color: ThemeColors.textMain(theme),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              p.activeMode == OSStudioMode.theory
                  ? "Explorateur de concepts et résumé de cours"
                  : "Simulateur d'ordonnancement de processus",
              style: TextStyle(
                color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Mode Switch (Toggle Simulation/Theory)
        _buildModeToggle(p, theme),
        const SizedBox(width: 16),
        // Algorithm Selection (Only in Simulation mode)
        if (p.activeMode == OSStudioMode.simulation)
          _buildAlgoSelector(p, theme),
      ],
    );
  }

  Widget _buildModeToggle(OSProvider p, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleItem(
            label: "Simulation",
            icon: Icons.biotech,
            isActive: p.activeMode == OSStudioMode.simulation,
            onTap: () => p.setActiveMode(OSStudioMode.simulation),
            theme: theme,
          ),
          _buildToggleItem(
            label: "Théorie",
            icon: Icons.menu_book,
            isActive: p.activeMode == OSStudioMode.theory,
            onTap: () => p.setActiveMode(OSStudioMode.theory),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required AppTheme theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.blueAccent.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isActive
              ? Border.all(color: Colors.blueAccent.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? Colors.blueAccent
                  : Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlgoSelector(OSProvider p, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SchedulingAlgorithm>(
          value: p.algorithm,
          dropdownColor: ThemeColors.sidebarBg(theme),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: const [
            DropdownMenuItem(
              value: SchedulingAlgorithm.fcfs,
              child: Text("FCFS (Premier arrivé, premier servi)"),
            ),
            DropdownMenuItem(
              value: SchedulingAlgorithm.sjf,
              child: Text("SJF (Plus court d'abord)"),
            ),
            DropdownMenuItem(
              value: SchedulingAlgorithm.roundRobin,
              child: Text("Round Robin (Bientôt)"),
            ),
          ],
          onChanged: (val) {
            if (val != null) p.setAlgorithm(val);
          },
        ),
      ),
    );
  }

  Widget _buildSimulationStatusBar(OSProvider p, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Controls
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            onPressed: p.runSimulation,
            tooltip: "Relancer la simulation",
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: p.currentStepIndex > 0 ? p.previousStep : null,
            color: Colors.white,
          ),
          IconButton(
            icon: Icon(p.isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: p.steps.isNotEmpty ? p.togglePlay : p.runSimulation,
            color: Colors.greenAccent,
            iconSize: 32,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: p.currentStepIndex < p.steps.length - 1
                ? p.nextStep
                : null,
            color: Colors.white,
          ),
          const SizedBox(width: 24),
          // Current Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.currentStep?.description ??
                      "Appuyez sur Lecture pour démarrer",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (p.currentStep != null)
                  Text(
                    "Temps T = ${p.currentStep!.time}",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
              ],
            ),
          ),
          // Progress
          if (p.steps.isNotEmpty)
            Text(
              "${p.currentStepIndex + 1} / ${p.steps.length}",
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppTheme theme) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_task,
              size: 48,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            const Text(
              "Aucun processus défini",
              style: TextStyle(color: Colors.white30, fontSize: 16),
            ),
            const Text(
              "Utilisez le formulaire à gauche pour commencer",
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
