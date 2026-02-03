import 'package:flutter/material.dart';
import 'dart:math' as math;

class MeriseActionFab extends StatefulWidget {
  final VoidCallback onAddEntity;
  final VoidCallback onAddRelation;
  final VoidCallback onToggleLink;
  final bool isLinkMode;
  final Function(bool isOpen)? onToggle;

  const MeriseActionFab({
    super.key,
    required this.onAddEntity,
    required this.onAddRelation,
    required this.onToggleLink,
    required this.isLinkMode,
    this.onToggle,
  });

  @override
  State<MeriseActionFab> createState() => _MeriseActionFabState();
}

class _MeriseActionFabState extends State<MeriseActionFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      widget.onToggle?.call(_isOpen);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isOpen ? 160 : 56,
      height: _isOpen ? 160 : 56,
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          // Sub-buttons
          _buildCircularButton(
            icon: Icons.rectangle_outlined,
            label: "Entité",
            angle: 180, // Gauche
            onTap: () {
              _toggle();
              widget.onAddEntity();
            },
            color: const Color(0xFF1E88E5),
          ),
          _buildCircularButton(
            icon: Icons.circle_outlined,
            label: "Relation",
            angle: 225, // Diagonale
            onTap: () {
              _toggle();
              widget.onAddRelation();
            },
            color: const Color(0xFF43A047),
          ),
          _buildCircularButton(
            icon: widget.isLinkMode ? Icons.link_off : Icons.add_link,
            label: "Lien",
            angle: 270, // Haut
            onTap: () {
              _toggle();
              widget.onToggleLink();
            },
            color: widget.isLinkMode ? Colors.orange : const Color(0xFF8E24AA),
          ),

          // Main Button
          FloatingActionButton(
            heroTag: "fab_main_menu",
            onPressed: _toggle,
            backgroundColor: const Color(0xFF1E88E5),
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _controller,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required String label,
    required double angle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double rad = angle * math.pi / 180;
        final double dist = 100.0 * _controller.value;
        final double x = dist * math.cos(rad);
        final double y = dist * math.sin(rad);

        return Transform.translate(
          offset: Offset(x, y),
          child: Opacity(
            opacity: _controller.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _controller,
                  child: FloatingActionButton(
                    heroTag: "fab_$label",
                    mini: true,
                    onPressed: onTap,
                    backgroundColor: color,
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                ),
                if (_controller.value > 0.8)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
