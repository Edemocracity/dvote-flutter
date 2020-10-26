import 'dart:convert';
import 'dart:typed_data';
import 'package:dvote/util/asyncify.dart';
import 'package:hex/hex.dart';
import 'package:web3dart/crypto.dart' as crypto;

const SIGNATURE_MESSAGE_PREFIX = '\u0019Ethereum Signed Message:\n';

class Signature {
  /// Sign the given payload using the private key and return a hex signature
  static String signString(String payload, String hexPrivateKey,
      {int chainId}) {
    return _signString(payload, hexPrivateKey, chainId);
  }

  /// Sign the given payload using the private key and return a hex signature
  static Future<String> signStringAsync(String payload, String hexPrivateKey,
      {int chainId}) {
    return runAsync<String, String Function(String, String, int)>(
        _signString, [payload, hexPrivateKey, chainId]);
  }

  /// Recover the public key that signed the given message into the given signature
  static String recoverSignerPubKey(String hexSignature, String strPayload,
      {int chainId}) {
    return _recoverSignerPubKey(hexSignature, strPayload, chainId);
  }

  /// Recover the public key that signed the given message into the given signature
  static Future<String> recoverSignerPubKeyAsync(
      String hexSignature, String strPayload,
      {int chainId}) {
    return runAsync<String, String Function(String, String, int)>(
        _recoverSignerPubKey, [hexSignature, strPayload, chainId]);
  }

  /// Check whether the given signature is valid and belongs to the given message and
  /// public key
  static bool isValidSignature(
      String hexSignature, String strPayload, String hexPublicKey,
      {int chainId}) {
    return _isValidSignature(hexSignature, strPayload, hexPublicKey, chainId);
  }

  /// Check whether the given signature is valid and belongs to the given message and
  /// public key
  static Future<bool> isValidSignatureAsync(
      String hexSignature, String strPayload, String hexPublicKey,
      {int chainId}) {
    return runAsync<bool, bool Function(String, String, String, int)>(
        _isValidSignature, [hexSignature, strPayload, hexPublicKey, chainId]);
  }

  // ////////////////////////////////////////////////////////////////////////////
  // / IMPLEMENTATION
  // ////////////////////////////////////////////////////////////////////////////

  /// Sign the given payload using the private key and return a hex signature
  static String _signString(String payload, String hexPrivateKey, int chainId) {
    if (payload == null)
      throw Exception("The payload is empty");
    else if (hexPrivateKey == null) throw Exception("The privateKey is empty");

    try {
      // Async version with Web3Dart

      // final signerPrivKey = EthPrivateKey.fromHex(hexPrivateKey.startsWith("0x")
      //     ? hexPrivateKey.substring(2)
      //     : hexPrivateKey);
      // final payloadBytes = Uint8List.fromList(utf8.encode(payload));
      // final signature =
      //     await signerPrivKey.signPersonalMessage(payloadBytes, chainId: chainId);
      // return "0x" + HEX.encode(signature);

      final packedPayload = _packPayloadForSignature(payload);

      final privKeyBytes = hexPrivateKey.startsWith("0x")
          ? Uint8List.fromList(HEX.decode(hexPrivateKey.substring(2)))
          : Uint8List.fromList(HEX.decode(hexPrivateKey));

      final signature =
          crypto.sign(crypto.keccak256(packedPayload), privKeyBytes);

      // https://github.com/ethereumjs/ethereumjs-util/blob/8ffe697fafb33cefc7b7ec01c11e3a7da787fe0e/src/signature.ts#L26
      // be aware that signature.v already is recovery + 27
      final chainIdV = chainId != null
          ? (signature.v - 27 + (chainId * 2 + 35))
          : signature.v;

      final r = _padUint8ListTo32(crypto.intToBytes(signature.r));
      final s = _padUint8ListTo32(crypto.intToBytes(signature.s));
      final v = crypto.intToBytes(BigInt.from(chainIdV));

      final sigBytes = _uint8ListFromList(r + s + v);
      return "0x" + HEX.encode(sigBytes);
    } catch (err) {
      throw Exception("The signature could not be computed");
    }
  }

