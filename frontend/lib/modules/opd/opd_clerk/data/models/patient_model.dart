class EmergencyContactModel {
  final String? name;
  final String? relationship;
  final String? contactNumber;
  final String? purok;
  final String? barangay;
  final String? cityMunicipal;
  final String? province;
  final String? provinceCode;
  final String? cityCode;
  final String? barangayCode;

  EmergencyContactModel({
    this.name,
    this.relationship,
    this.contactNumber,
    this.purok,
    this.barangay,
    this.cityMunicipal,
    this.province,
    this.provinceCode,
    this.cityCode,
    this.barangayCode,
  });

  String get fullAddress {
    final parts = <String>[];
    if (purok != null && purok!.isNotEmpty) parts.add(purok!.toUpperCase());
    if (barangay != null && barangay!.isNotEmpty) parts.add(barangay!.toUpperCase());
    if (cityMunicipal != null && cityMunicipal!.isNotEmpty) parts.add(cityMunicipal!.toUpperCase());
    if (province != null && province!.isNotEmpty) parts.add(province!.toUpperCase());
    return parts.isNotEmpty ? parts.join(', ') : 'Not provided';
  }

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) => EmergencyContactModel(
    name: json['name'],
    relationship: json['relationship'],
    contactNumber: json['contact_number'],
    purok: json['purok'],
    barangay: json['barangay'],
    cityMunicipal: json['city_municipal'],
    province: json['province'],
    provinceCode: json['province_code'],
    cityCode: json['city_code'],
    barangayCode: json['barangay_code'],
  );
}

class PatientModel {
  final String hospitalId;
  final String patientId;
  final String lastName;
  final String firstName;
  final String? middleName;
  final String? extension;
  final int age;
  final String sex;
  final String birthDate;
  final String lastVisit;
  final String department;
  final String status;
  final bool isActive;
  final String? _photoUrl;
  final String? contactNumber;
  final String? address;
  final String? purok;
  final String? barangay;
  final String? cityMunicipal;
  final String? province;
  final String? provinceCode;
  final String? cityCode;
  final String? barangayCode;
  final String? civilStatus;
  final String? religion;
  final EmergencyContactModel? emergencyContact;

  // Getter that constructs full URL if photoUrl is relative
  String? get photoUrl {
    if (_photoUrl == null || _photoUrl!.isEmpty) return null;
    
    final url = _photoUrl!.trim();
    
    // If it's already a full URL, return as-is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    // If it's a relative path, construct the full URL
    const baseUrl = 'http://10.0.2.2:8000'; // For Android emulator
    
    // Handle various path formats
    if (url.startsWith('/media/')) {
      // Already has /media/ prefix
      return '$baseUrl$url';
    } else if (url.startsWith('/')) {
      // Has leading slash but no /media/
      return '$baseUrl/media$url';
    } else {
      // No leading slash
      return '$baseUrl/media/$url';
    }
  }

  PatientModel({
    required this.hospitalId,
    required this.patientId,
    required this.lastName,
    required this.firstName,
    this.middleName,
    this.extension,
    required this.age,
    required this.sex,
    required this.birthDate,
    required this.lastVisit,
    required this.department,
    required this.status,
    this.isActive = true,
    String? photoUrl,
    this.contactNumber,
    this.address,
    this.purok,
    this.barangay,
    this.cityMunicipal,
    this.province,
    this.provinceCode,
    this.cityCode,
    this.barangayCode,
    this.civilStatus,
    this.religion,
    this.emergencyContact,
  }) : _photoUrl = photoUrl;

  String get fullName {
    final middle = middleName != null && middleName!.isNotEmpty ? ' $middleName' : '';
    final ext = extension != null && extension!.isNotEmpty ? ' $extension' : '';
    return '$lastName, $firstName$middle$ext';
  }

  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0] : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0] : '';
    return '$firstInitial$lastInitial'.toUpperCase();
  }

  String get ageSexDisplay => '$age yrs\n$sex';

  Map<String, dynamic> toJson() => {
    'hospital_id': hospitalId,
    'patient_id': patientId,
    'lastname': lastName,
    'firstname': firstName,
    'middlename': middleName,
    'extension': extension,
    'age': age,
    'sex': sex,
    'birthdate': birthDate,
    'last_visit': lastVisit,
    'department': department,
    'status': status,
    'is_active': isActive,
    'photo_url': photoUrl,
    'contact_number': contactNumber,
    'address': address,
    'purok': purok,
    'barangay': barangay,
    'city_municipal': cityMunicipal,
    'province': province,
    'civil_status': civilStatus,
    'religion': religion,
    'emergency_contact': emergencyContact,
  };

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    final photoUrlRaw = json['photo_url'];
    return PatientModel(
      hospitalId: json['hospital_id'] ?? '',
      patientId: json['patient_id'] ?? '',
      lastName: json['lastname'] ?? '',
      firstName: json['firstname'] ?? '',
      middleName: json['middlename'],
      extension: json['extension'],
      age: json['age'] is int ? json['age'] : int.tryParse(json['age'].toString()) ?? 0,
      sex: json['sex'] ?? '',
      birthDate: json['birthdate'] ?? '',
      lastVisit: json['last_visit'] ?? '',
      department: json['department'] ?? '',
      status: json['status'] ?? '',
      isActive: json['is_active'] ?? true,
      photoUrl: photoUrlRaw,
      contactNumber: json['contact_number'],
      address: json['address'],
      purok: json['purok'],
      barangay: json['barangay'],
      cityMunicipal: json['city_municipal'],
      province: json['province'],
      provinceCode: json['province_code'],
      cityCode: json['city_code'],
      barangayCode: json['barangay_code'],
      civilStatus: json['civil_status'],
      religion: json['religion'],
      emergencyContact: json['emergency_contact'] != null
          ? EmergencyContactModel.fromJson(json['emergency_contact'])
          : null,
    );
  }
}
