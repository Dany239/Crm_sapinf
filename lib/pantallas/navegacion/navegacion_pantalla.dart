import 'package:flutter/material.dart';

import '../../models/usuario_model.dart';
import '../../viewmodels/navegacion_viewmodel.dart';
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
  final NavegacionViewModel viewModel = NavegacionViewModel();

  @override
  void initState() {
    super.initState();
    viewModel.addListener(_actualizar);
  }

  @override
  void dispose() {
    viewModel.removeListener(_actualizar);
    viewModel.dispose();
    super.dispose();
  }

  void _actualizar() {
    if (mounted) setState(() {});
  }

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
      BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
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
    if (!viewModel.hayUsuarioAutenticado) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<UsuarioModel?>(
      stream: viewModel.usuarioActualStream,
      builder: (context, snapshot) {
        final usuario = snapshot.data;
        final accesoAdministrador = usuario?.accesoAdministrador ?? false;
        final pantallas = pantallasPorRol(accesoAdministrador);
        final items = itemsPorRol(accesoAdministrador);

        viewModel.asegurarIndiceValido(pantallas.length);

        return Scaffold(
          body: pantallas[viewModel.indiceActual],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: viewModel.indiceActual,
            selectedItemColor: const Color(0xFF1565C0),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            onTap: viewModel.cambiarIndice,
            items: items,
          ),
        );
      },
    );
  }
}
