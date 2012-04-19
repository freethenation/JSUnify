runtests=()->
    test "placeholder", ()->
        ok(true)
    
extern=(name, o)->window[name] = o
extern "RunJSUnifyLangUnitTests", runtests
