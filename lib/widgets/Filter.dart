import 'package:flutter/material.dart';

class Filter extends StatefulWidget {
  final Function(Map<String, dynamic>) onFilterChanged;

  const Filter({
    Key? key,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  _FilterState createState() => _FilterState();
}

class _FilterState extends State<Filter> {
  String _selectedSort = 'distance';
  String? _selectedPriceRange;
  double _minRating = 0.0;
  List<String> _selectedCategories = [];

  void _updateFilters() {
    widget.onFilterChanged({
      'sortBy': _selectedSort,
      'priceRange': _selectedPriceRange,
      'minRating': _minRating,
      'categories': _selectedCategories,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // 정렬 옵션
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSortChip('거리순', 'distance'),
              _buildSortChip('평점순', 'rating'),
              _buildSortChip('리뷰순', 'reviews'),
            ],
          ),
        ),
        SizedBox(height: 8),

        // 가격대 필터
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPriceChip('전체', null),
              _buildPriceChip('만원 미만', 'low'),
              _buildPriceChip('1-2만원', 'medium'),
              _buildPriceChip('2만원 이상', 'high'),
            ],
          ),
        ),
        SizedBox(height: 8),

        // 평점 필터
        Row(
          children: [
            Text('최소 평점: ${_minRating.toStringAsFixed(1)}'),
            Expanded(
              child: Slider(
                value: _minRating,
                min: 0.0,
                max: 5.0,
                divisions: 10,
                label: _minRating.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _minRating = value;
                    _updateFilters();
                  });
                },
              ),
            ),
          ],
        ),

        // 카테고리 필터
        Wrap(
          spacing: 8,
          children: [
            _buildCategoryChip('한식'),
            _buildCategoryChip('중식'),
            _buildCategoryChip('일식'),
            _buildCategoryChip('양식'),
            _buildCategoryChip('카페'),
          ],
        ),
      ],
    );
  }

  Widget _buildSortChip(String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedSort == value;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedSort = value;
            _updateFilters();
          });
        },
        backgroundColor: theme.cardColor,
        selectedColor: colorScheme.primary.withOpacity(0.2),
        checkmarkColor: colorScheme.primary,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: isSelected ? colorScheme.primary : theme.textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  Widget _buildPriceChip(String label, String? value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedPriceRange == value;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedPriceRange = selected ? value : null;
            _updateFilters();
          });
        },
        backgroundColor: theme.cardColor,
        selectedColor: colorScheme.primary.withOpacity(0.2),
        checkmarkColor: colorScheme.primary,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: isSelected ? colorScheme.primary : theme.textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedCategories.contains(category);

    return FilterChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedCategories.add(category);
          } else {
            _selectedCategories.remove(category);
          }
          _updateFilters();
        });
      },
      backgroundColor: theme.cardColor,
      selectedColor: colorScheme.primary.withOpacity(0.2),
      checkmarkColor: colorScheme.primary,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: isSelected ? colorScheme.primary : theme.textTheme.bodyMedium?.color,
      ),
    );
  }
}