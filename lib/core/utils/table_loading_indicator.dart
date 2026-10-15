import 'package:flutter/material.dart';

class TableLoadingIndicator extends StatelessWidget {
  const TableLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: Color(0xFF2E7D32),
        ),
      ),
    );
  }
}

class TableLoadingOverlay extends StatelessWidget {
  const TableLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: Color(0xB3FFFFFF),
              child: const TableLoadingIndicator(),
            ),
          ),
      ],
    );
  }
}
