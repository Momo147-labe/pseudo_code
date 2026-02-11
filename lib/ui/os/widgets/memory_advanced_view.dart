import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/os_provider.dart';

class MemoryAdvancedView extends StatefulWidget {
  const MemoryAdvancedView({super.key});

  @override
  State<MemoryAdvancedView> createState() => _MemoryAdvancedViewState();
}

class _MemoryAdvancedViewState extends State<MemoryAdvancedView> {
  final TextEditingController _pageController = TextEditingController();
  int? _translatedFrame;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OSProvider>().initializePageTable();
    });
  }

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
                // Logical Address Input
                Expanded(flex: 1, child: _buildAddressTranslation(p)),
                const SizedBox(width: 40),
                // Page Table View
                Expanded(child: _buildPageTable(p)),
                const SizedBox(width: 40),
                // Physical Memory View
                Expanded(child: _buildPhysicalMemory(p)),
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
          "GESTION AVANCÉE DE LA MÉMOIRE",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        Text(
          "Simulation de la Pagination (MMU)",
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAddressTranslation(OSProvider p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TRADUCTION D'ADRESSE",
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _pageController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "N° de Page Logique",
              labelStyle: TextStyle(color: Colors.white38),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final page = int.tryParse(_pageController.text);
                if (page != null) {
                  setState(() {
                    _translatedFrame = p.translateAddress(page);
                  });
                }
              },
              child: const Text("TRADUIRE"),
            ),
          ),
          const Spacer(),
          if (_translatedFrame != null)
            _buildResultBox()
          else
            const Text(
              "Entrez un numéro de page (0-3) pour tester la MMU.",
              style: TextStyle(color: Colors.white24, fontSize: 10),
            ),
        ],
      ),
    );
  }

  Widget _buildResultBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text(
            "RÉSULTAT MMU",
            style: TextStyle(
              color: Colors.green,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Page ${_pageController.text} -> Cadre $_translatedFrame",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'JetBrainsMono',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Adresse Physique: 0x${(_translatedFrame! * 4096).toRadixString(16).toUpperCase()}",
            style: const TextStyle(color: Colors.white54, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTable(OSProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "TABLE DES PAGES (RAM)",
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: ListView(
              children: p.pageTable.entries
                  .map((e) => _buildTableRow(e.key, e.value))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(int page, int frame) {
    bool isSource = _pageController.text == page.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSource
            ? Colors.blueAccent.withValues(alpha: 0.1)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Page $page",
            style: TextStyle(
              color: isSource ? Colors.blueAccent : Colors.white70,
              fontSize: 12,
            ),
          ),
          const Icon(Icons.arrow_right_alt, color: Colors.white24, size: 16),
          Text(
            "Cadre $frame",
            style: TextStyle(
              color: isSource ? Colors.blueAccent : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalMemory(OSProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "MÉMOIRE PHYSIQUE",
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 32,
              itemBuilder: (context, index) {
                bool isTarget = _translatedFrame == index;
                return Container(
                  decoration: BoxDecoration(
                    color: isTarget
                        ? Colors.blueAccent
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: isTarget ? Colors.white : Colors.white10,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      index.toString(),
                      style: TextStyle(
                        color: isTarget ? Colors.white : Colors.white10,
                        fontSize: 8,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
