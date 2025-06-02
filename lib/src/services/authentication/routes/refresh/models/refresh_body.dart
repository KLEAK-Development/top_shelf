import 'package:top_shelf/src/internal/body.dart';
import 'package:top_shelf/src/services/authentication/routes/refresh/models/refresh.dart';

class RefreshBody extends Body<Refresh> {
  RefreshBody(super.data);

  @override
  Refresh parse() => Refresh.fromJson(data);
}
