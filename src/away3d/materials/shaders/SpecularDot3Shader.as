﻿package away3d.materials.shaders
{
	import away3d.arcane;
	import away3d.containers.*;
	import away3d.core.base.*;
	import away3d.core.math.*;
	import away3d.core.render.*;
	import away3d.core.utils.*;
	import away3d.lights.*;
	
	import flash.display.*;
	import flash.geom.*;
	import flash.utils.*;
	
	use namespace arcane;
	
	/**
	 * Diffuse Dot3 shader class for directional lighting.
	 * 
	 * @see away3d.lights.DirectionalLight3D
	 */
    public class SpecularDot3Shader extends AbstractShader
    {
        /** @private */
		arcane override function updateMaterial(source:Object3D, view:View3D):void
        {
        	if (_bitmapDirty)
        		invalidateFaces();
        	
        	var _source_scene_directionalLights:Array = source.scene.directionalLights;
			var directional:DirectionalLight3D;
        	for each (directional in _source_scene_directionalLights) {
        		if (!directional.specularTransform[source] || !directional.normalMatrixSpecularTransform[source] || !directional.specularTransform[source][view] || directional.normalMatrixSpecularTransform[source][view] || view._updatedObjects[source] || view.updated) {
        			directional.setSpecularTransform(source, view);
        			directional.setNormalMatrixSpecularTransform(source, view, _specular, _shininess);
        			updateFaces(source, view);
        		}
        	}
        }
		/** @private */
		arcane override function renderLayer(priIndex:uint, viewSourceObject:ViewSourceObject, renderer:Renderer, layer:Sprite, level:int):int
        {
        	super.renderLayer(priIndex, viewSourceObject, renderer, layer, level);
        	
        	var _source_scene_directionalLights:Array = _source.scene.directionalLights;
			var directional:DirectionalLight3D;
        	for each (directional in _source_scene_directionalLights)
        	{
				_shape = _session.getLightShape(this, level++, layer, directional);
        		_shape.filters = [directional.normalMatrixSpecularTransform[_source][_view]];
        		_shape.blendMode = blendMode;
        		_graphics = _shape.graphics;
        		
				_source.session.renderTriangleBitmap(_bitmap, getMapping(priIndex), _screenVertices, _screenIndices, _startIndex, _endIndex, smooth, false, _graphics);
        	}
			
			if (debug)
                _source.session.renderTriangleLine(0, 0x0000FF, 1, _screenVertices, renderer.primitiveCommands[priIndex], _screenIndices, _startIndex, _endIndex);
            
            return level;
        }
        
        private var _zeroPoint:Point = new Point(0, 0);
        private var _bitmap:BitmapData;
        private var _normalDictionary:Dictionary = new Dictionary(true);
        private var _normalBitmap:BitmapData;
        private var _shininess:Number;
		private var _specular:uint;
		private var _specularTransform:Matrix3D;
		private var _szx:Number;
		private var _szy:Number;
		private var _szz:Number;
		private var _normal0z:Number;
		private var _normal1z:Number;
		private var _normal2z:Number;
		private var _bitmapDirty:Boolean;
		private var _u0:Number;
        private var _u1:Number;
        private var _u2:Number;
        private var _v0:Number;
        private var _v1:Number;
        private var _v2:Number;
        
		/**
		 * @inheritDoc
		 */
        public function updateFaces(source:Object3D = null, view:View3D = null):void
        {
        	notifyMaterialUpdate();
        	
        	for each (var faceMaterialVO:FaceMaterialVO in _faceDictionary)
        		if (source == faceMaterialVO.source && view == faceMaterialVO.view)
	        		if (!faceMaterialVO.cleared)
	        			faceMaterialVO.clear();
        }
        
		/**
		 * @inheritDoc
		 */
        public function invalidateFaces(source:Object3D = null, view:View3D = null):void
        {
        	source; view;
        	
        	_bitmapDirty = false;
        	
        	for each (var faceMaterialVO:FaceMaterialVO in _faceDictionary)
        		faceMaterialVO.invalidated = true;
        }
        
        protected override function calcMapping(priIndex:uint, map:Matrix):Matrix
        {
        	if (_uvs[0] == null || _uvs[1] == null || _uvs[2] == null)
                return null;

            _u0 = width * _uvs[0]._u;
            _u1 = width * _uvs[1]._u;
            _u2 = width * _uvs[2]._u;
            _v0 = height * (1 - _uvs[0]._v);
            _v1 = height * (1 - _uvs[1]._v);
            _v2 = height * (1 - _uvs[2]._v);
      
            // Fix perpendicular projections
            if ((_u0 == _u1 && _v0 == _v1) || (_u0 == _u2 && _v0 == _v2)) {
            	if (_u0 > 0.05)
                	_u0 -= 0.05;
                else
                	_u0 += 0.05;
                	
                if (_v0 > 0.07)           
                	_v0 -= 0.07;
                else
                	_v0 += 0.07;
            }
    
            if (_u2 == _u1 && _v2 == _v1) {
            	if (_u2 > 0.04)
                	_u2 -= 0.04;
                else
                	_u2 += 0.04;
                	
                if (_v2 > 0.06)           
                	_v2 -= 0.06;
                else
                	_v2 += 0.06;
            }
            
        	map.a = _u1 - _u0;
        	map.b = _v1 - _v0;
        	map.c = _u2 - _u0;
        	map.d = _v2 - _v0;
            map.tx = _u0;
            map.ty = _v0;
            map.invert();
            
            return map;
        }
        
		/**
		 * @inheritDoc
		 */
        protected override function renderShader(priIndex:uint):void
        {
        	priIndex;
        	
			//check to see if normalDictionary exists
			_normalBitmap = _normalDictionary[_faceVO];
			if (!_normalBitmap || _faceMaterialVO.resized) {
				_normalBitmap = _normalDictionary[_faceVO] = _parentFaceMaterialVO.bitmap.clone();
				_normalBitmap.lock();
			}
			
			_n0 = _source.geometry.getVertexNormal(_face.v0);
			_n1 = _source.geometry.getVertexNormal(_face.v1);
			_n2 = _source.geometry.getVertexNormal(_face.v2);
			
			var _source_scene_directionalLights:Array = _source.scene.directionalLights;
			
			var directional:DirectionalLight3D;
			
			for each (directional in _source_scene_directionalLights)
	    	{
				_specularTransform = directional.specularTransform[_source];
				 
				_szx = _specularTransform.szx;
				_szy = _specularTransform.szy;
				_szz = _specularTransform.szz;
				
				_normal0z = _n0.x * _szx + _n0.y * _szy + _n0.z * _szz;
				_normal1z = _n1.x * _szx + _n1.y * _szy + _n1.z * _szz;
				_normal2z = _n2.x * _szx + _n2.y * _szy + _n2.z * _szz;
				
				//check to see if the uv triangle lies inside the bitmap area
				if (_normal0z > -0.2 || _normal1z > -0.2 || _normal2z > -0.2) {
					
					//store a clone
					if (_faceMaterialVO.cleared && !_parentFaceMaterialVO.updated) {
						_faceMaterialVO.bitmap = _parentFaceMaterialVO.bitmap.clone();
						_faceMaterialVO.bitmap.lock();
					}
					
					//update booleans
					_faceMaterialVO.cleared = false;
					_faceMaterialVO.updated = true;
					
					//resolve normal map
					_normalBitmap.applyFilter(_bitmap, _faceVO.face.bitmapRect, _zeroPoint, directional.normalMatrixSpecularTransform[_source][_view]);
		            
					//draw into faceBitmap
					_faceMaterialVO.bitmap.draw(_normalBitmap, null, directional.diffuseColorTransform, blendMode);
				}
	    	}
        }
        
        //TODO: implement tangent space option
        /**
        * Determines if the DOT3 mapping is rendered in tangent space (true) or object space (false).
        */
        public var tangentSpace:Boolean;
        
        /**
        * Returns the width of the bitmapData being used as the shader DOT3 map.
        */
        public function get width():Number
        {
            return _bitmap.width;
        }
        
        /**
        * Returns the height of the bitmapData being used as the shader DOT3 map.
        */
        public function get height():Number
        {
            return _bitmap.height;
        }
        
        /**
        * Returns the bitmapData object being used as the shader DOT3 map.
        */
        public function get bitmap():BitmapData
        {
        	return _bitmap;
        }
        
        public function set bitmap(val:BitmapData):void
        {
        	_bitmap = val;
        	
        	_bitmapDirty = true;
        }
        
		/**
		 * The exponential dropoff value used for specular highlights.
		 */
        public function get shininess():Number
        {
        	return _shininess;
        }
		
        public function set shininess(val:Number):void
        {
        	_shininess = val;
        }
		
		/**
		 * Coefficient for specular light level.
		 */
		public function get specular():uint
		{
			return _specular;
		}
		
		public function set specular(val:uint):void
		{
			_specular = val;
		}
		
        /**
        * Returns the argb value of the bitmapData pixel at the given u v coordinate.
        * 
        * @param	u	The u (horizontal) texture coordinate.
        * @param	v	The v (verical) texture coordinate.
        * @return		The argb pixel value.
        */
        public function getPixel32(u:Number, v:Number):uint
        {
        	return _bitmap.getPixel32(u*_bitmap.width, (1 - v)*_bitmap.height);
        }
		
		/**
		 * Creates a new <code>SpecularDot3Shader</code> object.
		 * 
		 * @param	bitmap			The bitmapData object to be used as the material's DOT3 map.
		 * @param	init	[optional]	An initialisation object for specifying default instance properties.
		 */
        public function SpecularDot3Shader(bitmap:BitmapData, init:Object = null)
        {
            super(init);
            
			_bitmap = bitmap;
			
            shininess = ini.getNumber("shininess", 20);
            specular = ini.getColor("specular", 0xFFFFFF);
            tangentSpace = ini.getBoolean("tangentSpace", false);
        }
    }
}
