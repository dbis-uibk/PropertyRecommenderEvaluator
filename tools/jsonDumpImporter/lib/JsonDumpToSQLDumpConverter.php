<?php

require_once(ROOT_DIR . 'vendor/autoload.php');

use Wikibase\DataModel\Entity\BasicEntityIdParser;
use Wikibase\DataModel\DeserializerFactory;
use Wikibase\JsonDumpReader\JsonDumpFactory;
use DataValues\Deserializers\DataValueDeserializer;
use exceptions\NotImplementedException;

class JsonDumpToSQLDumpConverter {

    private static $dataValueClasses = [
        'boolean' => 'DataValues\BooleanValue',
        'number' => 'DataValues\NumberValue',
        'string' => 'DataValues\StringValue',
        'unknown' => 'DataValues\UnknownValue',
        'globecoordinate' => 'DataValues\Geo\Values\GlobeCoordinateValue',
        'monolingualtext' => 'DataValues\MonolingualTextValue',
        'multilingualtext' => 'DataValues\MultilingualTextValue',
        'quantity' => 'DataValues\QuantityValue',
        'time' => 'DataValues\TimeValue',
        'wikibase-entityid' => 'Wikibase\DataModel\Entity\EntityIdValue',
    ];
    private $jsonDumpFile;
    private $sqlDumpFile;

    public function __construct($jsonDumpFile, $sqlDumpFile) {
        if (!isset($jsonDumpFile)) {
            throw new InvalidArgumentException("No JSON dump file given!");
        }

        if (!file_exists($jsonDumpFile)) {
            throw new InvalidArgumentException("JSON dump file not found!");
        }

        if (!isset($sqlDumpFile)) {
            throw new InvalidArgumentException("No SQL dump file given!");
        }

        $this->jsonDumpFile = $jsonDumpFile;
        $this->sqlDumpFile = $sqlDumpFile;
    }

    public function convert($autocommit = true) {
        // open or create sql dump file
        $sqlFile = new SplFileObject($this->sqlDumpFile, "w");

        if (!$autocommit) {
            $sqlFile->fwrite("SET autocommit = 0;" . PHP_EOL);
        }

        // initialize json dump iterator
        $dataValueDeserializer = new DataValueDeserializer(self::$dataValueClasses);
        $deserializerFactory = new DeserializerFactory($dataValueDeserializer, new BasicEntityIdParser());
        $entityDeserializer = $deserializerFactory->newEntityDeserializer();

        $fileInfo = new finfo();
        $jsonDumpReader = null;
        $factory = new JsonDumpFactory();
        switch ($fileInfo->file($this->jsonDumpFile, FILEINFO_MIME_TYPE)) {
            case "application/x-gzip": $jsonDumpReader = $factory->newGzDumpReader($this->jsonDumpFile);
                break;
            case "application/x-bzip2": $jsonDumpReader = $factory->newBz2DumpReader($this->jsonDumpFile);
                break;
            default: throw new InvalidArgumentException("Unknown File Type!");
        }

        $iterator = $factory->newEntityDumpIterator($jsonDumpReader, $entityDeserializer);

        $lineCounter = 0;
        $tripleCounter = 0;
        $startTime = microtime(true);
        foreach ($iterator as $entity) {
            $lineCounter++;

            $pageId = $entity->getId()->getSerialization();
            $statements = $entity->getStatements();
            if ($statements->count() > 0) {
                foreach ($statements as $statement) {
                    $propertyId = $statement->getPropertyId()->getSerialization();

                    $mainSnak = $statement->getMainSnak();
                    $type = $this->getType($mainSnak);
                    try {
                        $value = $this->getValue($mainSnak);
                        $lang = $this->getLanguage($mainSnak);

                        $sql = $this->getSQL($pageId, $propertyId, $value, $lang, $type);
                        $sqlFile->fwrite($sql . PHP_EOL);
                    } catch (NotImplementedException $e) {
                        fwrite(STDERR, $e->getMessage() . " (page: " . $pageId . ", line: " . $lineCounter . ")" . PHP_EOL);

                        $sql = $this->getSQL($pageId, $propertyId, null, null, $type);
                        $sqlFile->fwrite($sql . PHP_EOL);
                    }

                    $tripleCounter++;
                }
            } else {
                $sql = $this->getSQL($pageId, null, null, null, null);
                $sqlFile->fwrite($sql . PHP_EOL);

                $tripleCounter++;
            }
        }

        if (!$autocommit) {
            $sqlFile->fwrite("COMMIT;" . PHP_EOL);
            $sqlFile->fwrite("SET autocommit = 1;" . PHP_EOL);
        }

        $elapsedTime = microtime(true) - $startTime;
        echo "Elapsed Time: " . $elapsedTime . " s = " . $elapsedTime / 3600 . " h" . PHP_EOL;
        echo "Number of entities in JSON: " . $lineCounter . "!" . PHP_EOL;
        echo "Number of triples: " . $tripleCounter . "!" . PHP_EOL;
    }

