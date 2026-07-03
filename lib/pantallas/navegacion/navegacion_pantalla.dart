import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../inicio/inicio_pantalla.dart';
import '../clientes/clientes_pantalla.dart';
import '../ventas/ventas_pantalla.dart';
import '../perfil/perfil_pantalla.dart';
import '../reportes/reportes_pantalla.dart';

class NavegacionPantalla extends StatefulWidget {
  const NavegacionPantalla({super.key});

  @override
  State<NavegacionPantalla> createState() => _NavegacionPantallaState();
}

class _NavegacionPantallaState extends State<NavegacionPantalla> {
  int indiceActual = 0;

  List<Widget> pantallasPorRol(bool accesoAdministrador) {
    if (accesoAdministrador) {
      return const [
        InicioPantalla(),
        ClientesPantalla(),
        VentasPantalla(),
        ReportesPantalla(),
        PerfilPantalla(),
      ];
    }

    return const [
      InicioPantalla(),
      ClientesPantalla(),
      VentasPantalla(),
      PerfilPantalla(),
    ];
  }

  List<BottomNavigationBarItem> itemsPorRol(bool accesoAdministrador) {
    if (accesoAdministrador) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_rounded),
          label: 'Clientes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.attach_money_rounded),
          label: 'Ventas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_rounded),
          label: 'Reportes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Perfil',
        ),
      ];
    }

    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_rounded),
        label: 'Inicio',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.people_rounded),
        label: 'Clientes',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.attach_money_rounded),
        label: 'Ventas',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_rounded),
        label: 'Perfil',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final rol = data?['rol']?.toString() ?? 'vendedor';
        final accesoAdministrador =
            rol == 'administrador' || data?['accesoAdministrador'] == true;
        final pantallas = pantallasPorRol(accesoAdministrador);
        final items = itemsPorRol(accesoAdministrador);

        if (indiceActual >= pantallas.length) {
          indiceActual = 0;
        }

        return Scaffold(
          body: pantallas[indiceActual],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: indiceActual,
            selectedItemColor: const Color(0xFF1565C0),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              setState(() {
                indiceActual = index;
              });
            },
            items: items,
          ),
        );
      },
    );
  }
}
