class Trip {
  final String country;
  final String city;
  final String dateType; // 'unknown', 'month', 'specific'
  final String? month;
  final int? year;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? reasonForTrip; // 'Study Abroad', 'Work', 'Vacation'
  final String? requestedLocation;

  Trip({
    required this.country,
    required this.city,
    required this.dateType,
    this.month,
    this.year,
    this.startDate,
    this.endDate,
    this.reasonForTrip,
    this.requestedLocation,
  });

  String getDateDisplay() {
    if (dateType == 'unknown') {
      return 'Anytime';
    } else if (dateType == 'month') {
      return '$month $year';
    } else if (dateType == 'specific') {
      return '${startDate!.month}/${startDate!.day}/${startDate!.year} - ${endDate!.month}/${endDate!.day}/${endDate!.year}';
    }
    return '';
  }

  String getCityImage() {
    // Map city names to their image assets
    switch (city.toLowerCase()) {
      case 'london':
        return 'lib/assets/London1.jpg';
      case 'florence':
        return 'lib/assets/Florence1.jpg';
      case 'berlin':
        return 'lib/assets/Berlin1.jpg';
      case 'seoul':
        return 'lib/assets/seoul1.jpg';
      case 'tokyo':
        return 'lib/assets/Japan1.jpg';
      default:
        return 'lib/assets/London1.jpg'; // Default fallback
    }
  }

  String getCountryFlag() {
    // Map country names to their flag emojis
    switch (country.toLowerCase()) {
      case 'uk':
      case 'united kingdom':
      case 'england':
        return '🇬🇧';
      case 'italy':
        return '🇮🇹';
      case 'germany':
        return '🇩🇪';
      case 'south korea':
      case 'korea':
        return '🇰🇷';
      case 'japan':
        return '🇯🇵';
      case 'usa':
      case 'united states':
      case 'america':
        return '🇺🇸';
      case 'france':
        return '🇫🇷';
      case 'spain':
        return '🇪🇸';
      case 'portugal':
        return '🇵🇹';
      case 'greece':
        return '🇬🇷';
      case 'netherlands':
        return '🇳🇱';
      case 'belgium':
        return '🇧🇪';
      case 'switzerland':
        return '🇨🇭';
      case 'austria':
        return '🇦🇹';
      case 'poland':
        return '🇵🇱';
      case 'czech republic':
      case 'czechia':
        return '🇨🇿';
      case 'hungary':
        return '🇭🇺';
      case 'sweden':
        return '🇸🇪';
      case 'norway':
        return '🇳🇴';
      case 'denmark':
        return '🇩🇰';
      case 'finland':
        return '🇫🇮';
      case 'ireland':
        return '🇮🇪';
      case 'iceland':
        return '🇮🇸';
      case 'croatia':
        return '🇭🇷';
      case 'turkey':
        return '🇹🇷';
      case 'canada':
        return '🇨🇦';
      case 'mexico':
        return '🇲🇽';
      case 'brazil':
        return '🇧🇷';
      case 'argentina':
        return '🇦🇷';
      case 'australia':
        return '🇦🇺';
      case 'new zealand':
        return '🇳🇿';
      case 'china':
        return '🇨🇳';
      case 'thailand':
        return '🇹🇭';
      case 'vietnam':
        return '🇻🇳';
      case 'singapore':
        return '🇸🇬';
      case 'malaysia':
        return '🇲🇾';
      case 'indonesia':
        return '🇮🇩';
      case 'philippines':
        return '🇵🇭';
      case 'india':
        return '🇮🇳';
      case 'uae':
      case 'united arab emirates':
        return '🇦🇪';
      case 'egypt':
        return '🇪🇬';
      case 'morocco':
        return '🇲🇦';
      case 'south africa':
        return '🇿🇦';
      default:
        return '🌍'; // Globe emoji as fallback
    }
  }

  String getCountryAbbreviation() {
    // Map country names to their abbreviations
    switch (country.toLowerCase()) {
      case 'uk':
      case 'united kingdom':
      case 'england':
        return 'UK';
      case 'italy':
        return 'IT';
      case 'germany':
        return 'DE';
      case 'south korea':
      case 'korea':
        return 'KR';
      case 'japan':
        return 'JP';
      case 'usa':
      case 'united states':
      case 'america':
        return 'US';
      case 'france':
        return 'FR';
      case 'spain':
        return 'ES';
      case 'portugal':
        return 'PT';
      case 'greece':
        return 'GR';
      case 'netherlands':
        return 'NL';
      case 'belgium':
        return 'BE';
      case 'switzerland':
        return 'CH';
      case 'austria':
        return 'AT';
      case 'poland':
        return 'PL';
      case 'czech republic':
      case 'czechia':
        return 'CZ';
      case 'hungary':
        return 'HU';
      case 'sweden':
        return 'SE';
      case 'norway':
        return 'NO';
      case 'denmark':
        return 'DK';
      case 'finland':
        return 'FI';
      case 'ireland':
        return 'IE';
      case 'iceland':
        return 'IS';
      case 'croatia':
        return 'HR';
      case 'turkey':
        return 'TR';
      case 'canada':
        return 'CA';
      case 'mexico':
        return 'MX';
      case 'brazil':
        return 'BR';
      case 'argentina':
        return 'AR';
      case 'australia':
        return 'AU';
      case 'new zealand':
        return 'NZ';
      case 'china':
        return 'CN';
      case 'thailand':
        return 'TH';
      case 'vietnam':
        return 'VN';
      case 'singapore':
        return 'SG';
      case 'malaysia':
        return 'MY';
      case 'indonesia':
        return 'ID';
      case 'philippines':
        return 'PH';
      case 'india':
        return 'IN';
      case 'uae':
      case 'united arab emirates':
        return 'AE';
      case 'egypt':
        return 'EG';
      case 'morocco':
        return 'MA';
      case 'south africa':
        return 'ZA';
      default:
        // Return first 2 letters uppercase as fallback
        return country.length >= 2 ? country.substring(0, 2).toUpperCase() : country.toUpperCase();
    }
  }
}
