# DOCS — Space Shooter amb Flame

Documentació de les preguntes 4b1 a 4b12 sobre el projecte.

## 4b1. GameWidget i GameLoop

El `GameWidget` sí que hi és. Viu a `lib/main.dart`, dins de la funció `main()`, en aquesta línia: `runApp(GameWidget(game: SpaceShooterGame()));`. És el widget de Flutter que serveix de pont entre l'arbre de widgets i el motor de Flame, i és qui fa que el joc ocupi la pantalla.

El `GameLoop`, en canvi, no apareix enlloc de manera explícita al nostre codi. Això és perquè Flame el crea sol quan una classe estén `FlameGame`. Aquest bucle invisible s'encarrega de cridar uns seixanta cops per segon els mètodes `update(dt)` i `render(canvas)` de tots els components actius. Nosaltres només aprofitem aquestes crides sobreescrivint-les quan ens interessa, però mai no instanciem ni gestionem el `GameLoop` directament.

## 4b2. Render i Update

El `GameWidget` en si mateix no implementa ni `render` ni `update`; simplement delega la feina al `FlameGame` i als seus components. Per tant, els llocs interessants del nostre codi són els components que fan d'aquests mètodes.

L'`update(double dt)` el sobreescrivim a la bala i a l'enemic perquè es moguin cada frame. A `Bullet`, per exemple, fem `position.y += dt * -500` perquè pugi a cinc-cents píxels per segon, i si surt per dalt la eliminem amb `removeFromParent()`. A `Enemy` fem pràcticament el mateix però en sentit contrari, baixant a dos-cents cinquanta píxels per segon. El paràmetre `dt` és molt important: són els segons que han passat des de l'últim frame, i multiplicar-hi la velocitat fa que el moviment sigui igual de ràpid tant si el joc va a seixanta FPS com si va a trenta.

El `render(Canvas canvas)` no el toquem explícitament enlloc, i no ens cal perquè totes les nostres entitats hereten de `SpriteAnimationComponent`, una classe que ja porta el seu propi `render` implementat per dibuixar el frame actual de la seva animació. El fons amb parallax fa exactament el mateix amb les seves capes d'estrelles.

## 4b3. Visibility, position, size, scale i canvas

La **posició** és omnipresent al codi: `Player.position = game.size / 2;` centra la nau al principi, els enemics reben la seva posició pel `SpawnComponent` i les bales la calculen a partir de la nau. Sempre és un `Vector2`.

El **size** també el definim a cada component, normalment al constructor: el jugador té `Vector2(100, 150)`, l'enemic `Vector2.all(50)` i la bala `Vector2(25, 50)`. És la mida visible del component a la pantalla.

El **scale** no el fem servir explícitament. Flame permet escalar un component amb alguna cosa com `component.scale = Vector2(2, 2)`, però nosaltres sempre preferim ajustar directament el `size`, perquè és més directe i evita confusions amb les caixes de col·lisió.

