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
	import flash.events.*;
	import flash.utils.*;
	
	public class MouseGestures extends GesturesBase
	{
		public static const global:MouseGestures = new MouseGestures();
		
		protected const globalCanceleables:Dictionary = new Dictionary(false);
		
		public function register(target:IEventDispatcher):IEventDispatcher
		{
			globalCanceleables[target] ||= [];
			const a:Array = globalCanceleables[target];
			
			if(a.length <= 0)
			{
				a.push(mouseUp(target).subscribeWith(upObs));
				a.push(mouseOver(target).subscribeWith(overObs));
				a.push(mouseOut(target).subscribeWith(outObs));
				a.push(mouseRollOver(target).subscribeWith(rollOverObs));
				a.push(mouseRollOut(target).subscribeWith(rollOutObs));
				a.push(mouseMove(target).subscribeWith(moveObs));
				
				a.push(mouseDown(target).subscribeWith(downObs));
				a.push(mouseDoubleDown(target).subscribeWith(doubleDownObs));
				a.push(mouseTripleDown(target).subscribeWith(tripleDownObs));
				
				a.push(mouseClick(target).subscribeWith(clickObs));
				a.push(mouseDoubleClick(target).subscribeWith(doubleClickObs));
				
				a.push(mouseDrag(target).subscribeWith(dragObs));
				a.push(mouseDoubleDrag(target).subscribeWith(doubleDragObs));
				a.push(mouseTripleDrag(target).subscribeWith(tripleDragObs));
				
				a.push(mouseWheel(target).subscribeWith(wheelObs));
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
		
		protected const upObs:ISubject = new Subject();
		protected const overObs:ISubject = new Subject();
		protected const outObs:ISubject = new Subject();
		protected const rollOverObs:ISubject = new Subject();
		protected const rollOutObs:ISubject = new Subject();
		protected const moveObs:ISubject = new Subject();
		protected const clickObs:ISubject = new Subject();
		protected const downObs:ISubject = new Subject();
		protected const doubleClickObs:ISubject = new Subject();
		protected const doubleDownObs:ISubject = new Subject();
		protected const tripleDownObs:ISubject = new Subject();
		protected const dragObs:ISubject = new Subject();
		protected const doubleDragObs:ISubject = new Subject();
		protected const tripleDragObs:ISubject = new Subject();
		protected const wheelObs:ISubject = new Subject();
		
		public function get up():IObservable
		{
			return upObs.asObservable();
		}
		
		public function get over():IObservable
		{
			return overObs.asObservable();
		}
		
		public function get out():IObservable
		{
			return outObs.asObservable();
		}
		
		public function get rollOver():IObservable
		{
			return rollOverObs.asObservable();
		}
		
		public function get rollOut():IObservable
		{
			return rollOutObs.asObservable();
		}
		
		public function get move():IObservable
		{
			return moveObs.asObservable();
		}
		
		public function get down():IObservable
		{
			return downObs.asObservable();
		}
		
		public function get doubleDown():IObservable
		{
			return doubleDownObs.asObservable();
		}
		
		public function get tripleDown():IObservable
		{
			return tripleDownObs.asObservable();
		}
		
		public function get click():IObservable
		{
			return clickObs.asObservable();
		}
		
		public function get doubleClick():IObservable
		{
			return doubleClickObs.asObservable();
		}
		
		public function get drag():IObservable
		{
			return dragObs.asObservable();
		}
		
		public function get doubleDrag():IObservable
		{
			return doubleDragObs.asObservable();
		}
		
		public function get tripleDrag():IObservable
		{
			return tripleDragObs.asObservable();
		}
		
		public function get wheel():IObservable
		{
			return wheelObs.asObservable();
		}
		
		public function mouseUp(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'up') ||
				cacheObs(target,
						 Observable.
						 fromEvent(target, MouseEvent.MOUSE_UP).
						 peek(function(event:Event):void {event.stopPropagation();}),
						 'up');
		}
		
		public function mouseOver(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'over') ||
				cacheObs(target,
						 Observable.
						 fromEvent(target, MouseEvent.MOUSE_OVER).
						 peek(function(event:Event):void {event.stopPropagation();}),
						 'over');
		}
		
		public function mouseOut(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'out') ||
				cacheObs(target,
						 Observable.
						 fromEvent(target, MouseEvent.MOUSE_OUT).
						 peek(function(event:Event):void {event.stopPropagation();}),
						 'out');
		}
		
		public function mouseRollOver(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'rollOver') ||
				cacheObs(target,
						 Observable.
						 fromEvent(target, MouseEvent.ROLL_OVER).
						 peek(function(event:Event):void {event.stopPropagation();}),
						 'rollOver');
		}
		
		public function mouseRollOut(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'rollOut') ||
				cacheObs(target,
						 Observable.
						 fromEvent(target, MouseEvent.ROLL_OUT).
						 peek(function(event:Event):void {event.stopPropagation();}),
						 'rollOut');
		}
		
		public function mouseMove(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'move') ||
				cacheObs(target,
						 Observable.
						 fromEvent(target, MouseEvent.MOUSE_MOVE).
						 peek(function(event:Event):void {event.stopPropagation();}),
						 'move');
		}
		
		public function mouseDown(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'down') ||
				cacheObs(target,
						 downGenerator(target).
						 filter(function(tuple:Object):Boolean {
							 return tuple.val == 1;
						 }).
						 map(function(tuple:Object):MouseEvent {
							 return tuple.event;
						 }),
						 'down');
		}
		
		public function mouseDoubleDown(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'doubleDown') ||
				cacheObs(target,
						 downGenerator(target).
						 filter(function(tuple:Object):Boolean {
							 return tuple.val == 2;
						 }).
						 map(function(tuple:Object):MouseEvent {
							 return tuple.event;
						 }),
						 'doubleDown');
		}
		
		public function mouseTripleDown(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'tripleDown') ||
				cacheObs(target,
						 downGenerator(target).
						 filter(function(tuple:Object):Boolean {
							 return tuple.val == 3;
						 }).
						 map(function(tuple:Object):MouseEvent {
							 return tuple.event;
						 }),
						 'tripleDown');
		}
		
		public function mouseClick(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'click') ||
				cacheObs(target,
						 Observable.
						 fromEvent(target, MouseEvent.CLICK).
						 peek(function(event:Event):void {event.stopPropagation();}),
						 'click');
		}
		
		public function mouseDoubleClick(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'doubleClick') || cacheObs(target,
															 mouseClick(target).
															 timeInterval().
															 filter(function(ti:TimeInterval):Boolean {
																 return ti.interval > 0 && ti.interval < 400;
															 }).
															 removeTimeInterval(),
															 'doubleClick');
		}
		
		public function mouseDrag(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'drag') ||
				cacheObs(target,
						 mouseDown(target).
						 mapMany(function(me:MouseEvent):IObservable {
							 return mouseMove(target).timestamp().
								 combineLatest(move.timestamp(),
											   function(left:TimeStamped, right:TimeStamped):MouseEvent {
												   return (left.timestamp > right.timestamp ? left.value : right.value) as MouseEvent;
											   }).
											   takeUntil(up);
						 }),
						 'drag');
		}
		
		public function mouseDoubleDrag(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'doubleDrag') ||
				cacheObs(target,
						 mouseDoubleDown(target).
						 mapMany(function(me:MouseEvent):IObservable {
							 return mouseMove(target).timestamp().
								 combineLatest(move.timestamp(),
											   function(left:TimeStamped, right:TimeStamped):MouseEvent {
												   return (left.timestamp > right.timestamp ? left.value : right.value) as MouseEvent;
											   }).
											   takeUntil(up);
						 }),
						 'doubleDrag');
		}
		
		public function mouseTripleDrag(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'tripleDrag') ||
				cacheObs(target,
						 mouseTripleDown(target).
						 mapMany(function(me:MouseEvent):IObservable {
							 return mouseMove(target).timestamp().
								 combineLatest(move.timestamp(),
											   function(left:TimeStamped, right:TimeStamped):MouseEvent {
												   return (left.timestamp > right.timestamp ? left.value : right.value) as MouseEvent;
											   }).
											   takeUntil(up);
						 }),
						 'tripleDrag');
		}
		
		public function mouseWheel(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'wheel') ||
				cacheObs(target,
						 Observable.fromEvent(target, MouseEvent.MOUSE_WHEEL),
						 'wheel');
		}
		
		protected function downGenerator(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'downGenerator') ||
				cacheObs(target,
						 Observable.fromEvent(target, MouseEvent.MOUSE_DOWN).
						 peek(function(event:Event):void {
							 event.stopPropagation();
						 }).
						 scan(function(state:Object, evt:MouseEvent):Object {
							 return {val: state.val + 1, event: evt};
						 }, {val: 0, event: null}, true).
						 takeUntil(Observable.timer(800, 0)).
						 repeat(),
						 'downGenerator');
		}
	}
}
