# HeroScript: Vlang Integration

## HeroScript Structure

HeroScript is a concise scripting language with the following structure:

```heroscript
!!actor.action_name
 param1: 'value1'
 param2: 'value with spaces'
 multiline_description: '
  This is a multiline description.
  It can span multiple lines.
  '
 arg1 arg2 // Arguments without keys
```

Key characteristics:

- **Actions**: Start with `!!`, followed by `actor.action_name` (e.g., `!!mailclient.configure`).
- **Parameters**: Defined as `key:value`. Values can be quoted for spaces.
- **Multiline Support**: Parameters like `description` can span multiple lines.
- **Arguments**: Values without keys (e.g., `arg1`).

## Processing HeroScript in Vlang

HeroScript can be parsed into a `playbook.PlayBook` object, allowing structured access to actions and their parameters, this is used in most of the herolib modules, it allows configuration or actions in a structured way.

```v
import incubaid.herolib.core.playbook { PlayBook }
import incubaid.herolib.ui.console

pub fn play(mut plbook PlayBook) ! {

 if plbook.exists_once(filter: 'docusaurus.define') {
  mut action := plbook.get(filter: 'docusaurus.define')!
  mut p := action.params
  //example how we get parameters from the action see aiprompts/herolib_core/core_params.md for more details
  path_build := p.get_default('path_build', '')!
  path_publish := p.get_default('path_publish', '')!
  reset := p.get_default_false('reset')
  use_doctree := p.get_default_false('use_doctree')
 }

 // Process 'docusaurus.add' actions to configure individual Docusaurus sites
 actions := plbook.find(filter: 'docusaurus.add')!
 for action in actions {
  mut p := action.params
  //do more processing here
 }
}
```

For detailed information on parameter retrieval methods (e.g., `p.get()`, `p.get_int()`, `p.get_default_true()`), refer to `aiprompts/herolib_core/core_params.md`.
