falafel = if  window? and window.falafel? then window.falafel else require('./falafel.js')
compile=(src, settings={})->
    inCallExpr=(node)->
        if not node? then return false
        if not node.inCallExpr?
            node.inCallExpr = if node.type == "CallExpression" then true else inCallExpr(node.parent)
        return node.inCallExpr
    ret = []    
    depthFirstFn = (node)->
        if node.ignore then return
        s = []
        if node.type == "ExpressionStatement"
            s.push "p.rule(#{ node.expression.source() });"
        if node.type == "CallExpression"
            s.push "{#{node.callee.name}:["
            s.push  (n.source() for n in node.arguments).join(',')
            s.push "]}"
        if node.type == "Identifier"
            s.push "Var(\"#{node.name}\")"
        if node.type == "LogicalExpression" or node.type == "BinaryExpression"
            if inCallExpr(node)
                ops =
                    "+":"add"
                    "-":"sub"
                    "*":"mult"
                    "/":"div"
                    "==":"eq"
                    "===":"eq"
                    "%":"mod"
                    "!=":"neq"
                    "!==":"neq"
                    ">":"greater"
                    "<":"less"
                    ">=":"greaterOrEqual"
                    "<=":"lessOrEqual"
                    "&&":"and"
                    "||":"or"
                if ops[node.operator]?
                    s.push("{#{ ops[node.operator] }:[#{ node.left.source() }, #{ node.right.source() }]}")    
            else
                s.push node.left.source() + "," + node.right.source()    
        if s.length > 0 then node.update(s.join(""))
        return
    
    breathFirstFn = (node)->
        if node.type == "FunctionExpression"
            node.ignore = true
        else if node.type == "ExpressionStatement" and node.parent.type == "Program" and node.expression.type == "CallExpression" and node.expression.callee.type != "FunctionExpression"
            node.ignore = false
        else if node.type == "ExpressionStatement" and node.parent.type == "Program" and (node.expression.type == "LogicalExpression" or node.expression.type == "BinaryExpression")
            node.ignore = false
        else if node.parent? and node.parent.ignore?
            node.ignore = node.parent.ignore
        else
            node.ignore = true
    
    if  not settings.isExpression? or not settings.isExpression
        ret.push "//This program was complied using JSUnify compiler v0.8.0"
        ret.push "(function(){"
        ret.push "var JSUnify;"
        ret.push "if (typeof module !== \"undefined\" && typeof require !== \"undefined\") { JSUnify = require('./JSUnifyCompiler.js'); }"
        ret.push "else { JSUnify = window.JSUnify; }"
        ret.push "var p = new JSUnify.Program();"
        ret.push "var prog = p;"
        ret.push "var settings = p.settings;"
        ret.push "var Var = JSUnify.Var;"
    
    ret.push falafel(src, {}, depthFirstFn, breathFirstFn).toString()
    if  not settings.isExpression? or not settings.isExpression
        for name, value of settings
            ret.push "settings[\"#{name}\"] = #{value};"
        ret.push "if (typeof module !== \"undefined\" && typeof require !== \"undefined\") {  module.exports = p; }"
        ret.push "else { window[settings.name] = p; }"
        ret.push "})();"
        
    #ret.push "if(typeof(window) == 'undefined') { } else {window.JSUnify.programs}"
    return  ret.join('\n')
extern "compile", compile