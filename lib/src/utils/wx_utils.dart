import 'dart:io';
import 'package:aviation_wx/src/cloud_cover.dart';
import 'package:xml/xml.dart';

import '../metar.dart';
import '../sky_condition.dart';

import './nooa_text_data.dart';

Future<XmlDocument> loadXMLFile(String path) async {
  File f = File('test/data/sample_metar_ksfo.xml');
  String xmlString = await f.readAsString();
  return parse(xmlString);
}

/// Returns a map of [METAR]s grouped by station and observation time.
/// The param [stations] is a list of station identifiers in ICAO format
/// and [hoursBefore] is the number of hours earlier to return previous
/// [METAR]s for each of the [stations].
Future<Map<String, List<METAR>>> downloadMETARs(
  List<String> stations,
  int hoursBefore,
) async {
  var xmlnodes =
      await NOOATextData.downloadAsXml('metars', hoursBefore, stations);
  Map<String, List<METAR>> metars = {};

  xmlnodes.forEach((node) {
    var metar = parseMETAR(node);
    if (metars[metar.station] == null) {
      metars[metar.station] = List();
    }
    metars[metar.station].add(metar);
  });

  metars.keys.forEach((station) {
    metars[station].sort((metarA, metarB) =>
        metarA.observationTime.compareTo(metarB.observationTime));
  });

  return metars;
}

/// Creates a new instance of [METAR] from an [XmlElement] that should
/// follow the [METAR Field Descriptions](https://aviationweather.gov/dataserver/fields?datatype=metar)
METAR parseMETAR(XmlElement node) {
  var metar = METAR();
  node.children.forEach((node) {
    if (node.nodeType == XmlNodeType.ELEMENT) {
      XmlElement e = node;
      if (e.name.local == 'raw_text') {
        metar.rawText = e.text;
      } else if (e.name.local == 'station_id') {
        metar.station = e.text;
      } else if (e.name.local == 'observation_time') {
        metar.observationTime = DateTime.tryParse(e.text);
      } else if (e.name.local == 'latitude') {
        metar.latitude = double.parse(e.text);
      } else if (e.name.local == 'longitude') {
        metar.longitude = double.parse(e.text);
      } else if (e.name.local == 'temp_c') {
        metar.temp = double.parse(e.text);
      } else if (e.name.local == 'dewpoint_c') {
        metar.dewPoint = double.parse(e.text);
      } else if (e.name.local == 'wind_dir_degrees') {
        metar.windDirection = int.parse(e.text);
      } else if (e.name.local == 'wind_speed_kt') {
        metar.windSpeed = int.parse(e.text);
      } else if (e.name.local == 'wind_gust_kt') {
        metar.windGust = int.parse(e.text);
      } else if (e.name.local == 'visibility_statute_mi') {
        metar.visibility = double.parse(e.text);
      } else if (e.name.local == 'altim_in_hg') {
        metar.altimeter = double.parse(e.text);
      } else if (e.name.local == 'sea_level_pressure_mb') {
        metar.seaLevelPressure = double.parse(e.text);
      } else if (e.name.local == 'sky_condition') {
        metar.skyConditions.add(SkyCondition(
          cover: CloudCover.tryParse(e.getAttribute('sky_cover')),
          base: int.parse(e.getAttribute('cloud_base_ft_agl')),
        ));
      } else if (e.name.local == 'flight_category') {
        metar.flightCategory = e.text;
      } else if (e.name.local == 'snow_in') {
        metar.snowDepth = double.parse(e.text);
      } else if (e.name.local == 'vert_vis_ft') {
        metar.verticalVisibility = int.parse(e.text);
      } else if (e.name.local == 'elevation_m') {
        metar.elevation = double.parse(e.text);
      } else if (e.name.local == 'precip_in') {
        metar.precipitation = double.parse(e.text);
      }
    }
  });
  return metar;
}
