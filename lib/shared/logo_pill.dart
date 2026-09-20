import 'package:flutter/material.dart';
import 'package:primware/shared/custom_spacer.dart';
import 'package:primware/shared/logo.dart';

class LogoPill extends StatefulWidget {
  const LogoPill({super.key});

  @override
  State<LogoPill> createState() => _LogoPillState();
}

class _LogoPillState extends State<LogoPill> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: CustomSpacer.medium),
      child: Container(
        decoration: Theme.of(context).brightness == Brightness.dark
            ? null
            : BoxDecoration(borderRadius: BorderRadius.circular(CustomSpacer.medium), color: Colors.white),
        padding: const EdgeInsets.all(CustomSpacer.small),
        child: const Logo(width: 60),
      ),
    );
  }
}
