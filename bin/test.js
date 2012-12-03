//This program was complied using JSUnify compiler v0.8.0
(function(){
var JSUnify;
if (typeof window != 'undefined' && typeof window.JSUnify != 'undefined' ) { JSUnify = window.JSUnify; }
else { JSUnify = require('JSUnifyCompiler'); }
var p = new JSUnify.Program();
var prog = p;
var settings = p.settings;
var Var = JSUnify.Var;
//test "Snowy Chicago", () ->
settings.name = "SnowyChicago";
p.rule({snowy:[Var("X")]},{cold:[Var("X"),Var("Y")]},{rainy:[Var("X"),Var("Y")]});
p.rule({rainy:['cinci',1]});
p.rule({rainy:['chicago',1]});
p.rule({cold:['chicago',1]});
if (typeof module !== "undefined" && typeof require !== "undefined") {  module.exports = p; }
else { window[settings.name] = p; }
})();