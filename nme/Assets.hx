package nme;
#if !macro


import format.display.MovieClip;
import haxe.Unserializer;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.media.Sound;
import nme.net.URLRequest;
import nme.text.Font;
import nme.utils.ByteArray;

#if (nme_install_tool && !display)
import nme.AssetData;
#end

#if (js && swfdev)
import format.swf.lite.SWFLite;
#elseif swf
import format.SWF;
#end

#if xfl
import format.XFL;
#end


/**
 * <p>The Assets class provides a cross-platform interface to access 
 * embedded images, fonts, sounds and other resource files.</p>
 * 
 * <p>The contents are populated automatically when an application
 * is compiled using the NME command-line tools, based on the
 * contents of the *.nmml project file.</p>
 * 
 * <p>For most platforms, the assets are included in the same directory
 * or package as the application, and the paths are handled
 * automatically. For web content, the assets are preloaded before
 * the start of the rest of the application. You can customize the 
 * preloader by extending the <code>NMEPreloader</code> class,
 * and specifying a custom preloader using <window preloader="" />
 * in the project file.</p>
 */
class Assets {
	
	
	public static var cachedBitmapData = new Map<String, BitmapData>();
	public static var id(get, null):Array<String>;
	public static var library(get, null):Map<String, LibraryType>;
	public static var path(get, null):Map<String, String>;
	public static var type(get, null):Map<String, AssetType>;
	
