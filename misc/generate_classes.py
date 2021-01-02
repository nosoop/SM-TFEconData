#!/usr/bin/python3

import toml
import chevron
import pathlib
import argparse

definitions = [
	"classdata/econ_item_definition.toml",
	"classdata/econ_item_schema.toml",
]

def transform_class_definition(data):
	# given a class definition TOML file, returns a dict appropriate for the class definition template
	
	# get top-level keyvalues
	output = {
		k: v for k, v in data.items() if k in ('classname', 'inherits', 'sourcefile', 'size')
	}
	
	# flattens properties subdicts into list and attaches the property name
	output['properties'] = [
		{ 'name': key, **value }
		for key, value in definition.get('properties', {}).items()
		if isinstance(value, dict)
	]
	
	output['decl_variables'] = []
	for i, prop in enumerate(output.get('properties', [])):
		# inlined values return the address interpreted as the type, instead of dereferencing
		# this is indicated by the '@' prefix for type
		if prop.get('type', '').startswith('@'):
			prop['inline'] = True
			prop['type'] = prop['type'].lstrip('@')
		
		# declvar entries are treated as symbols that need variable declarations
		if prop.get('declvar', False):
			output['decl_variables'].append({ 'var': prop.get('offset') })
		output['properties'][i] = prop
	
	return output

if __name__ == '__main__':
	parser = argparse.ArgumentParser(
			description = "Patches various useless messsages out of the given binary")
	
	parser.add_argument('template', help = "Template to use", type = pathlib.Path)
	parser.add_argument('data', help = "TOML definition file", type = pathlib.Path)
	parser.add_argument('output', help = "Output file", type = pathlib.Path)
	
	args = parser.parse_args()
	
	with args.template.open('rt') as f:
		template = f.read()
		definition = toml.load(args.data)
		definition['sourcefile'] = args.data.stem
		result = chevron.render(template, transform_class_definition(definition))
		with args.output.open('wt') as g:
			g.write(result)
