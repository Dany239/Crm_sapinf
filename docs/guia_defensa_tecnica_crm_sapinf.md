# Guía de defensa técnica del proyecto SAPINF CRM

Este documento está diseñado como una guía de estudio por capítulos para defender técnicamente el proyecto **SAPINF CRM**. La idea no es memorizar el código palabra por palabra, sino entender qué problema resuelve, cómo está organizado, cómo viajan los datos y cómo justificar sus decisiones técnicas.

---

# Capítulo 1. Visión general del proyecto

## ¿Qué es SAPINF CRM?

SAPINF CRM es una aplicación desarrollada en Flutter para gestionar procesos comerciales. Su objetivo es ayudar a una empresa a controlar clientes potenciales, ventas, seguimientos, agenda, reportes, usuarios, actividad de vendedores y alertas importantes.

En términos técnicos, es una aplicación cliente conectada a Firebase. Flutter construye la interfaz y Firebase funciona como backend para autenticación, base de datos y almacenamiento.

## Problema que resuelve

Antes de usar un CRM, un equipo comercial puede tener información dispersa en chats, hojas de cálculo o notas personales. Este proyecto centraliza esa información.

Permite responder preguntas como:

- ¿Qué clientes están registrados?
- ¿Qué vendedor está atendiendo a cada cliente?
- ¿Cuántas ventas se han registrado?
- ¿Qué clientes no han recibido seguimiento?
- ¿Qué vendedor está activo?
- ¿Qué reportes puede revisar un administrador?
- ¿Qué alertas comerciales existen?

## Usuarios principales

La app contempla principalmente dos perfiles:

- **Administrador:** puede revisar módulos gerenciales, reportes, usuarios, servicios y centro de control.
- **Vendedor:** puede gestionar sus clientes, ventas, seguimientos y perfil.

## Tecnologías principales

- **Flutter:** framework para construir la app multiplataforma.
- **Dart:** lenguaje de programación usado por Flutter.
- **Firebase Core:** inicialización del proyecto Firebase.
- **Firebase Auth:** autenticación de usuarios.
- **Cloud Firestore:** base de datos NoSQL en tiempo real.
- **Firebase Storage:** almacenamiento de imágenes o archivos.
- **PDF / Excel / Share Plus / Open File:** generación, apertura y compartición de reportes.
- **FL Chart:** gráficos comerciales.
- **Google Fonts:** tipografía personalizada.

---

# Capítulo 2. Estructura general del proyecto

La carpeta principal del código es `lib/`.

```text
lib/
  main.dart
  firebase_options.dart

  pantallas/
    login/
    splash/
    navegacion/
    inicio/
    clientes/
    ventas/
    seguimientos/
    reportes/
    usuarios/
    perfil/
    agenda/
    notificaciones/
    centro_control/

  servicios/
    sesion_usuario.dart
    notificaciones_servicio.dart
    exportacion_reportes_servicio.dart
    servicios_pantalla.dart
    agregar_servicio_pantalla.dart
    editar_servicio_pantalla.dart
    seleccionar_servicios_pantalla.dart
    logo_servicio.dart

  widgets/
    dashboard_header.dart
    kpi_card.dart
    registrador_actividad.dart
    sapinf_button.dart
    sapinf_textfield.dart
    sapinf_logo.dart

  theme/
    sapinf_colors.dart
    sapinf_spacing.dart
    sapinf_shadows.dart
    app_colors.dart
    app_spacing.dart
```

## Importancia de esta organización

La app está organizada por responsabilidades generales:

- `pantallas/`: contiene las vistas o pantallas que ve el usuario.
- `servicios/`: contiene lógica reutilizable o módulos auxiliares.
- `widgets/`: contiene componentes visuales reutilizables.
- `theme/`: contiene colores, espaciados y estilos.
- `main.dart`: punto de entrada de la app.
- `firebase_options.dart`: configuración de Firebase.

Esta organización permite ubicar rápido cada parte del sistema.

---

# Capítulo 3. Arquitectura actual del proyecto

## ¿El proyecto es MVVM?

Actualmente, el proyecto **no es MVVM puro**.

La arquitectura actual es más cercana a:

```text
Pantallas + Servicios + Widgets reutilizables + Firebase
```

En muchas pantallas se mezclan estas responsabilidades:

- Mostrar interfaz.
- Manejar estado.
- Validar formularios.
- Consultar Firebase.
- Guardar en Firebase.
- Navegar a otras pantallas.

Eso no es incorrecto para un proyecto en crecimiento, pero no corresponde totalmente al patrón MVVM.

