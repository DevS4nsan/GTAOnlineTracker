import 'package:flutter/material.dart';

class DynamicProgressBar extends StatelessWidget {
  final int obtained;
  final int total;
  final String label;

  const DynamicProgressBar({
    super.key,
    required this.obtained,
    required this.total,
    this.label = "Obtenidos",
  });

  @override
  Widget build(BuildContext context) {
    double progress = total == 0 ? 0 : obtained / total;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white12),
          ),
          child: Stack(
            children: [
              _buildTextRow(Colors.white),

              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    width: constraints.maxWidth, 
                    color: Colors.white,
                    child: _buildTextRow(Colors.black),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextRow(Color textColor) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'Chalet'),
          ),
          Text(
            "$obtained/$total",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'Chalet'),
          ),
        ],
      ),
    );
  }
}