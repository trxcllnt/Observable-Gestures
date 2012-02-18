package gestures.multitouch
{
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.ui.*;
	import flash.utils.*;
	
	import raix.interactive.*;
	import raix.reactive.*;
	
	public class MouseMultitouchSimulator
	{
		public function MouseMultitouchSimulator(stage:Stage, observables:ObservableGestures)
		{
			initialize(stage, observables);
		}
		
		[Embed(source = "touch_point_handle_31x32.png")]
		private const handleImage:Class;
		
		protected function initialize(stage:Stage, observables:ObservableGestures):void
		{
			observables.mouseDown(stage).
				filter(function(event:MouseEvent):Boolean {
					return !event.shiftKey && !event.altKey && !event.controlKey && !event.commandKey;
				}).
				subscribe(function(event:MouseEvent):void {
					Mouse.hide();
					
					const pos:Point = new Point(event.stageX, event.stageY);
					const handle:DisplayObject = makeHandles(1)[0];
					const loc:Point = new Point(pos.x - (handle.width * 0.5), pos.y - (handle.height * 0.5));
					handle.x = loc.x;
					handle.y = loc.y;
					stage.addChild(handle);
					
					var child:InteractiveObject = toEnumerable(getObjectsUnderPoint(stage, loc)).
					lastOrDefault(stage) as InteractiveObject;
					child.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_BEGIN,
						event, 1, true,
						new Point(event.localX, event.localY),
						handle, child));
					
					observables.mouseMove(stage).
						takeUntil(observables.mouseUp(stage)).
						subscribe(function(event:MouseEvent):void {
							handle.x = event.stageX - (handle.width * 0.5);
							handle.y = event.stageY - (handle.height * 0.5);
							
							const handlePosition:Point = new Point(event.stageX, event.stageY);
							const newChild:InteractiveObject = toEnumerable(getObjectsUnderPoint(stage, handlePosition)).
							lastOrDefault(stage) as InteractiveObject;
							const local:Point = child.globalToLocal(handlePosition);
							
							if(newChild != child)
							{
								child.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_OUT,
									event, 1, true, local, handle, child));
								if(child is DisplayObjectContainer &&
									DisplayObjectContainer(child).contains(newChild) == false)
								{
									child.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_ROLL_OUT,
										event, 1, true, local, handle, child));
									newChild.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_OVER,
										event, 1, true, local, handle, child));
									newChild.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_ROLL_OVER,
										event, 1, true, local, handle, child));
								}
								else
								{
									newChild.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_OVER,
										event, 1, true, local, handle, child));
								}
								child = newChild;
							}
							
							child.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_MOVE,
								event, 1, true, local, handle, child));
							
						},
						function():void {
							
							const local:Point = child.globalToLocal(new Point(handle.x + (handle.width * 0.5),
								handle.y + (handle.width * 0.5)));
							
							child.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_END,
								event, 1, true,
								local, handle, child));
							
							if(stage.contains(handle)) stage.removeChild(handle);
							
							Mouse.show();
						});
				});
			
			const shiftThenMouseDown:IObservable = observables.keyDown(stage).
				filter(function(event:KeyboardEvent):Boolean {
					return event.keyCode == Keyboard.SHIFT;
				}).
				distinctUntilChanged(function(e1:KeyboardEvent, e2:KeyboardEvent):Boolean {
					return e1 && e2 &&
						e1.keyCode == e2.keyCode &&
						e1.shiftKey == e2.shiftKey &&
						e1.controlKey == e2.controlKey &&
						e1.commandKey == e2.commandKey;
				}).
				mapMany(function(event:KeyboardEvent):IObservable {
					return observables.mouseDown(stage);
				});
			
			shiftThenMouseDown.
				filter(function(event:MouseEvent):Boolean {
					return event.shiftKey && !event.altKey && !(event.commandKey || event.controlKey);
				}).
				subscribe(twoHandleAction(stage, observables, 0));
			
			shiftThenMouseDown.
				filter(function(event:MouseEvent):Boolean {
					return event.shiftKey && !event.altKey && (event.commandKey || event.controlKey);
				}).
				subscribe(twoHandleAction(stage, observables, 100));
			
			shiftThenMouseDown.
				filter(function(event:MouseEvent):Boolean {
					return event.shiftKey && event.altKey && !(event.commandKey || event.controlKey);
				}).
				subscribe(twoHandleAction(stage, observables, 50, 'unison'));
		}
		
		protected function twoHandleAction(stage:Stage,
										   observables:ObservableGestures,
										   startDistance:Number = 0,
										   moveType:String = 'opposite'):Function
		{
			const originalStartDistance:Number = startDistance;
			return function(event:MouseEvent):void {
				
				Mouse.hide();
				
				startDistance = originalStartDistance;
				
				const pos:Point = new Point(stage.mouseX, stage.mouseY);
				
				const children:Array = [];
				const handles:Array = makeHandles(2).
					map(function(handle:DisplayObject, i:int, ... args):DisplayObject {
						
						const loc:Point = new Point(pos.x - (handle.width * 0.5), pos.y - (handle.height * 0.5));
						
						const child:InteractiveObject = toEnumerable(getObjectsUnderPoint(stage, loc)).
							lastOrDefault(stage) as InteractiveObject;
						
						children[i] = child;
						
						if(i == 0 && child is IMultitouchCompliant)
						{
							const control:InteractiveObject = IMultitouchCompliant(child).relatedControl;
							if(control)
							{
								const controlLocation:Point = control.localToGlobal(new Point(control.width * 0.5, control.height * 0.5));
								startDistance = controlLocation.x - loc.x;
							}
						}
						
						handle.x = loc.x + (startDistance * i);
						handle.y = loc.y;
						
						child.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_BEGIN,
																event, i + 1, true,
																new Point(event.localX, event.localY),
																handle, child));
						
						return stage.addChild(handle);
					}).
					reverse();
				
				observables.mouseMove(stage).
					takeUntil(observables.mouseUp(stage)).
					takeUntil(observables.keyUp(stage)).
					subscribe(function(event:MouseEvent):void {
						handles.forEach(function(handle:DisplayObject, i:int, len:int):void {
							
							const w:Number = (handle.width * 0.5);
							const h:Number = (handle.width * 0.5);
							var child:InteractiveObject = children[i];
							
							handle.x += ((pos.x - event.stageX) * (i == 0 ? 1 : -1));
							
							if(moveType == 'opposite')
								handle.y += ((pos.y - event.stageY) * (i == 0 ? 1 : -1));
							else if(moveType == 'unison')
								handle.y = event.stageY;
							
							const handlePosition:Point = new Point(handle.x + w, handle.y + h);
							const newChild:InteractiveObject = toEnumerable(getObjectsUnderPoint(stage, handlePosition)).
								lastOrDefault(stage) as InteractiveObject;
							const local:Point = child.globalToLocal(handlePosition);
							
							if(newChild != child)
							{
								child.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_OUT,
																		event, i + 1, i == 0, local, handle, child));
								if(child is DisplayObjectContainer &&
									DisplayObjectContainer(child).contains(newChild) == false)
								{
									child.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_ROLL_OUT,
																			event, i + 1, i == 0, local, handle, child));
									newChild.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_OVER,
																			   event, i + 1, i == 0, local, handle, child));
									newChild.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_ROLL_OVER,
																			   event, i + 1, i == 0, local, handle, child));
								}
								else
								{
									newChild.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_OVER,
																			   event, i + 1, i == 0, local, handle, child));
								}
								children[i] = child = newChild;
							}
							
							child.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_MOVE,
																	event, i + 1, i == 0, local, handle, child));
						});
						pos.x = event.stageX;
						pos.y = event.stageY;
					},
					function():void {
						handles.forEach(function(handle:DisplayObject, i:int, ... args):void {
							const child:InteractiveObject = children[i];
							const local:Point = child.globalToLocal(new Point(handle.x + (handle.width * 0.5),
																			  handle.y + (handle.width * 0.5)));
							child.dispatchEvent(translateTouchEvent(TouchEvent.TOUCH_END,
																	event, i + 1, true,
																	local, handle, child));
							if(stage.contains(handle))stage.removeChild(handle);
						});
						handles.length = 0;
						children.length = 0;
						Mouse.show();
					});
			};
		}
		
		protected function makeHandles(handleCount:int):Array
		{
			return new Array(handleCount).map(function(... args):DisplayObject {
				const image:DisplayObject = new handleImage();
				image.alpha = 0.7;
				return image;
			});
		}
		
		protected static function getObjectsUnderPoint(obj:DisplayObject, pt:Point):Array
		{
			const a:Array = [];
			
			if(obj.visible && obj.hitTestPoint(pt.x, pt.y, !(obj is Stage)))
			{
				if(obj is InteractiveObject && InteractiveObject(obj).mouseEnabled)
					a.push(obj);
				
				const doc:DisplayObjectContainer = obj as DisplayObjectContainer;
				if(doc && doc.mouseChildren && doc.numChildren)
				{
					var n:int = doc.numChildren;
					for(var i:int = 0; i < n; i++)
					{
						a.push.apply(null, getObjectsUnderPoint(doc.getChildAt(i), pt));
					}
				}
			}
			
			return a;
		}
		
		protected function translateTouchEvent(type:String,
											   event:MouseEvent,
											   id:int,
											   primary:Boolean,
											   local:Point,
											   handle:DisplayObject,
											   relatedObject:InteractiveObject):TouchEvent
		{
			return new TouchEvent(type,
								  true, true, id, primary,
								  local.x, local.y,
								  handle.width, handle.height, 1,
								  relatedObject, event.ctrlKey, event.altKey,
								  event.shiftKey, event.commandKey,
								  event.controlKey, getTimer());
		}
	}
}
