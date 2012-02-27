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
	
	public class TouchGestures extends GesturesBase
	{
		public static const global:TouchGestures = new TouchGestures();
		
		protected const globalCanceleables:Dictionary = new Dictionary(false);
		
		public function register(target:IEventDispatcher):IEventDispatcher
		{
			globalCanceleables[target] ||= [];
			const a:Array = globalCanceleables[target];
			
			if(a.length <= 0)
			{
				a.push(touchBegin(target).subscribeWith(touchBeginObs));
				a.push(touchEnd(target).subscribeWith(touchEndObs));
				a.push(touchMove(target).subscribeWith(touchMoveObs));
				a.push(touchOver(target).subscribeWith(touchOverObs));
				a.push(touchOut(target).subscribeWith(touchOutObs));
				a.push(touchRollOver(target).subscribeWith(touchRollOverObs));
				a.push(touchRollOut(target).subscribeWith(touchRollOutObs));
				a.push(touchTap(target).subscribeWith(touchTapObs));
				a.push(touchHold(target).subscribeWith(touchHoldObs));
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
		
		public function touchBegin(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'touchBegin') ||
				cacheObs(target,
						 Observable.fromEvent(target, TouchEvent.TOUCH_BEGIN),
						 'touchBegin');
		}
		
		public function touchEnd(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'touchEnd') ||
				cacheObs(target,
						 Observable.fromEvent(target, TouchEvent.TOUCH_END),
						 'touchEnd');
		}
		
		public function touchMove(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'touchMove') ||
				cacheObs(target,
						 Observable.fromEvent(target, TouchEvent.TOUCH_MOVE),
						 'touchMove');
		}
		
		public function touchOver(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'touchOver') ||
				cacheObs(target,
						 Observable.fromEvent(target, TouchEvent.TOUCH_OVER),
						 'touchOver');
		}
		
		public function touchOut(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'touchOut') ||
				cacheObs(target,
						 Observable.fromEvent(target, TouchEvent.TOUCH_OUT),
						 'touchOut');
		}
		
		public function touchRollOver(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'touchRollOver') ||
				cacheObs(target,
						 Observable.fromEvent(target, TouchEvent.TOUCH_ROLL_OVER),
						 'touchRollOver');
		}
		
		public function touchRollOut(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'touchRollOut') ||
				cacheObs(target,
						 Observable.fromEvent(target, TouchEvent.TOUCH_ROLL_OUT),
						 'touchRollOut');
		}
		
		public function touchTap(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'touchTap') ||
				cacheObs(target,
						 Observable.fromEvent(target, TouchEvent.TOUCH_TAP),
						 'touchTap');
		}
		
		public function touchClick(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'touchClick') ||
				cacheObs(target,
						 touchBegin(target).takeUntil(touchEnd(target)),
						 'touchClick');
		}
		
		public function touchHold(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'touchHold') ||
				cacheObs(target,
						 touchBegin(target).
						 mapMany(function(begin:TouchEvent):IObservable {
							 return Observable.timer(400, 0).
								 takeUntil(Observable.merge([
															touchEndObs,
															touchEnd(target),
															touchOut(target)
															])).
								 first().
								 map(function(... args):TouchEvent {
									 return begin;
								 });
						 }).
						 repeat(),
						 'touchHold');
		}
	}
}
