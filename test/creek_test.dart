import '../lib/creek.dart';
import 'dart:async';
import 'dart:io';
import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';

void main() {
  useVMConfiguration();

  Creek creek = new Creek();

  creek
    ..delete('/foo', (req, res) => res.send('Deleting success'))
    ..get('/foo', (req, res) => res.send('Getting success'))
    ..post('/foo', (req, res) => res.send('Posting success'))
    ..put('/foo', (req, res) => res.send('Putting success'));

  creek
    ..delete('/*', (req, res) => res.send('Generic delete'))
    ..get('/*', (req, res) => res.send('Generic get'))
    ..post('/*', (req, res) => res.send('Generic post'))
    ..put('/*', (req, res) => res.send('Generic put'));

  creek
    ..delete('/bar/:key', (req, res) { res.header('key', req.header('key'));  res.send('Key: ${req.header('key')}'); })
    ..get('/bar/:key', (req, res) { res.header('key', req.header('key')); res.send('Key: ${req.header('key')}'); })
    ..post('/bar/:key', (req, res) { res.header('key', req.header('key')); res.send('Key: ${req.header('key')}'); })
    ..put('/bar/:key', (req, res) { res.header('key', req.header('key')); res.send('Key: ${req.header('key')}'); });

  creek
    ..get('/filtered').where((req) {
      if (req.params['name'] == 'Creek') {
        return true;
      } else {
        req.response.status = HttpStatus.FORBIDDEN;
        req.response.close();
        return false;
      }
    }).listen((req) => req.response.send('Passed filter'));

  creek.notFoundHandler = (req, res) {
    res.status = HttpStatus.NOT_FOUND;
    res.send('Howdy, stranger!');
  };

  creek.bind('127.0.0.1', 7070).then(doTests,
      onError: doTests);

}

void doTests (HttpServerSubscription serverSubscription) {
  test('Creek binding', () {
    expect(serverSubscription.server, new isInstanceOf<HttpServer>());
  });

  HttpClient client = new HttpClient();

  group('Routing system', () {
    test('simple delete route', () {
      client.open('DELETE', 'localhost', 7070, '/foo').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Deleting success')));
        }));
      }));
    });

    test('simple get route', () {
      client.open('GET', 'localhost', 7070, '/foo').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Getting success')));
        }));
      }));
    });


    test('simple post route', () {
      client.open('POST', 'localhost', 7070, '/foo').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Posting success')));
        }));
      }));
    });

    test('simple put route', () {
      client.open('PUT', 'localhost', 7070, '/foo').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Putting success')));
        }));
      }));
    });

    test('generic delete route', () {
      client.open('DELETE', 'localhost', 7070, '/bar').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Generic delete')));
        }));
      }));
    });

    test('generic get route', () {
      client.open('GET', 'localhost', 7070, '/bar').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Generic get')));
        }));
      }));
    });

    test('generic post route', () {
      client.open('POST', 'localhost', 7070, '/bar').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Generic post')));
        }));
      }));
    });

    test('generic put route', () {
      client.open('PUT', 'localhost', 7070, '/bar').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Generic put')));
        }));
      }));
    });

    test('key delete route', () {
      client.open('DELETE', 'localhost', 7070, '/bar/test').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          expect(res.headers['key'].contains('test'), isTrue);
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Key: test')));
        }));
      }));
    });

    test('key get route', () {
      client.open('GET', 'localhost', 7070, '/bar/test').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          expect(res.headers['key'].contains('test'), isTrue);
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Key: test')));
        }));
      }));
    });

    test('key post route', () {
      client.open('POST', 'localhost', 7070, '/bar/test').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          expect(res.headers['key'].contains('test'), isTrue);
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Key: test')));
        }));
      }));
    });

    test('key put route', () {
      client.open('PUT', 'localhost', 7070, '/bar/test').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          expect(res.headers['key'].contains('test'), isTrue);
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Key: test')));
        }));
      }));
    });

    test('refused filtered get route', () {
      client.open('GET', 'localhost', 7070, '/filtered').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.FORBIDDEN));
        }));
      }));
    });


    // TODO Filtering tests
    test('accepted filtered get route', () {
      client.open('GET', 'localhost', 7070, '/filtered?name=Creek').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Passed filter')));
        }));
      }));
    });

    test('not found delete route', () {
      client.open('DELETE', 'localhost', 7070, '/something/weird').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.NOT_FOUND));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Howdy, stranger!')));
        }));
      }));
    });

    test('not found get route', () {
      client.open('GET', 'localhost', 7070, '/something/weird').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.NOT_FOUND));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Howdy, stranger!')));
        }));
      }));
    });

    test('not found post route', () {
      client.open('POST', 'localhost', 7070, '/something/weird').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.NOT_FOUND));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Howdy, stranger!')));
        }));
      }));
    });

    test('not found put route', () {
      client.open('PUT', 'localhost', 7070, '/something/weird').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.NOT_FOUND));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Howdy, stranger!')));
        }));
      }));
    });

  });

}
