package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;

	import starling.core.Starling;

	[SWF(frameRate = "60", width = "720", height = "480", backgroundColor = "#000000")]
	public class Main extends Sprite
	{

		//----------------------------------------------------------
		//
		//   Constructor 
		//
		//----------------------------------------------------------

		public function Main()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			var mStarling:Starling = new Starling(Game, stage);
			mStarling.antiAliasing = 4;
			mStarling.showStats = true;
			mStarling.start();
		}
	}
}
