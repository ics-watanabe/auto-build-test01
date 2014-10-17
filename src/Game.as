package
{
	import Box2D.Collision.Shapes.b2CircleShape;
	import Box2D.Collision.Shapes.b2PolygonShape;
	import Box2D.Common.Math.b2Vec2;
	import Box2D.Dynamics.b2Body;
	import Box2D.Dynamics.b2BodyDef;
	import Box2D.Dynamics.b2FixtureDef;
	import Box2D.Dynamics.b2World;
	
	import flash.geom.Point;
	import flash.utils.getTimer;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.extensions.PDParticleSystem;
	import starling.textures.Texture;

	internal class Game extends Sprite
	{

		//----------------------------------------------------------
		//
		//   Static Property 
		//
		//----------------------------------------------------------

		private static const WALL_WIDTH:Number = 350;
		private static const WALL_HEIGHT:Number = 1;
		private static const WALL_LENGTH:Number = 175;
		/** パーティクル(円)の数 */
		private static const PARTICLES_NUM:Number = 12;
		/** Box2Dの縮尺 */
		private static const SCALE:Number = 1 / 30;

		//----------------------------------------------------------
		//
		//   Constructor 
		//
		//----------------------------------------------------------

		public function Game()
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}

		//----------------------------------------------------------
		//
		//   Property 
		//
		//----------------------------------------------------------

		[Embed(source = "assets/bg.png")]
		private var BackgroundImage:Class;

		[Embed(source = "assets/particle.pex", mimeType = "application/octet-stream")]
		private var ParticleData:Class;

		[Embed(source = "assets/texture.png")]
		private var ParticleImage:Class;
		private var bg:Image;

		private var rorationSpeed:Number = 0;
		private var rotationValue:Number = 0;
		private var sh:Number;
		private var sw:Number;
		private var wallParts:Vector.<b2Body> = new Vector.<b2Body>();
		/** Box2D全体を管理するオブジェクト */
		private var world:b2World;

		//----------------------------------------------------------
		//
		//   Function 
		//
		//----------------------------------------------------------

		private function init(e:Event):void
		{
			sw = stage.stageWidth; // ステージの幅
			sh = stage.stageHeight; // ステージの高さ

			// bg
			bg = Image.fromBitmap(new BackgroundImage());
			bg.width = stage.stageWidth;
			bg.height = stage.stageHeight;
			addChild(bg);

			// Box2Dの初期化
			var gravity:b2Vec2 = new b2Vec2(0, 50); // 重力
			world = new b2World(gravity, false);

			// 壁を作成
			addStaticFloor(0, 0, WALL_WIDTH, WALL_HEIGHT); // 上壁
			addStaticFloor(0, 0, WALL_WIDTH, WALL_HEIGHT); // 下壁
			addStaticFloor(0, 0, WALL_WIDTH, WALL_HEIGHT); // 左壁
			addStaticFloor(0, 0, WALL_WIDTH, WALL_HEIGHT); // 右壁

			// ランダムにオブジェクトを配置
			var textureParticle:Texture = Texture.fromBitmap(new ParticleImage());
			for (var i:uint = 0; i < PARTICLES_NUM; i++)
			{
				var nx:Number = (Math.random() - 0.5) * sw / 4 + sw / 2;
				var ny:Number = (Math.random() - 0.5) * sh / 4 + sh / 2;
				addDynamicBox(nx, ny, 12, textureParticle);
			}

			addEventListener(Event.ENTER_FRAME, loop);
		}

		private function loop(event:Event):void
		{
			// 動く壁の計算
			rorationSpeed = 0.05 * Math.cos(getTimer() / 3000);
			rotationValue += rorationSpeed;
			for (var i:int = 0; i < wallParts.length; i++)
			{
				var angleWall:Number = rotationValue + i * Math.PI / 2;
				var pos:Point = Point.polar(WALL_LENGTH, angleWall);

				var wall:b2Body = wallParts[i];
				wall.SetPosition(new b2Vec2((pos.x + sw / 2) * SCALE, (pos.y + sh / 2) * SCALE));
				wall.SetAngle(angleWall + Math.PI / 2);
			}

			// Box2Dを更新
			world.Step(1 / 60, 5, 5);

			// Box2Dの計算結果を描画に反映
			var body:b2Body = world.GetBodyList();
			while (body)
			{
				var obj:DisplayObject = body.GetUserData() as DisplayObject;
				var position:b2Vec2 = body.GetPosition();

				if (obj is Quad)
				{
					// 表示位置を更新
					obj.x = position.x / SCALE;
					obj.y = position.y / SCALE;
					obj.rotation = body.GetAngle();
				}
				else if (obj is PDParticleSystem)
				{
					// パーティクルの発生位置を更新
					PDParticleSystem(obj).emitterX = position.x / SCALE;
					PDParticleSystem(obj).emitterY = position.y / SCALE;
				}
				body = body.GetNext();
			}
		}

		/**
		 * Box2Dの壁を作る関数
		 */
		private function addStaticFloor(nx:Number, ny:Number, w:Number, h:Number):void
		{
			var bodyDef:b2BodyDef = createBodyDef(nx, ny, b2Body.b2_staticBody);
			var image:Quad = new Quad(w, 2);
			image.pivotX = w / 2;
			image.pivotY = 0;
			image.alpha = 0.5;
			bodyDef.userData = image;
			addChild(image);
			var fixtureDef:b2FixtureDef = createFixtureWithPolyShape(w, h);
			fixtureDef.restitution = 1;
			var body:b2Body = world.CreateBody(bodyDef);
			body.CreateFixture(fixtureDef);
			wallParts.push(body);
		}

		/**
		 * Box2Dの動くオブジェクト(矩形)とStarlingのImageオブジェクトを作る関数
		 */
		private function addDynamicBox(nx:Number, ny:Number, radius:Number, texture:Texture):void
		{
			var bodyDef:b2BodyDef = createBodyDef(nx, ny, b2Body.b2_dynamicBody); // Box2Dの動くオブジェクトを作成
			var particles:DisplayObject = createParticlesForBodyDef(bodyDef, texture); // Starlingの表示オブジェクトを作成
			var fixtureDef:b2FixtureDef = createFixtureWithCircleShape(radius);
			fixtureDef.density = 0.5; // 密度
			fixtureDef.friction = 0.1; // 摩擦(0〜1の値で設定、0に近い方が滑りやすい)
			fixtureDef.restitution = 0.9; // 跳ね返り(0〜1の値で設定、1に近い方が跳ね返りやすい)
			var body:b2Body = world.CreateBody(bodyDef);
			body.CreateFixture(fixtureDef);
			addChild(particles);
		}

		private function createBodyDef(nx:Number, ny:Number, type:uint = 0):b2BodyDef
		{
			var bodyDef:b2BodyDef = new b2BodyDef();
			bodyDef.position.Set(nx * SCALE, ny * SCALE);
			bodyDef.type = type;
			return bodyDef;
		}

		private function createParticlesForBodyDef(bodyDef:b2BodyDef, texture:Texture):DisplayObject
		{
			// particles
			var particles:PDParticleSystem = new PDParticleSystem(
				XML(new ParticleData()),
				texture);

			particles.start();
			Starling.juggler.add(particles);

			bodyDef.userData = particles; // Box2DとStarlingのオブジェクトを紐付ける
			return particles;
		}

		/**
		 * Box2Dの矩形を作る関数
		 * @param w	横幅
		 * @param h	高さ
		 * @return 
		 */
		private function createFixtureWithPolyShape(w:Number, h:Number):b2FixtureDef
		{
			var fixtureDef:b2FixtureDef = new b2FixtureDef();
			var shape:b2PolygonShape = new b2PolygonShape();
			shape.SetAsBox(w / 2 * SCALE, h / 2 * SCALE);
			fixtureDef.shape = shape;
			return fixtureDef;
		}

		/**
		 * Box2Dの円を作る関数
		 * @param radius	半径
		 * @return 
		 */
		private function createFixtureWithCircleShape(radius:Number):b2FixtureDef
		{
			var fixtureDef:b2FixtureDef = new b2FixtureDef();
			var shape:b2CircleShape = new b2CircleShape();
			shape.SetRadius(radius * SCALE);
			fixtureDef.shape = shape;
			return fixtureDef;
		}
	}
}
