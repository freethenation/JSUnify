# JSUnify
JSUnify is a declarative JavaScript DSL(domain specific language) for logic programming. JSUnify consists of three major components

* A backward chaining rule engine.
* A powerful [unification engine](https://github.com/freethenation/unify.js).
* A compiler that compiles JSUnify to JavaScript.

JSUnify is very different then JavaScript. If you have ever used Prolog or another logic programming language then the concepts in JSUnify should be simple to grasp. If not then this readme will introduce you to a new programming paradigm.

# Status of JSUnify
JSUnify is under active development and is currently in beta and should not be used in production yet. That being said I would love any feedback or suggestions about the language or this readme.

### Features left to implement

* Tail call optimization
* A standard library
* Library loading
* Or operator in rules
* Finish command line tool
* Finish this README

# Why use JSUnify?
JSUnify is very good at some tasks. AI, symbolic math, and expert systems are all excellent uses for JSUnify. These tasks are not easy to achieve in an imperative language such as JavaScript. JSUnify is not good at IO, DOM manipulation, or really anything easily done easily in an imperative language like JavaScript. That is why JSUnify is a DSL (domain specific language) you can you JSUnify where it makes sense and JavaScript every where else.

# Fact, Rules and Queries
JSUnify programs consist of three main components, facts, rules, and queries. Facts and rules are combined in order to make a knowledge base. You use a JSUnify program by querying a knowledge base.

### Example 1
This first knowledge base is simply a collection of facts.

```javascript
var knowlagebase = $jsunify(function(){
	woman("sue"); //This is fact 1
	man("bob"); //This is fact 2
	man("frank"); //This says frank is man
});
```

The above code creates a knowledge base containing three facts. The first and last line in the example will be explained later. So how do we use this knowledge base? We query it like so!

```javascript
if (knowlagebase.query($jsunify(man("frank")))) {
  console.log("frank is a man!");
}
else { console.log("frank is NOT a man!") }
//Above code should print "frank is a man!"
```

```javascript
if (knowlagebase.query($jsunify(man("sue")))) {
  console.log("sue is a man!")
}
else { console.log("sue is NOT a man!") }
```

Ok, I think the queries above are fairly obvious. In the first example we are asking if there is a man in named frank aka `man("frank")`. There is so the console should display "frank is a man!". The second example asks if there is a man named sue. There is not so "sue is NOT a man!" is written to the console.

### A note about the `$jsunify` function

As mentioned before JSUnify includes a complier. The compiler is optional and does not have to be used but provides syntactic sugar making significantly easer to write and read JSUnify programs. The `$jsunify` function is a flag that tells the compiler to process the code inside of the `$jsunify` function call. If the code inside of the `$jsunify` function call is an anonymous function then the code is compiled to a JSUnify program. If the code is simply an expression it is compiled to JSUnify's json format. This is mainly used to create quires.

### Example 2

The second knowledge base contains the same facts as last time and a two rules.

```javascript
var knowlagebase = $jsunify(function(){
	woman("sue"); //This is fact 1
	man("bob"); //This is fact 2
	man("frank"); //This says frank is man
    hasCar("bob"); //This says bob has a car
    hasCar("sue"); //This says sue has a car
    //If bob has a car then he car drive
    canDrive("bob") == hasCar("bob"); 
    //If X is a man then X is a good driver ;)
    goodDriver(X) == man(X) && hasCar(X);
});
```

Look at the line `canDrive("bob") == hasCar("bob");`. This is a rule. A rule is made of two parts 1) a head and 2) a tail. The head is only true if the body is true. In this case the head is `canDrive("bob")` and the tail is `hasCar("bob")`. If you look further up in the knowledge base you will see that bob does indeed have a car so the query `canDrive("bob")` should succeed.

```javascript
if (knowlagebase.query($jsunify(canDrive("bob")))) {
  console.log("bob can drive!")
}
else { console.log("bob can NOT drive!") }
//This example should print "bob can drive!" to the console.
```

Now look at the rule `goodDriver(X) == man(X) && hasCar(X);`. Notice that this line has two conditions to the body of the rule, `man(X)` and `hasCar(X)`. This line also introduces variables. In the rule `X` is a variable and can be bound to a value.