	#if (swf && !js) private static var cachedSWFLibraries = new Map<String, SWF>(); #end
	#if (swfdev && js) private static var cachedSWFLibraries = new Map<String, SWFLite>(); #end
	#if xfl private static var cachedXFLLibraries = new Map<String, XFL>(); #end
	private static var initialized = false;
	
	
	private static function initialize():Void {
		
		if (!initialized) {
			
			#if (nme_install_tool && !display)
			
			AssetData.initialize();
			
			#end
			
			initialized = true;
			
		}
		
	}
	
	
	/**
	 * Gets an instance of an embedded bitmap
	 * @usage		var bitmap = new Bitmap(Assets.getBitmapData("image.jpg"));
	 * @param	id		The ID or asset path for the bitmap
	 * @param	useCache		(Optional) Whether to use BitmapData from the cache(Default: true)
	 * @return		A new BItmapData object
	 */
	public static function getBitmapData(id:String, useCache:Bool = true):BitmapData {
		
		initialize();
		
		#if (nme_install_tool && !display)
		
		if (AssetData.type.exists(id) && AssetData.type.get(id) == IMAGE) {
			
			if (useCache && cachedBitmapData.exists(id)) {
				
				return cachedBitmapData.get(id);
				
			} else {
				
				#if flash
				
				var data = cast(Type.createInstance(AssetData.className.get(id), []), BitmapData);
				
				#elseif js
				
				var data = cast(ApplicationMain.loaders.get(AssetData.path.get(id)).contentLoaderInfo.content, Bitmap).bitmapData;
				
				#else
				
				var data = BitmapData.load(AssetData.path.get(id));
				
				#end
				
				if (useCache) {
					
					cachedBitmapData.set(id, data);
					
				}
				
				return data;
				
			}
			
		}  else if (id.indexOf(":") > -1) {
			
			var libraryName = id.substr(0, id.indexOf(":"));
			var symbolName = id.substr(id.indexOf(":") + 1);
			
			if (AssetData.library.exists(libraryName)) {
				
				#if ((swf && !js) || (swfdev && js))
				
				if (AssetData.library.get(libraryName) == SWF) {
					
					if (!cachedSWFLibraries.exists(libraryName)) {
						
						#if js
						
						var unserializer = new Unserializer(getText("libraries/" + libraryName + ".dat"));
						unserializer.setResolver(cast { resolveEnum: resolveEnum, resolveClass: resolveClass });
						cachedSWFLibraries.set(libraryName, unserializer.unserialize());
						
						#else
						
						cachedSWFLibraries.set(libraryName, new SWF(getBytes("libraries/" + libraryName + ".swf")));
						
						#end
						
					}
					
					return cachedSWFLibraries.get(libraryName).getBitmapData(symbolName);
					
				}
				
				#end
				
				#if xfl
				
				if (AssetData.library.get(libraryName) == XFL) {
					
					if (!cachedXFLLibraries.exists(libraryName)) {
						
						cachedXFLLibraries.set(libraryName, Unserializer.run(getText("libraries/" + libraryName + "/" + libraryName + ".dat")));
						
					}
					
					return cachedXFLLibraries.get(libraryName).getBitmapData(symbolName);
					
				}
				
				#end
				
			} else {
				
				trace("[nme.Assets] There is no asset library named \"" + libraryName + "\"");
				
			}
			
		} else {
			
			trace("[nme.Assets] There is no BitmapData asset with an ID of \"" + id + "\"");
			
		}
		
		#end
		
		return null;
		
	}
	
	
	/**
	 * Gets an instance of an embedded binary asset
	 * @usage		var bytes = Assets.getBytes("file.zip");
	 * @param	id		The ID or asset path for the file
	 * @return		A new ByteArray object
	 */
	public static function getBytes(id:String):ByteArray {
		
		initialize();
		
		#if (nme_install_tool && !display)
		
		if (AssetData.type.exists(id)) {
			
			#if flash
			
			return Type.createInstance(AssetData.className.get(id), []);
			
			#elseif js

			var bytes:ByteArray = null;
			var data = ApplicationMain.urlLoaders.get(AssetData.path.get(id)).data;
			if (Std.is(data, String)) {
				var bytes = new ByteArray();
				bytes.writeUTFBytes(data);
			} else if (Std.is(data, ByteArray)) {
				bytes = cast data;
			} else {
				bytes = null;
			}

			if (bytes != null) {
				bytes.position = 0;
				return bytes;
			} else {
				return null;
			}
			
			#else
			
			return ByteArray.readFile(AssetData.path.get(id));
			
			#end
			
		} else {
			
			trace("[nme.Assets] There is no String or ByteArray asset with an ID of \"" + id + "\"");
			
		}
		
		#end
		
		return null;
		
	}
	
	
	/**
	 * Gets an instance of an embedded font
	 * @usage		var fontName = Assets.getFont("font.ttf").fontName;
	 * @param	id		The ID or asset path for the font
	 * @return		A new Font object
	 */
	public static function getFont(id:String):Font {
		
		initialize();
		
		#if (nme_install_tool && !display)
		
		if (AssetData.type.exists(id) && AssetData.type.get(id) == FONT) {
			
			#if (flash || js)
			
			return cast(Type.createInstance(AssetData.className.get(id), []), Font);
			
			#else
			
			return new Font(AssetData.path.get(id));
			
			#end
			
		} else {
			
			trace("[nme.Assets] There is no Font asset with an ID of \"" + id + "\"");
			
		}
		
		#end
		
		return null;
		
	}
	
	
	/**
	 * Gets an instance of a library MovieClip
	 * @usage		var movieClip = Assets.getMovieClip("library:BouncingBall");
	 * @param	id		The library and ID for the MovieClip
	 * @return		A new Sound object
	 */
	public static function getMovieClip(id:String):MovieClip {
		
		initialize();
		
		#if (nme_install_tool && !display)
		
		var libraryName = id.substr(0, id.indexOf(":"));
		var symbolName = id.substr(id.indexOf(":") + 1);
		
		if (AssetData.library.exists(libraryName)) {
			
			#if ((swf && !js) || (swfdev && js))
			
			if (AssetData.library.get(libraryName) == SWF) {
				
				if (!cachedSWFLibraries.exists(libraryName)) {
					
					#if js
					
					var unserializer = new Unserializer(getText("libraries/" + libraryName + ".dat"));
					unserializer.setResolver(cast { resolveEnum: resolveEnum, resolveClass: resolveClass });
					cachedSWFLibraries.set(libraryName, unserializer.unserialize());
					
					#else
					
					cachedSWFLibraries.set(libraryName, new SWF(getBytes("libraries/" + libraryName + ".swf")));
					
					#end
					
				}
				
				return cachedSWFLibraries.get(libraryName).createMovieClip(symbolName);
				
			}
			
			#end
			
			#if xfl
			
			if (AssetData.library.get(libraryName) == XFL) {
				
				if (!cachedXFLLibraries.exists(libraryName)) {
					
					cachedXFLLibraries.set(libraryName, Unserializer.run(getText("libraries/" + libraryName + "/" + libraryName + ".dat")));
					
				}
				
				return cachedXFLLibraries.get(libraryName).createMovieClip(symbolName);
				
			}
			
			#end
			
		} else {
			
			trace("[nme.Assets] There is no asset library named \"" + libraryName + "\"");
			
		}
		
		#end
		
		return null;
		
	}
	
	
	/**
	 * Gets an instance of an embedded sound
	 * @usage		var sound = Assets.getSound("sound.wav");
	 * @param	id		The ID or asset path for the sound
	 * @return		A new Sound object
	 */
	public static function getSound(id:String):Sound {
		
		initialize();
		
		#if (nme_install_tool && !display)
		
		if (AssetData.type.exists(id)) {
			
			var type = AssetData.type.get(id);
			
			if (type == SOUND || type == MUSIC) {
				
				#if flash
				
				return cast(Type.createInstance(AssetData.className.get(id), []), Sound);
				
				#elseif js
				
				return new Sound(new URLRequest(AssetData.path.get(id)));
				
				#else
				
				return new Sound(new URLRequest(AssetData.path.get(id)), null, type == MUSIC);
				
				#end
				
			}
			
		}
		
		trace("[nme.Assets] There is no Sound asset with an ID of \"" + id + "\"");
		
		#end
		
		return null;
		
	}
	
	
	/**
	 * Gets an instance of an embedded text asset
	 * @usage		var text = Assets.getText("text.txt");
	 * @param	id		The ID or asset path for the file
	 * @return		A new String object
	 */
	public static function getText(id:String):String {
		
		var bytes = getBytes(id);
		
		if (bytes == null) {
			
			return null;
			
		} else {

			return bytes.readUTFBytes(bytes.length);
	
		}
		
	}
	
	
	//public static function loadBitmapData(id:String, handler:BitmapData -> Void, useCache:Bool = true):BitmapData
	//{
		//return null;
	//}
	//
	//
	//public static function loadBytes(id:String, handler:ByteArray -> Void):ByteArray
	//{	
		//return null;
	//}
	//
	//
	//public static function loadText(id:String, handler:String -> Void):String
	//{
		//return null;
	//}
	
	
	#if js
	
