import '../lib/creek.dart';
import 'dart:async';
import 'dart:io';
import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';

String address = '127.0.0.1';
int port = 7070;

void send (HttpResponse response, String message) {
  response.write(message);
  response.close();
}

void main() {
  useVMConfiguration();

  Creek creek = new Creek();

  creek
    ..delete('/foo', (req, res) => send(res, 'Deleting success'))
    ..get('/foo', (req, res) => send(res, 'Getting success'))
    ..post('/foo', (req, res) => send(res, 'Posting success'))
    ..put('/foo', (req, res) => send(res, 'Putting success'));

  creek
    ..delete('/*', (req, res) => send(res, 'Generic delete'))
    ..get('/*', (req, res) => send(res, 'Generic get'))
    ..post('/*', (req, res) => send(res, 'Generic post'))
    ..put('/*', (req, res) => send(res, 'Generic put'));

  creek
    ..delete('/bar/:key', (req, res) { res.headers.set('key', req.queryParameters['key']);  send(res, 'Key: ${req.queryParameters['key']}'); })
    ..get('/bar/:key', (req, res) { res.headers.set('key', req.queryParameters['key']); send(res, 'Key: ${req.queryParameters['key']}'); })
    ..post('/bar/:key', (req, res) { res.headers.set('key', req.queryParameters['key']); send(res, 'Key: ${req.queryParameters['key']}'); })
    ..put('/bar/:key', (req, res) { res.headers.set('key', req.queryParameters['key']); send(res, 'Key: ${req.queryParameters['key']}'); });

  creek
    ..get('/filtered').where((req) {
      if (req.queryParameters['name'] == 'Creek') {
        return true;
      } else {
        req.response.statusCode = HttpStatus.FORBIDDEN;
        req.response.close();
        return false;
      }
    }).listen((req) => send(req.response, 'Passed filter'));

  creek.notFoundHandler = (req, res) {
    res.statusCode = HttpStatus.NOT_FOUND;
    send(res, 'Howdy, stranger!');
  };

  creek.bind(address, port).then(doTests,
      onError: doTests);
}

void doTests (HttpServerSubscription serverSubscription) {
  test('Creek binding', () {
    expect(serverSubscription.server, new isInstanceOf<HttpServer>());
  });

  HttpClient client = new HttpClient();

  group('Routing system', () {
    test('simple delete route', () {
      client.open('DELETE', address, port, '/foo').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Deleting success')));
        }));
      }));
    });

    test('simple get route', () {
      client.open('GET', address, port, '/foo').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Getting success')));
        }));
      }));
    });


    test('simple post route', () {
      client.open('POST', address, port, '/foo').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Posting success')));
        }));
      }));
    });

    test('simple put route', () {
      client.open('PUT', address, port, '/foo').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Putting success')));
        }));
      }));
    });

    test('generic delete route', () {
      client.open('DELETE', address, port, '/bar').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Generic delete')));
        }));
      }));
    });

    test('generic get route', () {
      client.open('GET', address, port, '/bar').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Generic get')));
        }));
      }));
    });

    test('generic post route', () {
      client.open('POST', address, port, '/bar').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Generic post')));
        }));
      }));
    });

    test('generic put route', () {
      client.open('PUT', address, port, '/bar').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Generic put')));
        }));
      }));
    });

    test('key delete route', () {
      client.open('DELETE', address, port, '/bar/test').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          expect(res.headers['key'].contains('test'), isTrue);
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Key: test')));
        }));
      }));
    });

    test('key get route', () {
      client.open('GET', address, port, '/bar/test').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          expect(res.headers['key'].contains('test'), isTrue);
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Key: test')));
        }));
      }));
    });

    test('key post route', () {
      client.open('POST', address, port, '/bar/test').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          expect(res.headers['key'].contains('test'), isTrue);
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Key: test')));
        }));
      }));
    });

    test('key put route', () {
      client.open('PUT', address, port, '/bar/test').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          expect(res.headers['key'].contains('test'), isTrue);
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Key: test')));
        }));
      }));
    });

    test('refused filtered get route', () {
      client.open('GET', address, port, '/filtered').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.FORBIDDEN));
        }));
      }));
    });


    // TODO Filtering tests
    test('accepted filtered get route', () {
      client.open('GET', address, port, '/filtered?name=Creek').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Passed filter')));
        }));
      }));
    });

    test('not found delete route', () {
      client.open('DELETE', address, port, '/something/weird').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.NOT_FOUND));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Howdy, stranger!')));
        }));
      }));
    });

    test('not found get route', () {
      client.open('GET', address, port, '/something/weird').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.NOT_FOUND));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Howdy, stranger!')));
        }));
      }));
    });

    test('not found post route', () {
      client.open('POST', address, port, '/something/weird').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.NOT_FOUND));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Howdy, stranger!')));
        }));
      }));
    });

    test('not found put route', () {
      client.open('PUT', address, port, '/something/weird').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.NOT_FOUND));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Howdy, stranger!')));
        }));
      }));
    });

  });

}
