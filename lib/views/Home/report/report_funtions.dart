import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';

import '../../../API/endpoint.api.dart';
import '../../../API/token.api.dart';
import '../../../API/user.api.dart';
import '../../Auth/auth_funtions.dart';

Future<List<Map<String, dynamic>>> fetchRecords({
  required BuildContext context,
  String? filter,
  bool onlyMyRecords = true,
}) async {
  try {
    await usuarioAuth(context: context);

    filter = onlyMyRecords == true ? 'SalesRep_ID eq ${UserData.id}' : '';

    final response = await get(
      Uri.parse(
        '${EndPoints.cdsCloseCash}?\$filter=$filter&\$orderby=DateTrx desc&\$expand=CDS_CloseCash_Line',
      ),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final List records = jsonResponse['records'];

      return records.map((record) {
        return {
          'id': record['id'],
          'Created': record['Created'],
          'DateFrom': record['DateFrom'],
          'DateTrx': record['DateTrx'],
          'GrandTotal': record['GrandTotal'],
          'TotalOrders': record['CDS_QtyOrder'] + record['CDS_QtyRefund'],

          'C_POS_ID': {
            'id': record['C_POS_ID']?['id'],
            'name': record['C_POS_ID']?['identifier'],
          },
          'SalesRep_ID': {
            'id': record['SalesRep_ID']?['id'],
            'name': record['SalesRep_ID']?['identifier'],
          },
          'CDS_CloseCash_Line': record['CDS_CloseCash_Line'] ?? [],
          'DocStatus': record['DocStatus']['id'],
        };
      }).toList();
    } else {
      debugPrint('Error al obtener Cierre de cajas: ${response.body}');
      return [];
    }
  } catch (e) {
    debugPrint('Error de red en fetchRecords: $e');
    return [];
  }
}
