import 'package:flutter/material.dart';
import '../utils/game_rules.dart';

class PropertyLimitsModal extends StatelessWidget {
  final Map<String, int> ownedCounts;
  final Set<String> ownedMCSubtypes;

  const PropertyLimitsModal({
    super.key, 
    required this.ownedCounts,
    required this.ownedMCSubtypes,
  });

  @override
  Widget build(BuildContext context) {
    final categories = GameRules.propertyLimits.keys.toList();
    categories.sort();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D0D),
        border: Border(top: BorderSide(color: Color(0xFF333333), width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "LÍMITES DEL CATÁLOGO", 
                style: TextStyle(fontFamily: "Pricedown", fontSize: 28, color: Colors.white)
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Rockstar limita la cantidad de propiedades que puedes poseer simultáneamente. Aquí está tu progreso:",
            style: TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Chalet'),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final limit = GameRules.propertyLimits[category]!;
                final owned = ownedCounts[category] ?? 0;
                final isMaxed = owned >= limit;
                Widget categoryRow = _buildMainRow(category, owned, limit, isMaxed);
                if (category == 'MC Businesses') {
                  return Column(
                    children: [
                      categoryRow,
                      _buildSubtypeRow('Cocaína', ownedMCSubtypes.contains('Cocaine')),
                      _buildSubtypeRow('Metanfetaminas', ownedMCSubtypes.contains('Meth')),
                      _buildSubtypeRow('Dinero Falso', ownedMCSubtypes.contains('Cash')),
                      _buildSubtypeRow('Hierba', ownedMCSubtypes.contains('Weed')),
                      _buildSubtypeRow('Documentos Falsos', ownedMCSubtypes.contains('Document')),
                    ],
                  );
                }
                if (category == 'Apartments & Garages') {
                  return Column(
                    children: [
                      categoryRow,
                      _buildSubtypeRow(
                        'Cualquier combinación permitida', 
                        owned > 0, 
                        trailingText: "Total: $owned",
                      ),
                    ],
                  );
                }
                return categoryRow;
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildMainRow(String title, int owned, int limit, bool isMaxed) {
    final textColor = isMaxed ? Colors.limeAccent : Colors.white;
    final borderColor = isMaxed ? Colors.limeAccent.withOpacity(0.3) : Colors.white12;
    final bgColor = isMaxed ? Colors.limeAccent.withOpacity(0.05) : const Color(0xFF1A1A1A);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(), 
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'Chalet')
          ),
          Row(
            children: [
              if (isMaxed) const Icon(Icons.check_circle, color: Colors.limeAccent, size: 16),
              if (isMaxed) const SizedBox(width: 8),
              Text(
                "$owned / $limit", 
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubtypeRow(String subtype, bool isOwned, {String? trailingText}) {
    final textColor = isOwned ? Colors.limeAccent : Colors.white54;
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        border: Border(left: BorderSide(color: isOwned ? Colors.limeAccent : Colors.white24, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(subtype.toUpperCase(), style: TextStyle(color: textColor, fontSize: 11, fontFamily: 'Chalet')),
          Text(
            trailingText ?? (isOwned ? "1 / 1" : "0 / 1"), 
            style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Chalet')
          ),
        ],
      ),
    );
  }
}