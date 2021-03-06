package net.systemeD.halcyon.connection {

    import flash.net.*;

    import flash.events.EventDispatcher;
    import flash.events.Event;

	public class Connection extends EventDispatcher {

        private static var connectionInstance:Connection = null;

        protected static var policyURL:String;
        protected static var apiBaseURL:String;
        protected static var params:Object;

        public static function getConnection(initparams:Object=null):Connection {
            if ( connectionInstance == null ) {
            
                params = initparams == null ? new Object() : initparams;
                policyURL = getParam("policy", "http://127.0.0.1:3000/api/crossdomain.xml");
                apiBaseURL = getParam("api", "http://127.0.0.1:3000/api/0.6/");
                var connectType:String = getParam("connection", "XML");
                
                if ( connectType == "XML" )
                    connectionInstance = new XMLConnection();
                else
                    connectionInstance = new AMFConnection();
            }
            return connectionInstance;
        }

        public static function getParam(name:String, defaultValue:String):String {
            trace("Returning param "+name+" as "+(params[name] == null ? defaultValue : params[name]));
            return params[name] == null ? defaultValue : params[name];
        }

        public static function get apiBase():String {
            return apiBaseURL;
        }

        public static function get serverName():String {
            return getParam("serverName", "Localhost");
        }
                
		public static function getConnectionInstance():Connection {
            return connectionInstance;
		}

		public function getEnvironment(responder:Responder):void {}

        // connection events
        public static var LOAD_STARTED:String = "load_started";
        public static var LOAD_COMPLETED:String = "load_completed";
        public static var SAVE_STARTED:String = "save_started";
        public static var SAVE_COMPLETED:String = "save_completed";
        public static var NEW_CHANGESET:String = "new_changeset";
        public static var NEW_CHANGESET_ERROR:String = "new_changeset_error";
        public static var NEW_NODE:String = "new_node";
        public static var NEW_WAY:String = "new_way";
        public static var NEW_RELATION:String = "new_relation";
        public static var NEW_POI:String = "new_poi";
        public static var TAG_CHANGE:String = "tag_change";
        public static var NODE_MOVED:String = "node_moved";
        public static var WAY_NODE_ADDED:String = "way_node_added";
        public static var WAY_NODE_REMOVED:String = "way_node_removed";

        // store the data we download
        private var negativeID:Number = -1;
        private var nodes:Object = {};
        private var ways:Object = {};
        private var relations:Object = {};
        private var pois:Array = [];
        private var changeset:Changeset = null;

        protected function get nextNegative():Number {
            return negativeID--;
        }

        protected function setNode(node:Node,queue:Boolean):void {
            nodes[node.id] = node;
            if (node.loaded) { sendEvent(new EntityEvent(NEW_NODE, node),queue); }
        }

        protected function setWay(way:Way,queue:Boolean):void {
            ways[way.id] = way;
            if (way.loaded) { sendEvent(new EntityEvent(NEW_WAY, way),queue); }
        }

        protected function setRelation(relation:Relation,queue:Boolean):void {
            relations[relation.id] = relation;
            if (relation.loaded) { sendEvent(new EntityEvent(NEW_RELATION, relation),queue); }
        }

        protected function renumberNode(oldID:Number, node:Node):void {
            nodes[node.id] = node;
            delete nodes[oldID];
        }

        protected function renumberWay(oldID:Number, way:Way):void {
            ways[way.id] = way;
            delete ways[oldID];
        }

        protected function renumberRelation(oldID:Number, relation:Relation):void {
            relations[relation.id] = relation;
            delete relations[oldID];
        }

		public function sendEvent(e:*,queue:Boolean):void {
			// queue is only used for AMFConnection
			dispatchEvent(e);
		}

        public function registerPOI(node:Node):void {
            if ( pois.indexOf(node) < 0 ) {
                pois.push(node);
                sendEvent(new EntityEvent(NEW_POI, node),false);
            }
        }

        protected function unregisterPOI(node:Node):void {
            var index:uint = pois.indexOf(node);
            if ( index >= 0 ) {
                pois.splice(index,1);
            }
        }

        protected function setActiveChangeset(changeset:Changeset):void {
            this.changeset = changeset;
            sendEvent(new EntityEvent(NEW_CHANGESET, changeset),false);
        }
        
        public function getNode(id:Number):Node {
            return nodes[id];
        }

        public function getWay(id:Number):Way {
            return ways[id];
        }

        public function getRelation(id:Number):Relation {
            return relations[id];
        }

        public function createNode(tags:Object, lat:Number, lon:Number):Node {
            var node:Node = new Node(nextNegative, 0, tags, true, lat, lon);
            setNode(node,false);
            return node;
        }

        public function createWay(tags:Object, nodes:Array):Way {
            var way:Way = new Way(nextNegative, 0, tags, true, nodes.concat());
            setWay(way,false);
            return way;
        }

        public function createRelation(tags:Object, members:Array):Relation {
            var relation:Relation = new Relation(nextNegative, 0, tags, true, members.concat());
            setRelation(relation,false);
            return relation;
        }

        public function getAllNodeIDs():Array {
            var list:Array = [];
            for each (var node:Node in nodes)
                list.push(node.id);
            return list;
        }

        public function getAllWayIDs():Array {
            var list:Array = [];
            for each (var way:Way in ways)
                list.push(way.id);
            return list;
        }

        public function getAllRelationIDs():Array {
            var list:Array = [];
            for each (var relation:Relation in relations)
                list.push(relation.id);
            return list;
        }

        public function getActiveChangeset():Changeset {
            return changeset;
        }
        
        // these are functions that the Connection implementation is expected to
        // provide. This class has some generic helpers for the implementation.
		public function loadBbox(left:Number, right:Number,
								top:Number, bottom:Number):void {
	    }
	    
	    public function setAppID(id:Object):void {}
	    public function setAuthToken(id:Object):void {}
	    public function createChangeset(tags:Object):void {}
	    public function uploadChanges():void {}
    }

}

