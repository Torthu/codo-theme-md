FS      = require 'fs'
Path    = require 'path'
mkdirp  = require 'mkdirp'
_       = require 'lodash'
Theme   = require './_theme'
Util    = require 'util'

renderClass = require './renderClass.coffee'

module.exports = class Theme.Templater
	constructor: (@destination) ->

	class: (entity, cb, context) ->
		obj = entity.inspect()
		obj["descendants"] = entity.descendants.filter (m) -> m.visible
		obj["inheritedMethods"] = entity.inheritedMethods().filter (m) -> m.entity.visible
		obj["methods"] = entity.effectiveMethods().filter (m) -> m.visible
		obj["inheritedProperties"] = entity.inheritedProperties().filter (p) -> p.visible
		cb renderClass(obj, context.environment)

	mixin: (entity, cb, context) ->
		obj = entity.inspect()

		cb JSON.stringify(obj, null, "\t")

	extra: (entity, cb, context) ->
		obj = entity.inspect()

		cb JSON.stringify(obj, null, "\t")

	index: (tree, cb, context) ->

		template = '# Overview \n\n'

		tree.map (item) ->
			template += "- [#{item.name}](./#{item.name}.md)\n"

		cb template

	# @param [String] template the template name
	# @param [Object] context the context object
	# @param [String] filename the output file name
	#
	render: (template, context = {}, filename = '') ->
		cb = (err, md) =>
			if filename.length > 0
				file = Path.join @destination, filename
				dir  = Path.dirname(file)

				mkdirp.sync(dir)

				if err
					FS.writeFileSync(file, err)

				else
					FS.writeFileSync(file, md)

		@[template](context.entity, cb, context)

