part of 'flutter_holo_date_picker.dart';

/// Solar months of 31 days.
const List<int> _solarMonthsOf31Days = const <int>[1, 3, 5, 7, 8, 10, 12];

/// DatePicker widget.
class DatePickerWidget extends StatefulWidget {
  DatePickerWidget({
    Key? key,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.dateFormat = DatePickerConstants.DATETIME_PICKER_DATE_FORMAT,
    this.locale = DatePickerI18n.DATETIME_PICKER_LOCALE_DEFAULT,
    this.pickerTheme = DateTimePickerTheme.Default,
    this.onChanged,
    this.looping = false,
    this.squeeze = 0.95,
    this.diameterRatio = 1.5,
  }) : super(key: key) {
    DateTime minTime = firstDate ??
        DateTime.parse(DatePickerConstants.DATE_PICKER_MIN_DATETIME);
    DateTime maxTime = lastDate ??
        DateTime.parse(DatePickerConstants.DATE_PICKER_MAX_DATETIME);
    assert(minTime.compareTo(maxTime) < 0);
  }

  final DateTime? firstDate, lastDate, initialDate;
  final String dateFormat;
  final DateTimePickerLocale locale;
  final DateTimePickerTheme pickerTheme;

  final void Function(DateTime)? onChanged;
  final bool looping;

  final double squeeze;
  final double diameterRatio;

  @override
  State<StatefulWidget> createState() => _DatePickerWidgetState();
}

class _DatePickerWidgetState extends State<DatePickerWidget> {
  late DateTime _minDateTime, _maxDateTime;

  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;
  late int _selectedHour;
  late int _selectedMinutes;

  late List<int> _yearRange, _monthRange, _dayRange, _hourRange, _minutesRange;

  late final FixedExtentScrollController _yearController;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _dayController;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minutesController;

  late Map<String, FixedExtentScrollController?> _scrollControllers;
  late Map<String, List<int>?> _valueRanges;

  bool _isChangeDateRange = false;

  // whene change year the returned month is incorrect with the shown one
  // So _lock make sure that month doesn't change from cupertino widget
  // we will handle it manually
  bool _lock = false;

  @override
  void initState() {
    // handle current selected year、month、day
    DateTime initDateTime = widget.initialDate ?? DateTime.now();
    _selectedYear = initDateTime.year;
    _selectedMonth = initDateTime.month;
    _selectedDay = initDateTime.day;
    _selectedHour = initDateTime.hour;
    _selectedMinutes = initDateTime.minute;

    // handle DateTime range
    _minDateTime = widget.firstDate ??
        DateTime.parse(DatePickerConstants.DATE_PICKER_MIN_DATETIME);
    _maxDateTime = widget.lastDate ??
        DateTime.parse(DatePickerConstants.DATE_PICKER_MAX_DATETIME);

    // limit the range of year
    _yearRange = _calcYearRange();

    final maxYear = max(_minDateTime.year, _selectedYear);
    _selectedYear = min(maxYear, _maxDateTime.year);

    // limit the range of month
    _monthRange = _calcMonthRange();
    _selectedMonth = _calcCurrentMonth();

    // limit the range of day
    _dayRange = _calcDayRange();
    final maxDay = max(_dayRange.first, _selectedDay);
    _selectedDay = min(maxDay, _dayRange.last);

    // limit the range of hours
    _hourRange = _calcHourRange();

    // limit the range of minutes
    _minutesRange = _calcMinutesRange();

    // create scroll controller
    _yearController = FixedExtentScrollController(
      initialItem: _selectedYear - _yearRange.first,
    );
    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonth - _monthRange.first,
    );
    _dayController = FixedExtentScrollController(
      initialItem: _selectedDay - _dayRange.first,
    );

    _hourController = FixedExtentScrollController(
      initialItem: _selectedHour - _hourRange.first,
    );
    _minutesController = FixedExtentScrollController(
      initialItem: _selectedMinutes - _minutesRange.first,
    );

    _scrollControllers = {
      'y': _yearController,
      'M': _monthController,
      'd': _dayController,
      'h': _hourController,
      'm': _minutesController
    };
    _valueRanges = {
      'y': _yearRange,
      'M': _monthRange,
      'd': _dayRange,
      'h': _hourRange,
      'm': _minutesRange,
    };

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<String> formats = DateTimeFormatter.splitDateFormat(widget.dateFormat);

