package gestures.multitouch
{
	import flash.display.Stage;
	import flash.events.IEventDispatcher;
	
	import raix.reactive.*;
	
	public class PanObservable extends Gesture
	{
		public function PanObservable(target:IEventDispatcher, stage:Stage)
		{
			super(target, stage);
		}
		
		override public function subscribeWith(observer:IObserver):ICancelable
		{
			return beginObservable().
				mapMany(function(... args):IObservable {
					return moveObservable(0);
				}).
				filter(function(... args):Boolean {
					return activeTouches.length == touchActivationCount;
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
