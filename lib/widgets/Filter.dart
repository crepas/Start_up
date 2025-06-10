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
  String selectedFilter = ''; // 빈 문자열로 시작 (아무것도 선택 안됨)
  String? selectedSort; // 'likes', 'reviews', 'distance'
  Set<String> selectedCategories = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialFilters != null) {
      // 초기 필터 값 설정
      if (widget.initialFilters!['sortBy'] != null) {
        selectedSort = widget.initialFilters!['sortBy'];
        // 정렬이 선택되어 있으면 해당 필터 활성화
        if (selectedSort == 'likes') selectedFilter = '좋아요';
        else if (selectedSort == 'reviews') selectedFilter = '리뷰';
        else if (selectedSort == 'distance') selectedFilter = '거리';
      }
      if (widget.initialFilters!['categories'] != null) {
        selectedCategories = Set<String>.from(widget.initialFilters!['categories']);
        if (selectedCategories.isNotEmpty) selectedFilter = '카테고리';
      }
    }
  }

  void _notify() {
    Map<String, dynamic> filters = {};

    // 정렬 정보 추가
    if (selectedSort != null) {
      filters['sortBy'] = selectedSort;
    }

    // 카테고리 정보 추가
    if (selectedCategories.isNotEmpty) {
      filters['categories'] = selectedCategories.toList();
    }

    print('Filter에서 전송하는 데이터: $filters');
    widget.onFilterChanged(filters);
  }

  void _clearFilter(String type) {
    setState(() {
      if (type == 'sort') {
        selectedSort = null;
        if (selectedFilter == '거리' || selectedFilter == '좋아요' || selectedFilter == '리뷰') {
          selectedFilter = '';
        }
      }
      if (type == 'category') {
        selectedCategories.clear();
        if (selectedFilter == '카테고리') {
          selectedFilter = '';
        }
      }
      _notify();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filterButtons = [
      {'label': '거리', 'icon': Icons.place},
      {'label': '좋아요', 'icon': Icons.favorite}, // 하트 -> 좋아요로 변경
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
              if (selectedSort == 'likes') _activeChip('좋아요 많은순', () => _clearFilter('sort')),
              if (selectedSort == 'reviews') _activeChip('리뷰 많은순', () => _clearFilter('sort')),
              if (selectedSort == 'distance') _activeChip('거리 가까운순', () => _clearFilter('sort')),
              ...selectedCategories.map((cat) => _activeChip(cat, () {
                setState(() {
                  selectedCategories.remove(cat);
                  if (selectedCategories.isEmpty && selectedFilter == '카테고리') {
                    selectedFilter = '';
                  }
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
              // 가까운 순만 (먼 순 제거)
              _buildFixedSizeChip(
                label: '가까운 순',
                icon: Icons.near_me,
                selected: selectedSort == 'distance',
                onSelected: (v) {
                  setState(() {
                    selectedSort = v ? 'distance' : null;
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

      case '좋아요':
        return Padding(
          key: ValueKey('좋아요'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 많은 순만
              _buildFixedSizeChip(
                label: '많은 순',
                icon: Icons.favorite,
                selected: selectedSort == 'likes',
                onSelected: (v) {
                  setState(() {
                    selectedSort = v ? 'likes' : null;
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

      case '리뷰':
        return Padding(
          key: ValueKey('리뷰'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 많은 순만
              _buildFixedSizeChip(
                label: '많은 순',
                icon: Icons.comment,
                selected: selectedSort == 'reviews',
                onSelected: (v) {
                  setState(() {
                    selectedSort = v ? 'reviews' : null;
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