## Cómo se vería en MVVM

En MVVM, las responsabilidades estarían separadas así:

```text
View
  Pantalla Flutter. Solo muestra interfaz y eventos.

ViewModel
  Maneja estado, validaciones y acciones.

Model
  Representa entidades como Cliente, Venta, Usuario.

Repository / Service
  Se comunica con Firebase.
```

Ejemplo ideal:

```text
AgregarVentaPantalla
  llama a
VentaViewModel
  llama a
VentaRepository
  llama a
FirebaseFirestore
```

## Cómo defenderlo

Puedes decir:

> “El proyecto está organizado de forma modular por funcionalidades. Actualmente no implementa MVVM estricto, pero sí utiliza separación parcial de responsabilidades mediante pantallas, servicios, widgets reutilizables y temas. La arquitectura permite evolucionar hacia MVVM extrayendo la lógica de negocio de las pantallas hacia ViewModels y repositorios.”

---

# Capítulo 4. Flujo completo desde que inicia la aplicación

El flujo general de inicio es:

```text
main()
  ↓
Firebase.initializeApp()
  ↓
MyApp
  ↓
SplashPantalla
  ↓
AuthGate
  ↓
¿Hay usuario autenticado?
  ├── No → LoginPantalla
  └── Sí → RegistradorActividad → NavegacionPantalla
```

## Explicación del flujo

1. La app inicia en `main.dart`.
2. Flutter se asegura de que sus bindings estén listos.
3. Firebase se inicializa usando `firebase_options.dart`.
4. Se ejecuta `runApp`.
5. Se muestra `SplashPantalla`.
6. Luego entra `AuthGate`.
7. `AuthGate` escucha el estado de autenticación.
8. Si no hay sesión, muestra `LoginPantalla`.
9. Si hay sesión, muestra `NavegacionPantalla`.
10. `RegistradorActividad` envuelve la navegación para registrar última actividad del usuario.

---

# Capítulo 5. Archivo `main.dart`

## ¿Para qué sirve?

Es el punto de entrada principal de la aplicación.

## ¿Por qué fue creado?

Toda app Flutter necesita una función `main()` para arrancar. En este proyecto también se usa para inicializar Firebase, configurar idioma, tema y decidir el flujo inicial.

## ¿Cuándo se ejecuta?

Se ejecuta al abrir la aplicación.

## ¿Quién lo llama?

El sistema operativo/plataforma llama a la función `main()` cuando inicia la app.

## ¿Qué información recibe?

No recibe parámetros directos.

## ¿Qué devuelve?

No devuelve una vista directamente; ejecuta `runApp()` para iniciar Flutter.

## ¿Con qué otros archivos se comunica?

- `firebase_options.dart`
- `login_pantalla.dart`
- `navegacion_pantalla.dart`
- `splash_pantalla.dart`
- `registrador_actividad.dart`
- `sapinf_colors.dart`

## ¿Qué pasaría si se elimina?

La aplicación no iniciaría.

## Importancia dentro de la arquitectura

Es el punto central de arranque y configuración global.

## Función `main()` línea por línea

```dart
Future<void> main() async {
```

Define la función principal. Es `async` porque Firebase necesita inicializarse antes de mostrar la app.

```dart
WidgetsFlutterBinding.ensureInitialized();
```

Prepara Flutter para usar plugins nativos antes de llamar a Firebase.

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

Conecta la aplicación con el proyecto Firebase correspondiente a la plataforma actual.

```dart
runApp(const MyApp());
```

Arranca la interfaz principal de Flutter.

## Clase `MyApp`

`MyApp` define el `MaterialApp`, el tema visual, el idioma y la primera pantalla.

La propiedad más importante es:

```dart
home: const SplashPantalla(siguientePantalla: AuthGate()),
```

Esto significa que la app primero muestra una pantalla splash y después pasa al verificador de sesión.

## Clase `AuthGate`

`AuthGate` decide si el usuario debe ver el login o entrar al sistema.

Usa:

```dart
FirebaseAuth.instance.authStateChanges()
```

Este stream escucha cambios de sesión en tiempo real.

Si hay usuario autenticado:

```dart
return const RegistradorActividad(child: NavegacionPantalla());
```

Si no hay usuario:

```dart
return const LoginPantalla();
```

---

# Capítulo 6. Firebase en el proyecto

## ¿Cómo se conecta con Firebase?

La conexión se realiza en `main.dart`:

