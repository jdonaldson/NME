import installers.AndroidInstaller;
import installers.CPPInstaller;
import installers.IOSInstaller;
import installers.WebOSInstaller;

import neko.FileSystem;
import neko.io.File;
import neko.io.Path;
import neko.Lib;
import neko.Sys;


class InstallTool {
	
	
	static public function create(nme:String, command:String, defines:Hash <String>, includePaths:Array <String>, projectFile:String, target:String, verbose:Bool, debug:Bool) {
		
      var installer: installers.InstallerBase = null;
		switch (target) {
			
			case "android":
				
				installer = new AndroidInstaller();
			
			case "windows", "mac", "linux":
				
				installer = new CPPInstaller();
			
			case "iphoneos", "iphonesim":
				
				installer = new IOSInstaller();
			
			case "webos":
				
				installer = new WebOSInstaller();

			case "flash":

				installer = new installers.FlashInstaller();

			default:
				
				Lib.println ("The specified target is not supported: " + target);
				return;
			
		}

		installer.create(nme, command, defines, includePaths, projectFile, target, verbose, debug);
		
	}

	
	
	private static function argumentError (error:String):Void {
		
		Lib.println (error);
		Lib.println ("Usage :  haxelib run nme [-v] COMMAND ...");
		Lib.println (" COMMAND : copy-if-newer source destination");
		Lib.println (" COMMAND : update build.nmml [-DFLAG -Dname=val... ]");
		Lib.println (" COMMAND : (update|build|rerun) [-debug] build.nmml target");
		Lib.println (" COMMAND : uninstall build.nmml target");
		
	}
	
	
	public static function copyIfNewer (source:String, destination:String, verbose:Bool) {
		
		if (!isNewer (source, destination)) {
			
			return;
			
		}
		
		if (verbose) {
			
			Lib.println ("Copy " + source + " to " + destination);
			
		}
		
		File.copy (source, destination);
		
	}
	
	
	static public function getNeko ():String {
		
		var path:String = Sys.getEnv ("NEKO_INSTPATH");
		
		if (path == null || path == "") {
			
			path = Sys.getEnv ("NEKO_INSTALL_PATH");
			
		}
		
		if (path == null || path == "") {
			
			path = Sys.getEnv ("NEKOPATH");
			
		}
		
		if (path == null || path == "") {
			
			if (Sys.systemName () == "windows") {
				
				path = "C:/Motion-Twin/neko";
				
			} else {
				
				path = "/usr/lib/neko";
				
			}
			
		}
		
		return path + "/";
		
	}
	
	
	public static function isNewer (source:String, destination:String):Bool {
		
		if (source == null || !FileSystem.exists (source)) {
			
			throw ("Error: " + source + " does not exist");
			return false;
			
		}
		
		if (FileSystem.exists (destination)) {
			
			if (FileSystem.stat (source).mtime.getTime () < FileSystem.stat (destination).mtime.getTime ()) {
				
				return false;
				
			}
			
		}
		
		return true;
		
	}
	
	
	public static function main () {
		
		var command:String = "";
		var debug:Bool = false;
		var defines = new Hash <String> ();
		var includePaths = new Array <String> ();
		var verbose:Bool = false;
		
		includePaths.push (".");
		
		var args:Array <String> = Sys.args ();
		var nme:String = "";
		
		if (args.length > 0) {
			
			// When called from haxelib, the last argument is the calling directory. The path to nme is set as the current working directory 
			
			var lastArgument:String = new Path (args[args.length - 1]).toString ();
			
			if (lastArgument.substr (-1) == "/" || lastArgument.substr (-1) == "\\") {
				
				lastArgument = lastArgument.substr (0, lastArgument.length - 1);
				
			}
			
			if (FileSystem.exists (lastArgument) && FileSystem.isDirectory (lastArgument)) {
				
				nme = Sys.getCwd ();
				Sys.setCwd (lastArgument);
				
				defines.set ("NME", nme);
				args.pop ();
				
			}
			
		}
		
		if (new EReg ("window", "i").match (Sys.systemName ())) {
			
			defines.set ("windows", "1");
			defines.set ("NME_HOST", "windows");
			
		} else if (new EReg ("linux", "i").match (Sys.systemName ())) {
			
			defines.set ("linux", "1");
			defines.set ("NME_HOST", "linux");
			
		} else if (new EReg ("mac", "i").match (Sys.systemName ())) {
			
			defines.set ("macos", "1");
			defines.set ("NME_HOST", "darwin-x86");
			
		}
		
		var words:Array <String> = new Array <String> ();
		
		for (arg in args) {
			
			var equals:Int = arg.indexOf ("=");
			
			if (equals > 0) {
				
				defines.set (arg.substr (0, equals), arg.substr (equals + 1));
				
			} else if (arg == "-64") {
				
				defines.set ("NME_64", "1");
				
			} else if (arg.substr (0, 2) == "-D") {
				
				defines.set (arg.substr (2), "");
				
			} else if (arg.substr (0, 2) == "-l") {
				
				includePaths.push (arg.substr (2));
				
			} else if (arg == "-v") {
				
				verbose = true;
				
			} else if (arg == "-debug") {
				
				debug = true;
				
			} else if (command.length == 0) {
				
				command = arg;
				
			} else {
				
				words.push (arg);
				
			}
			
		}
		
		if (Sys.environment ().exists ("HOME")) {
			
			includePaths.push (Sys.getEnv ("HOME"));
			
		}
		
		if (Sys.environment ().exists ("USERPROFILE")) {
			
			includePaths.push (Sys.getEnv ("USERPROFILE"));
			
		}
		
		includePaths.push (nme + "/install-tool");
		
		var validCommands:Array <String> = ["copy-if-newer", "rerun", "update", "test", "build", "installer", "uninstall"];
		
		if (!Lambda.exists (validCommands, function (c) return command == c)) {
			
			if (command != "") {
				
				argumentError ("Unknown command: " + command);
				return;
				
			}
			
		}
		
		if (command == "copy-if-newer") {
			
			if (words.length != 2) {
				
				argumentError ("Wrong number of arguments for command: " + command);
				return;
				
			}
			
			copyIfNewer (words[0], words[1], verbose);
			
		} else {
			
			if (words.length != 2) {
				
				argumentError ("Wrong number of arguments for command: " + command);
				return;
				
			}
			
			if (!FileSystem.exists (words[0])) {
				
				argumentError ("Error using command: " + command + ", you must specify a *.nmml file");
				return;
				
			}
			
			for (key in Sys.environment ().keys ()) {
				
				defines.set (key, Sys.getEnv (key));
				
			}
			
			if (!defines.exists ("NME_CONFIG")) {
				
				defines.set ("NME_CONFIG", ".hxcpp_config.xml");
				
			}
			
			var target:String = words[1];
			
			if (target == "cpp") {
				
				if (defines.get ("NME_HOST") == "windows") {
					
					target = "windows";
					
				} else if (defines.get ("NME_HOST") == "linux") {
					
					target = "linux";
					
				} else if (defines.get ("NME_HOST") == "darwin-x86") {
					
					target = "mac";
					
				} else {
					
					throw ("Error: " + defines.get("NME_HOST") + " is not a recognized host platform");
					
				}
				
			}
			
			create(nme, command, defines, includePaths, words[0], target, verbose, debug);
		}
		
	}
	
	
}