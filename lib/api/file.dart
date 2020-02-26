import 'dart:convert';
import 'dart:typed_data';
import 'package:dvote/net/http.dart';
import "../net/gateway.dart";
import "../net/ipfs.dart";
import "../wrappers/content-uri.dart";

/// Fetch the given content URI using a Vocdoni Gateway
/// and return it as a string
Future<String> fetchFileString(ContentURI cUri,
    [DVoteGateway gw, int gwTimeout]) {
  return fetchFileBytes(cUri, gw ?? null, gwTimeout)
      .then((Uint8List data) => utf8.decode(data.toList()));
}

/// Fetch the given content URI using a Vocdoni Gateway
/// and return it as a byte array
Future<Uint8List> fetchFileBytes(ContentURI cUri,
    [DVoteGateway gw, int gwTimeout]) async {
  if (cUri == null) throw Exception("Invalid Content URI");

  // Attempt 1: fetch all from a gateway
  if (gw != null) {
    Map<String, dynamic> reqParams = {
      "method": "fetchFile",
      "uri": cUri.toString()
    };

    try {
      Map<String, dynamic> response =
          await gw.sendRequest(reqParams, timeout: gwTimeout ?? 10);
      if (!(response is Map) || !(response["content"] is String)) {
        throw Exception("Invalid response received from the gateway");
      }
      return base64.decode(response["content"]);
    } on Exception catch (err) {
      if (err.toString() != "Exception: The request timed out" &&
          err.toString() != "Exception: The response timestamp is invalid")
        throw err;
      // otherwise, continue below
    }
  }

  // Attempt 2: fetch fallback from IPFS public gateways
  if (cUri.ipfsHash != null) {
    try {
      var response = await fetchIpfsHash(cUri.ipfsHash);
      if (response != null) return response;
    } catch (err) {
      // continue
    }
  }

  // Attempt 3: fetch from fallback https endpoints
  for (String uri in cUri.httpsItems) {
    try {
      var response = await httpGetWithTimeout(uri);
      return response;
    } catch (err) {
      // keep trying
      continue;
    }
  }

  // Attempt 4: fetch from fallback http endpoints
  for (String uri in cUri.httpItems) {
    try {
      var response = await httpGetWithTimeout(uri);
      return response;
    } catch (err) {
      // keep trying
      continue;
    }
  }

  throw Exception("Unable to connect to the network");
}