La **visibility** no la gestionem amb un booleà de tipus "visible/invisible". Quan volem que una cosa desaparegui (una bala que surt de pantalla, un enemic destruït o una explosió que ja ha acabat l'animació) la traiem del joc amb `removeFromParent()`. L'alternativa `isVisible` existeix en alguns components, però no ens ha calgut utilitzar-la.

El **canvas** no el toquem mai directament, però hi és per sota. Quan `SpriteAnimationComponent` executa el seu `render(Canvas canvas)`, el motor li passa el canvas de Flutter on s'ha de pintar, i la superclasse s'encarrega de dibuixar-hi el frame actiu del sprite.

## 4b4. SpriteComponent, Animation i AnimationGroup

El `SpriteComponent` pur no apareix al codi final. Sí que surt al pas 2 del tutorial, on la nau és encara una imatge estàtica, però al pas 3 ja el substituïm per `SpriteAnimationComponent` i ja no tornem enrere.

L'**animation**, en canvi, és el nucli visual de tot el joc. Cada entitat (jugador, bala, enemic i explosió) carrega la seva animació dins del seu `onLoad()` amb `game.loadSpriteAnimation(...)`, passant-li el nom de l'arxiu i un `SpriteAnimationData.sequenced` que indica quants frames té el sprite sheet, quant dura cada frame i quina mida té cada un. L'explosió, a més, porta `loop: false` perquè la seqüència es reprodueixi una sola vegada i després es destrueixi sola gràcies a `removeOnFinish: true`.

L'**AnimationGroup** (concretament `SpriteAnimationGroupComponent`) no l'hem necessitat. És una classe útil quan un personatge té diverses animacions que s'han d'alternar segons un estat (per exemple, parat, caminant, saltant i atacant), cosa que no passa al nostre joc, on cada entitat té una única animació en bucle.

## 4b5. Generació d'elements

Sí, i de fet és una de les parts més interessants del codi. Utilitzem `SpawnComponent` en dos llocs.

El primer és dins de `Player.onLoad()`, on creem un `_bulletSpawner` que genera una bala cada dos dècimes de segon, però amb `autoStart: false`, de manera que està parat fins que l'activem. L'activem amb `_bulletSpawner.timer.start()` quan el jugador comença a arrossegar el dit, i el parem amb `.stop()` quan deixa de tocar la pantalla. Així el jugador "dispara automàticament" mentre arrossega, sense haver de prémer botons.

El segon és dins de `SpaceShooterGame.onLoad()`, on afegim un altre `SpawnComponent` que genera un enemic cada segon en una franja situada just per sobre del límit superior de la pantalla. D'aquesta manera els enemics apareixen fora del camp visible i baixen progressivament.

## 4b6. Shape, Circle i Arithmetic

De **shape** en fem servir un `Rectangle.fromLTWH(0, 0, size.x, -Enemy.enemySize)` per definir l'àrea on apareixen els enemics, i també `RectangleHitbox` per les caixes de col·lisió de les bales i dels enemics. Formes rectangulars, vaja.

De **circle** no en fem servir cap. Flame ofereix `CircleHitbox` i formes circulars, però com que tots els sprites del nostre joc són rectangulars, encaixa millor una hitbox rectangular i no hem tingut la necessitat de fer servir cercles.

D'**arithmetic**, en canvi, n'hi ha per tot arreu gràcies al tipus `Vector2` que permet operacions vectorials directament. Escrivim coses com `game.size / 2` per centrar la nau, `position + Vector2(0, -height / 2)` per col·locar la bala al morro del jugador, `position.add(delta)` per moure'l seguint el gest del dit i `position.y += dt * 250` per fer baixar l'enemic cada frame. Són operacions senzilles, però bàsiques perquè el joc funcioni.

## 4b7. Comanda per desplegar a GitHub

Per pujar els canvis al repositori la comanda és la habitual: `git add .`, després `git commit -m "missatge"` i finalment `git push origin main`. Això és suficient perquè el codi font estigui al GitHub.

Una altra cosa diferent és publicar la versió web al **GitHub Pages**. En aquest cas primer cal compilar la web amb `flutter build web --base-href "/nom-del-repo/"` (substituint el nom pel del nostre repositori), i després pujar el contingut de `build/web` a una branca `gh-pages`. A Settings → Pages del GitHub s'activa aquesta branca com a origen i al cap d'uns minuts el joc és accessible per URL.

## 4b8. loadingBuilder, backgroundBuilder i OverlayBuilderMap

Aquests tres són paràmetres opcionals del `GameWidget` que **ara mateix no utilitzem**, però que són molt útils. El `loadingBuilder` defineix un widget que es mostra mentre el joc està carregant assets (típicament un `CircularProgressIndicator`); el `backgroundBuilder` és un widget que es pinta darrere del joc (útil si volem un fons de color darrere del canvas de Flame); i l'`overlayBuilderMap` és un diccionari de widgets que podem activar i desactivar dinàmicament cridant `game.overlays.add('Nom')` o `game.overlays.remove('Nom')`, perfecte per menús i pantalles superposades.

Per activar-los canviaríem el `runApp` per alguna cosa així:

```dart
runApp(
  GameWidget<SpaceShooterGame>(
    game: SpaceShooterGame(),
    loadingBuilder: (context) => const Center(child: CircularProgressIndicator()),
    backgroundBuilder: (context) => Container(color: Colors.black),
    overlayBuilderMap: {
      'PauseMenu': (context, game) => const Center(child: Text('PAUSA')),
      'GameOver':  (context, game) => const Center(child: Text('GAME OVER')),
    },
    initialActiveOverlays: const [],
  ),
);
```

## 4b9. Canviar naus i bales per goril·les i plàtans

La manera més senzilla és substituir directament els arxius `assets/images/player.png` i `assets/images/bullet.png` per nous sprite sheets (amb la mateixa mida de frames, perquè si no s'haurien d'ajustar els `textureSize` del codi). Així no cal tocar ni una línia de Dart.

Si preferim una opció més neta amb nous noms de fitxer, podem afegir `gorilla.png` i `banana.png` a la mateixa carpeta i canviar les referències dins dels `onLoad()` corresponents. A `Player.onLoad()` substituiríem `'player.png'` per `'gorilla.png'`, i a `Bullet.onLoad()` canviaríem `'bullet.png'` per `'banana.png'`. Com que el `pubspec.yaml` ja declara la carpeta `assets/images/` sencera, no cal afegir-hi res més.

## 4b10. Canviar el color de fons

La forma més neta és sobreescrivir el mètode `backgroundColor()` dins de `SpaceShooterGame`:

```dart
@override
Color backgroundColor() => const Color(0xFF101030); // blau marí fosc
```

Alternativament podem passar-ho pel `backgroundBuilder` del `GameWidget` (veure 4b8) o col·locar un `RectangleComponent` amb el color desitjat com a primer component afegit al `onLoad()`.

## 4b11. Pausa del joc

Flame ofereix dos mètodes directes a `FlameGame` que podem cridar des de qualsevol lloc: `pauseEngine()` atura tant l'`update` com el `render`, i `resumeEngine()` els torna a activar. No cal tocar el `GameLoop` a mà.

Un exemple típic és combinar-ho amb un overlay. Afegim un mètode `togglePause()` al nostre joc que, si està pausat, truca a `resumeEngine()` i treu l'overlay; i si no ho està, crida `pauseEngine()` i mostra l'overlay de pausa. El pots disparar amb una tecla (`KeyboardEvents`) o amb un botó a la pantalla. Al nostre codi actual encara no tenim pausa implementada, però afegir-la és poca cosa.

## 4b12. Pantalla d'inici, selector de nivell i configuració

Això s'implementa amb el sistema d'overlays que hem comentat al 4b8. La idea és que el joc sempre està actiu per sota, però mentre hi hagi un overlay activ el jugador veu una pantalla de Flutter convencional per sobre.

El primer pas és modificar el `main()` perquè al principi el joc arrenqui amb l'overlay del menú principal activat:

```dart
void main() {
  final game = SpaceShooterGame();
  runApp(
    GameWidget<SpaceShooterGame>(
      game: game,
      initialActiveOverlays: const ['MainMenu'],
      overlayBuilderMap: {
        'MainMenu':    (context, g) => MainMenu(game: g),
        'LevelSelect': (context, g) => LevelSelect(game: g),
        'Settings':    (context, g) => SettingsScreen(game: g),
      },
    ),
  );
}
```

La pantalla d'inici (`MainMenu`) és un widget de Flutter normal amb el títol del joc i botons per jugar, anar a configuració, etc. Quan el jugador prem "Jugar", el widget crida `game.overlays.remove('MainMenu')` i `game.overlays.add('LevelSelect')`, cosa que fa desaparèixer el menú principal i mostra el selector de nivell.

El selector de nivell (`LevelSelect`) mostra tres botons (Fàcil, Mitjà, Difícil). Cadascun crida un mètode del joc com `game.startLevel(n)`, que ajusta la dificultat (per exemple, el `period` del `SpawnComponent` d'enemics: nivell 1 = un enemic cada 1.2 segons, nivell 3 = un cada 0.6 segons) i tanca l'overlay perquè comenci a jugar.

La pantalla de configuració (`SettingsScreen`) és similar: mostra opcions (volum, dificultat per defecte, controls) amb `Slider` o `Switch` de Flutter, i un botó de "Tornar" que treu l'overlay de configuració i torna a mostrar el menú principal.

Un esquelet bàsic del menú principal seria:

```dart
class MainMenu extends StatelessWidget {
  final SpaceShooterGame game;
  const MainMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('SPACE SHOOTER',
                style: TextStyle(color: Colors.white, fontSize: 40)),
            ElevatedButton(
              onPressed: () {
                game.overlays.remove('MainMenu');
                game.overlays.add('LevelSelect');
              },
              child: const Text('Jugar'),
            ),
            ElevatedButton(
              onPressed: () {
                game.overlays.remove('MainMenu');
                game.overlays.add('Settings');
              },
              child: const Text('Configuració'),
            ),
          ],
        ),
      ),
    );
  }
}
```

Les altres dues pantalles segueixen el mateix patró, canviant només el contingut i els botons. Un cop l'estructura d'overlays està muntada, afegir-ne de noves (per exemple una pantalla de "Game Over" o un rànquing) és trivial: només cal declarar-les al `overlayBuilderMap` i cridar `game.overlays.add('NomNou')` quan calgui.
