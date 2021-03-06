﻿package  {
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	import com.gskinner.utils.Rndm;
	import flash.geom.ColorTransform;
	
	public class Level {
		
		public static const COLORS:Array = [0x151729, 0x343857, 0x555976, 0x818396, 0x9fa9b3, 0xbfc9cd];

		[Embed(source = "graphics/tiles.png")]
		private static const TILES_CLASS:Class;
		private static var _tiles:BitmapData;
		public static function get tiles():BitmapData {
			if (!_tiles) {
				_tiles = (new TILES_CLASS()).bitmapData;
			}
			return _tiles;
		}
		[Embed(source = "graphics/misc.png")]
		private static const MISC_CLASS:Class;
		private static var _misc:BitmapData;
		public static function get misc():BitmapData {
			if (!_misc) {
				_misc = (new MISC_CLASS()).bitmapData;
			}
			return _misc;
		}

		public static const GRID_SIZE:int = 20;
		
		public var camX:Number = 0;
		public var camY:Number = 0;
		public var desiredCamX:Number = 0;
		public var desiredCamY:Number = 0;
		public function get xOffset():int {
			return Math.floor(camX - Main.WIDTH / 2);
		}
		public function get yOffset():int {
			return Math.floor(camY - Main.WIDTH / 2);
		}

		public var screenShakeCount:int = 0;
		public var screenShakeAmt:int = 0;

		public var colorTransform:ColorTransform;
		
		public var player:Player;

		// 2D array of pieces
		public var pieces:Array;
		public var piecesLeft:int = 0;
		public var piecesTop:int = 0;
		public var piecesWidth:int = 1;
		public var piecesHeight:int = 1;

		// ========================= THINGS AND THE ACTIVE THING AND SUCH =========================
		public var things:Array;
		private var _activeIndex:int = 0;

		public function get activeIndex():int {
			return _activeIndex;
		}

		public function set activeIndex(value:int):void {
			if (activeThing) {
				activeThing.active = false;
			}
			_activeIndex = value % things.length;
			if (_activeIndex < 0) _activeIndex += things.length;
			activeThing.active = true;
		}

		public function get activeThing():Thing {
			if (activeIndex > things.length) {
				return null;
			}
			return things[activeIndex];
		};

		public function set activeThing(value:Thing):void {
			// better not be -1 you jerk
			activeIndex = things.indexOf(value);
		}

		// ========================= MISC THINGS =========================

		public var mouseOverred:Thing = null;

		public var batteryIcon:BatteryIcon;
		public var pointsDisplay:TextBox;
		public var hoverText:TextBox;

		public var title:Title;
		public var howTo:HowTo;
		public var buyPage:BuyPage;

		// ========================= STATE =========================

		private var _points:int = 0;
		public function get points():int {
			return _points;
		}
		public function set points(value:int):void {
			_points = value;
			if (pointsDisplay) {
				pointsDisplay.textField.text = value.toString();
			} 
		}
		public var totalPoints:int = 0;
		
		public var count:int = 0;
		public var state:int = STATE_TITLE;

		public static const STATE_TITLE:int = 0;
		public static const STATE_MOVE:int = 1;
		public static const STATE_ANIM:int = 2;
		public static const STATE_HOWTO:int = 3;
		public static const STATE_BUYING:int = 4;

		// ========================= CONSTRUCTOR AND FUNCTIONS =========================

		public function Level() {
			batteryIcon = new BatteryIcon();
			pointsDisplay = new TextBox("nokia", COLORS[1], 16, "right");
			pointsDisplay.x = 0;
			pointsDisplay.y = 0;
			pointsDisplay.textField.text = "0";

			hoverText = new TextBox("m3x6", COLORS[4], 16);
			hoverText.textField.width += 2;
			hoverText.setBg(COLORS[0], 0.4);

			title = new Title();
			howTo = new HowTo();
			buyPage = new BuyPage(this);
			
			regen();
		}

		public function regen():void {
			points = 0;
			things = [];

			colorTransform = null

			piecesLeft = 0;
			piecesTop = 0;
			piecesHeight = 1;
			piecesWidth = 1;
			pieces = [[null]];
			addLevelPiece(0, 0);
			getPieceAtPieceCoord(0, 0).addSurroundingPieces();

			var oldPlayer:Player = player;
			player = new Player(this);
			if (oldPlayer) {
				player.moves = oldPlayer.moves;
				player.renderOffset = oldPlayer.renderOffset;
			}

			var playerX:int = 0;
			var playerY:int = 0;
			do {
				playerX = Rndm.integer(LevelPiece.WIDTH);
				playerY = Rndm.integer(LevelPiece.HEIGHT);
			}
			while (!validSquare(playerX, playerY));
			addThingAt(player, playerX, playerY);
			activeThing = player;
			
			batteryIcon.player = player;
		}

		public function addLevelPiece(x:int, y:int):void {
			var row:*;
			var newRow:Array;
			var i:int;

			while (x < piecesLeft) {
				// Add left column
				for each (row in pieces) {
					row.unshift(null);
				}
				piecesLeft --;
			}
			while (x >= piecesLeft + piecesWidth) {
				// Add right column
				for each (row in pieces) {
					row.push(null);
				}
				piecesWidth ++;
			}

			while (y < piecesTop) {
				// Add top row
				newRow = [];
				for (i = 0; i < piecesWidth; i ++) {
					newRow.push(null);
				}
				pieces.unshift(newRow);
				piecesTop --;
			}
			while (y >= piecesTop + piecesHeight) {
				// Add bottom row
				newRow = [];
				for (i = 0; i < piecesWidth; i ++) {
					newRow.push(null);
				}
				pieces.push(newRow);
				piecesHeight ++;
			}

			// TODO: Set this properly?
			pieces[y - piecesTop][x - piecesLeft] = new LevelPiece(this, x, y);
			pieces[y - piecesTop][x - piecesLeft].addThings();
		}

		public function getPieceAtPieceCoord(x:int, y:int):LevelPiece {
			if (x < piecesLeft || y < piecesTop || x >= piecesLeft + piecesWidth || y >= piecesTop + piecesHeight) {
				return null;
			}
			return pieces[y - piecesTop][x - piecesLeft];
		}

		public function getPieceAtGridCoord(x:int, y:int):LevelPiece {
			var pieceX:int = Math.floor(x / LevelPiece.WIDTH);
			var pieceY:int = Math.floor(y / LevelPiece.HEIGHT);

			return getPieceAtPieceCoord(pieceX, pieceY);
		}

		public function getTileAt(x:int, y:int):int {
			var piece:LevelPiece = getPieceAtGridCoord(x, y);
			if (piece == null) {
				return 0;
			}

			var relX:int = Util.absMod(x, LevelPiece.WIDTH);
			var relY:int = Util.absMod(y, LevelPiece.HEIGHT);

			return piece.map[relY][relX];
		}

		public function getThingAt(x:int, y:int):Thing {
			var piece:LevelPiece = getPieceAtGridCoord(x, y);
			if (piece == null) {
				return null;
			}

			var relX:int = Util.absMod(x, LevelPiece.WIDTH);
			var relY:int = Util.absMod(y, LevelPiece.HEIGHT);

			return piece.thingMap[relY][relX];
		}

		public function addThingAt(thing:Thing, x:int, y:int):void {
			setThingAt(thing, x, y);
			things.push(thing);
		}

		public function setThingAt(thing:Thing, x:int, y:int, clearOld:Boolean = true):void {
			if (clearOld) {
				var existingThing:Thing = getThingAt(x, y);
				if (existingThing && existingThing !== thing) {
					removeThing(existingThing);
				}
			}

			var piece:LevelPiece = getPieceAtGridCoord(x, y);
			if (piece == null) {
				return;
			}

			var relX:int = Util.absMod(x, LevelPiece.WIDTH);
			var relY:int = Util.absMod(y, LevelPiece.HEIGHT);
			piece.thingMap[relY][relX] = thing;
			if (thing) {
				thing.x = x;
				thing.y = y;
			}
		}

		public function removeThing(thing:Thing):void {
			thing.dead = true;
			var index:int = things.indexOf(thing);
			if (things[index] === player) {
			}
			if (activeIndex == index) {
				activeIndex --;
			}
			things.splice(index, 1);
			if (activeIndex > index) {
				_activeIndex --;
			}

			if (thing === player) {
				SoundManager.setSong("bitcrush");
				colorTransform = new ColorTransform(0.6, 0.6, 0.7);
			}
 		}

		
		public function validSquare(x:int, y:int):Boolean {
			return !!getTileAt(x, y);
		}

		// really just has anything but player
		public function hasEnemy(x:int, y:int, ignore:Array = null):Boolean {
			if (ignore == null) ignore = [];

			var thing:Thing = getThingAt(x, y);
			for each (var ignoreThing:* in ignore) {
				if (thing == ignoreThing) {
					return false;
				}
			}
			return !!thing;
		}

		public function update():void {
			var thing:*;
			count ++;
			switch (state) {
				case STATE_TITLE:
					// nothing?
					break;
				case STATE_MOVE:
					// pick ya move
					if (activeThing === player && !player.dead) {
						// wait for the player to pick a move
					}
					else {
						for (var i:int = 0; i < Math.ceil(things.length / 4); i ++) {
							if (activeThing !== player) {
								activeThing.startMoveAnim();
							}
							activeIndex ++;
							count = 0;

							if (activeThing === player && !player.dead) {
								state = STATE_ANIM;
								break;
							}
						}
					}
					break;
				case STATE_ANIM:
					var somethingAnimating:Boolean = false;
					for each (thing in things) {
						if (thing.animating) {
							somethingAnimating = true;
							break;
						}
					}
					if (!somethingAnimating) {
						state = STATE_MOVE;
					}
					break;
				case STATE_BUYING:
					buyPage.update();
					break;
			}

			for each (thing in things) {
				thing.update();
			}

			screenShakeCount --;
			if (screenShakeCount < 0) {
				screenShakeCount = 0;
				screenShakeAmt = 0;
			}

			desiredCamX = player.centerX;
			desiredCamY = player.centerY;
			
			// update cam
			camX += (desiredCamX - camX) / 10;
			camY += (desiredCamY - camY) / 10;
		}

		// ========================= (MOUSE) INPUT =========================

		public function onMouseDown(x:Number, y:Number):void {
			var localX:int = x + xOffset;
			var localY:int = y + yOffset;

			var gridX:int = Math.floor(localX / GRID_SIZE);
			var gridY:int = Math.floor(localY / GRID_SIZE);

			switch (state) {
				case STATE_TITLE:
					state = STATE_HOWTO;
					break;
				case STATE_HOWTO:
					state = STATE_MOVE;
					SoundManager.setSong("song");
					break;
				case STATE_BUYING:
					buyPage.onMouseDown(x, y);
					break;
				case STATE_MOVE:
					if (player.dead) {
						goToStore();
					}
					else if (activeThing == player && player.canMoveTo(gridX, gridY)) {
						// move player
						player.startMoveAnim({x: gridX - player.x, y: gridY - player.y});
						getPieceAtGridCoord(gridX, gridY).addSurroundingPieces();
						state = STATE_ANIM;
					}
					break;
			}
		}

		public function goToStore():void {
			buyPage.start();
			totalPoints += points;
			state = STATE_BUYING;
		}

		public function onMouseMove(x:Number, y:Number):void {
			switch (state) {
				case STATE_BUYING:
					buyPage.onMouseMove(x, y);
					break;
				default:
					if (mouseOverred) {
						mouseOverred.showMoves = false;
					}
					mouseOverred = null;
					
					var localX:int = x + xOffset;
					var localY:int = y + yOffset;

					var gridX:int = Math.floor(localX / GRID_SIZE);
					var gridY:int = Math.floor(localY / GRID_SIZE);

					var thing:Thing = getThingAt(gridX, gridY);
					if (thing) {
						mouseOverred = thing;
						mouseOverred.showMoves = true;

					}


					if (mouseOverred && mouseOverred.name) {
						hoverText.textField.text = mouseOverred.name + "\n" + mouseOverred.description;
						hoverText.redrawBg();
						hoverText.y = Main.HEIGHT - hoverText.textField.height;
					}
					else {
						hoverText.textField.text = "";
						hoverText.clearBg();
					}
					break;
			}
		}

		// ========================= RENDERING =========================

		public function render(context:BitmapData):void {
			context.fillRect(context.rect, COLORS[0]);

			switch (state) {
				case STATE_TITLE:
					title.render(context);
					break;
				case STATE_HOWTO:
					howTo.render(context);
					break;
				case STATE_BUYING:
					buyPage.render(context);
					break;
				default:
					var xOffset:int = this.xOffset;
					var yOffset:int = this.yOffset;

					if (Main.screenShake) {
						xOffset += Rndm.integer(-screenShakeAmt, screenShakeAmt+1);
						yOffset += Rndm.integer(-screenShakeAmt, screenShakeAmt+1);
					}

					renderBg(context, xOffset, yOffset);
					renderThings(context, xOffset, yOffset);
					renderMoves(context, xOffset, yOffset);
					
					batteryIcon.render(context);
					pointsDisplay.render(context);

					if (mouseOverred) {
						hoverText.render(context);
					}

					if (colorTransform) {
						context.draw(context, null, colorTransform);
					}
					break;
			}
		}
		
		public function renderThings(context:BitmapData, xOffset:int = 0, yOffset:int = 0):void {
			for each (var thing:* in things) {
				thing.render(context, xOffset, yOffset);
			}
		}
		
		public function renderMoves(context:BitmapData, xOffset:int = 0, yOffset:int = 0):void {
			for each (var thing:* in things) {
				thing.maybeRenderMoves(context, xOffset, yOffset);
			}
		}
		
		public function renderBg(context:BitmapData, xOffset:int = 0, yOffset:int = 0):void {
			var rect:Rectangle = new Rectangle(0, 0, 20, 23);
			var point:Point = new Point();

			for (var y:int = piecesTop * LevelPiece.HEIGHT; y < (piecesTop + piecesHeight) * LevelPiece.HEIGHT; y ++) {
				point.y = y * GRID_SIZE - yOffset;
				for (var x:int = piecesLeft * LevelPiece.WIDTH; x < (piecesLeft + piecesWidth) * LevelPiece.WIDTH; x ++) {
					point.x = x * GRID_SIZE - xOffset;

					if (getTileAt(x, y)) {
						if (getTileAt(x, y+1)) {
							rect.x = 0 * rect.width;
							rect.y = 0 * rect.height;
						}
						else {
							rect.x = 1 * rect.width;
							rect.y = 0 * rect.height;
						}
						context.copyPixels(tiles, rect, point, null, null, true);
					}
				}
			}
		}


	}
	
}
