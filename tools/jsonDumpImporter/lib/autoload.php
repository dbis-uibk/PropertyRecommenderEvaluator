<?php
spl_autoload_register(function ($className) {
	$className = str_replace('\\', DIRECTORY_SEPARATOR, $className);
	$classFile = array(
		LIB_DIR.$className.'.php',
	);

	foreach($classFile as $file) {
		if (file_exists($file)) {
            require_once $file;
            return true;
		}
	}
    
	return false;
});
