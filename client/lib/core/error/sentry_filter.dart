import 'package:sentry_flutter/sentry_flutter.dart';

SentryEvent? stripPii(SentryEvent event, Hint hint) {
  final user = event.user;
  if (user != null) {
    event.user = SentryUser(
      id: user.id,
      email: null,
      username: null,
      ipAddress: null,
      data: user.data,
    );
  }

  final request = event.request;
  if (request != null) {
    final headers = <String, String>{...request.headers};
    headers.remove('authorization');
    headers.remove('cookie');
    event.request = SentryRequest(
      url: request.url,
      method: request.method,
      headers: headers,
      data: request.data,
      queryString: request.queryString,
      cookies: request.cookies,
    );
  }

  event.contexts.remove('profile');

  return event;
}
