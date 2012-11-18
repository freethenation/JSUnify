falafel = if  window? and window.falafel? then window.falafel else require('falafel')
compile=(src)->
	ignore=(node)->
		if  not node? then return false
		if not node.ignore?
			node.ignore = if node.type == "FunctionExpression" or 
				node.type == "AssignmentExpression" then true else ignore(node.parent)
		return node.ignore
	ret = []
	ret.push "//This program was complied using JSUnify compiler version 1.0"
	ret.push "settings = {};"
	ret.push "var Var = JSUnify.Var;"
	ret.push "var p = new JSUnify.Program();"
	ret.push falafel(src, (node)->
		if ignore(node) then return # If we are inside a function def then we do not want to do any processing
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
		if node.type == "BinaryExpression" and node.operator == "=="
			s.push node.left.source()
			s.push ","
			s.push node.right.source()
		else if node.type == "BinaryExpression"
			ops = {
				"+":"add"
				"-":"sub"
				"*":"mult"
				"/":"div"
			}
			if ops[node.operator]?
				s.push("\"#{ops[node.operator]}\":[#{node.left.source()},#{node.right.source()}]")			
		if node.type == "ExpressionStatement" and node.expression.ignore? and !node.expression.ignore
			s.push "p.rule("
			s.push node.expression.source()
			s.push ");"
		if s.length > 0 then node.update(s.join(""))
		return
	).toString()
	#ret.push "if(typeof(window) == 'undefined') { } else {window.JSUnify.programs}"
	return  ret.join('\n')
extern "compile", compile