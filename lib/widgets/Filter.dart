import 'package:flutter/material.dart';

class Filter extends StatefulWidget {
  @override
  _FilterState createState() => _FilterState();
}

class _FilterState extends State<Filter> {
  List<String> selectedFilters = []; // 선택된 필터 목록

  // 필터 옵션 목록
  final List<Map<String, dynamic>> filterOptions = [
    {'id': 'distance', 'name': '거리순', 'icon': Icons.location_on, 'isIcon': true},
    {'id': 'price', 'name': '가격대', 'icon': Icons.attach_money, 'isIcon': true},
    {'id': 'rating', 'name': '평점', 'icon': Icons.star, 'isIcon': true},
    {'id': 'category', 'name': '카테고리', 'icon': 'assets/Heart_P.png', 'isIcon': false},
  ];

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('필터 선택'),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: filterOptions.map((filter) {
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    title: Row(
                      children: [
                        filter['isIcon']
                            ? Icon(filter['icon'])
                            : Image.asset(
                          filter['icon'],
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: 8),
                        Text(filter['name']),
                      ],
                    ),
                    value: selectedFilters.contains(filter['id']),
                    activeColor: Color(0xFFA0CC71),
                    checkColor: Colors.white,
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true && !selectedFilters.contains(filter['id'])) {
                          selectedFilters.add(filter['id']);
                        } else if (value == false) {
                          selectedFilters.remove(filter['id']);
                        }
                      });
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('닫기'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeFilter(String filterId) {
    setState(() {
      selectedFilters.remove(filterId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseUnit = screenWidth / 360;

    return Container(
      height: baseUnit * 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: baseUnit * 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: selectedFilters.map((filterId) {
                  final filter = filterOptions.firstWhere(
                        (f) => f['id'] == filterId,
                  );
                  return Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: baseUnit * 2,
                      vertical: baseUnit * 1,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: baseUnit * 4,
                      vertical: baseUnit * 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(baseUnit * 20),
                    ),
                    child: Row(
                      children: [
                        filter['isIcon']
                            ? Icon(
                          filter['icon'],
                          size: baseUnit * 12,
                          color: Colors.grey.shade700,
                        )
                            : Image.asset(
                          filter['icon'],
                          width: baseUnit * 12,
                          height: baseUnit * 12,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: baseUnit * 2),
                        Text(
                          filter['name'],
                          style: TextStyle(
                            fontSize: baseUnit * 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(width: baseUnit * 2),
                        GestureDetector(
                          onTap: () => _removeFilter(filterId),
                          child: Icon(
                            Icons.close,
                            size: baseUnit * 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: baseUnit * 4),
            child: IconButton(
              icon: Icon(Icons.filter_list_alt),
              onPressed: _showFilterDialog,
            ),
          ),
        ],
      ),
    );
  }
}