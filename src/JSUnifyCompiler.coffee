falafel = if typeof(module)=='undefined' then window.falafel else require('free-falafel')

compile=(src)->
    depthFirstFn = (node)->
        if node.unifyType == null then return
        indent = (new Array(node.unifyIndent + 5)).join(" ")
        if node.unifyType == "JsUnifyCall"
            node.update([
                "(function(){"
                "var JSUnify = typeof(module) == 'undefined' || typeof(require) == 'undefined' ? window.JSUnify : require('jsunify');"
                "var Var = JSUnify.Var;"
                if node.isUnifyProg then "return new JSUnify.Program()\n#{ node.arguments[0].source() }" else "return #{ node.arguments[0].source() };"
                "})()"
                ].join("\n" + indent))
        else if node.unifyType == "ProgramRoot"
            node.update(node.body.source())
        else if node.unifyType == "OutCall"
            if node.type == "LogicalExpression" or node.type == "BinaryExpression"
                node.update("#{ node.left.source() }, #{ node.right.source() }")
            else if node.type == "ExpressionStatement"
                node.update("#{ indent }.rule(#{ node.expression.source() })")
            else if node.type == "BlockStatement"
                node.update((n.source() for n in node.body).join('\n'))
        else if node.unifyType == "ExprRoot" or node.unifyType == "InCall"
            if node.type == "CallExpression"
                node.update([
                    "[\"#{node.callee.name}\","
                    (n.source() for n in node.arguments).join(',')
                    "]"
                    ].join(""))
            else if node.type == "Identifier"
                node.update("Var(\"#{node.name}\")")
            else if node.type == "LogicalExpression" or node.type == "BinaryExpression"
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
                    node.update("[\"#{ ops[node.operator] }\", #{ node.left.source() }, #{ node.right.source() }]")
        return
    
    #util functions to detect node types
    isJsUnifyCall = (node) -> node.type == "CallExpression" and node.callee.name == "$jsunify"
    isJsProgramOrExprRoot = (node) ->  node.parent? and isJsUnifyCall(node.parent)
    #util vars
    descendantNodeTypes = {ProgramRoot:"OutCall", ExprRoot:"InCall", ProgramRoot:"OutCall", InCall:"InCall", OutCall:"OutCall"}
    
    breathFirstFn = (node)->
        #detect jsunify node type 
        if isJsUnifyCall(node) 
            node.unifyType = "JsUnifyCall"
            node.unifyIndent = node.loc.start.column
        else if isJsProgramOrExprRoot(node)
            node.unifyType = if node.type == "FunctionExpression" then "ProgramRoot" else "ExprRoot"
            node.isUnifyProg = node.type == "FunctionExpression"
            node.parent.isUnifyProg = node.isUnifyProg
        else if node.type == "FunctionExpression" # functions other than root should not be transformed
            node.unifyType = null
        else if node.type == "CallExpression" and node.parent?.unifyType? #if call and parent has a unifyType then we are "InCall"
            node.unifyType = "InCall"
        else if node.parent? #If we have a parent inherit
            node.unifyType = if node.parent.unifyType == null then null else descendantNodeTypes[node.parent.unifyType]
        else #default to no unify type
            node.unifyType = null
        #set isUnifyProg
        if node.unifyType != null and node.parent?.isUnifyProg? and not node.isUnifyProg?
            node.isUnifyProg = node.parent.isUnifyProg
         # set node.unifyIndent
         if node.unifyType != null and not node.unifyIndent? and node.parent?.unifyIndent?
            node.unifyIndent = node.parent.unifyIndent
        return
    
    return falafel(src, { loc:true }, depthFirstFn, breathFirstFn).toString()

extern "compile", compile