	private static function resolveClass(name:String):Class <Dynamic> {
		
		name = StringTools.replace(name, "native.", "browser.");
		return Type.resolveClass(name);
		
	}
	
	
	private static function resolveEnum(name:String):Enum <Dynamic> {
		
		name = StringTools.replace(name, "native.", "browser.");
		return Type.resolveEnum(name);
		
	}
	
	#end
	
	
	
	
	// Getters & Setters
	
	
	
	
	private static function get_id():Array<String> {
		
		initialize ();
		
		var ids = [];
		
		#if (nme_install_tool && !display)
		
		for (key in AssetData.type.keys ()) {
			
			ids.push (key);
			
		}
		
		#end
		
		return ids;
		
	}
	
	
	private static function get_library():Map<String, LibraryType> {
		
		initialize ();
		
		#if (nme_install_tool && !display)
		
		return AssetData.library;
		
		#else
		
		return new Map<String, LibraryType> ();
		
		#end
		
	}
	
	
	private static function get_path():Map<String, String> {
		
		initialize ();
		
		#if ((nme_install_tool && !display) && !flash)
		
		return AssetData.path;
		
		#else
		
		return new Map<String, String> ();
		
		#end
		
	}
	
	
	private static function get_type():Map<String, AssetType> {
		
		initialize ();
		
		#if (nme_install_tool && !display)
		
		return AssetData.type;
		
		#else
		
		return new Map<String, AssetType> ();
		
		#end
		
	}
	
	
}


enum AssetType {
	
	BINARY;
	FONT;
	IMAGE;
	MUSIC;
	SOUND;
	TEXT;
	
}


enum LibraryType {
	
	SWF;
	XFL;
	
}


#else


import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.io.File;