```dart
Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

La configuración está en:

```text
lib/firebase_options.dart
```

## Servicios de Firebase usados

### Firebase Auth

Sirve para iniciar sesión, registrar usuarios y cerrar sesión.

Ejemplo:

```dart
FirebaseAuth.instance.currentUser
```

Obtiene el usuario actual.

### Cloud Firestore

Sirve como base de datos principal.

Ejemplo:

```dart
FirebaseFirestore.instance.collection('ventas').add({...});
```

Crea una venta.

### Firebase Storage

Sirve para almacenar archivos o imágenes, por ejemplo fotos de perfil.

## Colecciones principales

```text
usuarios
clientes
ventas
seguimientos
notificaciones
servicios
```

---

# Capítulo 7. Autenticación

## Archivos relacionados

```text
lib/pantallas/login/login_pantalla.dart
lib/pantallas/login/registro_pantalla.dart
lib/main.dart
```

## ¿Para qué sirve?

Permite controlar quién entra al CRM.

## ¿Por qué fue creada?

Un CRM maneja información comercial sensible. No debe estar disponible sin usuario y contraseña.

## ¿Cuándo se ejecuta?

- Al abrir la app.
- Al iniciar sesión.
- Al cerrar sesión.
- Al registrar un usuario.

## ¿Quién la llama?

`AuthGate` escucha el estado de sesión.

## ¿Qué información recibe?

Normalmente correo y contraseña.

## ¿Qué información devuelve?

Firebase devuelve un usuario autenticado o un error.

## ¿Con qué archivos se comunica?

- `main.dart`
- `navegacion_pantalla.dart`
- `registro_pantalla.dart`
- `perfil_pantalla.dart`
- Firestore colección `usuarios`

## Si se elimina

La app no tendría control de acceso.

---

# Capítulo 8. Navegación

## Archivo principal

```text
lib/pantallas/navegacion/navegacion_pantalla.dart
```

## ¿Para qué sirve?

Controla la navegación inferior de la app.

## ¿Por qué fue creado?

Para centralizar el acceso a los módulos principales.

## ¿Cuándo se ejecuta?

Después de iniciar sesión.

## ¿Quién lo llama?

`AuthGate` en `main.dart`.

## ¿Qué información recibe?

No recibe parámetros. Obtiene el usuario actual desde Firebase Auth.

## ¿Qué información devuelve?

Un `Scaffold` con:

- Pantalla actual.
- `BottomNavigationBar`.

## ¿Con qué archivos se comunica?

- `InicioPantalla`
- `ClientesPantalla`
- `VentasPantalla`
- `ReportesPantalla`
- `PerfilPantalla`
- Firebase Auth
- Firestore colección `usuarios`

## Importancia

Permite que la navegación cambie según el rol.

Si el usuario tiene acceso de administrador, se muestra Reportes. Si es vendedor, no.

---

# Capítulo 9. Manejo de roles y permisos

Los roles se consultan desde Firestore en la colección `usuarios`.

Campos importantes:

```text
rol
accesoAdministrador
```

El rol permite decidir qué pantallas ve el usuario.

Ejemplo:

```dart
final accesoAdministrador =
    rol == 'administrador' || data?['accesoAdministrador'] == true;
```

Esto significa:

- Si `rol` es `administrador`, tiene acceso.
- Si `accesoAdministrador` es `true`, también tiene acceso.

## Importancia

Este control protege módulos como:

- Reportes.
- Usuarios.
- Servicios.
- Centro de Control Comercial.

---

# Capítulo 10. Estados en Flutter dentro del proyecto

El proyecto maneja estado principalmente con:

- `setState`
- `StreamBuilder`
- `FutureBuilder`
- `TextEditingController`
- `Timer`

## `setState`

Sirve para actualizar la interfaz cuando cambia un valor.

Ejemplo:

```dart
setState(() {
  cargando = true;
});
```

## `StreamBuilder`

Sirve para escuchar datos en tiempo real.

Ejemplo:

```dart
FirebaseFirestore.instance.collection('clientes').snapshots()
```

Cuando Firestore cambia, la pantalla se reconstruye.

## `FutureBuilder`

Sirve para mostrar datos que se cargan una vez.

## `TextEditingController`

Sirve para leer lo que el usuario escribe.

## `Timer`

Sirve para ejecutar una acción cada cierto tiempo, como registrar actividad.

---

# Capítulo 11. Flujo de datos

## Flujo al guardar una venta

```text
Usuario escribe datos
  ↓
TextEditingController guarda temporalmente el texto
  ↓
guardarVenta() valida los campos
  ↓
