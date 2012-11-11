falafel = if  window? and window.falafel? then window.falafel else irequire('falafel')
compile=(src)->
	return falafel(src, (node)->
		if node.type == "CallExpression"
			s = []
			s.push "{#{node.callee.name}:["
			s.push  (n.source() for n in node.arguments).join(',')
			s.push "]}"
			node.update(s.join(''))
		return
	)
extern "compile", compile