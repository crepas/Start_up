import 'package:flutter/material.dart';

class FoodCategoryBar extends StatefulWidget {
  final String currentCategory;
  final Function(String) onCategorySelected;

  const FoodCategoryBar({
    super.key, 
    required this.currentCategory,
    required this.onCategorySelected,
  });

  @override
  State<FoodCategoryBar> createState() => _FoodCategoryBarState();
}

class _FoodCategoryBarState extends State<FoodCategoryBar> {
  final List<Map<String, dynamic>> categories = [
    {'label': '전체', 'icon': Icons.restaurant, 'key': 'all'},
    {'label': '한식', 'emoji': '🍲', 'key': 'korean'},
    {'label': '중식', 'emoji': '🥢', 'key': 'chinese'},
    {'label': '일식', 'emoji': '🍣', 'key': 'japanese'},
    {'label': '양식', 'emoji': '🍔', 'key': 'western'},
    {'label': '카페', 'emoji': '☕', 'key': 'cafe'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: categories.map((category) {
            final isActive = widget.currentCategory == category['key'];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onTap: () => widget.onCategorySelected(category['key']!),
                child: Column(
                  children: [
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive 
                            ? colorScheme.primary.withOpacity(0.2) 
                            : theme.cardColor,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : [],
                      ),
                      child: Center(
                        child: category.containsKey('icon')
                            ? Icon(
                                category['icon'] as IconData,
                                color: isActive 
                                    ? colorScheme.primary 
                                    : theme.hintColor,
                                size: 28,
                              )
                            : Text(
                                category['emoji']!,
                                style: TextStyle(
                                  fontSize: 26,
                                  height: 1.0,
                                  color: isActive 
                                      ? colorScheme.primary 
                                      : theme.hintColor,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['label']!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive 
                            ? colorScheme.primary 
                            : theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
} 