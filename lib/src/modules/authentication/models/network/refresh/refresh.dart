class Refresh {
  final String refreshToken;

  const Refresh(this.refreshToken);

  factory Refresh.fromJson(Map<String, dynamic> json) {
    if (json case {'refresh_token': final String refreshToken}) {
      return Refresh(
        refreshToken,
      );
    } else {
      throw FormatException('Unexpected JSON');
    }
  }
}
