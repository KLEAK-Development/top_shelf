import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/modules/models/network/create_account/create_account.dart';
import 'package:top_shelf/src/modules/routes/accounts/create_account/create_account.dart'
    as create_account;
import 'package:top_shelf/top_shelf.dart';

Future<Response> handler(Request request) async {
  final object = await create_account.handler(
    request,
    request.get<CreateAccount>(),
  );
  return generateResponse(request, object, status: HttpStatus.created);
}
