falafel = if  window? and window.falafel? then window.falafel else irequire('falafel')
compile=(src)->
	inFunc=(node)->
		if  not node? then return false
		if not node.inFunc?
			node.inFunc = if node.type == "FunctionExpression" then true else inFunc(node.parent)
		return node.inFunc
	return falafel(src, (node)->
		if inFunc(node) then return
		s = []
		if node.type == "CallExpression"
			s.push "{#{node.callee.name}:["
			s.push  (n.source() for n in node.arguments).join(',')
			s.push "]}"
		if s.length > 0 then node.update(s.join(''))
		return
	)
extern "compile", compile

#FunctionExpression