  /// Recover the public key that signed the given message into the given signature
  static String _recoverSignerPubKey(
      String hexSignature, String strPayload, int chainId) {
    if (hexSignature == null ||
        hexSignature.length < 130 ||
        hexSignature.length > 132)
      throw Exception("The hexSignature is invalid");
    else if (strPayload == null) throw Exception("The payload is empty");

    // TODO: `CHAIN ID` IS NOT USED

    try {
      final packedPayload = _packPayloadForSignature(strPayload);
      final messageHashBytes = crypto.keccak256(packedPayload);

      String rStr, sStr, vStr;
      if (hexSignature.startsWith("0x")) {
        rStr = hexSignature.substring(0 + 2, 64 + 2);
        sStr = hexSignature.substring(64 + 2, 128 + 2);
        vStr = hexSignature.substring(128 + 2, 130 + 2);
      } else {
        rStr = hexSignature.substring(0, 64);
        sStr = hexSignature.substring(64, 128);
        vStr = hexSignature.substring(128, 130);
      }

      final r = BigInt.parse(rStr, radix: 16);
      final s = BigInt.parse(sStr, radix: 16);
      final v = int.parse(vStr, radix: 16);

      final signatureData = crypto.MsgSignature(r, s, v);
      final pubKey = crypto.ecRecover(messageHashBytes, signatureData);
      return "0x04" + HEX.encode(pubKey);
    } catch (err) {
      throw Exception("The signature could not be verified");
    }
  }

  /// Check whether the given signature is valid and belongs to the given message and
  /// public key
  static bool _isValidSignature(String hexSignature, String strPayload,
      String hexPublicKey, int chainId) {
    if (hexSignature == null ||
        hexSignature.length < 130 ||
        hexSignature.length > 132)
      throw Exception("The hexSignature is invalid");
    else if (strPayload == null)
      throw Exception("The payload is empty");
    else if (hexPublicKey == null || !hexPublicKey.startsWith("0"))
      throw Exception("The hexPublicKey should be a hex string");

    if (hexSignature.startsWith("0x"))
      hexSignature = hexSignature.substring(2); // Strip 0x
    if (hexPublicKey.startsWith("0x"))
      hexPublicKey = hexPublicKey.substring(2); // Strip 0x

    // expand the pubKey if not already
    hexPublicKey =
        HEX.encode(crypto.decompressPublicKey(HEX.decode(hexPublicKey)));

    // TODO: CHAIN ID IS NOT USED

    try {
      final pubKeyBytes =
          Uint8List.fromList(HEX.decode(hexPublicKey.substring(2))); // Strip 04

      final packedPayload = _packPayloadForSignature(strPayload);
      final messageHashBytes = crypto.keccak256(packedPayload);

      final rStr = hexSignature.substring(0, 64);
      final sStr = hexSignature.substring(64, 128);
      final vStr = hexSignature.substring(128, 130);

      final r = BigInt.parse(rStr, radix: 16);
      final s = BigInt.parse(sStr, radix: 16);
      var v = int.parse(vStr, radix: 16);

      // v should be 27 or 28, but 0 and 1 are also possible versions
      if (v < 27) {
        v += 27;
      }

      final signatureData = crypto.MsgSignature(r, s, v);
      return crypto.isValidSignature(
          messageHashBytes, signatureData, pubKeyBytes);
    } catch (err) {
      throw Exception("The signature could not be verified");
    }
  }

  // ////////////////////////////////////////////////////////////////////////////
  // / INTERNAL
  // ////////////////////////////////////////////////////////////////////////////

  static Uint8List _packPayloadForSignature(String payload) {
    final payloadBytes = Uint8List.fromList(utf8.encode(payload));
    final prefix = SIGNATURE_MESSAGE_PREFIX + payloadBytes.length.toString();
    final prefixBytes = ascii.encode(prefix);
    return _uint8ListFromList(prefixBytes + payloadBytes);
  }

  // ////////////////////////////////////////////////////////////////////////////
  // / BORROWED
  // ////////////////////////////////////////////////////////////////////////////

  // _uint8ListFromList and _padUint8ListTo32 are borrowed from 'package:web3dart/src/utils/typed_data.dart'
  // as web3dart does not export them

  static Uint8List _uint8ListFromList(List<int> data) {
    if (data is Uint8List) return data;

    return Uint8List.fromList(data);
  }

  static Uint8List _padUint8ListTo32(Uint8List data) {
    assert(data.length <= 32);
    if (data.length == 32) return data;

    // todo there must be a faster way to do this?
    return Uint8List(32)..setRange(32 - data.length, 32, data);
  }
}
