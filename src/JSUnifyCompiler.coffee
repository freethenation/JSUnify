falafel = if  window? and window.falafel? then window.falafel else irequire('falafel')
compile=(src)->
	inFunc=(node)->
		if  not node? then return false
		if not node.inFunc?
			node.inFunc = if node.type == "FunctionExpression" then true else inFunc(node.parent)
		return node.inFunc
	
	return falafel(src, (node)->
		if inFunc(node) then return # If we are inside a function def then we do not want to do any processing
		s = []
		if node.type == "CallExpression"
			s.push "{#{node.callee.name}:["
			s.push  (n.source() for n in node.arguments).join(',')
			s.push "]}"
		if node.type == "Identifier"
			s.push "Var(\"#{node.name}\")"
		if node.type == "LogicalExpression"
			s.push node.left.source()
			s.push ","
			s.push node.right.source()
		if node.type == "BinaryExpression"
			s.push node.left.source()
			s.push ","
			s.push node.right.source()
		if node.type == "ExpressionStatement"
			s.push "p.rule("
			s.push node.expression.source()
			s.push ");"
		if s.length > 0 then node.update(s.join(''))
		return
	)
extern "compile", compile