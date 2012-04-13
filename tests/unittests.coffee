 $(document).ready(()->
    
    module "Example module"
    
    test "Example test", ()->
        expect(2);
        equal( true, true, "passing test" );
        equal( true, false, "failing test" );
 )