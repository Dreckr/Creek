import '../lib/route.dart';
import 'package:unittest/unittest.dart';
import 'dart:async';
import 'dart:io';

void main() {
  RouteServer server;
  server = new RouteServer('127.0.0.1', 7070, 1);

  group('RouteServer instantiation', () {

    test('address is correct', () => expect(server.address, equals('127.0.0.1')));

    test('port is correct', () => expect(server.port, equals(7070)));

    test('backlog is correct', () => expect(server.backlog, equals(1)));

  });

  HttpClient client;
  client = new HttpClient();

  server
    ..delete('/foo', (req, res) => res.send('Deleting success!'))
    ..get('/foo', (req, res) => res.send('Getting success!'))
    ..post('/foo', (req, res) => res.send('Posting success!'))
    ..put('/foo', (req, res) => res.send('Putting success!'));

  server
    ..delete('/*', (req, res) => res.send('Generic delete!'))
    ..get('/*', (req, res) => res.send('Generic get!'))
    ..post('/*', (req, res) => res.send('Generic post!'))
    ..put('/*', (req, res) => res.send('Generic put!'));

  server
    ..delete('/bar/:key', (req, res) { res.header('key', req.header('key'));  res.send('Key: ${req.header('key')}!'); })
    ..get('/bar/:key', (req, res) { res.header('key', req.header('key')); res.send('Key: ${req.header('key')}!'); })
    ..post('/bar/:key', (req, res) { res.header('key', req.header('key')); res.send('Key: ${req.header('key')}!'); })
    ..put('/bar/:key', (req, res) { res.header('key', req.header('key')); res.send('Key: ${req.header('key')}!'); });

  server.run().then((_) {
    group('Routing system', () {
      test('simple delete route', () {
        client.open('DELETE', 'localhost', 7070, '/foo').then(expectAsync1((req) {
          req.close().then(expectAsync1((res) {
            expect(res.statusCode, equals(200));
            res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Deleting success!')));
          }));
        }));
      });

      test('simple get route', () {
        client.open('GET', 'localhost', 7070, '/foo').then(expectAsync1((req) {
          req.close().then(expectAsync1((res) {
            expect(res.statusCode, equals(200));
            res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Getting success!')));
          }));
        }));
      });


      test('simple post route', () {
        client.open('POST', 'localhost', 7070, '/foo').then(expectAsync1((req) {
          req.close().then(expectAsync1((res) {
            expect(res.statusCode, equals(200));
            res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Posting success!')));
          }));
        }));
      });

      test('simple put route', () {
        client.open('PUT', 'localhost', 7070, '/foo').then(expectAsync1((req) {
          req.close().then(expectAsync1((res) {
            expect(res.statusCode, equals(200));
            res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Putting success!')));
          }));
        }));
      });

      test('generic delete route', () {
        client.open('DELETE', 'localhost', 7070, '/bar').then(expectAsync1((req) {
          req.close().then(expectAsync1((res) {
            expect(res.statusCode, equals(200));
            res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Generic delete!')));
          }));
        }));
      });

      test('generic get route', () {
        client.open('GET', 'localhost', 7070, '/bar').then(expectAsync1((req) {
          req.close().then(expectAsync1((res) {
            expect(res.statusCode, equals(200));
            res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Generic get!')));
          }));
        }));
      });

      test('generic post route', () {
        client.open('POST', 'localhost', 7070, '/bar').then(expectAsync1((req) {
          req.close().then(expectAsync1((res) {
            expect(res.statusCode, equals(200));
            res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Generic post!')));
          }));
        }));
      });

      test('generic put route', () {
        client.open('PUT', 'localhost', 7070, '/bar').then(expectAsync1((req) {
          req.close().then(expectAsync1((res) {
            expect(res.statusCode, equals(200));
            res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Generic put!')));
          }));
        }));
      });

      test('key delete route', () {
        client.open('DELETE', 'localhost', 7070, '/bar/test').then(expectAsync1((req) {
          req.close().then(expectAsync1((res) {
            expect(res.statusCode, equals(200));
            expect(res.headers['key'].contains('test'), isTrue);
            res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Key: test!')));
          }));
        }));
      });

      test('key get route', () {
        client.open('GET', 'localhost', 7070, '/bar/test').then(expectAsync1((req) {
          req.close().then(expectAsync1((res) {
            expect(res.statusCode, equals(200));
            expect(res.headers['key'].contains('test'), isTrue);
            res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Key: test!')));
          }));
        }));
      });

      test('key post route', () {
        client.open('POST', 'localhost', 7070, '/bar/test').then(expectAsync1((req) {
          req.close().then(expectAsync1((res) {
            expect(res.statusCode, equals(200));
            expect(res.headers['key'].contains('test'), isTrue);
            res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Key: test!')));
          }));
        }));
      });

      test('key put route', () {
        client.open('PUT', 'localhost', 7070, '/bar/test').then(expectAsync1((req) {
          req.close().then(expectAsync1((res) {
            expect(res.statusCode, equals(200));
            expect(res.headers['key'].contains('test'), isTrue);
            res.listen((chars) => expect(new String.fromCharCodes(chars), equals('Key: test!')));
          }));
        }));
      });

      // TODO Filtering tests

      // TODO Default route

    });
  });
}
