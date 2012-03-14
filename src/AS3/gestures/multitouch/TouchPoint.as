package gestures.multitouch
{
	import flash.events.IEventDispatcher;
	import flash.events.TouchEvent;
	import flash.geom.Point;
	
	public class TouchPoint extends Point
	{
		public function TouchPoint(x:Number = 0, y:Number = 0, target:Object = null, id:int = 0)
		{
			super(x, y);
			i = id;
			t = target as IEventDispatcher;
		}
		
		public var previous:TouchPoint;
		public const speed:Point = new Point();
		
		private var i:int;
		public function get id():int
		{
			return i;
		}
		
		private var t:IEventDispatcher;
		public function get target():IEventDispatcher
		{
			return t;
		}
		
		override public function clone():Point
		{
			const tp:TouchPoint = new TouchPoint(x, y, t, i);
			tp.previous = previous;
			tp.speed.x = speed.x;
			tp.speed.y = speed.y;
			return tp;
		}
		
		public static function fromEvent(touch:TouchEvent):TouchPoint
		{
			return new TouchPoint(touch.stageX, touch.stageY, touch.target, touch.touchPointID);
		}
	}
}
