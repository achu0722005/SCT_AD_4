import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main(){
  runApp(Myapp());
}
class Myapp extends StatelessWidget {
  const Myapp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Qrcodehomescreen(),
    );
  }
}

class Qrcodehomescreen extends StatefulWidget {
  const Qrcodehomescreen({super.key});

  @override
  State<Qrcodehomescreen> createState() => _QrcodehomescreenState();
}

class _QrcodehomescreenState extends State<Qrcodehomescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Qr scanner / generator",style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        ),
        actions: [
          IconButton(onPressed: (){}, icon: Icon(Icons.cancel,color: Colors.white,size: 10,))
        ],
        centerTitle: true,
      ),
    );
  }
}

