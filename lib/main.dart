                                                                                                          
import 'package:flame/collisions.dart';                                                                                                          
import 'package:flame/components.dart';                                                                                                   
import 'package:flame/events.dart';                                                                                                          
import 'package:flame/experimental.dart';                                                                                             
import 'package:flame/game.dart';                                                                                                                         
import 'package:flame/input.dart';                                                                                                           
import 'package:flame/parallax.dart';                                                                                                            
import 'package:flutter/material.dart';                                                                                                                   
                                                                                                                                                                                            
// Punto de entrada de la app. Montamos un GameWidget que renderiza el juego.                                                                                                               
void main() {                                                                                                                                                                               
  runApp(GameWidget(game: SpaceShooterGame()));                                                                                                                                             
}                                                                                                                                                                                           
  
// Clase principal del juego.                                                                                                                                                               
// - FlameGame: clase base que gestiona el bucle de juego, cámara y componentes.
// - PanDetector: añade callbacks onPanStart/onPanUpdate/onPanEnd para arrastres.                                                                                                           
// - HasCollisionDetection: activa el sistema de colisiones entre hitboxes.                                                                                                                 
class SpaceShooterGame extends FlameGame                                                                                                                                                    
    with PanDetector, HasCollisionDetection {                                                                                                                                               
  // 'late' porque se asigna dentro de onLoad, no en el constructor.                                                                                                                        
  late Player player;                                                                                                                                                                       
                                                                
  // onLoad se llama una vez al arrancar el juego. Es async porque cargamos imágenes.                                                                                                       
  @override                                                     
  Future<void> onLoad() async {                                                                                                                                                             
    // --- FONDO CON PARALLAX ---                               
    // Tres capas de estrellas que se mueven a distintas velocidades para dar sensación de profundidad.                                                                                     
    final parallax = await loadParallaxComponent(                                                                                                                                           
      [
        ParallaxImageData('stars_0.png'), // Capa más lenta (lejana).                                                                                                                       
        ParallaxImageData('stars_1.png'), // Capa intermedia.                                                                                                                               
        ParallaxImageData('stars_2.png'), // Capa más rápida (cercana).
      ],                                                                                                                                                                                    
      baseVelocity: Vector2(0, -5),              // Velocidad base: sube 5 px/s (eje Y invertido).
      repeat: ImageRepeat.repeat,                // Se repite en bucle al salir de pantalla.                                                                                                
      velocityMultiplierDelta: Vector2(0, 5),    // Cada capa suma 5 a la velocidad de la anterior.                                                                                         
    );                                                                                                                                                                                      
    add(parallax); // Añadimos el fondo al árbol de componentes del juego.                                                                                                                  
                                                                                                                                                                                            
    // --- JUGADOR ---                                          
    player = Player();                                                                                                                                                                      
    add(player);                                                                                                                                                                            
  
    // --- SPAWNER DE ENEMIGOS ---                                                                                                                                                          
    // SpawnComponent crea instancias periódicamente sin tener que gestionar un Timer a mano.
    add(                                                                                                                                                                                    
      SpawnComponent(                                                                                                                                                                       
        // 'factory' recibe un índice (cuántos ha creado) y devuelve el nuevo componente.                                                                                                   
        factory: (index) => Enemy(),                                                                                                                                                        
        // Cada 1 segundo aparece un enemigo.                   
        period: 1,                                                                                                                                                                          
        // 'area' define dónde se colocan. LTWH = left, top, width, height.
        // La altura negativa (-enemySize) coloca el spawn JUSTO encima del borde superior,                                                                                                 
        // así los enemigos aparecen "fuera" y entran desplazándose hacia abajo.                                                                                                            
        area: Rectangle.fromLTWH(0, 0, size.x, -Enemy.enemySize),                                                                                                                           
      ),                                                                                                                                                                                    
    );                                                                                                                                                                                      
  }                                                             

  // Mientras el dedo está arrastrando, movemos al jugador con el delta del gesto.                                                                                                          
  @override
  void onPanUpdate(DragUpdateInfo info) => player.move(info.delta.global);                                                                                                                  
                                                                                                                                                                                            
  // Al iniciar el arrastre empezamos a disparar.
  @override                                                                                                                                                                                 
  void onPanStart(DragStartInfo info) => player.startShooting();                                                                                                                            
  
  // Al soltar el dedo paramos de disparar.                                                                                                                                                 
  @override                                                     
  void onPanEnd(DragEndInfo info) => player.stopShooting();                                                                                                                                 
}
                                                                                                                                                                                            
