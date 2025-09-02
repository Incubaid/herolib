# module toml.ast.walker


## Contents
- [inspect](#inspect)
- [walk](#walk)
- [walk_and_modify](#walk_and_modify)
- [Modifier](#Modifier)
- [Visitor](#Visitor)
- [Inspector](#Inspector)
  - [visit](#visit)
- [InspectorFn](#InspectorFn)

## inspect
```v
fn inspect(value &ast.Value, data voidptr, inspector_callback InspectorFn) !
```

inspect traverses and checks the AST Value node on a depth-first order and based on the data given

[[Return to contents]](#Contents)

## walk
```v
fn walk(visitor Visitor, value &ast.Value) !
```

walk traverses the AST using the given visitor

[[Return to contents]](#Contents)

## walk_and_modify
```v
fn walk_and_modify(modifier Modifier, mut value ast.Value) !
```

walk_and_modify traverses the AST using the given modifier and lets the visitor modify the contents.

[[Return to contents]](#Contents)

## Modifier
```v
interface Modifier {
	modify(mut value ast.Value) !
}
```

Modifier defines a modify method which is invoked by the walker on each Value node it encounters.

[[Return to contents]](#Contents)

## Visitor
```v
interface Visitor {
	visit(value &ast.Value) !
}
```

Visitor defines a visit method which is invoked by the walker on each Value node it encounters.

[[Return to contents]](#Contents)

## Inspector
## visit
```v
fn (i &Inspector) visit(value &ast.Value) !
```

visit calls the inspector callback on the specified Value node.

[[Return to contents]](#Contents)

## InspectorFn
```v
type InspectorFn = fn (value &ast.Value, data voidptr) !
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:20:35