    return GestureDetector(
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: formats.map((format) {
            List<int> range = _findPickerItemRange(format)!;
            return _DatePickerColumnWidget(
              scrollController: _findScrollController(format),
              squeeze: widget.squeeze,
              pickerTheme: widget.pickerTheme,
              diameterRatio: widget.diameterRatio,
              range: range,
              selectedYear: _selectedYear,
              selectedMonth: _selectedMonth,
              locale: widget.locale,
              format: format,
              onSelectedItemChanged: (value) {
                if (format.contains('y')) {
                  _lock = true;
                  _changeYearSelection(value);
                  _lock = false;
                } else if (format.contains('M')) {
                  if (_lock) {
                    _lock = false;
                    return;
                  }
                  _changeMonthSelection(value);
                } else if (format.contains('d')) {
                  _changeDaySelection(value);
                } else if (format.contains('h')) {
                  _changeHoursSelection(value);
                } else if (format.contains('m')) {
                  _changeMinutesSelection(value);
                }
              },
              looping: widget.looping,
            );
          }).toList(),
        ),
      ),
    );
  }

  /// notify selected date changed
  void _onSelectedChange() {
    final dateTime = DateTime(
      _selectedYear,
      _selectedMonth,
      _selectedDay,
      _selectedHour,
      _selectedMinutes,
    );
    widget.onChanged?.call(dateTime);
  }

  /// find scroll controller by specified format
  FixedExtentScrollController? _findScrollController(String format) {
    final key = _scrollControllers.keys.firstWhereOrNull((key) {
      return format.contains(key);
    });

    return _scrollControllers[key];
  }

  /// find item value range by specified format
  List<int>? _findPickerItemRange(String format) {
    final key = _valueRanges.keys.firstWhereOrNull((key) {
      return format.contains(key);
    });
    return _valueRanges[key];
  }

  /// change the selection of year picker
  void _changeYearSelection(int index) {
    int year = _yearRange.first + index;
    if (_selectedYear != year) {
      _selectedYear = year;
      _changeDateRange();
      _onSelectedChange();
    }
  }

  /// change the selection of month picker
  void _changeMonthSelection(int index) {
    _monthRange = _calcMonthRange();

    int month = _monthRange.first + index;
    if (_selectedMonth != month) {
      _selectedMonth = month;

      _changeDateRange();
      _onSelectedChange();
    }
  }

  /// change the selection of day picker
  void _changeHoursSelection(int index) {
    if (_isChangeDateRange) return;

    _selectedHour = index;
    _onSelectedChange();
  }

  /// change the selection of day picker
  void _changeMinutesSelection(int index) {
    if (_isChangeDateRange) return;

    _selectedMinutes = index;
    _onSelectedChange();
  }

  /// change the selection of day picker
  void _changeDaySelection(int index) {
    if (_isChangeDateRange) return;

    int dayOfMonth = _dayRange.first + index;
    if (_selectedDay != dayOfMonth) {
      _selectedDay = dayOfMonth;
      _onSelectedChange();
    }
  }

  // get the correct month
  int _calcCurrentMonth() {
    var month = _selectedMonth;
    List<int> monthRange = _calcMonthRange();
    if (month < monthRange.last) {
      month = max(month, monthRange.first);
    } else {
      month = max(monthRange.last, monthRange.first);
    }

    return month;
  }

  /// change range of month and day
  void _changeDateRange() {
    if (_isChangeDateRange) {
      return;
    }
    _isChangeDateRange = true;

    List<int> monthRange = _calcMonthRange();
    bool didMonthRangeChange = _monthRange.first != monthRange.first ||
        _monthRange.last != monthRange.last;
    if (didMonthRangeChange) {
      // selected year changed
      _selectedMonth = _calcCurrentMonth();
    }

    List<int> dayRange = _calcDayRange();
    bool didDayRangeChange =
        _dayRange.first != dayRange.first || _dayRange.last != dayRange.last;
    if (didDayRangeChange) {
      // day range changed, need limit the value of selected day
      _selectedDay = max(min(_selectedDay, dayRange.last), dayRange.first);
    }

    setState(() {
      _monthRange = monthRange;
      _dayRange = dayRange;

      _valueRanges['M'] = monthRange;
      _valueRanges['d'] = dayRange;
    });

    if (didMonthRangeChange) {
      int currMonth = _selectedMonth;
      _monthController.jumpToItem(monthRange.last - monthRange.first);
      if (currMonth < monthRange.last) {
        _monthController.jumpToItem(currMonth - monthRange.first);
      }
    }

    if (didDayRangeChange) {
      int currDay = _selectedDay;

      if (currDay < dayRange.last) {
        _dayController.jumpToItem(currDay - dayRange.first);
      } else {
        _dayController.jumpToItem(dayRange.last - dayRange.first);
      }
    }

    _isChangeDateRange = false;
  }

  /// calculate the count of day in current month
  int _calcDayCountOfMonth() {
    if (_selectedMonth == 2) {
      return _isLeapYear(_selectedYear) ? 29 : 28;
    } else if (_solarMonthsOf31Days.contains(_selectedMonth)) {
      return 31;
    }
    return 30;
  }

  /// whether or not is leap year
  bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
  }

  /// calculate the range of year
  List<int> _calcYearRange() {
    return [_minDateTime.year, _maxDateTime.year];
  }

  /// calculate the range of hours
  List<int> _calcHourRange() {
    return [0, 23];
  }

  /// calculate the range of  minutes
  List<int> _calcMinutesRange() {
    return [0, 59];
  }

  /// calculate the range of month
  List<int> _calcMonthRange() {
    var minMonth = 1;
    var maxMonth = 12;

    final minYear = _minDateTime.year;
    final maxYear = _maxDateTime.year;

    if (minYear == _selectedYear) {
      // selected minimum year, limit month range
      minMonth = _minDateTime.month;
    }
    if (maxYear == _selectedYear) {
      // selected maximum year, limit month range
      maxMonth = _maxDateTime.month;
    }
    return [minMonth, maxMonth];
  }

  /// calculate the range of day
  List<int> _calcDayRange() {
    var minDay = 1;
    var maxDay = _calcDayCountOfMonth();

    final minYear = _minDateTime.year;
    final maxYear = _maxDateTime.year;
    final minMonth = _minDateTime.month;
    final maxMonth = _maxDateTime.month;
    final month = _selectedMonth;

    if (minYear == _selectedYear && minMonth == month) {
      // selected minimum year and month, limit day range
      minDay = _minDateTime.day;
    }
    if (maxYear == _selectedYear && maxMonth == month) {
      // selected maximum year and month, limit day range
      maxDay = _maxDateTime.day;
    }
    return [minDay, maxDay];
  }
}

