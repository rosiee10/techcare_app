class Region {
  final String code;
  final String name;

  Region({required this.code, required this.name});

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
    };
  }
}

class Province {
  final String code;
  final String name;
  final String regionCode;

  Province({required this.code, required this.name, required this.regionCode});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      regionCode: json['region_code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'region_code': regionCode,
    };
  }
}

class City {
  final String code;
  final String name;
  final String provinceCode;
  final bool isCity;

  City({
    required this.code,
    required this.name,
    required this.provinceCode,
    this.isCity = true,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      provinceCode: json['province_code'] ?? '',
      isCity: json['is_city'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'province_code': provinceCode,
      'is_city': isCity,
    };
  }
}

class Barangay {
  final String code;
  final String name;
  final String cityCode;

  Barangay({required this.code, required this.name, required this.cityCode});

  factory Barangay.fromJson(Map<String, dynamic> json) {
    return Barangay(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      cityCode: json['city_code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'city_code': cityCode,
    };
  }
}
