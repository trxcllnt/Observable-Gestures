package gestures.multitouch
{
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Point;
	
	import raix.reactive.*;
	
	internal class Gesture extends AbsObservable
	{
		public function Gesture(target:IEventDispatcher, stage:Stage)
		{
			this.target = target;
			this.stage = stage;
		}
		
		public var touchActivationCount:int = 1;
		
		protected var target:IEventDispatcher;
		protected var stage:Stage;
		
		protected const activeTouchIDs:Array = [];
		protected const activeTouches:Array = [];
		
		protected function beginObservable():IObservable
		{
			return Observable.fromEvent(target, TouchEvent.TOUCH_BEGIN).
				filter(function(begin:TouchEvent):Boolean {
					return activeTouchIDs.indexOf(begin.touchPointID) == -1;
				}).
				peek(function(begin:TouchEvent):void {
					activeTouches.push(begin);
					activeTouchIDs.push(begin.touchPointID);
				});
//			const faker:IObservable = Observable.defer(function():IObservable {
//				return Observable.fromArray(activeTouches);
//			});
//			
//			const theRealThing:IObservable = Observable.fromEvent(target, TouchEvent.TOUCH_BEGIN).
//				filter(function(begin:TouchEvent):Boolean {
//					return activeTouchIDs.indexOf(begin.touchPointID) == -1;
//				}).
//				peek(function(begin:TouchEvent):void {
//					activeTouches.push(begin);
//					activeTouchIDs.push(begin.touchPointID);
//				});
//			
//			return Observable.ifElse(function():Boolean {
//				return activeTouchIDs.length >= touchActivationCount;
//			}, faker, theRealThing);
		}
		
		protected function moveObservable(index:int):IObservable
		{
			return Observable.fromEvent(stage, TouchEvent.TOUCH_MOVE).
				filter(function(move:TouchEvent):Boolean {
					return move.touchPointID == activeTouchIDs[index];
				}).
				map(function(move:TouchEvent):TouchPoint {
					return TouchPoint.fromEvent(move);
				}).
				scan(function(prev:TouchPoint, point:TouchPoint):TouchPoint {
					point.previous = prev;
					const delta:Point = point.subtract(point.previous);
					point.speed.x = delta.x * 2.5; // magic
					point.speed.y = delta.y * 2.5; // magic
					return point;
				}).
				filter(function(point:TouchPoint):Boolean {
					return point.previous != null;
				});
		}
		
		protected function endObservable():IObservable
		{
			return Observable.fromEvent(stage, TouchEvent.TOUCH_END).
				filter(function(end:TouchEvent):Boolean {
					return activeTouchIDs.indexOf(end.touchPointID) != -1;
				}).
				peek(function(end:TouchEvent):void {
					const i:int = activeTouchIDs.indexOf(end.touchPointID);
					if(i != -1)
					{
						activeTouches.splice(i, 1);
						activeTouchIDs.splice(i, 1);
					}
				});
		}
	}
}
