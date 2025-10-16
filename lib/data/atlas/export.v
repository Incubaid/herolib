module atlas

import incubaid.herolib.core.pathlib

@[params]
pub struct ExportArgs {
pub mut:
    destination string
    reset       bool = true
    include     bool = true  // process includes during export
    redis       bool = true
}

// Export all collections
pub fn (mut a Atlas) export(args ExportArgs) ! {
    mut dest := pathlib.get_dir(path: args.destination, create: true)!

    if args.reset {
        dest.empty()!
    }

    for _, mut col in a.collections {
        col.export(
            destination: dest
            reset:       args.reset
            include:     args.include
            redis:       args.redis
        )!
    }
}