import 'dart:async';
import 'dart:io';
import 'package:creek/creek.dart';
import 'package:creek/src/transformer.dart';
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
    ..delete('/foo').listen((request) => send(request.response, 'Deleting success'))
    ..get('/foo').listen((request) => send(request.response, 'Getting success'))
    ..post('/foo').listen((request) => send(request.response, 'Posting success'))
    ..put('/foo').listen((request) => send(request.response, 'Putting success'));

  creek
    ..delete('/bar/*').listen((request) => send(request.response, 'Generic delete'))
    ..get('/bar/*').listen((request) => send(request.response, 'Generic get'))
    ..post('/bar/*').listen((request) => send(request.response, 'Generic post'))
    ..put('/bar/*').listen((request) => send(request.response, 'Generic put'));

  creek
    ..get('/filtered').where((request) {
      if (request.uri.queryParameters['name'] == 'Creek') {
        return true;
      } else {
        request.response.statusCode = HttpStatus.FORBIDDEN;
        request.response.close();
        return false;
      }
    }).listen((request) => send(request.response, 'Passed filter'));

  creek.notFoundHandler = (request) {
    request.response.statusCode = HttpStatus.NOT_FOUND;
    send(request.response, 'Howdy, stranger!');
  };

  creek.bind(address: address, port: port).then(doTests,
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
      client.open('DELETE', address, port, '/bar/something').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Generic delete')));
        }));
      }));
    });

    test('generic get route', () {
      client.open('GET', address, port, '/bar/something').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Generic get')));
        }));
      }));
    });

    test('generic post route', () {
      client.open('POST', address, port, '/bar/something').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Generic post')));
        }));
      }));
    });

    test('generic put route', () {
      client.open('PUT', address, port, '/bar/something').then(expectAsync1((req) {
        req.close().then(expectAsync1((res) {
          expect(res.statusCode, equals(HttpStatus.OK));
          res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Generic put')));
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
