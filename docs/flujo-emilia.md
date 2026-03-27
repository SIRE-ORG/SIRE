# Flujo de trabajo — Emilia

### SIRE · Designer & Frontend Flutter

---

## Tu rol en el proyecto

Eres responsable de todo lo visual de la aplicación. Tu trabajo vive **exclusivamente** dentro de la carpeta `lib/presentation/` del proyecto Flutter. No necesitas entender cómo funciona la base de datos, cómo se llama la API ni cómo se transforma la información internamente — eso está resuelto en otras capas del proyecto.

Lo que sí necesitas entender es cómo **leer datos** que ya están preparados para ti y cómo **llamar acciones** que ya están implementadas. Esto se hace a través de un sistema llamado Riverpod, que es el gestor de estado del proyecto. En este documento encontrarás todo lo que necesitas para trabajar con él.

---

## La estructura del proyecto Flutter

El proyecto sigue una arquitectura en tres capas:

```
lib/
├── data/           ← conexión con la API y base de datos
├── domain/         ← reglas de negocio y entidades
└── presentation/   ← pantallas y componentes visuales ← aquí trabajas tú
    ├── screens/    ← las pantallas de la app
    ├── widgets/    ← componentes reutilizables
    └── providers/  ← los providers que consumirás desde tus pantallas
```

**Regla fundamental: tus commits no deben modificar archivos fuera de `lib/presentation/`.**

Si en algún momento necesitas un dato que no está disponible o una acción que no existe, lo más útil es anotarlo como un comentario `// TODO:` en el código y avisar al equipo en el grupo. Así queda registrado en contexto y se puede resolver sin interrumpir tu flujo de trabajo.

---

## La carpeta de documentación

El repositorio tiene una carpeta `/docs` en la rama `dev` donde vive toda la documentación del proyecto. Esta carpeta **no existe en `main`** — es exclusiva del entorno de desarrollo.

```
docs/
├── definicion.md           ← documento de definición del proyecto
├── api-contract.md         ← contrato de API entre Daniel y Cristóbal
├── api-status.md           ← estado de implementación de endpoints
├── flujo-emilia.md         ← este documento
├── flujo-cristobal.md      ← documento de flujo de Cristóbal
└── dudas/
    ├── emilia/             ← aquí dejas tus archivos de dudas
    └── cristobal/          ← dudas de Cristóbal
```

### Cómo usar la carpeta de dudas

Cuando tengas una pregunta que requiera más contexto del que cabe en un comentario de código, puedes crear un archivo Markdown en `docs/dudas/emilia/` y describirla ahí:

```
docs/dudas/emilia/detalle-publicacion.md
```

```markdown
# Dudas — Pantalla detalle de publicación

## publicationDetailProvider
Necesito saber si este provider ya está disponible en dev.
Lo necesito para mostrar la imagen y el nombre del dueño.
Por ahora estoy usando datos estáticos como placeholder.

## Navegación desde el feed
¿El id de la publicación se pasa como parámetro de ruta
o como argumento de navegación?
```

Luego avisas en el grupo con el link al archivo. El archivo viaja junto con tu rama y se mergea a `dev` con el PR correspondiente, así queda el historial de lo que se preguntó y cómo se resolvió.

---

## El contrato — qué tienes disponible para usar

Tienes a disposición un conjunto de **providers** y **entidades** que son tu interfaz con el resto del sistema. Son los únicos elementos que necesitas conocer para construir cualquier pantalla.

### Entidades (los objetos que vas a mostrar)

```dart
// Un resultado del feed
Publication {
  String id
  String title
  String description
  String imageUrl
  String region
  String ownerName
  double? rating        // puede ser nulo si aún no tiene puntuaciones
}

// Una reserva del usuario
Reservation {
  String id
  String publicationTitle
  String ownerName
  DateTime date
  String startTime      // "10:00"
  String endTime        // "10:30"
  ReservationStatus status  // pending | completed | failed | cancelled | rejected
}

// Estado de autenticación
UserState {
  AuthStatus status     // unauthenticated | guest | active
  String? name
  String? email
}
```

### Providers disponibles (para leer datos)

```dart
// Lista de publicaciones del feed
feedProvider → AsyncValue<List<Publication>>

// Lista de reservas del usuario actual
reservationsProvider → AsyncValue<List<Reservation>>

// Estado de autenticación del usuario
authProvider → UserState

// Detalle de una publicación específica
publicationDetailProvider(String id) → AsyncValue<Publication>

// Slots disponibles para una fecha específica
availableSlotsProvider(String publicationId, DateTime date) → AsyncValue<List<TimeSlot>>
```

### Acciones disponibles (para ejecutar cosas)

```dart
// Feed
feedNotifier.changeOrder(FeedOrder order)   // cambia el ordenamiento

// Reservas
reservationNotifier.create(publicationId, slotId)
reservationNotifier.cancel(reservationId)

// Autenticación
authNotifier.registerGuest(name, email, phone)
authNotifier.login(email, password)
authNotifier.logout()
authNotifier.requestPasswordLink()   // envía magic link al correo
```

---

## Cómo usar los providers en una pantalla

Riverpod funciona con `ConsumerWidget` en lugar del `StatelessWidget` habitual. La diferencia es que recibes un objeto `ref` que te permite leer providers. Aquí van los patrones más comunes:

