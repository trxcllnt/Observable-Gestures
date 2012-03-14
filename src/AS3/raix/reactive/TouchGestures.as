/**
 * Copyright (c) 2012 Paul Taylor (guyinthechair.com)
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

package raix.reactive
{
	import com.flashdynamix.motion.Tweensy;
	import com.flashdynamix.motion.TweensyTimeline;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.*;
	
	import gestures.multitouch.ExpandData;
	import gestures.multitouch.TouchPoint;
	
	public class TouchGestures extends GesturesBase
	{
		public static const global:TouchGestures = new TouchGestures();
		public var stage:Stage;
		
		protected const globalCanceleables:Dictionary = new Dictionary(false);
		
		public function register(target:IEventDispatcher):IEventDispatcher
		{
			globalCanceleables[target] ||= [];
			const a:Array = globalCanceleables[target];
			
			if(a.length <= 0)
			{
//				a.push(singleTouchBegin(target).subscribeWith(touchBeginObs));
//				a.push(touchEnd(target).subscribeWith(touchEndObs));
//				a.push(touchMove(target).subscribeWith(touchMoveObs));
			}
			
			return target;
		}
		
		public function unregister(target:IEventDispatcher):IEventDispatcher
		{
			const a:Array = globalCanceleables[target] || [];
			a.forEach(function(subscription:ICancelable, ... args):void {
				subscription.cancel();
			});
			a.length = 0;
			
			delete globalCanceleables[target];
			
			return target;
		}
		
		protected const touchBeginObs:ISubject = new Subject();
		protected const touchEndObs:ISubject = new Subject();
		protected const touchMoveObs:ISubject = new Subject();
		protected const touchOverObs:ISubject = new Subject();
		protected const touchOutObs:ISubject = new Subject();
		protected const touchRollOverObs:ISubject = new Subject();
		protected const touchRollOutObs:ISubject = new Subject();
		protected const touchTapObs:ISubject = new Subject();
		protected const touchHoldObs:ISubject = new Subject();
		
		public function get begin():IObservable
		{
			return touchBeginObs.asObservable();
		}
		
		public function get end():IObservable
		{
			return touchEndObs.asObservable();
		}
		
		public function get move():IObservable
		{
			return touchMoveObs.asObservable();
		}
		
		public function singleTouchBegin(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'singleTouchBegin') ||
				cacheObs(target, 'singleTouchBegin',
						 touchTransaction(target).
						 filter(function(points:Array):Boolean {
							 return points.length == 1;
						 }).
						 map(function(points:Array):TouchPoint {
							 return points[0];
						 }));
		}
		
		public function singleTouchTap(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'singleTouchTap') ||
				cacheObs(target, 'singleTouchTap',
						 Observable.fromEvent(target, TouchEvent.TOUCH_TAP).
						 map(function(tap:TouchEvent):TouchPoint {
							 return new TouchPoint(tap.stageX, tap.stageY, tap.target, tap.touchPointID);
						 }));
		}
		
		public function doubleTouchBegin(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'doubleTouchBegin') ||
				cacheObs(target, 'doubleTouchBegin',
						 touchTransaction(target).
						 filter(function(points:Array):Boolean {
							 return points.length == 2;
						 }));
		}
		
		public function tripleTouchBegin(target:IEventDispatcher):IObservable
		{
			return touchTransaction(target).
				filter(function(points:Array):Boolean {
					return points.length == 3;
				});
		}
		
		public function quadTouchBegin(target:IEventDispatcher):IObservable
		{
			return touchTransaction(target).
				filter(function(points:Array):Boolean {
					return points.length == 4;
				});
		}
		
		public function singleTouchMove(startObject:DisplayObject = null, boundaries:* = null, momentum:Boolean = true):IObservable
		{
			startObject ||= stage;
			boundaries ||= startObject.parent ? startObject.parent.getBounds(stage) : stage.getBounds(stage);
			
			const boundsObs:IObservable = (boundaries is Rectangle) ? Observable.value(boundaries) : IObservable(boundaries);
			
			return Observable.createWithCancelable(function(observer:IObserver):ICancelable {
				
				const composite:CompositeCancelable = new CompositeCancelable();
				
				const beginObservable:IObservable = singleTouchBegin(startObject).
					peek(function(begin:TouchPoint):void {
						var bounds:Rectangle;
						composite.add(boundsObs.subscribe(function(rect:Rectangle):void {
							bounds = rect;
						}));
						
						const moveObservable:IObservable = Observable.fromEvent(stage, TouchEvent.TOUCH_MOVE).
							map(function(move:TouchEvent):TouchPoint {
								return TouchPoint.fromEvent(move);
							}).
							scan(function(a:TouchPoint, b:TouchPoint):TouchPoint {
								const delta:Point = b.subtract(a);
								b.previous = a;
								b.speed.x = delta.x * 2.5;
								b.speed.y = delta.y * 2.5;
								return b;
							}, begin, true).
							takeUntil(Observable.fromEvent(stage, TouchEvent.TOUCH_END).
									  merge(touchTransaction(startObject)));
						
						var lastPoint:TouchPoint = new TouchPoint();
						var timeoutCancelable:ICancelable;
						
						const moveObserver:IObserver = Observer.create(function(point:TouchPoint):void {
							if(timeoutCancelable)
								timeoutCancelable.cancel();
							
							timeoutCancelable = Observable.interval(60).take(1).
								subscribe(null, function():void {
									lastPoint.speed.x = 0;
									lastPoint.speed.y = 0;
								});
							
							lastPoint = point;
							observer.onNext(point);
						},
						function():void {
							if(timeoutCancelable)
							{
								timeoutCancelable.cancel();
							}
							
							if(momentum && lastPoint.speed.length > 0)
							{
								dispatchMomentum(observer, lastPoint, startObject.getBounds(startObject), bounds);
							}
							else
							{
								observer.onCompleted();
							}
						});
						
						composite.add(moveObservable.subscribeWith(moveObserver));
					});
				
				composite.add(beginObservable.publish().connect());
				
				return composite;
			});
		}
		
		public function doubleTouchMove(target:IEventDispatcher):IObservable
		{
			return doubleTouchBegin(target).
				mapMany(function(points:Array):IObservable {
					const moveObsFactory:Function = function(point:TouchPoint):IObservable {
						return touchMove(stage, point).
							filter(function(move:TouchPoint):Boolean {
								return move.id == point.id;
							}).
							takeUntil(touchTransaction(target));
					};
					
					points = points.concat();
					const left:IObservable = moveObsFactory(points.shift());
					const right:IObservable = moveObsFactory(points.shift());
					
					return left.zip(right, function(l:TouchPoint, r:TouchPoint):Array {
						return [l, r];
					});
				});
		}
		
		public function tripleTouchMove(target:IEventDispatcher):IObservable
		{
			return tripleTouchBegin(target).
				mapMany(function(points:Array):IObservable {
					const moveObsFactory:Function = function(point:TouchPoint):IObservable {
						return touchMove(stage, point).
							filter(function(move:TouchPoint):Boolean {
								return move.id == point.id;
							}).
							takeUntil(touchTransaction(target));
					};
					
					points = points.concat();
					const left:IObservable = moveObsFactory(points.shift());
					const middle:IObservable = moveObsFactory(points.shift());
					const right:IObservable = moveObsFactory(points.shift());
					
					return left.combineLatest(middle, function(l:TouchPoint, r:TouchPoint):Array {
						return [l, r];
					}).
					combineLatest(right, function(l:Array, r:TouchPoint):Array {
						return l.concat(r);
					});
				});
		}
		
		public function quadTouchMove(target:IEventDispatcher):IObservable
		{
			return quadTouchBegin(target).
				mapMany(function(points:Array):IObservable {
					const moveObsFactory:Function = function(point:TouchPoint):IObservable {
						return touchMove(stage, point).
							filter(function(move:TouchPoint):Boolean {
								return move.id == point.id;
							}).
							takeUntil(touchTransaction(target));
					};
					
					points = points.concat();
					const leftA:IObservable = moveObsFactory(points.shift());
					const leftB:IObservable = moveObsFactory(points.shift());
					const rightA:IObservable = moveObsFactory(points.shift());
					const rightB:IObservable = moveObsFactory(points.shift());
					
					const left:IObservable = leftA.combineLatest(leftB, function(l:TouchPoint, r:TouchPoint):Array {
						return [l, r];
					});
					
					const right:IObservable = rightA.combineLatest(rightB, function(l:TouchPoint, r:TouchPoint):Array {
						return [l, r];
					});
					
					return left.combineLatest(right, function(l:Array, r:Array):Array {
						return l.concat(r);
					});
				});
		}
		
		public function touchEnd(target:IEventDispatcher):IObservable
		{
			return Observable.fromEvent(target, TouchEvent.TOUCH_END);
		}
		
		public function touchMove(target:IEventDispatcher, firstPoint:TouchPoint = null):IObservable
		{
			return Observable.fromEvent(target, TouchEvent.TOUCH_MOVE).
				map(function(move:TouchEvent):TouchPoint {
					return new TouchPoint(move.stageX, move.stageY, move.target, move.touchPointID);
				}).
				timeInterval().
				scan(function(a:TimeInterval, b:TimeInterval):TimeInterval {
					const p1:TouchPoint = a.value as TouchPoint;
					const p2:TouchPoint = b.value as TouchPoint;
					const delta:Point = p2.subtract(p1);
					p2.previous = p1;
					p2.speed.x = Math.max(Math.min(delta.x / (Math.max(b.interval, 1) / 10), 35), -35);
					p2.speed.y = Math.max(Math.min(delta.y / (Math.max(b.interval, 1) / 10), 35), -35);
					
//					trace(p2.speed.x, (Math.max(b.interval, 1) / 10));
					
					return b;
				}, new TimeInterval(firstPoint, 0), firstPoint != null).
				removeTimeInterval();
		}
		
		public function doublePan(target:IEventDispatcher):IObservable
		{
			return doubleTouchMove(target).
				scan(function(prev:Array, curr:Array):Array {
					if(prev[0] is TouchPoint || prev[1] is TouchPoint)
						return [prev, curr];
					return [prev[1], curr];
				}).
				filter(function(points:Array):Boolean {
					return !(points[0] is TouchPoint || points[1] is TouchPoint);
				}).
				filter(function(both:Array):Boolean {
					const prev:Array = both[0];
					const curr:Array = both[1];
					
					const r1:Point = curr[0].subtract(prev[0]);
					const r2:Point = curr[1].subtract(prev[1]);
					
					if(r1.x == r2.x)
					{
						return (r1.y < 0 && r2.y < 0) || (r1.y > 0 && r2.y > 0);
					}
					else if(r1.y == r2.y)
					{
						return (r1.x < 0 && r2.x < 0) || (r1.x > 0 && r2.x > 0);
					}
					
					return false;
				}).
				map(function(both:Array):Array {
					return both[1];
				});
		}
		
		public function zoom(target:IEventDispatcher):IObservable
		{
			const obs:IObservable = getObs(target, 'zoom');
			
			if(obs)
			{
				return obs;
			}
			
			var start:Array = [];
			
			const terminator:ICancelable = touchTransaction(target).
				subscribe(function(... args):void {
					start.length = 0;
				});
			
			return cacheObs(target, 'zoom',
							doubleTouchMove(target).
							scan(function(both:Array, curr:Array):Array {
								
								if(both.length == 0)
									both = [curr, curr];
								
								if(start.length == 0)
									start = curr.concat();
								
								return [both[1], curr];
							}, [], true).
							filter(function(both:Array):Boolean {
								const prev:Array = both[0];
								const curr:Array = both[1];
								
								const p:Point = prev[0].subtract(prev[1]);
								const c:Point = curr[0].subtract(curr[1]);
								
								return (c.length > p.length);
							}).
							map(function(both:Array):ExpandData {
								const curr:Array = both[1];
								
								const c1:Point = curr[0];
								const c2:Point = curr[1];
								
								const s1:Point = start[0];
								const s2:Point = start[1];
								
								const delta:Number = c1.subtract(c2).subtract(s1.subtract(s2)).length;
								
								return new ExpandData(c1, c2, delta);
							}).
							finallyAction(function():void {
								start = null
								terminator.cancel();
							}))
		}
		
		public function pinch(target:IEventDispatcher):IObservable
		{
			const obs:IObservable = getObs(target, 'pinch');
			
			if(obs)
			{
				return obs;
			}
			
			var start:Array = [];
			
			const terminator:ICancelable = touchTransaction(target).
				subscribe(function(... args):void {
					start.length = 0;
				});
			
			return cacheObs(target, 'pinch',
							doubleTouchMove(target).
							scan(function(both:Array, curr:Array):Array {
								
								if(both.length == 0)
									both = [curr, curr];
								
								if(start.length == 0)
									start = curr.concat();
								
								return [both[1], curr];
							}, [], true).
							filter(function(both:Array):Boolean {
								const prev:Array = both[0];
								const curr:Array = both[1];
								
								const p:Point = prev[0].subtract(prev[1]);
								const c:Point = curr[0].subtract(curr[1]);
								
								return (c.length < p.length);
							}).
							map(function(both:Array):ExpandData {
								const curr:Array = both[1];
								
								const c1:Point = curr[0];
								const c2:Point = curr[1];
								
								const s1:Point = start[0];
								const s2:Point = start[1];
								
								const delta:Number = c1.subtract(c2).subtract(s1.subtract(s2)).length;
								
								return new ExpandData(c1, c2, delta);
							}).
							finallyAction(function():void {
								start = null;
								terminator.cancel();
							}));
		}
		
		protected function touchTransaction(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'beginGenerator') ||
				cacheObs(target, 'beginGenerator',
						 Observable.createWithCancelable(function(observer:IObserver):ICancelable {
							 const composite:CompositeCancelable = new CompositeCancelable();
							 const touchPoints:Array = [];
							 
							 composite.add(Observable.fromEvent(target, TouchEvent.TOUCH_BEGIN).
										   filter(function(begin:TouchEvent):Boolean {
											   return touchPoints.every(function(point:TouchPoint, ... args):Boolean {
												   return point.id != begin.touchPointID;
											   });
										   }).
										   subscribe(function(begin:TouchEvent):void {
											   touchPoints.push(new TouchPoint(begin.stageX, begin.stageY, begin.target as IEventDispatcher, begin.touchPointID));
											   observer.onNext(touchPoints.concat());
										   }));
							 
							 composite.add(Observable.fromEvent(stage, TouchEvent.TOUCH_END).
										   filter(function(end:TouchEvent):Boolean {
											   return touchPoints.some(function(point:TouchPoint, idx:int, ... args):Boolean {
												   return point.id == end.touchPointID;
											   });
										   }).
										   map(function(end:TouchEvent):int {
											   var i:int = -1;
											   touchPoints.some(function(point:TouchPoint, idx:int, ... args):Boolean {
												   i = idx;
												   return point.id == end.touchPointID;
											   });
											   return i;
										   }).
										   subscribe(function(i:int):void {
											   touchPoints.splice(i, 1);
											   observer.onNext(touchPoints.concat());
										   }));
							 
							 return composite;
						 }));
		}
		
		protected function dispatchMomentum(observer:IObserver, start:TouchPoint,
											object:Rectangle, bounds:Rectangle):void
		{
			const speed:Point = start.speed.clone();
			const time:Number = Math.min(speed.length / 100, 0.25);
			const temp:Point = start.clone();
			
			var destination:Point = start.add(speed);
			
			var timeline:TweensyTimeline = Tweensy.to(temp,
													  {x: destination.x, y: destination.y},
													  time);
			const updateObservable:Function = function():void {
				const point:TouchPoint = new TouchPoint();
				point.previous = start.clone() as TouchPoint;
				point.x = temp.x;
				point.y = temp.y;
				start = point;
				observer.onNext(point);
			};
			timeline.onUpdate = updateObservable;
			
			timeline.onComplete = function():void {
				speed.x = NaN;
				speed.y = NaN;
				
				if(object.x < bounds.x)
					speed.x = bounds.x - object.x;
				else if(object.x + object.width > bounds.x + bounds.width)
					speed.x = (bounds.x + bounds.width) - (object.x + object.width);
				if(object.y < bounds.y)
					speed.y = bounds.y - object.y;
				else if(object.y + object.height > bounds.y + bounds.height)
					speed.y = (bounds.y + bounds.height) - (object.y + object.height);
				
				if(speed.x == speed.x || speed.y == speed.y)
				{
					timeline.dispose();
					speed.x ||= 0;
					speed.y ||= 0;
					destination = start.add(speed);
					timeline = Tweensy.to(temp, {x: destination.x, y: destination.y}, time);
					timeline.onUpdate = updateObservable;
					timeline.onComplete = observer.onCompleted;
				}
				else
				{
					observer.onCompleted();
				}
			};
		}
	}
}
