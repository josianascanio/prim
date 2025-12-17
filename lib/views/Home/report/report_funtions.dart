import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';

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

Future<Map<String, dynamic>?> fetchCloseCash({
  required BuildContext context,
  required int closeCashId,
}) async {
  try {
    await usuarioAuth(context: context);

    final response = await get(
      Uri.parse(
        '${EndPoints.cdsCloseCash}?\$filter=id eq $closeCashId&\$orderby=DateTrx desc&\$expand=CDS_CloseCash_Line',
      ),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final List records = jsonResponse['records'] ?? [];

      if (records.isEmpty) {
        return null;
      }

      final record = records.first as Map<String, dynamic>;

      // Fallback de vendedor: si no viene SalesRep_ID, usamos CreatedBy
      final Map<String, dynamic>? salesRep =
          (record['SalesRep_ID'] as Map<String, dynamic>?) ??
          (record['CreatedBy'] as Map<String, dynamic>?);

      final List<dynamic> lines = (record['CDS_CloseCash_Line'] ?? []) as List;

      final payments = lines.map((l) {
        final line = l as Map<String, dynamic>;
        return {
          'C_POSTenderType_ID': {
            'id': line['C_POSTenderType_ID']?['id'],
            'identifier': line['C_POSTenderType_ID']?['identifier'],
          },
          'PayAmt': line['PayAmt'] ?? 0,
          'C_DocType_ID': {
            'id': line['C_DocType_ID']?['id'],
            'identifier': line['C_DocType_ID']?['identifier'],
          },
        };
      }).toList();

      final int qtyOrder = (record['CDS_QtyOrder'] ?? 0) as int;
      final int qtyRefund = (record['CDS_QtyRefund'] ?? 0) as int;

      return {
        'id': record['id'],
        'Created': record['Created'],
        'DateFrom': record['DateFrom'],
        'DateTrx': record['DateTrx'],
        'IsActive': record['IsActive'] ?? true,
        'Processed': record['Processed'] ?? false,
        'GrandTotal': record['GrandTotal'] ?? 0,

        // Cantidades
        'QtyOrders': qtyOrder,
        'QtyReturns': qtyRefund,
        'TotalOrders': qtyOrder + qtyRefund,

        // Órdenes
        'TaxBaseAmt': record['CDS_TaxBaseAmt'] ?? 0,
        'TaxAmt': record['CDS_TaxAmt'] ?? 0,
        'ExemptAmt': record['CDS_TotalExemptOrders'] ?? 0,
        'TotalOrdersAmt':
            record['CDS_TotalOrders'] ?? record['GrandTotal'] ?? 0,

        // Devoluciones
        'ReturnTaxBaseAmt': record['CDS_TaxBaseAmtRefund'] ?? 0,
        'ReturnTaxAmt': record['CDS_TaxAmtRefund'] ?? 0,
        'ReturnExemptAmt': record['CDS_TotalExemptRefund'] ?? 0,
        'TotalReturnsAmt': record['CDS_TotalRefund'] ?? 0,

        // Referencias
        'C_POS_ID': {
          'id': record['C_POS_ID']?['id'],
          'name': record['C_POS_ID']?['identifier'],
        },
        'SalesRep_ID': {'id': salesRep?['id'], 'name': salesRep?['identifier']},
        'DocStatus': record['DocStatus']?['id'],

        // Líneas (raw)
        'CDS_CloseCash_Line': lines,

        // Líneas normalizadas para UI
        'payments': payments,
      };
    } else {
      debugPrint('Error al obtener detalle Cierre de caja: ${response.body}');
      return null;
    }
  } catch (e) {
    debugPrint('Error de red en fetchCloseCashDetailById: $e');
    return null;
  }
}