Se obtiene la sesión del usuario
  ↓
Se guarda en Firestore colección ventas
  ↓
Se crea una notificación
  ↓
Se muestra mensaje de éxito
  ↓
Se vuelve a la pantalla anterior
```

## Flujo al listar datos

```text
Firestore collection.snapshots()
  ↓
StreamBuilder recibe cambios
  ↓
Flutter reconstruye la lista
  ↓
Usuario ve datos actualizados
```

---

# Capítulo 12. Módulo de ventas

## Archivos

```text
lib/pantallas/ventas/ventas_pantalla.dart
lib/pantallas/ventas/agregar_venta_pantalla.dart
lib/pantallas/ventas/editar_venta_pantalla.dart
```

## Propósito

Registrar, listar y editar ventas.

## Importancia

El módulo de ventas alimenta:

- Dashboard.
- Reportes.
- Centro de Control Comercial.
- Ranking de vendedores.
- Indicadores financieros.

---

# Capítulo 13. Archivo `agregar_venta_pantalla.dart`

Este capítulo explica el archivo activo con detalle.

## ¿Para qué sirve?

Permite registrar una nueva venta asociada a un cliente.

## ¿Por qué fue creado?

Porque el CRM necesita almacenar oportunidades comerciales o ventas reales.

## ¿Cuándo se ejecuta?

Cuando el usuario presiona la opción para agregar una venta.

## ¿Quién lo llama?

Puede ser llamado desde:

- `VentasPantalla`
- `DetalleClientePantalla`
- Cualquier pantalla que navegue con `Navigator.push`

## ¿Qué información recibe?

Puede recibir:

```dart
clienteIdInicial
clienteNombreInicial
```

Esto permite abrir la pantalla con un cliente ya seleccionado.

## ¿Qué información devuelve?

No devuelve un objeto directamente. Al guardar, hace:

```dart
Navigator.pop(context);
```

Eso vuelve a la pantalla anterior.

## ¿Con qué otros archivos se comunica?

- `sesion_usuario.dart`
- `notificaciones_servicio.dart`
- Firestore colección `clientes`
- Firestore colección `ventas`
- Firestore colección `notificaciones`

## ¿Qué pasaría si se elimina?

No se podrían registrar ventas nuevas.

## Importancia

Es una pantalla clave del flujo comercial.

---

## Explicación línea por línea de las partes principales

### Imports

```dart
import 'package:flutter/material.dart';
```

Importa los widgets principales de Flutter.

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
```

Permite leer y guardar datos en Firestore.

```dart
import 'package:google_fonts/google_fonts.dart';
```

Permite usar tipografías de Google.

```dart
import '../../servicios/sesion_usuario.dart';
```

Importa la clase y funciones para obtener datos del usuario actual.

```dart
import '../../servicios/notificaciones_servicio.dart';
```

Importa el servicio para crear notificaciones.

### Clase `AgregarVentaPantalla`

```dart
class AgregarVentaPantalla extends StatefulWidget {
```

Declara una pantalla con estado. Se usa `StatefulWidget` porque la pantalla cambia cuando el usuario selecciona cliente, servicio, estado o cuando se activa la carga.

```dart
final String? clienteIdInicial;
final String? clienteNombreInicial;
```

Guarda datos opcionales del cliente. Son opcionales porque la pantalla puede abrirse con o sin cliente preseleccionado.

```dart
const AgregarVentaPantalla({
  super.key,
  this.clienteIdInicial,
  this.clienteNombreInicial,
});
```

Constructor de la pantalla.

```dart
State<AgregarVentaPantalla> createState() => _AgregarVentaPantallaState();
```

Crea el estado interno donde vive la lógica.

### Estado `_AgregarVentaPantallaState`

```dart
String? clienteIdSeleccionado;
String? clienteNombreSeleccionado;
```

Variables que almacenan el cliente seleccionado.

```dart
final descripcionController = TextEditingController();
final montoController = TextEditingController();
```

Controladores para leer la descripción y el monto escritos por el usuario.

```dart
String servicioSeleccionado = 'Desarrollo de software';
String estadoSeleccionado = 'Pendiente';
```

Valores iniciales para los desplegables.

```dart
late Future<SesionUsuario> sesionFuture;
```

Guarda una carga futura de la sesión del usuario.

```dart
bool cargando = false;
```

Indica si se está guardando la venta.

### `initState()`

```dart
void initState() {
```

Se ejecuta una sola vez cuando la pantalla se crea.

```dart
super.initState();
```

