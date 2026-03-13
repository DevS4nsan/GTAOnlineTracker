import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        children: [
          TextSpan(
            text: "grand theft auto ",
            style: TextStyle(fontFamily: "Pricedown", fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          TextSpan(
            text: "ONLINE ",
            style: TextStyle(fontFamily: "Pricedown",  fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          TextSpan(
            text: "tracker",
            style: TextStyle(fontFamily: "Pricedown", fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}