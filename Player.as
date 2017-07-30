﻿package  {
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	
	public class Player extends Thing {

		[Embed(source = "graphics/spritesheet.png")]
		private static const IMAGE_CLASS:Class;
		private static var _image:BitmapData;
		public static function get image():BitmapData {
			if (!_image) {
				_image = (new IMAGE_CLASS()).bitmapData;
			}
			return _image;
		}

		public function Player(level:Level) {
			super(level);

			power = 4;

			renderOffset = 0;

			moves = [
				{x:  0, y:  0},

				{x: -1, y:  0},
				{x:  1, y:  0},
				{x:  0, y: -1},
				{x:  0, y:  1},

				{x: -2, y:  0},
				{x:  2, y:  0},
				{x:  0, y: -2},
				{x:  0, y:  2},
			]

			name = null;
			description = null;
		}

		public override function doMove():void {
			// assume this move is ok
			if (x != prevX || y != prevY) {
				power --;
			}
			var thing:Thing = replacingThing;
			if (thing && thing !== this) {
				power = 4;
				level.points ++;
			}
			level.activeIndex ++;
			super.doMove();
		}

		public override function maybeRenderMoves(context:BitmapData, xOffset:int = 0, yOffset:int = 0):void {
			if (active || showMoves) {
				renderMoves(context, xOffset, yOffset);
			}
		}

		public override function renderMoves(context:BitmapData, xOffset:int = 0, yOffset:int = 0):void {
			var rect:Rectangle = new Rectangle(0, 0, 20, 20);
			var point:Point = new Point();
			for each (var move:* in moves) {
				if (level.validSquare(x + move.x, y + move.y)) {
					point.x = (x + move.x) * Level.GRID_SIZE - xOffset;
					point.y = (y + move.y) * Level.GRID_SIZE - yOffset;
					context.copyPixels(Level.misc, rect, point, null, null, true);
				}
			}
		}

	}
	
}
