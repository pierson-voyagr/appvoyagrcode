import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/trip.dart';

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key});

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  String? _selectedCountry;
  String? _selectedCity;
  String? _dateType;
  String? _selectedMonth;
  int? _selectedYear;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _reasonForTrip;
  bool _requestNewLocation = false;
  String? _requestedLocation;

  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _locationRequestController = TextEditingController();

  List<String> _filteredCountries = [];
  List<String> _filteredCities = [];
  List<String> _filteredRequestedCities = [];

  bool _showCountryPills = false;
  bool _showCityPills = false;
  bool _showRequestedCityPills = false;

  final Map<String, List<String>> _countryCities = {
    'UK': ['London'],
    'Italy': ['Florence'],
    'Germany': ['Berlin'],
    'South Korea': ['Seoul'],
    'Japan': ['Tokyo'],
  };

  final Map<String, String> _countryFlags = {
    'UK': '🇬🇧',
    'Italy': '🇮🇹',
    'Germany': '🇩🇪',
    'South Korea': '🇰🇷',
    'Japan': '🇯🇵',
  };

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<String> _reasonOptions = [
    'Study Abroad',
    'Work',
    'Vacation',
  ];

  final List<String> _requestableCities = [
    'Rio De Janeiro',
    'NYC',
    'LA',
    'Paris',
    'Venice',
    'Barcelona',
    'Madrid',
    'Chicago',
    'Mexico City',
  ];

  @override
  void initState() {
    super.initState();
    _filteredCountries = _countryCities.keys.toList();
    _filteredRequestedCities = _requestableCities;
  }

  @override
  void dispose() {
    _countryController.dispose();
    _cityController.dispose();
    _locationRequestController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = _countryCities.keys.toList();
      } else {
        _filteredCountries = _countryCities.keys
            .where((country) => country.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _filterCities(String query) {
    setState(() {
      final cities = _countryCities[_selectedCountry] ?? [];
      if (query.isEmpty) {
        _filteredCities = cities;
      } else {
        _filteredCities = cities
            .where((city) => city.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _filterRequestedCities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRequestedCities = _requestableCities;
      } else {
        _filteredRequestedCities = _requestableCities
            .where((city) => city.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showMonthPicker(BuildContext context) {
    int selectedMonthIndex = _selectedMonth != null
        ? _months.indexOf(_selectedMonth!)
        : 0;

    final currentYear = DateTime.now().year;
    final years = List.generate(10, (index) => currentYear + index);
    int selectedYearIndex = _selectedYear != null
        ? years.indexOf(_selectedYear!)
        : 0;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 50,
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = _months[selectedMonthIndex];
                          _selectedYear = years[selectedYearIndex];
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 32.0,
                        scrollController: FixedExtentScrollController(initialItem: selectedMonthIndex),
                        onSelectedItemChanged: (int index) {
                          selectedMonthIndex = index;
                        },
                        children: _months.map((month) => Center(child: Text(month))).toList(),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 32.0,
                        scrollController: FixedExtentScrollController(initialItem: selectedYearIndex),
                        onSelectedItemChanged: (int index) {
                          selectedYearIndex = index;
                        },
                        children: years.map((year) => Center(child: Text(year.toString()))).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStartDatePicker(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime tempDate = _startDate != null
        ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day)
        : today;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 50,
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      child: const Text('Next'),
                      onPressed: () {
                        setState(() {
                          _startDate = tempDate;
                        });
                        Navigator.of(context).pop();
                        // Open end date picker after start date is selected
                        _showEndDatePicker(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempDate,
                  minimumDate: today,
                  maximumDate: today.add(const Duration(days: 365)),
                  onDateTimeChanged: (DateTime newDate) {
                    tempDate = DateTime(newDate.year, newDate.month, newDate.day);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEndDatePicker(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final minDate = _startDate != null
        ? _startDate!.add(const Duration(days: 1))
        : today.add(const Duration(days: 1));

    DateTime tempDate = _endDate != null && _endDate!.isAfter(minDate)
        ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day)
        : minDate;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 50,
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Back'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Go back to start date picker
                        _showStartDatePicker(context);
                      },
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        setState(() {
                          _endDate = tempDate;
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempDate,
                  minimumDate: minDate,
                  maximumDate: today.add(const Duration(days: 365)),
                  onDateTimeChanged: (DateTime newDate) {
                    tempDate = DateTime(newDate.year, newDate.month, newDate.day);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF1C1C1E),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF1C1C1E),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Country Section
                  const Text(
                    'Country',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          border: Border.all(
                            color: const Color(0xFF2E55C6),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _countryController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search for a country',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                            filled: true,
                            fillColor: const Color(0xFF2C2C2E),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          onChanged: _filterCountries,
                          onTap: () {
                            setState(() {
                              _showCountryPills = true;
                            });
                          },
                        ),
                      ),
                      if (_showCountryPills) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _filteredCountries.map((country) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCountry = country;
                                  _countryController.text = country;
                                  _selectedCity = null;
                                  _cityController.clear();
                                  _filteredCities = _countryCities[country] ?? [];
                                  _showCountryPills = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedCountry == country
                                      ? const Color(0xFF2E55C6)
                                      : const Color(0xFFC3DAF4),
                                  border: Border.all(
                                    color: const Color(0xFF2E55C6),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${_countryFlags[country] ?? ''} ',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      country,
                                      style: TextStyle(
                                        color: _selectedCountry == country
                                            ? Colors.white
                                            : const Color(0xFF2E55C6),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),

                  // City Section (appears after country selection)
                  if (_selectedCountry != null) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'City',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2E),
                            border: Border.all(
                              color: const Color(0xFF2E55C6),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextField(
                            controller: _cityController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search for a city',
                              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                              filled: true,
                              fillColor: const Color(0xFF2C2C2E),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            onChanged: _filterCities,
                            onTap: () {
                              setState(() {
                                _showCityPills = true;
                              });
                            },
                          ),
                        ),
                        if (_showCityPills) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _filteredCities.map((city) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCity = city;
                                    _cityController.text = city;
                                    _showCityPills = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedCity == city
                                        ? const Color(0xFF2E55C6)
                                        : const Color(0xFFC3DAF4),
                                    border: Border.all(
                                      color: const Color(0xFF2E55C6),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Text(
                                    city,
                                    style: TextStyle(
                                      color: _selectedCity == city
                                          ? Colors.white
                                          : const Color(0xFF2E55C6),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ],

                  // Dates Section (appears after city selection)
                  if (_selectedCity != null) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'Dates',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Unknown option
                    _buildDateOption(
                      'Unknown',
                      'unknown',
                      null,
                    ),
                    const SizedBox(height: 12),

                    // Month option
                    _buildDateOption(
                      'Month',
                      'month',
                      null,
                    ),
                    const SizedBox(height: 12),

                    // Specific dates option
                    _buildDateOption(
                      'Specific Dates',
                      'specific',
                      null,
                    ),
                  ],

                  // Reason for Trip Section (appears after dates selection)
                  if (_dateType != null) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'Reason for Trip',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _reasonOptions.map((reason) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _reasonForTrip = reason;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _reasonForTrip == reason
                                  ? const Color(0xFF2E55C6)
                                  : const Color(0xFFC3DAF4),
                              border: Border.all(
                                color: const Color(0xFF2E55C6),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              reason,
                              style: TextStyle(
                                color: _reasonForTrip == reason
                                    ? Colors.white
                                    : const Color(0xFF2E55C6),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Request Location Section (appears after reason for trip)
                  if (_reasonForTrip != null) ...[
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _requestNewLocation = !_requestNewLocation;
                          if (!_requestNewLocation) {
                            _requestedLocation = null;
                            _locationRequestController.clear();
                          }
                        });
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _requestNewLocation
                                  ? const Color(0xFF2E55C6)
                                  : Colors.transparent,
                              border: Border.all(
                                color: const Color(0xFF2E55C6),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: _requestNewLocation
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Have a location you want us to add?',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_requestNewLocation) ...[
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              border: Border.all(
                                color: const Color(0xFF2E55C6),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: TextField(
                              controller: _locationRequestController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Search for a city to request',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                                filled: true,
                                fillColor: const Color(0xFF2C2C2E),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              onChanged: _filterRequestedCities,
                              onTap: () {
                                setState(() {
                                  _showRequestedCityPills = true;
                                });
                              },
                            ),
                          ),
                          if (_showRequestedCityPills) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _filteredRequestedCities.map((city) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _requestedLocation = city;
                                      _locationRequestController.text = city;
                                      _showRequestedCityPills = false;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _requestedLocation == city
                                          ? const Color(0xFF2E55C6)
                                          : const Color(0xFFC3DAF4),
                                      border: Border.all(
                                        color: const Color(0xFF2E55C6),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Text(
                                      city,
                                      style: TextStyle(
                                        color: _requestedLocation == city
                                            ? Colors.white
                                            : const Color(0xFF2E55C6),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Create Trip button at bottom
          Container(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit() ? _handleSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSubmit()
                      ? const Color(0xFF2E55C6)
                      : const Color(0xFFC3DAF4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  disabledBackgroundColor: const Color(0xFFC3DAF4),
                  disabledForegroundColor: Colors.white,
                ),
                child: const Text(
                  'Create Trip',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateOption(String label, String type, Widget? expandedContent) {
    final isSelected = _dateType == type;

    String displayText = label;
    if (isSelected) {
      if (type == 'month' && _selectedMonth != null && _selectedYear != null) {
        displayText = '$_selectedMonth $_selectedYear';
      } else if (type == 'specific' && _startDate != null && _endDate != null) {
        displayText = '${_startDate!.month}/${_startDate!.day}/${_startDate!.year} - ${_endDate!.month}/${_endDate!.day}/${_endDate!.year}';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2C2C2E) : const Color(0xFF2C2C2E),
        border: Border.all(
          color: isSelected ? const Color(0xFF2E55C6) : const Color(0xFF48484A),
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _dateType = type;
            if (type != 'month') {
              _selectedMonth = null;
              _selectedYear = null;
            }
            if (type != 'specific') {
              _startDate = null;
              _endDate = null;
            }
          });

          // Automatically open picker when selecting month or specific dates
          if (type == 'month') {
            _showMonthPicker(context);
          } else if (type == 'specific') {
            _showStartDatePicker(context);
          }
        },
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Color(0xFF2E55C6)),
            ],
          ),
        ),
      ),
    );
  }

  bool _canSubmit() {
    if (_selectedCountry == null || _selectedCity == null || _dateType == null) {
      return false;
    }

    if (_dateType == 'unknown') return true;
    if (_dateType == 'month') return _selectedMonth != null && _selectedYear != null;
    if (_dateType == 'specific') return _startDate != null && _endDate != null;

    return false;
  }

  void _handleSubmit() {
    // Create a Trip object with the selected data
    final trip = Trip(
      country: _selectedCountry!,
      city: _selectedCity!,
      dateType: _dateType!,
      month: _selectedMonth,
      year: _selectedYear,
      startDate: _startDate,
      endDate: _endDate,
      reasonForTrip: _reasonForTrip,
      requestedLocation: _requestNewLocation ? _requestedLocation : null,
    );

    // Return the trip to the previous screen
    Navigator.pop(context, trip);
  }
}
