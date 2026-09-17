class User {
  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final String role;
  final String createdAt;
  final String updatedAt;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.role = 'student',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory User.fromRow(Map<String, dynamic> row) => User(
        id: row['id'] as int,
        name: row['name'] as String,
        email: row['email'] as String,
        passwordHash: row['password_hash'] as String,
        role: row['role'] as String,
        createdAt: row['created_at'] as String,
        updatedAt: row['updated_at'] as String,
      );
}