Ejecuta la inicialización de la clase padre.

```dart
clienteIdSeleccionado = widget.clienteIdInicial;
clienteNombreSeleccionado = widget.clienteNombreInicial;
```

Si la pantalla recibió un cliente inicial, lo asigna como seleccionado.

```dart
sesionFuture = obtenerSesionUsuario();
```

Carga la información del usuario actual.

### `guardarVenta()`

```dart
Future<void> guardarVenta() async {
```

Método asíncrono que guarda la venta.

```dart
if (clienteIdSeleccionado == null || montoController.text.trim().isEmpty) {
```

Valida que exista cliente y monto.

```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Cliente y monto son obligatorios')),
);
```

Muestra un mensaje si faltan datos.

```dart
return;
```

Detiene el proceso para evitar guardar datos incompletos.

```dart
setState(() {
  cargando = true;
});
```

Activa el estado de carga y redibuja la pantalla.

```dart
final sesion = await obtenerSesionUsuario();
```

Obtiene datos del usuario activo.

```dart
final referencia =
    await FirebaseFirestore.instance.collection('ventas').add({
```

Crea un nuevo documento en la colección `ventas`.

```dart
'clienteId': clienteIdSeleccionado,
```

Guarda el ID del cliente.

```dart
'cliente': clienteNombreSeleccionado,
```

Guarda el nombre del cliente.

```dart
'servicio': servicioSeleccionado,
```

Guarda el servicio vendido.

```dart
'descripcion': descripcionController.text.trim(),
```

Guarda la descripción sin espacios sobrantes.

```dart
'monto': montoController.text.trim(),
```

Guarda el monto.

```dart
'estado': estadoSeleccionado,
```

Guarda el estado comercial de la venta.

```dart
...datosPropietario(sesion),
```

Agrega datos del vendedor: ID, nombre y correo.

```dart
'fechaRegistro': FieldValue.serverTimestamp(),
```

Guarda la fecha usando el servidor de Firebase.

```dart
});
```

Finaliza la creación del documento.

```dart
await NotificacionesServicio.crear(
```

Crea una notificación asociada a la venta.

```dart
titulo: 'Nueva venta registrada',
```

Define el título de la notificación.

```dart
descripcion:
    '${sesion.nombre} registró una venta para $clienteNombreSeleccionado por L. ${montoController.text.trim()}.',
```

Crea una descripción entendible para el usuario.

```dart
tipo: 'venta',
icono: 'attach_money',
color: 'green',
```

Clasifica la notificación y define su presentación.

```dart
autor: sesion,
```

Indica quién generó la venta.

```dart
usuariosDestinatarios: [sesion.uid],
```

Incluye al usuario creador como destinatario.

```dart
referenciaId: referencia.id,
referenciaColeccion: 'ventas',
```

Relaciona la notificación con el documento de venta.

```dart
if (!mounted) return;
```

Evita usar `context` si la pantalla ya no existe.

```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Venta guardada correctamente')),
);
```

Muestra confirmación.

```dart
Navigator.pop(context);
```

Regresa a la pantalla anterior.

### `dispose()`

```dart
descripcionController.dispose();
montoController.dispose();
```

Libera memoria de los controladores.

Esto es una buena práctica porque evita fugas de memoria.

### `campoDecoracion()`

Este método devuelve un `InputDecoration`.

Sirve para no repetir el mismo diseño en cada campo del formulario.

Recibe:

- `label`
- `icono`
- `hintText`

Devuelve:

- Un objeto de decoración para inputs.

### `opcionDesplegable()`

Construye el diseño visual de una opción dentro de un `DropdownButtonFormField`.

Recibe:

- Icono.
- Texto.
- Color.

Devuelve:

- Un `Row` con icono y texto.

### `opcionServicio()`

Convierte un texto de servicio en un `DropdownMenuItem`.

Usa un `switch` para asignar iconos y colores diferentes.

### `opcionEstado()`

Hace lo mismo que `opcionServicio`, pero para estados:

- Pendiente.
- En proceso.
- Cerrada.
- Cancelada.

### `selectorCliente()`

Este método carga clientes desde Firestore.

Si la pantalla recibió un cliente inicial, muestra un campo solo lectura.

Si no recibió cliente, muestra un desplegable con clientes disponibles.

Usa:

```dart
StreamBuilder<QuerySnapshot>
```

para escuchar clientes en tiempo real.

También usa:

```dart
FutureBuilder<SesionUsuario>
```

para saber si el usuario es administrador o vendedor.