class _DatePickerColumnWidget extends StatelessWidget {
  final FixedExtentScrollController? scrollController;
  final bool looping;
  final void Function(int) onSelectedItemChanged;
  final double squeeze;
  final DateTimePickerTheme pickerTheme;
  final double diameterRatio;
  final String format;
  final int selectedYear;
  final int selectedMonth;
  final List<int> range;
  final DateTimePickerLocale locale;

  const _DatePickerColumnWidget({
    Key? key,
    required this.scrollController,
    required this.looping,
    required this.onSelectedItemChanged,
    required this.squeeze,
    required this.pickerTheme,
    required this.diameterRatio,
    required this.format,
    required this.selectedYear,
    required this.selectedMonth,
    required this.range,
    required this.locale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Stack(
        fit: StackFit.loose,
        children: [
          Positioned(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 18),
              height: pickerTheme.pickerHeight,
              decoration: BoxDecoration(color: pickerTheme.backgroundColor),
              child: CupertinoPicker(
                selectionOverlay: SizedBox.shrink(),
                backgroundColor: pickerTheme.backgroundColor,
                scrollController: scrollController,
                squeeze: squeeze,
                diameterRatio: diameterRatio,
                itemExtent: pickerTheme.itemHeight,
                onSelectedItemChanged: onSelectedItemChanged,
                looping: looping,
                children: List<Widget>.generate(
                  range.last - range.first + 1,
                  (index) {
                    final value = range.first + index;

                    var weekday = DateTime(
                      selectedYear,
                      selectedMonth,
                      value,
                    ).weekday;

                    return _ItemWidget(
                      pickerTheme: pickerTheme,
                      value: value,
                      format: format,
                      locale: locale,
                      weekday: weekday,
                    );
                  },
                ),
              ),
            ),
          ),
          _DividerWidget(pickerTheme: pickerTheme, top: 63),
          _DividerWidget(pickerTheme: pickerTheme, top: 99),
        ],
      ),
    );
  }
}

class _DividerWidget extends StatelessWidget {
  final DateTimePickerTheme pickerTheme;
  final double top;
  const _DividerWidget({Key? key, required this.pickerTheme, required this.top})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = pickerTheme.dividerColor ?? pickerTheme.itemTextStyle.color;
    return Positioned(
      child: Container(
        margin: EdgeInsets.only(top: top),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
            Expanded(
              child: Divider(
                color: color,
                height: 1,
                thickness: pickerTheme.dividerThickness,
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
          ],
        ),
      ),
    );
  }
}

class _ItemWidget extends StatelessWidget {
  final DateTimePickerTheme pickerTheme;
  final int value;
  final String format;
  final DateTimePickerLocale locale;
  final int weekday;

  const _ItemWidget({
    Key? key,
    required this.pickerTheme,
    required this.value,
    required this.format,
    required this.locale,
    required this.weekday,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: pickerTheme.itemHeight,
      alignment: Alignment.center,
      child: AutoSizeText(
        DateTimeFormatter.formatDateTime(
          value: value,
          format: format,
          locale: locale,
          weekday: weekday,
        ),
        maxLines: 1,
        style: pickerTheme.itemTextStyle,
      ),
    );
  }
}
