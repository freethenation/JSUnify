falafel = if  window? and window.falafel? then window.falafel else require('falafel')
compile=(src)->
	inFuncExpr=(node)->
		if  not node? then return false
		if not node.inFuncExpr?
			node.inFuncExpr = if node.type == "FunctionExpression" then true else inFuncExpr(node.parent)
		return node.inFuncExpr
	inCallExpr=(node)->
		if not node? then return false
		if not node.inCallExpr?
			node.inCallExpr = if node.type == "CallExpression" then true else inCallExpr(node.parent)
		return node.inCallExpr
	setIsRule=(node, isRule)->
		if not node? then return
		node.isRule = isRule
		setIsRule(node.parent, isRule)
		return
	getIsRule=(node)-> !node.isRule? || node.isRule
	ret = []
	#ret.push "//This program was complied using JSUnify compiler version 1.0"
	#ret.push "settings = {};"
	#ret.push "var Var = JSUnify.Var;"
	#ret.push "var p = new JSUnify.Program();"
	ret.push falafel(src, (node)->
		if inFuncExpr(node) then return # If we are inside a function def then we do not want to do any processing
		s = []
		if node.type == "ExpressionStatement" and getIsRule(node)
			s.push "p.rule(#{ node.expression.source() });"
		if node.type == "CallExpression"
			s.push "{#{node.callee.name}:["
			s.push  (n.source() for n in node.arguments).join(',')
			s.push "]}"
		if inCallExpr(node)
			if node.type == "Identifier"
				s.push "Var(\"#{node.name}\")"
			if node.type == "BinaryExpression" || node.type == "LogicalExpression"
				ops =
					"+":"add"
					"-":"sub"
					"*":"mult"
					"/":"div"
					"==":"eq"
				if ops[node.operator]?
					s.push("\"#{ ops[node.operator] }\":[#{ node.left.source() }, #{ node.right.source() }]")			
		else	
			if node.type == "AssignmentExpression"
				setIsRule(node, false)
			if node.type == "LogicalExpression" || node.type == "BinaryExpression"
				s.push node.left.source() + "," + node.right.source()
		if s.length > 0 then node.update(s.join(""))
		return
	).toString()
	#ret.push "if(typeof(window) == 'undefined') { } else {window.JSUnify.programs}"
	return  ret.join('\n')
extern "compile", compile