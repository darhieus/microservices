##To be added;

returning errors
documenting functions
empty-tables


# Lua Style Guide

This style guide contains a list of guidelines that we try to follow for the
Kong codebase.

This style guide started as a copy of the [[Olivine Labs style guide]](https://github.com/Olivine-Labs/lua-style-guide/blob/master/README.md#TOC)


## <a name='TOC'>Table of Contents</a>

  1. [Tables](#tables)
  1. [Strings](#strings)
  1. [Functions](#functions)
  1. [Properties](#properties)
  1. [Variables](#variables)
  1. [constants](#constants)
  1. [Conditional Expressions & Equality](#conditionals)
  1. [Blocks](#blocks)
  1. [Whitespace](#whitespace)
  1. [Commas](#commas)
  1. [Semicolons](#semicolons)
  1. [Type Casting & Coercion](#type-coercion)
  1. [Naming Conventions](#naming-conventions)
  1. [Modules](#modules)
  1. [Testing](#testing)
  1. [Performance](#performance)


## <a name='tables'>Tables</a>

  - Use the constructor syntax for table property creation where possible. Use
    trailing commas (last element) to minimize diffs in future updates.

    ```lua
    -- bad
    local player = {}
    player.name = "Jack"
    player.class = "Rogue"

    -- good
    local player = {
      name = "Jack",
      class = "Rogue",
    }
    ```

  - Define functions externally to table definition.

    ```lua
    -- bad
    local player = {
      attack = function() 
      -- ...stuff...
      end
    }

    -- good
    local function attack()
    end

    local player = {
      attack = attack
    }
    ```

  - Consider `nil` properties when selecting lengths.
    If a table (used as a list or array) can contain 'holes' or `nil` entries,
    the best approach is to use an `n` property to track the actual length.

    ```lua
    -- bad
    local list = { "hello", nil, "there" }

    -- good
    local list = { "hello", nil, "there", n = 3 }
    ```

  - When tables have functions, use `self` when referring to itself.

    ```lua
    -- bad
    local me = {
      fullname = function(this)
        return this.first_name .. " " .. this.last_name
      end
    }

    -- good
    local me = {
      fullname = function(self)
        return self.first_name .. " " .. self.last_name
      end
    }
    ```

    **[[back to top]](#TOC)**

## <a name='strings'>Strings</a>

  - Use double quotes `""` for strings.

    ```lua
    -- bad
    local name = 'Bob Parr'

    -- good
    local name = "Bob Parr"

    -- bad
    local fullName = 'Bob ' .. self.lastName

    -- good
    local fullName = "Bob " .. self.lastName
    ```

  - Strings longer than 80 characters should be written across multiple lines 
    using concatenation. This allows you to indent nicely.

    ```lua
    -- bad
    local errorMessage = "This is a super long error that was thrown because of Batman. When you stop to think about how Batman had anything to do with this, you would get nowhere fast."

    -- good
    local errorMessage = "This is a super long error that " ..
      "was thrown because of Batman. " ..
      "When you stop to think about " ..
      "how Batman had anything to do " ..
      "with this, you would get nowhere " ..
      "fast."
    ```

    **[[back to top]](#TOC)**


## <a name='functions'>Functions</a>
  - Prefer lots of small functions to large, complex functions. [Smalls Functions Are Good For The Universe](http://kikito.github.io/blog/2012/03/16/small-functions-are-good-for-the-universe/).

  - Prefer function syntax over variable syntax. This helps differentiate
    between named and anonymous functions. It also allows for recursion
    without forward declaring the local variable.

    ```lua
    -- bad
    local nope = function(name, options)
      -- ...stuff...
      return nope(name, options)  -- this fails because `nope` is unknown
    end

    -- good
    local function yup(name, options)
      -- ...stuff...
      return yup(name, options)  -- this works because `yup` is known
    end
    ```

  - Perform validation early and return as early as possible.

    ```lua
    -- bad
    local is_good_name = function(name, options, arg)
      local is_good = #name > 3
      is_good = is_good and #name < 30

      -- ...stuff...

      return is_bad
    end

    -- good
    local is_good_name = function(name, options, args)
      if #name < 3 or #name > 30 then return false end

      -- ...stuff...

      return true
    end
    ```

  **[[back to top]](#TOC)**


## <a name='properties'>Properties</a>

  - Use dot notation when accessing known properties.

    ```lua
    local luke = {
      jedi = true,
      age = 28
    }

    -- bad
    local isJedi = luke["jedi"]

    -- good
    local isJedi = luke.jedi
    ```

    **[[back to top]](#TOC)**


## <a name='variables'>Variables</a>

  - Always use `local` to declare variables. Not doing so will result in
    global variables and pollutes the global namespace.

    ```lua
    -- bad
    superPower = SuperPower()

    -- good
    local superPower = SuperPower()
    ```

    **[[back to top]](#TOC)**


## <a name='constants'>Constants</a>

  - Name constants in ALL_CAPS and declare them at the top of the module.

    ```lua
    -- bad
    -- do some stuff here
    local max_super_power = 100 

    -- good
    local MAX_SUPER_POWER = 100

    -- do some stuff here
    ```

    **[[back to top]](#TOC)**


## <a name='conditionals'>Conditional Expressions & Equality</a>

  - Use shortcuts when you can, unless you need to know the difference between
    false and nil.

    ```lua
    -- bad
    if name ~= nil then
      -- ...stuff...
    end

    -- good
    if name then
      -- ...stuff...
    end
    ```

  - Minimize branching where it makes sense.
    This will benefit the performance of the code. 

    ```lua
    --bad
    if thing then
      return false
    else
      -- ...do stuff...
    end

    --good
    if thing then
      return false
    end
    -- ...do stuff...
    ```

  - Prefer short code-paths where it makes sense. 

    ```lua
    --bad
    if not thing then
      -- ...stuff with lots of lines...
    else
      x = nil
    end

    --good
    if thing then
      x = nil
    else
      -- ...stuff with lots of lines...
    end
    ```

  - Prefer defaults to `else` statements where it makes sense. This results in
    less complex and safer code at the expense of variable reassignment, so
    situations may differ.

    ```lua
    --bad
    local function full_name(first, last)
      local name

      if first and last then
        name = first .. " " .. last
      else
        name = "John Smith"
      end

      return name
    end

    --good
    local function full_name(first, last)
      local name = "John Smith"

      if first and last then
        name = first .. " " .. last
      end

      return name
    end
    ```

  - Short ternaries are okay.

    ```lua
    local function default_name(name)
      -- return the default "Waldo" if name is nil
      return name or "Waldo"
    end

    local function brew_coffee(machine)
      return machine and machine.is_loaded and "coffee brewing" or "fill your water"
    end
    ```


    **[[back to top]](#TOC)**


## <a name='blocks'>Blocks</a>

  - Single line blocks are okay for *small* statements. Try to keep lines to 80 characters.
    Indent lines if they overflow past the limit.

    ```lua
    -- good
    if test then return false end

    -- good
    if test then
      return false
    end

    -- bad
    if test < 1 and do_complicated_function(test) == false or seven == 8 and nine == 10 then do_other_complicated_function() end

    -- good
    if test < 1 and do_complicated_function(test) == false or
       seven == 8 and nine == 10 then

      do_other_complicated_function() 
      return false 
    end
    ```

    **[[back to top]](#TOC)**


## <a name='whitespace'>Whitespace</a>

  - Use soft tabs set to 2 spaces. Tab characters and 4-space tabs result in public flogging.

    ```lua
    -- bad
    function() 
    ∙∙∙∙local name
    end

    -- bad
    function() 
    ∙local name
    end

    -- good
    function() 
    ∙∙local name
    end
    ```

  - Place 1 space before opening and closing braces. Place no spaces around parens.

    ```lua
    -- bad
    local test = {one=1}

    -- good
    local test = { one = 1 }

    -- bad
    dog.set("attr",{
      age = "1 year",
      breed = "Bernese Mountain Dog",
    })

    -- good
    dog.set("attr", {
      age = "1 year",
      breed = "Bernese Mountain Dog",
    })
    ```

  - Place an empty newline at the end of the file.

    ```lua
    -- bad
    (function(global) 
      -- ...stuff...
    end)(self)
    ```

    ```lua
    -- good
    (function(global) 
      -- ...stuff...
    end)(self)

    ```

  - Surround operators with spaces.

    ```lua
    -- bad
    local thing=1
    thing = thing-1
    thing = thing*1
    thing = 'string'..'s'

    -- good
    local thing = 1
    thing = thing - 1
    thing = thing * 1
    thing = 'string' .. 's'
    ```

  - Use one space after commas.

    ```lua
    --bad
    local thing = {1,2,3}
    thing = {1 , 2 , 3}
    thing = {1 ,2 ,3}

    --good
    local thing = {1, 2, 3}
    ```

  - Add a line break after multiline blocks and before `else` and `elseif` blocks.

    ```lua
    --bad
    if thing then
      -- ...stuff...
    end
    function derp()
      -- ...stuff...
    end
    local wat = 7
    if x == y then
      -- ...stuff...
    elseif
      -- ...stuff...
    else
      -- ...stuff...
    end

    --good
    if thing then
      -- ...stuff...
    end

    function derp()
      -- ...stuff...
    end

    local wat = 7

    if x == y then
      -- ...stuff...

    elseif
      -- ...stuff...

    else
      -- ...stuff...
    end
    ```

  - Delete unnecessary whitespace at the end of lines.

    **[[back to top]](#TOC)**

## <a name='commas'>Commas</a>

  - Trailing commas are encouraged as they reduce the diff size when reviewing.

    ```lua
    -- bad
    local thing = {
      once = 1,
      upon = 2,
      aTime = 3
    }

    -- good
    local thing = {
      once = 1,
      upon = 2,
      aTime = 3,
    }
    ```

    **[[back to top]](#TOC)**


## <a name='type-coercion'>Type Casting & Coercion</a>

  - Perform type coercion at the beginning of the statement. Use the built-in functions. (`tostring`, `tonumber`, etc.)

  - Use `tostring` for strings if you need to cast without string concatenation.

    ```lua
    -- bad
    local totalScore = reviewScore .. ""

    -- good
    local totalScore = tostring(reviewScore)
    ```

  - Use `tonumber` for Numbers.

    ```lua
    local inputValue = "4"

    -- bad
    local val = inputValue * 1

    -- good
    local val = tonumber(inputValue)
    ```

    **[[back to top]](#TOC)**


## <a name='naming-conventions'>Naming Conventions</a>

  - Use descriptive names. Use more descriptive names for variables with larger scopes,
    single letter names are ok for small scopes.

    ```lua
    -- bad
    local x = "a variable that will used through out an entire module"
    local sum
    for some_very_long_name = 1, 5
      sum = sum + some_very_long_name
    end
    
    -- good
    local descriptive_name = "a variable that will used through out an entire module"
    local sum
    for i = 1, 5
      sum = sum + i
    end
    ```

  - Use underscores for ignored variables in loops or when ignoring (intermediate) return values.
    Ignoring trailing return values with underscores is ok if it enhances clarity.

    ```lua
    --good
    for _, name in pairs(names) do
      -- ...stuff...
    end
    local result1, _, result3 = returns_three_values()
    ```

    ```lua
    --ok
    local some_value, _, _ = returns_three_values()
    ```

  - Use snake_case when naming objects, functions, and instances. Tend towards
    verbosity if unsure about naming.

    ```lua
    -- bad
    local OBJEcttsssss = {}
    local thisIsMyObject = {}
    local this-is-my-object = {}

    local c = function()
      -- ...stuff...
    end

    -- good
    local this_is_my_object = {}

    local function do_that_thing()
      -- ...stuff...
    end
    ```

  - Use PascalCase for factories.

    ```lua
    -- bad
    local player = require('player')

    -- good
    local Player = require('player')
    local me = Player({ name = 'Jack' })
    ```

    **[[back to top]](#TOC)**

  - Use `is` or `has` for boolean-returning functions.

    ```lua
    --bad
    local function evil(alignment)
      return alignment < 100
    end

    --good
    local function is_evil(alignment)
      return alignment < 100
    end
    ```

## <a name='modules'>Modules</a>

  - The module should return a table or function.
  - The module should not use the global namespace for anything ever.
  - The file should be named like the module.

  **[[back to top]](#TOC)**

## <a name='testing'>Testing</a>

  - Use [busted](http://olivinelabs.com/busted) and write lots of tests in a /spec 
    folder. Separate tests by module.
  - Use descriptive `describe` and `it` blocks so it's obvious to see what
    precisely is failing.
  - Test one functionality per test, repeat for multiple functionalities.

  - For the keyword assertions (`nil`, `true`, and `false`) use the `is_xxx` format

    ```lua
    --bad
    assert.Nil(something)

    --good
    assert.is_nil(something)
    ```

  - Use specific assertions where available. The specific assertion will provide better
    error messages when they fail, as they better understand the context.

    ```lua
    --bad
    local value = r.body.headers["x-something"]
    assert(value == "something","expected 'something'")

    --good
    local value = assert.request(r).has.header("x-something")
    assert.equal("something", value)
    ```

    **[[back to top]](#TOC)**

## <a name='performance'>Performance</a>

  - cache globals when used repeatedly. Locals are faster than looking up globals.

    ```lua
    --bad
    for i = 1, 20 do
      t[i] = math.floor(t[i])
    end

    --good
    local math_floor = math.floor
    for i = 1, 20 do
      t[i] = math_floor(t[i])
    end
    ```

  - Insertion into lists by using the length operator `#`. Never use the 'length' 
    functions (neither `table.getn` nor `string.len`).

    ```lua
    --bad
    local t = {}
    for i, value in ipairs({ "hello", "world" }) do
      table_insert(t,value)
    end
    print(table.getn(t))

    --good
    local t = {}
    for i, value in ipairs({ "hello", "world" }) do
      t[#t + 1] = value
    end
    print(#t)
    ```

    **[[back to top]](#TOC)**

**[[back to top]](#TOC)**