environment = undefined

# References to MDN docs
# @private
_mdnTypeReferences =
	int: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'
	integer: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'
	float: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'
	number: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number'
	string: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String'
	str: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String'
	array: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array'
	arr: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array'
	object: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object'
	obj: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object'
	boolean: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Boolean'
	bool: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Boolean'
	function: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function'
	promise: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise'
	json: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON'
	set: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Set'
	map: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map'
	element: 'https://developer.mozilla.org/en-US/docs/Web/API/element'
	error: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error'
	math: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math'
	date: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date'
	splat: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Spread_operator'
	spread: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Spread_operator'
	args: 'https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Spread_operator'

# Find type reference (if defined)
# @param [String] typeName
# @return [String]
findType = (types) ->
	types = types.split(',')
	typesFound = []

	for typeName in types
		typeName = typeName.trim()



		if environment.references[typeName]?
			type = environment.reference(typeName)

		found = typeName.match(/<(.*?)>/)
		if found
			console.log 'found', found
			typeName = found[1].replace('<', '').replace('>', '')
			console.log 'found typeName', typeName

			if environment.references[typeName]?
				type = environment.reference(typeName)

			if _mdnTypeReferences[typeName.toLowerCase()]
				typesFound.push "Array< [#{typeName}](#{_mdnTypeReferences[typeName.toLowerCase()]}) >"

			else if type
				console.log "Array< [#{typeName}](#{typeName}.md) >"
				typesFound.push "Array< [#{typeName}](#{typeName}.md) >"

			else
				typesFound.push "Array< #{typeName} >"

		else if _mdnTypeReferences[typeName.toLowerCase()]
			typesFound.push "[#{typeName}](#{_mdnTypeReferences[typeName.toLowerCase()]})"
		else if type
			typesFound.push "[#{typeName}](#{typeName}.md)"
		else
			typesFound.push typeName


	return typesFound.join(' or ')

# Render a single method
# Used by renderMethods
# @param [String] str
# @param [Entity] method
# @return [String]
renderMethod = (str, method) ->

	if method.entity
		inherited = true
		method = method.entity

	if method.visible is false
		return str

	else
		if method.documentation?.params?.length > 0
			param = method.documentation.params.reduce (str, param) ->
				optionsStr = ''
				if method.documentation.options?[param.name]
					for option in method.documentation.options[param.name]
						type = findType(param.type)
						optionsStr += "| #{param.name}.**#{option.name}** | #{type} | #{option.description or ''} |\n"

				type = findType(param.type)
				str = str + "| **#{param.name}** | #{type} | #{param.description or ''} |\n"


				if optionsStr isnt ''
					str += """
					#{optionsStr}
					"""

				return str
			, ''

		if param? and param isnt ''
			param = """
			| Parameter | Type | Description |
			| --------- | ---- | ----------- |
			#{param}
			"""

		parameters = method.parameters?.join(', ')
		parameters ?= ''

		fixme = method.documentation?.fixme or= ''
		async = if method.documentation?.async then 'async' else ''

		return str + """
			### #{if method.documentation?.private then 'private ' else ''}#{if method.kind is 'static' then 'static' else ''} #{async} #{method.name} #{if inherited is true then '(inherited)' else ''}
			#{if method.documentation?.deprecated? then '\nWarning: This method is deprecated\n\n' else ''}
			**Signature:** #{if method.documentation?.private then 'private ' else 'public '}#{if method.kind is 'static' then 'static' else ''} #{method.name}(#{parameters}) -> #{async or method.documentation?.returns?.type.toLowerCase() or 'void'}

			#{if param? then param else ''}

			#{method.documentation?.summary or ''}

			---

		"""

# Render class methods
# @param [Entity] obj
# @return [String]
renderMethods = (obj) ->
	template = ''

	if obj.methods?.length > 0
		methods = obj.methods.reduce(renderMethod, '')

		template += """
			## Methods
			#{methods}
		"""

	if obj.inheritedMethods.length > 0
		console.log 'render inherited methods'
		methods = obj.inheritedMethods.reduce(renderMethod, '')

		template += """
		#{methods}
		"""
	else
		console.log 'not rendering inherited'

	return template

# Render class properties
# @param [Entity] obj
# @return [String]
renderProperties = (obj) ->
	template = ''
	if obj.properties?.length > 0
		properties = obj.properties.reduce (str, property) ->
			if property.documentation?.private
				return str
				# - [#{property.documentation?.property.toLowerCase()}] **#{property.name}** #{property.documentation?.summary.replace(/\n/g, ' ')}
			return str + """
				| #{property.name} | #{property.documentation?.property.toLowerCase()} | #{property.documentation?.summary.replace(/\n/g, ' ')} |

			"""
		, ''

		if properties isnt ''
			template += """
				## Properties
				| Property | Type | Description |
				| -------- | ---- | ----------- |
				#{properties}

			"""

		if obj.inheritedProperties.length > 0
			template += """
			### Inherited
			| Property | Type | Description |
			| -------- | ---- | ----------- |
			"""
			for property in obj.inheritedProperties()
				template += "| #{property.name} | #{property.documentation?.property.toLowerCase()} | #{property.documentation?.summary.replace(/\n/g, ' ')} |\n"

	return template

# Render class variables
# @param [Entity] obj
# @return [String]
renderVariables = (obj) ->
	template = ''
	if obj.variables?.length > 0
		properties = obj.variables.reduce (str, variable) ->
			if variable.documentation?.private
				return str
			else
				return str + """
					| **#{variable.name}** | #{if variable.constant then 'constant' else 'variable'} | #{variable.value?.replace(/\n/g, ' ')} | #{variable.kind} | #{variable.documentation?.summary.replace(/\n/g, ' ')} | \n
				"""
		, ''

		if properties isnt ''
			template += """
				| Name | Constant | Default | Type | Description |
				| ---- | -------- | ------- | ---- | ----------- |
				#{properties}

				"""

	return template

# Render the examples
# @param [Entity] obj
# @return [String]
renderExamples = (obj) ->
	template = ''
	if obj.documentation?.examples?.length > 0
		examples = obj.documentation.examples?.reduce (str = '', example) ->
			return str + """
				### #{example.title or= 'Example'}
				```
				#{example.code}
				```

			"""
		, ''

		template = """
		## Usage
		#{examples}
		"""

	return template

# Render overview of class
# @param [Entity] obj
# @return [String]
renderOverview = (obj) ->
	descendants = []
	for descendant in obj.descendants.filter((x) -> x.visible())
			descendants.push "[#{descendant.name}](#{descendant.name}.md)"

	template = """
		## Overview
		|     |     |
		| --- | --- |
		| **Inherits:** | [#{obj.parent?.name}](#{obj.parent?.name}.md) |
		| **Extended by:** | #{descendants.join(', ')} |
		| **Authors:** | #{obj.documentation?.authors?.join(', ')} |
		| **Copyright:** | #{obj.documentation?.copyright} |

		### Summary
		#{obj.documentation?.summary}

	"""

	return template

# Render a class
# @param [Entity] obj
# @param [Environment] env
# @return [String]
renderClass = (obj, env) ->
	environment = env

	return """
		# #{obj.name} (Class) #{if obj.documentation?.deprecated? then 'Deprecated' else ''}
		#{if obj.documentation?.deprecated? then 'Warning: This class is deprecated ' + obj.documentation?.deprecated else ''}

		#{renderOverview(obj)}
		#{renderProperties(obj)}
		#{renderMethods(obj)}
		#{renderExamples(obj)}
	"""

module.exports = renderClass
