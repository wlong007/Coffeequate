define ["parse", "generateInfo"], (parse, generateInfo) ->

	# Terminals for the equation tree.

	class Terminal
		# Base class for terminals.
		constructor: (@label) ->

		evaluate: ->

		copy: ->
			return new Terminal(@label)

		toString: ->
			@label

	class Constant extends Terminal
		# Constants in the equation tree, e.g. 1/2
		constructor: (value, @denominator=null) ->
			@cmp = -6

			if @denominator?
				[@numerator, denominator] = parse.constant(value)
				@denominator *= denominator
			else
				[@numerator, @denominator] = parse.constant(value)

		evaluate: ->
			@numerator/@denominator

		copy: ->
			return new Constant(@numerator, @denominator)

		compareSameType: (b) ->
			# Compare this object with another of the same type.
			if @evaluate() < b.evaluate()
				return -1
			else if @evaluate() == b.evaluate()
				return 0
			else
				return 1

		multiply: (b) ->
			# Multiply by another constant and return the result.
			return new Constant(@numerator * b.numerator, @denominator * b.denominator)

		add: (b) ->
			# Add another constant and return the result.
			return new Constant(b.denominator * @numerator + @denominator * b.numerator, @denominator * b.denominator)

		equals: (b) ->
			# Test equality between this object and another.
			unless b instanceof Constant
				return false
			return @evaluate() == b.evaluate()

		replaceVariables: (replacements) ->
			@copy() # Does nothing - this is a constant.

		getAllVariables: ->
			[]

		sub: (substitutions) ->
			@copy()

		simplify: ->
			@copy()

		expand: ->
			@copy()

		expandAndSimplify: ->
			@copy()

		substituteExpression: (sourceExpression, variable, equivalencies) ->
			[@copy()]

		getVariableUnits: ->
			null

		toMathML: (equationID, expression=false, equality="0", topLevel=false) ->
			# Return this constant as a MathML string.
			if topLevel
				[mathClass, mathID, html] = generateInfo.getMathMLInfo(equationID, expression, equality)
				closingHTML = "</math></div>"
			else
				html = ""
				closingHTML = ""

			if @denominator == 1
				return html + "<mn class=\"constant\">#{@numerator}</mn>" + closingHTML
			return html + "<mfrac class=\"constant\"><mrow><mn>#{@numerator}</mn></mrow><mrow><mn>#{@denominator}</mn></mrow></mfrac>" + closingHTML

		toHTML: (equationID, expression=false, equality="0", topLevel=false) ->
			# Return this constant as an HTML string.
			[mathClass, mathID, html] = generateInfo.getHTMLInfo(equationID, expression, equality)

			unless topLevel
				html = ""
				closingHTML = ""
			else
				closingHTML = "</div>"

			if @denominator == 1
				return html + "#{@numerator}" + closingHTML
			return html + "(#{@numerator}/#{@denominator})" + closingHTML

		toLaTeX: ->
			# Return this constant as a LaTeX string.
			if @denominator == 1
				return "#{@numerator}"
			return "\\frac{#{@numerator}}{#{@denominator}}"

		toString: ->
			unless @denominator == 1
				return "#{@numerator}/#{@denominator}"
			return "#{@numerator}"

		differentiate: (variable) ->
			return new Constant(0)

	class SymbolicConstant extends Terminal
		# Symbolic constants in the equation tree, e.g. π
		constructor: (@label, @value=null) ->
			@cmp = -5

			@units = null

		copy: ->
			return new SymbolicConstant(@label, @value)

		compareSameType: (b) ->
			# Compare this object with another of the same type.
			if @label < b.label
				return -1
			else if @label == b.label
				return 0
			else
				return 1

		evaluate: ->
			@value

		equals: (b) ->
			unless b instanceof SymbolicConstant
				return false
			return @label == b.label and @value == b.value

		replaceVariables: (replacements) ->
			@copy() # Does nothing - this is a constant.

		getAllVariables: ->
			[]

		sub: (substitutions) ->
			@copy()

		simplify: ->
			@copy()

		expand: ->
			@copy()

		expandAndSimplify: ->
			@copy()

		substituteExpression: (sourceExpression, variable, equivalencies) ->
			[@copy()]

		getVariableUnits: ->
			null

		toHTML: (equationID, expression=false, equality="0", topLevel=false) ->
			if topLevel
				[mathClass, mathID, html] = generateInfo.getHTMLInfo(equationID, expression, equality)
				closingHTML = "</div>"
			else
				html = ""
				closingHTML = ""
			return html + "<span class=\"constant symbolic-constant\">" + @toString() + "</span>" + closingHTML

		toMathML: (equationID, expression=false, equality="0", topLevel=false) ->
			if topLevel
				[mathClass, mathID, html] = generateInfo.getMathMLInfo(equationID, expression, equality)
				closingHTML = "</math></div>"
			else
				html = ""
				closingHTML = ""

			"#{html}<mn class=\"constant symbolic-constant\">#{@label}</mn>#{closingHTML}"

		toLaTeX: ->
			"\\text{#{@toString()}}"

		differentiate: (variable) ->
			return new Constant(0)

	class Variable extends Terminal
		# Variables in the equation tree, e.g. m
		constructor: (@label) ->
			@cmp = -4

			@units = null

		copy: ->
			return new Variable(@label)

		compareSameType: (b) ->
			# Compare this object with another of the same type.
			if @label < b.label
				return -1
			else if @label == b.label
				return 0
			else
				return 1

		equals: (b, equivalencies=null) ->
			# Check equality between this and some other object.
			unless b instanceof Variable
				return false

			if equivalencies?
				return @label in equivalencies.get(b.label)
			else
				return b.label == @label

		replaceVariables: (replacements) ->
			if @label of replacements
				@label = replacements[@label]

		getAllVariables: ->
			[@label]

		sub: (substitutions) ->
			if @label of substitutions
				substitute = substitutions[@label]
				if substitute.copy?
					return substitute.copy()
				else
					return new Constant(substitute)
			else
				return @copy()

		substituteExpression: (sourceExpression, variable, equivalencies=null, eliminate=false) ->
			# Replace all instances of a variable with an expression.

			# Generate an equivalencies index if necessary.
			if not equivalencies?
				equivalencies = {get: (variable) -> [variable]}

			variableEquivalencies = equivalencies.get(variable)

			# Eliminate the target variable if set to do so.
			if eliminate
				sourceExpressions = sourceExpression.solve(variable)
			else
				sourceExpressions = [sourceExpression]
			if @label == variable or @label in variableEquivalencies
				return (e.copy() for e in sourceExpressions)
			else
				return [@copy()]

		getVariableUnits: (variable, equivalencies) ->
			if equivalencies?
				if @label in equivalencies.get(variable)
					return @units
			else if @label == variable
				return @units
			return null

		simplify: ->
			@copy()

		expand: ->
			@copy()

		expandAndSimplify: ->
			@copy()

		toMathML: (equationID, expression=false, equality="0", topLevel=false) ->
			# Return the variable as a MathML string.
			if topLevel
				[mathClass, mathID, html] = generateInfo.getMathMLInfo(equationID, expression, equality)
				closingHTML = "</div>"
			else
				html = ""
				closingHTML = ""

			# The ID of the variable will wind up being variable-equation/expression-equationID-@label
			# E.g. variable-expression-1-p-0

			# Strip the ID off of the variable, if it has one.
			labelArray = @label.split("-")
			label = labelArray[0]
			labelID = if labelArray[1]? then 'id="variable-' + (if expression then "expression" else "equation") + "-#{equationID}-" + @label + '"' else ""

			atCount = 0
			while label[0] == "@"
				atCount += 1
				label = label[1..]

			atStart = "<mover accent=\"true\">"
			atEnd = "<mrow><mo>" + ("." for i in [0...atCount]).join("") + "</mo></mrow></mover>"

			if label.length > 1
				return html + atStart + '<msub class="variable"' + labelID + '><mi>' + label[0] + '</mi><mi>' + label[1..] + "</mi></msub>" + atEnd + closingHTML
			else
				return html + atStart + '<mi class="variable"' + labelID + '>' + label + '</mi>' + atEnd + closingHTML

		toHTML: (equationID, expression=false, equality="0", topLevel=false) ->
			# Return an HTML string representing the variable.
			if topLevel
				[mathClass, mathID, html] = generateInfo.getHTMLInfo(equationID, expression, equality)
				closingHTML = "</div>"
			else
				html = ""
				closingHTML = ""

			# Strip the ID off of the variable, if it has one.
			labelArray = @label.split("-")
			label = labelArray[0]
			labelID = if labelArray[1]? then 'id="variable-' + (if expression then "expression" else "equation") + "-#{equationID}-" + @label + '"' else ""
			return html + '<span class="variable"' + labelID + '>' + label + '</span>' + closingHTML

		toLaTeX: ->
			# Convert -'s to _'s, and subscript everything.
			str = @label.replace("-", "_")
			if str.length > 1
				str = str[0] + "_{" + str[1..] + "}"
			return str

		differentiate: (variable) ->
			if variable == @label
				return new Constant(1)
			return new Constant(0)

	return {

		Terminal: Terminal

		Variable: Variable

		Constant: Constant

		SymbolicConstant: SymbolicConstant

	}