Si es administrador, puede ver más clientes. Si es vendedor, ve solo los suyos.

### `encabezadoVenta()`

Construye el encabezado visual azul de la pantalla.

No guarda datos. Solo mejora presentación.

### `build()`

Construye toda la pantalla.

Incluye:

- `Scaffold`
- `AppBar`
- `SingleChildScrollView`
- formulario
- botón Guardar

El botón usa:

```dart
onPressed: cargando ? null : guardarVenta
```

Si está guardando, se desactiva. Si no, llama a `guardarVenta`.

---

# Capítulo 14. Servicio `sesion_usuario.dart`

## ¿Para qué sirve?

Representa y obtiene la información del usuario actual.

## Clase `SesionUsuario`

Guarda:

- `uid`
- `nombre`
- `correo`
- `rol`
- `accesoAdministrador`

## Getter `esAdministrador`

```dart
bool get esAdministrador => rol == 'administrador' || accesoAdministrador;
```

Devuelve `true` si el usuario es administrador por rol o por permiso extra.

## Función `obtenerSesionUsuario()`

Consulta Firebase Auth para saber quién está logueado y Firestore para obtener sus datos.

## Función `datosPropietario()`

Devuelve un mapa con datos del vendedor:

```dart
{
  'vendedorId': sesion.uid,
  'vendedorNombre': sesion.nombre,
  'vendedorCorreo': sesion.correo,
}
```

Esto se agrega a ventas, clientes o seguimientos para saber quién creó o atiende cada registro.

---

# Capítulo 15. Servicio `notificaciones_servicio.dart`

## ¿Para qué sirve?

Centraliza la creación y gestión de notificaciones internas.

## ¿Por qué fue creado?

Para evitar que cada pantalla tenga su propia lógica de notificaciones.

## Métodos principales

### `crear()`

Crea una notificación en la colección `notificaciones`.

Recibe:

- Título.
- Descripción.
- Tipo.
- Icono.
- Color.
- Autor.
- Destinatarios.
- Referencia opcional.

Devuelve:

- `Future<void>`.

### `esVisiblePara()`

Determina si una notificación debe mostrarse a un usuario.

Devuelve:

- `true` si puede verla.
- `false` si no.

### `estaLeidaPor()`

Determina si el usuario ya leyó una notificación.

### `marcarLeida()`

Actualiza Firestore para marcar una notificación como leída.

### `generarRecordatoriosPendientes()`

Busca seguimientos pendientes y crea recordatorios.

---

# Capítulo 16. Módulo de inicio y dashboard

Archivo:

```text
lib/pantallas/inicio/inicio_pantalla.dart
```

## ¿Para qué sirve?

Es el dashboard principal del CRM.

## Muestra

- Resumen comercial.
- Clientes.
- Ventas.
- Seguimientos.
- Gráficos.
- Notificaciones.
- Centro de Control Comercial para administradores.
- Drawer con accesos rápidos.

## ¿Por qué fue creado?

Para dar una visión rápida del estado comercial al entrar a la app.

## ¿Cuándo se ejecuta?

Cuando el usuario entra a la pestaña Inicio.

## ¿Quién lo llama?

`NavegacionPantalla`.

## ¿Con qué se comunica?

- `usuarios`
- `clientes`
- `ventas`
- `seguimientos`
- `notificaciones`
- `NotificacionesServicio`
- `CentroControlComercialPantalla`
- `ReportesPantalla`
- `ServiciosPantalla`
- `UsuariosPantalla`
- `AgendaPantalla`

## Importancia

Es la pantalla más estratégica porque resume el estado del negocio.

---

# Capítulo 17. Centro de Control Comercial

Archivo:

```text
lib/pantallas/centro_control/centro_control_comercial_pantalla.dart
```

## ¿Para qué sirve?

Da al administrador una pantalla ejecutiva con información comercial consolidada.

## Indicadores esperados

- Vendedores conectados.
- Seguimientos realizados hoy.
- Ventas del día.
- Clientes sin seguimiento.
- Ranking del mes.
- Alertas importantes.

## ¿Por qué fue creado?

Para que el gerente pueda saber rápidamente quién está trabajando y qué necesita atención.

## Importancia

Representa la capa gerencial del CRM.

---

# Capítulo 18. Módulo de clientes

Carpeta:

```text
lib/pantallas/clientes/
```

Archivos:

```text
clientes_pantalla.dart
agregar_cliente_pantalla.dart
editar_cliente_pantalla.dart
detalle_cliente_pantalla.dart
```

## Propósito