### Ejemplo: pantalla del feed

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sire/presentation/providers/feed_provider.dart';
import 'package:sire/domain/entities/publication.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Leer el provider — devuelve AsyncValue<List<Publication>>
    final feedState = ref.watch(feedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SIRE')),
      body: feedState.when(
        // Mientras carga
        loading: () => const Center(child: CircularProgressIndicator()),
        // Si hay un error
        error: (error, _) => Center(child: Text('Error: $error')),
        // Cuando los datos están listos
        data: (publications) => ListView.builder(
          itemCount: publications.length,
          itemBuilder: (context, index) {
            final pub = publications[index];
            return PublicationCard(publication: pub);
          },
        ),
      ),
    );
  }
}
```

### Ejemplo: card de publicación

```dart
class PublicationCard extends StatelessWidget {
  final Publication publication;

  const PublicationCard({super.key, required this.publication});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Image.network(publication.imageUrl),
        title: Text(publication.title),
        subtitle: Text(publication.ownerName),
        trailing: publication.rating != null
            ? Text('★ ${publication.rating!.toStringAsFixed(1)}')
            : null,
        onTap: () {
          Navigator.pushNamed(context, '/publication/${publication.id}');
        },
      ),
    );
  }
}
```

### Ejemplo: llamar una acción (crear reserva)

```dart
class ReservationFormScreen extends ConsumerWidget {
  final String publicationId;
  final String slotId;

  const ReservationFormScreen({
    super.key,
    required this.publicationId,
    required this.slotId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          // ... campos del formulario ...
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(reservationNotifier.notifier)
                  .create(publicationId, slotId);

              Navigator.pushReplacementNamed(context, '/my-reservations');
            },
            child: const Text('Confirmar reserva'),
          ),
        ],
      ),
    );
  }
}
```

### Ejemplo: leer el estado de autenticación

```dart
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authProvider);

    if (userState.status == AuthStatus.unauthenticated) {
      return const LoginScreen();
    }

    return Scaffold(
      body: Column(
        children: [
          Text('Hola, ${userState.name}'),
          if (userState.status == AuthStatus.guest)
            ElevatedButton(
              onPressed: () {
                ref.read(authNotifier.notifier).requestPasswordLink();
              },
              child: const Text('Crear contraseña'),
            ),
        ],
      ),
    );
  }
}
```

---

## Git — cómo trabajar con el repositorio

### Configuración inicial (solo la primera vez)

```bash
# Clonar el repositorio
git clone https://github.com/SIRE-ORG/SIRE.git
cd SIRE

# Configurar tu nombre
git config user.name "Emilia"
git config user.email "tu@correo.com"
```

### Flujo diario

```bash
# 1. Asegúrate de tener lo último de dev
git checkout dev
git pull

# 2. Crea tu rama para la pantalla en la que vas a trabajar
git checkout -b emilia/pantalla-feed

# 3. Trabaja en tu pantalla...

# 4. Guarda tus cambios
git add .
git commit -m "feat: pantalla feed con lista de publicaciones"

# 5. Sube tu rama al repositorio
git push origin emilia/pantalla-feed
```

### Cómo nombrar tus ramas

El formato es siempre: `emilia/[qué-estás-haciendo]`

```
emilia/pantalla-feed
emilia/pantalla-detalle-publicacion
emilia/pantalla-mis-reservas
emilia/widget-publication-card
emilia/pantalla-formulario-reserva
```

### Cómo nombrar tus commits

Usa este formato: `tipo: descripción corta en minúsculas`

| Tipo | Cuándo usarlo |
|---|---|
| `feat:` | Cuando agregás una pantalla o widget nuevo |
| `fix:` | Cuando corregís algo que estaba mal |
| `style:` | Cuando solo cambiás colores, espaciados, tipografía |
| `refactor:` | Cuando reorganizás código sin cambiar lo que hace |
| `docs:` | Cuando agregas o actualizas un archivo en `/docs` |

**Ejemplos:**

```bash
git commit -m "feat: pantalla feed con cards de publicaciones"
git commit -m "feat: widget publication card con imagen y rating"
git commit -m "fix: overflow en card cuando el título es muy largo"
git commit -m "style: ajuste de paleta de colores en pantalla de perfil"
git commit -m "docs: agregar dudas sobre navegación en detalle de publicación"
```

### Crear un Pull Request

Cuando termines una pantalla y esté lista para integrarse:

1. Ve al repositorio: [github.com/SIRE-ORG/SIRE](https://github.com/SIRE-ORG/SIRE)
2. Haz clic en **"Pull requests"** → **"New pull request"**
3. Base: `dev` ← Compare: `emilia/pantalla-feed`
4. Escribe un título descriptivo: *"Pantalla feed con lista paginada"*
5. Describí brevemente qué hiciste y si hay algo puntual que quieras destacar
6. Asigna a Daniel como reviewer
7. Haz clic en **"Create pull request"**

Los archivos de dudas que hayas creado en `docs/dudas/emilia/` viajan en el mismo PR. No necesitas un PR separado para documentación.

---

## Cómo avisar al equipo si algo te bloquea

En el grupo de WhatsApp, usa este formato:

> 🔴 **Bloqueada** en [nombre de la pantalla] — necesito [qué cosa específica]. Dejé un comentario en `[ruta]` / un archivo en `docs/dudas/emilia/[archivo].md`

**Ejemplo:**
> 🔴 **Bloqueada** en pantalla de detalle de publicación — necesito que `publicationDetailProvider` esté disponible en dev. Dejé las dudas en `docs/dudas/emilia/detalle-publicacion.md`

---