class Assets {
	
	
	macro public static function embedBitmap ():Array<Field> {
		
		var currentClass = Context.getLocalClass();
		var classType = currentClass.get();
		var metaData = classType.meta.get();
		
		var position = Context.currentPos();
        var fields = Context.getBuildFields();
		
		for (meta in metaData) {
			
			if (meta.name == ":bitmap") {
				
				if (meta.params.length > 0) {
					
					switch (meta.params[0].expr) {
						
						case EConst(CString(filePath)):
							
							var path = Context.resolvePath (filePath);
							var bytes = File.getBytes (path);
							
							#if neko // C++ has a compile error right now with the ByteArray String value
							
							var fieldValue = { pos: position, expr: EConst(CString(bytes.toString())) };
							fields.push ({ kind: FVar(macro :String, fieldValue), name: "embeddedData", doc: null, meta: [], access: [ APrivate, AStatic ], pos: position });
							
							fields.push ({
								
								kind: FFun({
									
									args: [
										
										{ name: "width", opt: false, type: macro :Int, value: null },
										{ name: "height", opt: false, type: macro :Int, value: null },
										{ name: "transparent", opt: true, type: macro :Bool, value: macro true },
										{ name: "fillRGBA", opt: true, type: macro :Int, value: macro 0xFFFFFFFF },
										{ name: "gpuMode", opt: true, type: macro :Bool, value: macro false }
										
									],
									
									expr: macro {
										
										super(0, 0);
										
										var byteArray = nme.utils.ByteArray.fromBytes (haxe.io.Bytes.ofString (embeddedData));
										nmeHandle = BitmapData.nme_bitmap_data_from_bytes (byteArray, null);
										
									},
									
									params: [],
									ret: null
									
								}),
								
								meta: [],
								name: "new",
								doc: null,
								pos: position,
								access: [ APublic ]
								
							});
							
							return fields;
							
							#end
							
						default:
						
					}
					
				}
				
			}
			
		}
		
		return null;
		
	}
	
	
	macro public static function embedFile ():Array<Field> {
		
		var currentClass = Context.getLocalClass();
		var classType = currentClass.get();
		var metaData = classType.meta.get();
		
		for (meta in metaData) {
			
			Sys.println (meta.name);
			
		}
		
		return null;
		
	}
	
	
	macro public static function embedFont ():Array<Field> {
		
		var currentClass = Context.getLocalClass();
		var classType = currentClass.get();
		var metaData = classType.meta.get();
		
		for (meta in metaData) {
			
			Sys.println (meta.name);
			
		}
		
		return null;
		
	}
	
	
	macro public static function embedSound ():Array<Field> {
		
		var currentClass = Context.getLocalClass();
		var classType = currentClass.get();
		var metaData = classType.meta.get();
		
		var position = Context.currentPos();
        var fields = Context.getBuildFields();
		
		for (meta in metaData) {
			
			if (meta.name == ":sound") {
				
				if (meta.params.length > 0) {
					
					switch (meta.params[0].expr) {
						
						case EConst(CString(filePath)):
							
							var path = Context.resolvePath (filePath);
							var bytes = File.getBytes (path);
							
							#if false // C++ has a compile error right now with the ByteArray String value, and Neko can't load Sound from bytes ("CFFILoader.h(248) : NOT Implemented:api_buffer_data")
							
							var fieldValue = { pos: position, expr: EConst(CString(bytes.toString())) };
							fields.push ({ kind: FVar(macro :String, fieldValue), name: "embeddedData", doc: null, meta: [], access: [ APrivate, AStatic ], pos: position });
							
							fields.push ({
								
								kind: FFun({
									
									args: [
										
										{ name: "stream", opt: true, type: macro :nme.net.URLRequest, value: null },
										{ name: "context", opt: true, type: macro :nme.media.SoundLoaderContext, value: null },
										{ name: "forcePlayAsMusic", opt: true, type: macro :Bool, value: macro false }
										
									],
									
									expr: macro {
										
										super();
										
										var byteArray = nme.utils.ByteArray.fromBytes (haxe.io.Bytes.ofString (embeddedData));
										loadCompressedDataFromByteArray(byteArray, byteArray.length, forcePlayAsMusic);
										
									},
									
									params: [],
									ret: null
									
								}),
								
								meta: [],
								name: "new",
								doc: null,
								pos: position,
								access: [ APublic ]
								
							});
							
							return fields;
							
							#end
							
						default:
						
					}
					
				}
				
			}
			
		}
		
		return null;
		
		
	}
	
	
}


#end