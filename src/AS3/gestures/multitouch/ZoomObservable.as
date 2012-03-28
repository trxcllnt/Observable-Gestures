package gestures.multitouch
{
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	
	import raix.reactive.*;
	
	public class ZoomObservable extends Gesture
	{
		public function ZoomObservable(target:IEventDispatcher, stage:Stage)
		{
			super(target, stage);
			touchActivationCount = 2;
		}
		
		override public function subscribeWith(observer:IObserver):ICancelable
		{
			const cancelable:CompositeCancelable = new CompositeCancelable();
			
			return beginObservable().
				filter(function(... args):Boolean {
					return activeTouches.length == touchActivationCount;
				}).
				mapMany(function(... args):IObservable {
					return moveObservable(0).
						zip(moveObservable(1), function(... args):Array {
							return args;
						});
				}).
				filter(function(points:Array):Boolean {
					points = points.concat();
					const r:TouchPoint = points.pop();
					const l:TouchPoint = points.pop();
					return l.subtract(r).length > l.previous.subtract(r.previous).length;
				}).
				map(function(points:Array):ScaleGestureVO {
					return new ScaleGestureVO(points.shift(), points.shift());
				}).
				takeUntil(endObservable().
						  peek(function(... args):void {
							  activeTouches.length = 0;
							  activeTouchIDs.length = 0;
						  })).
						  subscribeWith(observer);
		}
	}
}
