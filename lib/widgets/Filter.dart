import 'package:flutter/material.dart';

class Filter extends StatefulWidget {
  final Function(Map<String, dynamic>) onFilterChanged;
  final Map<String, dynamic>? initialFilters;

  const Filter({
    Key? key, 
    required this.onFilterChanged,
    this.initialFilters,
  }) : super(key: key);

  @override
  State<Filter> createState() => _FilterState();
}

class _FilterState extends State<Filter> {
  String selectedFilter = '거리';
  String? distanceOrder; // 'asc' or 'desc'
  bool onlyHeart = false;
  String? reviewOrder; // 'asc' or 'desc'
  Set<String> selectedCategories = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialFilters != null) {
      // 초기 필터 값 설정
      if (widget.initialFilters!['distanceOrder'] != null) {
        distanceOrder = widget.initialFilters!['distanceOrder'];
      }
      if (widget.initialFilters!['onlyHeart'] != null) {
        onlyHeart = widget.initialFilters!['onlyHeart'];
      }
      if (widget.initialFilters!['reviewOrder'] != null) {
        reviewOrder = widget.initialFilters!['reviewOrder'];
      }
      if (widget.initialFilters!['categories'] != null) {
        selectedCategories = Set<String>.from(widget.initialFilters!['categories']);
      }
    }
  }

  void _notify() {
    widget.onFilterChanged({
      'filter': selectedFilter,
      'distanceOrder': distanceOrder,
      'onlyHeart': onlyHeart,
      'reviewOrder': reviewOrder,
      'categories': selectedCategories.toList(),
    });
  }

  void _clearFilter(String type) {
    setState(() {
      if (type == 'distance') distanceOrder = null;
      if (type == 'heart') onlyHeart = false;
      if (type == 'review') reviewOrder = null;
      if (type == 'category') selectedCategories.clear();
      _notify();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filterButtons = [
      {'label': '거리', 'icon': Icons.place},
      {'label': '하트', 'icon': Icons.favorite},
      {'label': '리뷰', 'icon': Icons.comment},
      {'label': '카테고리', 'icon': Icons.restaurant},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 필터 바
        Container(
          color: Theme.of(context).cardColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: filterButtons.map((btn) {
              final isActive = selectedFilter == btn['label'];
              return TextButton.icon(
                icon: Icon(
                  btn['icon'] as IconData,
                  color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
                  size: 20,
                ),
                label: Text(
                  btn['label'] as String,
                  style: TextStyle(
                    color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: isActive ? Theme.of(context).colorScheme.primary.withOpacity(0.08) : Colors.transparent,
                  shape: StadiumBorder(),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                onPressed: () {
                  setState(() {
                    selectedFilter = btn['label'] as String;
                  });
                },
              );
            }).toList(),
          ),
        ),
        // 옵션 영역
        AnimatedSwitcher(
          duration: Duration(milliseconds: 200),
          child: _buildFilterOptions(),
        ),
        // 적용된 필터 태그
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 2,
            children: [
              if (distanceOrder == 'asc') _activeChip('거리: 가까운 순', () => _clearFilter('distance')),
              if (distanceOrder == 'desc') _activeChip('거리: 먼 순', () => _clearFilter('distance')),
              if (onlyHeart) _activeChip('하트 등록만', () => _clearFilter('heart')),
              if (reviewOrder == 'asc') _activeChip('리뷰: 적은 순', () => _clearFilter('review')),
              if (reviewOrder == 'desc') _activeChip('리뷰: 많은 순', () => _clearFilter('review')),
              ...selectedCategories.map((cat) => _activeChip(cat, () {
                setState(() {
                  selectedCategories.remove(cat);
                  _notify();
                });
              })),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterOptions() {
    // 고정 크기와 스타일을 위한 상수 정의
    const double chipHeight = 32.0;
    const double iconSize = 16.0;
    const double fontSize = 12.0;
    const double horizontalPadding = 12.0;
    
    // 색상만 변경되는 함수 정의
    Color getChipColor(bool selected) => selected ? Theme.of(context).colorScheme.primary : Colors.grey;
    Color getTextColor(bool selected) => selected ? Theme.of(context).colorScheme.primary : Colors.black87;
    Color getBackgroundColor(bool selected) => selected 
        ? Theme.of(context).colorScheme.primary.withOpacity(0.15) 
        : Colors.grey[200]!;
        
    // 공통 스타일 정의
    TextStyle fixedTextStyle(bool selected) => TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.normal,
      height: 1.0,
      letterSpacing: 0,
      color: getTextColor(selected),
    );

    switch (selectedFilter) {
      case '거리':
        return Padding(
          key: ValueKey('거리'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 가까운 순
              _buildFixedSizeChip(
                label: '가까운 순',
                icon: Icons.arrow_upward,
                selected: distanceOrder == 'asc',
                onSelected: (v) {
                  setState(() {
                    distanceOrder = v ? 'asc' : null;
                    _notify();
                  });
                },
                height: chipHeight,
                iconSize: iconSize,
                textStyle: fixedTextStyle,
                getBackgroundColor: getBackgroundColor,
                getIconColor: getChipColor,
              ),
              SizedBox(width: 10),
              // 먼 순
              _buildFixedSizeChip(
                label: '먼 순',
                icon: Icons.arrow_downward,
                selected: distanceOrder == 'desc',
                onSelected: (v) {
                  setState(() {
                    distanceOrder = v ? 'desc' : null;
                    _notify();
                  });
                },
                height: chipHeight,
                iconSize: iconSize,
                textStyle: fixedTextStyle,
                getBackgroundColor: getBackgroundColor,
                getIconColor: getChipColor,
              ),
            ],
          ),
        );
        
      case '하트':
        return Padding(
          key: ValueKey('하트'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('하트 등록된 맛집만 보기', style: TextStyle(fontSize: 13, color: Colors.red)),
              SizedBox(width: 8),
              Switch(
                value: onlyHeart,
                activeColor: Colors.red,
                onChanged: (v) {
                  setState(() {
                    onlyHeart = v;
                    _notify();
                  });
                },
              ),
            ],
          ),
        );
        
      case '리뷰':
        return Padding(
          key: ValueKey('리뷰'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 적은 순
              _buildFixedSizeChip(
                label: '적은 순',
                icon: Icons.arrow_upward,
                selected: reviewOrder == 'asc',
                onSelected: (v) {
                  setState(() {
                    reviewOrder = v ? 'asc' : null;
                    _notify();
                  });
                },
                height: chipHeight,
                iconSize: iconSize,
                textStyle: fixedTextStyle,
                getBackgroundColor: getBackgroundColor,
                getIconColor: getChipColor,
              ),
              SizedBox(width: 10),
              // 많은 순
              _buildFixedSizeChip(
                label: '많은 순',
                icon: Icons.arrow_downward,
                selected: reviewOrder == 'desc',
                onSelected: (v) {
                  setState(() {
                    reviewOrder = v ? 'desc' : null;
                    _notify();
                  });
                },
                height: chipHeight,
                iconSize: iconSize,
                textStyle: fixedTextStyle,
                getBackgroundColor: getBackgroundColor,
                getIconColor: getChipColor,
              ),
            ],
          ),
        );
        
      case '카테고리':
        final categories = ['한식', '중식', '일식', '양식', '카페'];
        return Padding(
          key: ValueKey('카테고리'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFixedSizeFilterChip(
                    label: cat,
                    selected: selectedCategories.contains(cat),
                    onSelected: (v) {
                      setState(() {
                        if (v) selectedCategories.add(cat);
                        else selectedCategories.remove(cat);
                        _notify();
                      });
                    },
                    height: chipHeight,
                    textStyle: fixedTextStyle,
                    getBackgroundColor: getBackgroundColor,
                  ),
                )).toList(),
              ),
            ),
          ),
        );
        
      default:
        return SizedBox.shrink();
    }
  }

  // 고정 크기 ChoiceChip 생성 위젯
  Widget _buildFixedSizeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required Function(bool) onSelected,
    required double height,
    required double iconSize,
    required TextStyle Function(bool) textStyle,
    required Color Function(bool) getBackgroundColor,
    required Color Function(bool) getIconColor,
  }) {
    return Container(
      height: height,
      child: Material(
        color: getBackgroundColor(selected),
        shape: StadiumBorder(),
        child: InkWell(
          onTap: () => onSelected(!selected),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: iconSize,
                  color: getIconColor(selected),
                ),
                SizedBox(width: 4),
                Text(
                  label,
                  style: textStyle(selected),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // 고정 크기 FilterChip(카테고리용) 생성 위젯
  Widget _buildFixedSizeFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
    required double height,
    required TextStyle Function(bool) textStyle,
    required Color Function(bool) getBackgroundColor,
  }) {
    return Container(
      height: height,
      child: Material(
        color: getBackgroundColor(selected),
        shape: StadiumBorder(),
        child: InkWell(
          onTap: () => onSelected(!selected),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Center(
              child: Text(
                label,
                style: textStyle(selected),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _activeChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11)),
          SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            child: Icon(Icons.close, size: 13, color: Colors.grey),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
      shape: StadiumBorder(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
    );
  }
}