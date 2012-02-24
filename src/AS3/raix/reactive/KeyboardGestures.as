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
	
	public class KeyboardGestures extends GesturesBase
	{
		public static const global:KeyboardGestures = new KeyboardGestures();
		
		protected const globalCanceleables:Dictionary = new Dictionary(false);
		
		public function register(target:IEventDispatcher):IEventDispatcher
		{
			globalCanceleables[target] ||= [];
			const a:Array = globalCanceleables[target];
			
			if(a.length <= 0)
			{
				a.push(keyDown(target).subscribeWith(keyDownObs));
				a.push(keyUp(target).subscribeWith(keyUpObs));
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
		
		protected const keyDownObs:ISubject = new Subject();
		protected const keyUpObs:ISubject = new Subject();
		
		public function keyDown(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'keyDown') ||
				cacheObs(target,
						 Observable.fromEvent(target, KeyboardEvent.KEY_DOWN),
						 'keyDown');
		}
		
		public function keyUp(target:IEventDispatcher):IObservable
		{
			return getObs(target, 'keyUp') ||
				cacheObs(target,
						 Observable.fromEvent(target, KeyboardEvent.KEY_UP),
						 'keyUp');
		}
	
	}
}
