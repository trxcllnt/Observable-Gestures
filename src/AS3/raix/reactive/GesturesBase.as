package raix.reactive
{
	import flash.events.*;
	import flash.utils.*;

	public class GesturesBase
	{
		protected const localCancelables:Dictionary = new Dictionary(false);
		
		protected function getObs(target:IEventDispatcher, name:String):IObservable
		{
			return localCancelables[target] ? localCancelables[target][name] : null;
		}
		
		protected function cacheObs(target:IEventDispatcher, obs:IObservable, name:String):IObservable
		{
			localCancelables[target] ||= {};
			return localCancelables[target][name] ||= obs;
		}
	}
}