// Nave del jugador.                                            
// - SpriteAnimationComponent: componente con animación por sprite sheet.
// - HasGameReference<SpaceShooterGame>: expone 'game' tipado para acceder al juego padre.                                                                                                  
class Player extends SpriteAnimationComponent                                                                                                                                               
    with HasGameReference<SpaceShooterGame> {                                                                                                                                               
  // Tamaño de la nave en pantalla (100x150 px) y ancla en el centro para facilitar el posicionamiento.                                                                                     
  Player() : super(size: Vector2(100, 150), anchor: Anchor.center);                                                                                                                         
                                                                                                                                                                                            
  // Spawner de balas. 'late final' = se asigna una sola vez en onLoad y luego es inmutable.                                                                                                
  late final SpawnComponent _bulletSpawner;                                                                                                                                                 
                                                                                                                                                                                            
  @override                                                     
  Future<void> onLoad() async {
    await super.onLoad();
                                                                                                                                                                                            
    // Carga del sprite sheet del jugador: 4 frames de 32x48 px con 0.2s por frame.                                                                                                         
    animation = await game.loadSpriteAnimation(                                                                                                                                             
      'player.png',                                                                                                                                                                         
      SpriteAnimationData.sequenced(                            
        amount: 4,                     // Número de frames.                                                                                                                                 
        stepTime: 0.2,                 // Duración de cada frame (segundos).
        textureSize: Vector2(32, 48),  // Tamaño de cada frame dentro del sheet.                                                                                                            
      ),                                                                                                                                                                                    
    );                                                                                                                                                                                      
                                                                                                                                                                                            
    // Centramos la nave en la pantalla al empezar.             
    position = game.size / 2;
                                                                                                                                                                                            
    // Configuramos el spawner de balas pero NO lo arrancamos todavía.
    _bulletSpawner = SpawnComponent(                                                                                                                                                        
      period: 0.2,          // Una bala cada 0.2s mientras está activo.                                                                                                                     
      selfPositioning: true, // Desactiva el auto-posicionado por 'area'; posición la marca la factory.                                                                                     
      factory: (index) => Bullet(                                                                                                                                                           
        // La bala sale desde el morro de la nave (parte superior, por eso -height/2).                                                                                                      
        position: position + Vector2(0, -height / 2),                                                                                                                                       
      ),                                                        
      autoStart: false,     // No empieza a disparar solo; lo controlamos con start/stop.                                                                                                   
    );                                                                                                                                                                                      
    // Importante: lo añadimos al juego, no al jugador, para que viva independiente.                                                                                                        
    game.add(_bulletSpawner);                                                                                                                                                               
  }                                                             
                                                                                                                                                                                            
  // Movimiento: sumar el delta del gesto a la posición actual.                                                                                                                             
  void move(Vector2 delta) => position.add(delta);
                                                                                                                                                                                            
  // Arranca y para el timer interno del spawner.                                                                                                                                           
  void startShooting() => _bulletSpawner.timer.start();
  void stopShooting() => _bulletSpawner.timer.stop();                                                                                                                                       
}                                                               
                                                                                                                                                                                            
// Proyectil disparado por el jugador.                                                                                                                                                      
class Bullet extends SpriteAnimationComponent
    with HasGameReference<SpaceShooterGame> {                                                                                                                                               
  // Posición inicial pasada por el spawner (super.position redirige al constructor padre).
  Bullet({super.position})                                                                                                                                                                  
      : super(size: Vector2(25, 50), anchor: Anchor.center);
                                                                                                                                                                                            
  @override                                                                                                                                                                                 
  Future<void> onLoad() async {
    await super.onLoad();                                                                                                                                                                   
                                                                
    // Animación de la bala: 4 frames de 8x16 px.                                                                                                                                           
    animation = await game.loadSpriteAnimation(
      'bullet.png',                                                                                                                                                                         
      SpriteAnimationData.sequenced(                            
        amount: 4,
        stepTime: 0.2,
        textureSize: Vector2(8, 16),                                                                                                                                                        
      ),
    );                                                                                                                                                                                      
                                                                
    // Hitbox pasivo: no inicia comprobaciones, solo responde cuando alguien activo                                                                                                         
    // (el enemigo) lo comprueba. Es más eficiente cuando hay muchas balas.
    add(RectangleHitbox(collisionType: CollisionType.passive));                                                                                                                             
  }                                                                                                                                                                                         
                                                                                                                                                                                            
  // update se ejecuta cada frame; 'dt' = segundos desde el frame anterior.                                                                                                                 
  @override                                                     
  void update(double dt) {                                                                                                                                                                  
    super.update(dt);                                           
    // Velocidad de 500 px/s hacia arriba (en Flame, Y negativo = arriba).
    position.y += dt * -500;                                                                                                                                                                
    // Si la bala ya salió por el borde superior, la eliminamos para liberar memoria.
    if (position.y < -height) removeFromParent();                                                                                                                                           
  }                                                                                                                                                                                         
}                                                                                                                                                                                           
                                                                                                                                                                                            