Gestionar clientes potenciales y clientes reales.

## Importancia

El cliente es la entidad central del CRM.

Ventas y seguimientos dependen de clientes.

## Flujo básico

```text
Lista de clientes
  ↓
Agregar / editar / ver detalle
  ↓
Guardar en Firestore
  ↓
Actualizar lista en tiempo real
```

---

# Capítulo 19. Módulo de seguimientos

Carpeta:

```text
lib/pantallas/seguimientos/
```

Archivos:

```text
seguimientos_pantalla.dart
agregar_seguimiento_pantalla.dart
editar_seguimiento_pantalla.dart
```

## Propósito

Registrar llamadas, reuniones, correos o gestiones comerciales realizadas a clientes.

## Importancia

Permite saber si un cliente está siendo atendido.

También alimenta:

- Agenda.
- Recordatorios.
- Alertas.
- Centro de Control Comercial.

---

# Capítulo 20. Módulo de reportes

Archivo:

```text
lib/pantallas/reportes/reportes_pantalla.dart
```

Servicio:

```text
lib/servicios/exportacion_reportes_servicio.dart
```

## Propósito

Analizar información comercial y exportarla.

## Funciones principales

- Ver métricas.
- Filtrar por vendedor.
- Filtrar por rango de fechas.
- Generar PDF.
- Generar Excel.
- Abrir archivos.
- Compartir por apps instaladas.

## Importancia

Permite presentar resultados a gerencia o empresas.

---

# Capítulo 21. Módulo de usuarios

Carpeta:

```text
lib/pantallas/usuarios/
```

Archivos:

```text
usuarios_pantalla.dart
agregar_usuario_pantalla.dart
editar_usuario_pantalla.dart
```

## Propósito

Administrar vendedores y usuarios del sistema.

## Importancia

Permite controlar:

- Roles.
- Accesos.
- Actividad.
- Datos del usuario.

---

# Capítulo 22. Widgets reutilizables

## `dashboard_header.dart`

Encabezado superior del dashboard.

Muestra título, menú y notificaciones.

## `kpi_card.dart`

Tarjeta para indicadores.

## `registrador_actividad.dart`

Registra la última actividad del usuario.

## `sapinf_button.dart`

Botón con estilo SAPINF.

## `sapinf_textfield.dart`

Campo de texto con estilo SAPINF.

## `sapinf_logo.dart`

Logo reutilizable.

## Importancia

Los widgets reutilizables reducen duplicación y mantienen consistencia visual.

---

# Capítulo 23. Tema visual

Carpeta:

```text
lib/theme/
```

## Archivos

```text
sapinf_colors.dart
sapinf_spacing.dart
sapinf_shadows.dart
app_colors.dart
app_spacing.dart
```

## Propósito

Centralizar diseño visual.

## Importancia

Permite que la app tenga identidad visual consistente.

Si se cambia un color de marca, puede actualizarse desde un solo lugar.

---

# Capítulo 24. Buenas prácticas aplicadas

El proyecto aplica varias buenas prácticas:

- Separación por carpetas.
- Uso de Firebase Auth para seguridad.
- Uso de Firestore en tiempo real.
- Uso de `StreamBuilder` para datos vivos.
- Uso de `FutureBuilder` para cargas únicas.
- Uso de `dispose()` para liberar controladores.
- Uso de `mounted` antes de usar `context` después de operaciones asíncronas.
- Uso de servicios para lógica compartida.
- Uso de widgets reutilizables.
- Uso de tema visual centralizado.
- Control de acceso por rol.
- Uso de `FieldValue.serverTimestamp()` para fechas confiables del servidor.

---

# Capítulo 25. Patrones de diseño identificables

## 1. Componentización

La app divide partes visuales en widgets reutilizables.

## 2. Observer / programación reactiva

`StreamBuilder` observa cambios en Firestore.

## 3. Service Layer parcial

Servicios como `NotificacionesServicio` y `ExportacionReportesServicio` centralizan lógica.

## 4. Singleton implícito

Firebase usa instancias globales:

```dart
FirebaseAuth.instance
FirebaseFirestore.instance
```

## 5. Stateful UI

Muchas pantallas usan `StatefulWidget` para manejar cambios locales.

---

# Capítulo 26. Qué pasaría si se elimina cada parte importante

