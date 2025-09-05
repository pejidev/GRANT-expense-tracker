class AppUser {
  final int id;
  final String authId;
  final String name;
  final String email;
  final bool onboardingComplete;

  AppUser({
    required this.id,
    required this.authId,
    required this.name,
    required this.email,
    this.onboardingComplete = false,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      authId: map['auth_id'],
      name: map['name'],
      email: map['email'],
      onboardingComplete: map['onboarding_complete'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'auth_id': authId,
      'name': name,
      'email': email,
      'onboarding_complete': onboardingComplete,
    };
  }
}
