class ChangePassword {
  final String currentPassword;
  final String newPassword;

  const ChangePassword(this.currentPassword, this.newPassword);

  factory ChangePassword.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'currentPassword': final String currentPassword,
          'newPassword': final String newPassword
        }) {
      return ChangePassword(currentPassword, newPassword);
    } else {
      throw FormatException('Unexpected JSON');
    }
  }
}
