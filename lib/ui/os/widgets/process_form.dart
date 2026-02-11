import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/os_model.dart';
import '../../../providers/os_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../theme.dart';

class ProcessForm extends StatefulWidget {
  const ProcessForm({super.key});

  @override
  State<ProcessForm> createState() => _ProcessFormState();
}

class _ProcessFormState extends State<ProcessForm> {
  final _nameController = TextEditingController();
  final _arrivalController = TextEditingController(text: '0');
  final _burstController = TextEditingController(text: '1');
  Color _selectedColor = Colors.blue;

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.cyan,
    Colors.pink,
    Colors.amber,
  ];

  @override
  Widget build(BuildContext context) {
    final osProvider = context.read<OSProvider>();
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("AJOUTER UN PROCESSUS", theme),
          const SizedBox(height: 16),
          _buildTextField("Nom (ex: P1)", _nameController, theme),
          const SizedBox(height: 12),
          _buildTextField(
            "Temps d'arrivée",
            _arrivalController,
            theme,
            isNumber: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            "Temps d'exécution (Burst)",
            _burstController,
            theme,
            isNumber: true,
          ),
          const SizedBox(height: 16),
          Text(
            "Couleur",
            style: TextStyle(color: ThemeColors.textMain(theme), fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableColors
                .map(
                  (c) => GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: _selectedColor == c
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final name = _nameController.text.trim();
                final arrival = int.tryParse(_arrivalController.text) ?? 0;
                final burst = int.tryParse(_burstController.text) ?? 1;

                if (name.isNotEmpty) {
                  osProvider.addProcess(
                    OSProcess(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      arrivalTime: arrival,
                      burstTime: burst,
                      color: _selectedColor,
                    ),
                  );
                  _nameController.clear();
                  _arrivalController.text = '0';
                  _burstController.text = '1';
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("AJOUTER"),
            ),
          ),
          const Divider(height: 32, color: Colors.white10),
          _buildSectionTitle("LISTE DES PROCESSUS", theme),
          const SizedBox(height: 12),
          Expanded(
            child: Consumer<OSProvider>(
              builder: (context, p, _) => ListView.builder(
                itemCount: p.processes.length,
                itemBuilder: (context, i) {
                  final pro = p.processes[i];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: pro.color,
                      radius: 8,
                    ),
                    title: Text(
                      pro.name,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    subtitle: Text(
                      "Arr: ${pro.arrivalTime}, Burst: ${pro.burstTime}",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => p.removeProcess(pro.id),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppTheme theme) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.amber,
        fontWeight: FontWeight.bold,
        fontSize: 10,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    AppTheme theme, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
    );
  }
}
