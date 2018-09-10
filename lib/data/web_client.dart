// Copyright 2018, Devoxx
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:built_collection/built_collection.dart';
import 'package:voxxedapp/models/conference.dart';
import 'package:voxxedapp/models/serializers.dart';
import 'package:voxxedapp/models/speaker.dart';
import 'package:voxxedapp/util/logger.dart';

class WebClient {
  static const _requestTimeoutDuration = Duration(seconds: 10);
  static const maxAttempts = 3;

  const WebClient();

  String createAllConferencesUrl() =>
      'https://beta.voxxeddays.com/backend/api/voxxeddays/events/future/voxxed';

  String createSingleConferenceUrl(int id) =>
      'https://beta.voxxeddays.com/backend/api/voxxeddays/events/$id';

  String createAllSpeakersUrl(String cfpUrl, String cfpVersion) =>
      '$cfpUrl/api/conferences/$cfpVersion/speakers';

  String createSingleSpeakerUrl(
          String cfpUrl, String cfpVersion, String uuid) =>
      '$cfpUrl/api/conferences/CFPVDT18/speakers/$uuid';

  Future<http.Response> _makeRequest(String url) async {
    int attempts = 0;
    http.Response response;

    do {
      attempts++;
      response =
          await http.get(url).timeout(_requestTimeoutDuration).catchError((_) {
        String msg = 'Timed out requesting $url.';
        log.warning(msg);
        throw Exception(msg);
      });
    } while (response.statusCode == 500 && attempts < maxAttempts);

    return response;
  }

  Future<BuiltList<Conference>> fetchConferences() async {
    final response = await _makeRequest(createAllConferencesUrl());

    if (response.statusCode != 200) {
      final msg = 'Failed to fetch conferences, status: ${response.statusCode}';
      log.warning(msg);
      throw Exception(msg);
    }

    final parsedJson = json.decode(response.body);
    final deserialized = serializers.deserialize(
      parsedJson,
      specifiedType: Conference.listSerializationType,
    );

    return deserialized;
  }

  Future<Conference> fetchConference(int id) async {
    final response = await _makeRequest(createSingleConferenceUrl(id));

    if (response.statusCode != 200) {
      final msg =
          'Failed to fetch conference $id, status: ${response.statusCode}';
      log.warning(msg);
      throw Exception(msg);
    }

    final parsedJson = json.decode(response.body);
    final deserialized =
        serializers.deserializeWith(Conference.serializer, parsedJson);
    return deserialized;
  }

  Future<BuiltList<Speaker>> fetchSpeakers(
      String cfpUrl, String cfpVersion) async {
    final response =
        await _makeRequest(createAllSpeakersUrl(cfpUrl, cfpVersion));

    if (response.statusCode != 200) {
      final msg = 'Failed to fetch speakers for $cfpVersion, '
          'status: ${response.statusCode}';
      log.warning(msg);
      throw Exception(msg);
    }

    final parsedJson = json.decode(response.body);
    final deserialized = serializers.deserialize(
      parsedJson,
      specifiedType: Speaker.listSerializationType,
    );

    return deserialized;
  }

  Future<Speaker> fetchSpeaker(
      String cfpUrl, String cfpVersion, String uuid) async {
    final response =
        await _makeRequest(createSingleSpeakerUrl(cfpUrl, cfpVersion, uuid));

    if (response.statusCode != 200) {
      final msg = 'Failed to fetch speaker for $uuid at $cfpVersion, '
          'status: ${response.statusCode}';
      log.warning(msg);
      throw Exception(msg);
    }

    final parsedJson = json.decode(response.body);
    final deserialized =
        serializers.deserializeWith(Speaker.serializer, parsedJson);

    return deserialized;
  }
}
