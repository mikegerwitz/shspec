<!--
  Copyright (C) 2014 Mike Gerwitz

  This file is part of shspec.

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

## License
shspec is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