Future<List<Map<String, dynamic>>> fetctSalesRep() async {
  try {
    final response = await get(
      Uri.parse(EndPoints.salesRep),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final records = (jsonResponse['records'] as List?) ?? const [];

      final List<Map<String, dynamic>> reps = [];
      for (final record in records) {
        final adUsers = (record['AD_User'] as List?) ?? const [];
        if (adUsers.isEmpty) {
          continue;
        }
        final adUserId = adUsers.first['id'];
        final name = record['Name'];
        if (adUserId == null || name == null) {
          continue;
        }
        reps.add({'id': adUserId, 'name': name});
      }
      return reps;
    } else {
      throw Exception(
        'Error al cargar los representantes comerciales: ${response.statusCode}',
      );
    }
  } catch (e) {
    CurrentLogMessage.add(
      'Excepción al obtener los representantes comerciales: $e',
      level: 'ERROR',
      tag: 'fetctSalesRep',
    );
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchTerminals() async {
  try {
    final response = await get(
      Uri.parse(EndPoints.cPos),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': Token.auth!,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final records = (jsonResponse['records'] as List?) ?? const [];

      final List<Map<String, dynamic>> reps = [];
      for (final record in records) {
        final id = record['id'];
        final name = record['Name'];
        if (id == null || name == null) {
          continue;
        }
        reps.add({'id': id, 'name': name});
      }
      return reps;
    } else {
      throw Exception('Error al cargar los terminales: ${response.statusCode}');
    }
  } catch (e) {
    CurrentLogMessage.add(
      'Excepción al obtener los terminales: $e',
      level: 'ERROR',
      tag: 'fetchTerminals',
    );
    return [];
  }
}

Future<Map<String, dynamic>> postNewCloseCash({
  int? salesRepID,
  required int terminalID,
  required String dateTrx,
  String? dateFrom,
  required BuildContext context,
}) async {
  try {
    await usuarioAuth(context: context);
    final String dateTrxIso = _toIsoUtcZ(dateTrx);
    final String? dateFromIso = (dateFrom != null && dateFrom.trim().isNotEmpty)
        ? _toIsoUtcZ(dateFrom)
        : null;

    final Map<String, dynamic> data = {
      if (salesRepID != null) "SalesRep_ID": {"id": salesRepID},
      "C_POS_ID": {"id": terminalID},
      "DateTrx": dateTrxIso,
      if (dateFromIso != null) "DateFrom": dateFromIso,
    };

    final response = await post(
      Uri.parse(EndPoints.cdsCloseCash),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 201) {
      CurrentLogMessage.add(
        'Error al crear y completar el cierre de caja: ${response.body}',
        level: 'ERROR',
        tag: 'postInvoice',
      );

      return {
        'success': false,
        'message': 'Error al crear y completar el cierre de caja.',
      };
    }

    Map<String, dynamic> jsonData = jsonDecode(response.body);
    await refreshCloseCash(cdsCloseCashID: jsonData['id']);

    return {'success': true, 'Record_ID': jsonData['id']};
  } catch (e) {
    CurrentLogMessage.add(
      'Excepción general: $e',
      level: 'ERROR',
      tag: 'postNewCloseCash',
    );
    return {'success': false, 'message': 'Excepción inesperada: $e'};
  }
}

Future<Map<String, dynamic>> refreshCloseCash({
  required int cdsCloseCashID,
}) async {
  try {
    final Map<String, dynamic> data = {"CDS_CloseCash_ID": cdsCloseCashID};

    final response = await post(
      Uri.parse(Processes.cdsCloseCashProcess),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      CurrentLogMessage.add(
        'Error al actualizar el cierre de caja: ${response.body}',
        level: 'ERROR',
        tag: 'refreshCloseCash',
      );

      return {
        'success': false,
        'message': 'Error al actualizar el cierre de caja.',
      };
    }

    return {'success': true};
  } catch (e) {
    CurrentLogMessage.add(
      'Excepción general: $e',
      level: 'ERROR',
      tag: 'refreshCloseCash',
    );
    return {'success': false, 'message': 'Excepción inesperada: $e'};
  }
}

String _toIsoUtcZ(String input) {
  final s = input.trim();
  if (s.isEmpty) return s;

  if (RegExp(r"Z$").hasMatch(s) && s.contains('T')) return s;

  DateTime dt;
  if (s.length == 10) {
    dt = DateFormat('yyyy-MM-dd').parseStrict(s);
  } else {
    dt = DateFormat('yyyy-MM-dd HH:mm').parseStrict(s);
  }

  return DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(dt.toLocal());
}

Future<Map<String, dynamic>> updateCloseCashStatus({
  required int cdsCloseCashID,
}) async {
  try {
    final Map<String, dynamic> data = {"DocStatus": 'CO', "Processed": true};

    final response = await put(
      Uri.parse('${EndPoints.cdsCloseCash}/$cdsCloseCashID'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': Token.auth!,
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      CurrentLogMessage.add(
        'Error al cerrar el cierre de caja: ${response.body}',
        level: 'ERROR',
        tag: 'updateCloseCashStatus',
      );

      return {
        'success': false,
        'message': 'Error al cerrar el cierre de caja.',
      };
    }

    return {'success': true};
  } catch (e) {
    CurrentLogMessage.add(
      'Excepción general: $e',
      level: 'ERROR',
      tag: 'updateCloseCashStatus',
    );
    return {'success': false, 'message': 'Excepción inesperada: $e'};
  }
}