| Elemento | Consecuencia |
|---|---|
| `main.dart` | La app no inicia |
| `firebase_options.dart` | Firebase no conecta |
| `login_pantalla.dart` | No se puede iniciar sesión |
| `registro_pantalla.dart` | No se pueden registrar usuarios desde la app |
| `navegacion_pantalla.dart` | No hay navegación principal |
| `inicio_pantalla.dart` | No hay dashboard |
| `clientes/` | No hay gestión de clientes |
| `ventas/` | No hay gestión de ventas |
| `seguimientos/` | No hay control de gestiones comerciales |
| `reportes_pantalla.dart` | No hay análisis comercial |
| `exportacion_reportes_servicio.dart` | No hay PDF, Excel, abrir o compartir |
| `usuarios/` | No hay administración de usuarios |
| `notificaciones_servicio.dart` | No hay alertas internas |
| `registrador_actividad.dart` | No se mide actividad del vendedor |
| `theme/` | Se pierde consistencia visual |
| `widgets/` | Se duplica código visual |

---

# Capítulo 27. Cómo defender el proyecto en una presentación

## Respuesta corta

> “SAPINF CRM es una aplicación Flutter conectada a Firebase que permite administrar clientes, ventas, seguimientos, usuarios, reportes y actividad comercial. Usa Firebase Auth para autenticación, Firestore como base de datos en tiempo real y una estructura modular por pantallas, servicios, widgets y temas.”

## Respuesta sobre arquitectura

> “La arquitectura actual no es MVVM pura. Es modular por funcionalidades, con servicios reutilizables para lógica común. Se puede migrar a MVVM separando las pantallas como Views, la lógica como ViewModels, las entidades como Models y Firebase como Repository.”

## Respuesta sobre seguridad

> “La seguridad funcional se maneja con Firebase Auth y control de roles desde Firestore. Según el rol del usuario se muestran u ocultan módulos como reportes, usuarios y centro de control.”

## Respuesta sobre datos

> “Los datos se guardan en Firestore por colecciones. Las pantallas usan streams para escuchar cambios en tiempo real, por eso cuando se agrega o edita información, la interfaz puede actualizarse automáticamente.”

---

# Capítulo 28. Preguntas frecuentes de defensa

## ¿Por qué usaron Firebase?

Porque permite autenticación, base de datos en tiempo real y almacenamiento sin construir un backend desde cero.

## ¿Por qué Flutter?

Porque permite crear una app multiplataforma con una sola base de código.

## ¿Por qué Firestore?

Porque permite datos en tiempo real, estructura flexible y buena integración con Flutter.

## ¿La app funciona sin internet?

Puede depender de la caché de Firestore para ciertos datos, pero las operaciones principales requieren conexión para sincronizar.

## ¿Qué mejora técnica harías después?

Migraría gradualmente a MVVM, empezando por Clientes o Ventas.

## ¿Cuál es el módulo más importante?

Clientes, porque es la base del CRM. Ventas y seguimientos dependen de clientes.

## ¿Cuál es la pantalla más estratégica?

Inicio/Dashboard, porque resume el estado comercial.

---

# Capítulo 29. Plan recomendado para migrar a MVVM

## Fase 1. Crear modelos

```text
lib/models/
  cliente_model.dart
  venta_model.dart
  usuario_model.dart
  seguimiento_model.dart
```

## Fase 2. Crear repositorios

```text
lib/repositories/
  clientes_repository.dart
  ventas_repository.dart
  usuarios_repository.dart
```

## Fase 3. Crear ViewModels

```text
lib/viewmodels/
  clientes_viewmodel.dart
  ventas_viewmodel.dart
```

## Fase 4. Limpiar pantallas

Las pantallas dejarían de llamar directamente a Firebase.

Antes:

```dart
FirebaseFirestore.instance.collection('ventas').add({...});
```

Después:

```dart
viewModel.guardarVenta();
```

---

# Capítulo 30. Conclusión general

SAPINF CRM es un sistema comercial funcional y modular. Su valor principal es que integra en una sola app clientes, ventas, seguimientos, usuarios, reportes, notificaciones y control gerencial.

Técnicamente, usa Flutter para la interfaz y Firebase para backend. La aplicación aprovecha Firestore en tiempo real, autenticación con Firebase Auth, control de roles y componentes reutilizables.

La arquitectura actual es suficiente para una primera versión funcional. Sin embargo, para una versión más profesional y escalable, la siguiente mejora recomendada es migrar gradualmente a MVVM.

La defensa técnica más sólida es reconocer esto:

> “El proyecto ya está modularizado por pantallas, servicios, widgets y temas. No es MVVM puro todavía, pero está preparado para evolucionar a MVVM separando lógica de negocio, modelos y repositorios.”