// Enemigo que cae desde arriba.                                
class Enemy extends SpriteAnimationComponent
    with HasGameReference<SpaceShooterGame>, CollisionCallbacks {                                                                                                                           
  // Posición la fija el SpawnComponent al crearlo.
  Enemy({super.position})                                                                                                                                                                   
      : super(size: Vector2.all(enemySize), anchor: Anchor.center);                                                                                                                         
                                                                                                                                                                                            
  // Tamaño cuadrado constante para reutilizar al calcular el área de spawn.                                                                                                                
  static const enemySize = 50.0;                                
                                                                                                                                                                                            
  @override                                                     
  Future<void> onLoad() async {
    await super.onLoad();                                                                                                                                                                   
  
    // Sheet del enemigo: 4 frames de 16x16 px escalados a 50x50.                                                                                                                           
    animation = await game.loadSpriteAnimation(                 
      'enemy.png',                                                                                                                                                                          
      SpriteAnimationData.sequenced(                                                                                                                                                        
        amount: 4,
        stepTime: 0.2,                                                                                                                                                                      
        textureSize: Vector2.all(16),                           
      ),
    );                                                                                                                                                                                      
  
    // Hitbox activo (valor por defecto): comprueba choques contra hitboxes activos y pasivos.                                                                                              
    add(RectangleHitbox());                                     
  }                                                                                                                                                                                         
                                                                
  @override                                                                                                                                                                                 
  void update(double dt) {                                      
    super.update(dt);
    // Baja a 250 px/s.
    position.y += dt * 250;                                                                                                                                                                 
    // Si se sale por abajo, lo descartamos.
    if (position.y > game.size.y) removeFromParent();                                                                                                                                       
  }                                                             
                                                                                                                                                                                            
  // Se llama automáticamente en el primer frame de contacto con otro hitbox.                                                                                                               
  @override
  void onCollisionStart(                                                                                                                                                                    
    Set<Vector2> intersectionPoints, // Puntos exactos donde se tocaron las figuras.
    PositionComponent other,         // El otro componente implicado.                                                                                                                       
  ) {                                                                                                                                                                                       
    super.onCollisionStart(intersectionPoints, other);                                                                                                                                      
    // Solo reaccionamos si el otro es una bala.                                                                                                                                            
    if (other is Bullet) {                                                                                                                                                                  
      removeFromParent();                       // Muere el enemigo.                                                                                                                        
      other.removeFromParent();                 // Muere la bala.                                                                                                                           
      game.add(Explosion(position: position));  // Explosión en el punto del impacto.                                                                                                       
    }                                                                                                                                                                                       
  }                                                                                                                                                                                         
}                                                                                                                                                                                           
                                                                
// Animación de explosión de "un solo uso".                                                                                                                                                 
class Explosion extends SpriteAnimationComponent
    with HasGameReference<SpaceShooterGame> {                                                                                                                                               
  Explosion({super.position})                                                                                                                                                               
      : super(
          size: Vector2.all(150),     // Explosión bastante grande para que se note.                                                                                                        
          anchor: Anchor.center,      // Centrada sobre el punto del impacto.                                                                                                               
          removeOnFinish: true,       // Al terminar la animación, se autodestruye.                                                                                                         
        );                                                                                                                                                                                  
                                                                                                                                                                                            
  @override                                                     
  Future<void> onLoad() async {
    await super.onLoad();                                                                                                                                                                   
  
    // 6 frames de 32x32 px, rápidos (0.1s) y SIN loop para que solo suene una vez.                                                                                                         
    animation = await game.loadSpriteAnimation(                 
      'explosion.png',                                                                                                                                                                      
      SpriteAnimationData.sequenced(                            
        amount: 6,
        stepTime: 0.1,                                                                                                                                                                      
        textureSize: Vector2.all(32),
        loop: false,                                                                                                                                                                        
      ),                                                      
    );
  }
}