    private function getValue($snak) {
        $snakType = $snak->getType();
        if ($snakType == "value") {
            $dataValue = $snak->getDataValue();
            switch ($dataValue->getType()) {
                case "boolean":
                case "number":
                case "string":
                case "unknown":
                    return $dataValue->getValue();

                case "globecoordinate":
                    return $dataValue->getLatitude() . "°N, " . $dataValue->getLongitude() . "°E";
                case "monolingualtext":
                    return $dataValue->getText();

                case "multilingualtext":
                    // TODO implement (not sure how to handle)
                    throw new NotImplementedException("Handling type \"" . $dataValue->getType() . "\" not implemented!");

                case "quantity":
                    return $dataValue->getAmount()->getValue();
                case "time":
                    return $dataValue->getTime();
                case "wikibase-entityid":
                    return $dataValue->getEntityId()->getSerialization();

                default:
                    // TODO implement (not sure how to handle)
                    throw new NotImplementedException("Handling type \"" . $dataValue->getType() . "\" not implemented!");
            }
        } else {
            return $snakType;
        }
    }

    private function getLanguage($snak) {
        $snakType = $snak->getType();
        if ($snakType == "value") {
            $dataValue = $snak->getDataValue();
            switch ($dataValue->getType()) {
                case "boolean":
                case "number":
                case "string":
                case "unknown":
                case "globecoordinate":
                case "quantity":
                case "time":
                case "wikibase-entityid":
                    return null;

                case "monolingualtext":
                    return $dataValue->getLanguageCode();

                case "multilingualtext":
                    // TODO implement (not sure how to handle)
                    throw new NotImplementedException("Handling type \"" . $dataValue->getType() . "\" not implemented!");
                default:
                    // TODO implement (not sure how to handle)
                    throw new NotImplementedException("Handling type \"" . $dataValue->getType() . "\" not implemented!");
            }
        } else {
            return null;
        }
    }

    private function getType($snak) {
        $snakType = $snak->getType();
        if ($snakType == "value") {
            $dataValue = $snak->getDataValue();
            return $dataValue->getType();
        } else {
            return null;
        }
    }

    private function getSQL($pageId, $propertyId, $value, $lang, $type) {
        $sql = "CALL insertTriple(";

        $sql .= $this->prepareForSQL($pageId);
        $sql .= ", ";

        $sql .= $this->prepareForSQL($propertyId);
        $sql .= ", ";

        $sql .= $this->prepareForSQL($value);
        $sql .= ", ";

        $sql .= $this->prepareForSQL($lang);
        $sql .= ", ";

        $sql .= $this->prepareForSQL($type);
        $sql .= ");";

        return $sql;
    }

    private function prepareForSQL($variable) {
        if (isset($variable)) {
            return "\"" . addslashes($variable) . "\"";
        } else {
            return "NULL";
        }
    }

}