```javascript
if (knowlagebase.query($jsunify(goodDriver("bob")))) {
  console.log("bob is a good driver!");
}
else { console.log("bob is NOT a good driver!") }
//1) JSUnify finds the rule goodDriver(X) == man(X) && hasCar(X);
//   and binds X to "bob" essentially introducing the rule 
//   goodDriver("bob") == man("bob") && hasCar("bob") to the database.
//2) JSUnify tries to satisfy the first condition man("bob") and succeeds
//3) JSUnify tries to satisfy the second condition hasCar("bob") and succeeds
//4) JSUnify, satisfying all the conditions, asserts goodDriver("bob")
//5) "bob is a good driver!" is printed to the console.
```
```javascript
if (knowlagebase.query($jsunify(goodDriver("frank")))) {
  console.log("frank is a good driver!");
}
else { console.log("frank is NOT a good driver!") }
//1) JSUnify finds the rule goodDriver(X) == man(X) && hasCar(X);
//   and binds X to "frank" essentially introducing the rule 
//   goodDriver("frank") == man("frank") && hasCar("frank") to the database.
//2) JSUnify tries to satisfy the first condition man("frank") and succeeds
//3) JSUnify tries to satisfy the second condition hasCar("frank") and fails
//4) JSUnify, NOT satisfying all the conditions, failes to resolve the query.
//5) "frank is NOT a good driver!" is printed to the console.
```

Variables can also be used in queries. For example lets say you wanted to know who is a good driver.

```javascript
var res = knowlagebase.query($jsunify(goodDriver(X)));
if (res) {
  console.log(res.get("X") + " is a good driver!");
}
else { console.log("There are NOT ANY good drivers!") }
//1) JSUnify finds the rule goodDriver(X) == man(X) && hasCar(X);
//2) JSUnify tries to satisfy the first condition man(X) and succeeds by
//   binding X to "bob" and matching the man("bob")
//3) JSUnify tries to satisfy the second condition hasCar("bob"). Remember 
//   X has been bound to "bob".
//4) JSUnify, satisfying all the conditions, asserts goodDriver("bob")
//5) "bob is a good driver!" is printed to the console. Note: res.get("X")
//   returns the value bound to X in the query after the query is a success.
```

### A note about JSUnify and proof search

JSUnify attempts to satisfy a query(aka goal) by looking at each rule/fact in order (from top to bottom) and unifying that rule/fact with the goal. If you are unfamiliar with unification I suggest you read the [documentation for unify.js](https://github.com/freethenation/unify.js) (the library JSUnify uses to preform unification). If the goal unifies successfully with a rule then the rule's conditions become the new goals. If the rule has no conditions (aka its a fact) then no new goals are created and the query succeeds. I think an example is in order.

### Example 3

```javascript
var knowlagebase = $jsunify(function(){
    snowy(X) == rainy(X,Y) && cold(X,Z); //rule 1
    rainy("cinci", "very");              //rule 2
    rainy("chicago", "little");          //rule 3
    cold("chicago", "really");           //rule 4
});
var res = knowlagebase.query($jsunify(snowy(K)));
if (res) {
  console.log("Its snowy in " + res.get("K"));
}
else { console.log("Its NOT snowy anywhere!"); }
```

Alright, a trace of JSUnify's proof search:

1. `snowy(K)` is added to the list of goals
2. The goal `snowy(K)` is satisfied by rule 1 and its two conditions (`rainy(X,Y)` and `cold(X,Y)`) become the new goals.
3. The goal `rainy(X,Y)` is satisfied by rule 2 binding `X` to `"cinci"` and `Y` to `"very"`.
4. Because there are no conditions JSUnify moves to the next goal, `cold("cinci",Z)` (Remember X was bound to "cinci").
5. The goal `cold("cinci",Z)` can not be satisfied so JSUnify backtracks and negates steps 3 and 4 instead satisfying `rainy(X,Y)` with rule 3.
6. Because there are no conditions JSUnify moves to the next goal, `cold("chicago",Z)`.
7. The goal `cold("chicago",Z)` is satisfied using rule 4.
8. There are no more goals so the search is complete!