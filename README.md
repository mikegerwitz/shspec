<!--
  Copyright (C) 2014 Mike Gerwitz

  This file is part of GNU shspec.js.

  Copying and distribution of this file, with or without modification, are
  permitted in any medium without royalty provided the copyright notice and
  this notice are preserved.  This file is offered as-is, without warranty
  of any kind.
-->

# shspec
```sh
#!/bin/bash
describe shspec
  it is a BDD framework for shell
    expect current-shell-support
      to output "bash"

    expect pronounciation
      to succeed
      and to output "shell spec"
  end

  it is currently under development
    expect is-stable
      to succeed
      and to output "Because of self-testing"

    expect is-comprehensive
      to fail
      and to output "You should check back later."
  end
end
```

