import sys.io.File;
import haxeshim.Config;
import json2object.utils.special.VSCodeSchemaWriter;

class SchemaGenerator {
	static function main() {
		File.saveContent("schemas/.haxerc.schema.json", new VSCodeSchemaWriter<Config>("\t").schema);
	}
}
