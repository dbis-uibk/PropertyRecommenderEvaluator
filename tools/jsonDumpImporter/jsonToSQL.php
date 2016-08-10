<?php

define('ROOT_DIR', realpath(dirname(__FILE__)) . '/');
define('LIB_DIR', ROOT_DIR . 'lib/');

require_once(LIB_DIR . 'autoload.php');

if (count($argv) != 3) {
    echo "USAGE: php " . $argv[0] . " <json-dump-input> <sql-dump-output>\n";
    return;
} else {
    try {
        $converter = new JsonDumpToSQLDumpConverter($argv[1], $argv[2]);
        $converter->convert(false);
    } catch (InvalidArgumentException $e) {
        fwrite(STDERR, $e->getMessage() . PHP_EOL);
    }
}